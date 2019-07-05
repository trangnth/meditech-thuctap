# Fix inconsistent Openstack volumes and instances from Cinder and Nova via the database

Bạn sẽ gặp phải một số trường hợp ví dụ như việc xóa volumes vì một lỗi nào đó mà không thể thực hiện, khiến OPS bị delay và thông báo rằng volume error deleting. Hoặc đôi khi thực tế bạn thực hiện xóa nhầm máy ảo ở phía kvm hoặc volume ở backend ceph, nfs,... Khi ấy, điều bạn cần là cập nhật lại db cho nó trở về đúng trạng thái.

**Lưu ý quan trọng:**

Việc này là hoàn toàn không được khuyến cáo nếu như bạn chưa thực sự chắc chắn rằng mình đã fix lỗi ở phía backend bởi việc chỉnh sửa DB không phải là fix lỗi.

### Xóa máy ảo

- Backend của bạn gặp vấn đề khi xóa máy ảo. Bạn đã thực hiện xóa toàn bộ ở backend (volume, hoặc file disk local), remove khỏi domain bằng virsh,... Tuy nhiên nova vẫn nhận định rằng nó đang ở trạng thái active. Câu query sau có thể đưa vm vào trạng thái deleted

Hãy thử command này trước

`nova force-delete`

```
$ mysql nova_db> update instances set deleted='1', vm_state='deleted', deleted_at=now() where uuid='$vm_uuid' and project_id='$project_uuid';
```

Nếu bạn thực sự muốn delete khỏi db chứ không phải đánh dấu nó là đã bị delete thì bạn cần thực hiện 1 số câu lệnh sau

```
$ mysql nova_db> delete from instance_faults where instance_faults.instance_uuid = '$vm_uuid';
> delete from nova.instance_extra where instance_extra.instance_uuid = '$vm_uuid';
> delete from instance_id_mappings where instance_id_mappings.uuid = '$vm_uuid';
> delete from instance_info_caches where instance_info_caches.instance_uuid = '$vm_uuid';
> delete from instance_system_metadata where instance_system_metadata.instance_uuid = '$vm_uuid';
> delete from security_group_instance_association where security_group_instance_association.instance_uuid = '$vm_uuid';
> delete from block_device_mapping where block_device_mapping.instance_uuid = '$vm_uuid';
> delete from fixed_ips where fixed_ips.instance_uuid = '$vm_uuid';
> delete from instance_actions_events where instance_actions_events.action_id in (select id from instance_actions where instance_actions.instance_uuid = '$vm_uuid');
> delete from instance_actions where instance_actions.instance_uuid = '$vm_uuid';
> delete from virtual_interfaces where virtual_interfaces.instance_uuid = '$vm_uuid';
> delete from instances where instances.uuid = '$vm_uuid';
```

### Thay đổi host cho VM

Trường hợp migrate hoặc resize bị fail, disk trên thực tế đã được chuyển sang host khác hoặc nó vẫn nằm ở dưới shared storage nhưng nova vẫn bị confuse. Hãy chắc chắn rằng domain info của máy ảo đang nằm trên 1 host và disk cũng vậy (bạn có thể dùng lsof và tgt-adm)

Câu query sau sẽ thay đổi host cho vm

```
$ mysql nova_db> update instances set host='compute-hostname.domain',node='compute-hostname.domain' where uuid='$vm_uuid' and project_id='$project_uuid';
```

### Đưa volume vào trạng thái detach

Trường hợp này câu lệnh detach của bạn báo lỗi, volume ở trạng thái detaching nhưng thực tế bạn đã chắc chắn rằng ở phía backend volume đang không được sử dụng bởi vm nào.

Hãy thử câu lệnh sau trước

`cinder reset-state --state available $volume_uuid`

Nếu không được, bạn có thể thay đổi state bằng câu lệnh sau

```
$ mysql cinder_db> update cinder.volumes set attach_status='detached',status='available' where id ='$volume_uuid';
```

Hãy chắc chắn rằng không có dữ liệu nào được ghi vào volume.

### Detach volume từ nova

Một vài trường hợp cinder đã đánh dấu rằng volume đã được detach nhưng nova thì không. Vẫn như trước đó, bạn phải chắc chắn rằng volume đã thực sự detach ở phía backend. Bạn có thể sử dụng câu lệnh sau :

```
mysql nova_db> delete from block_device_mapping where not deleted and volume_id='$volume_uuid' and project_id='$project_uuid';
```

### Xóa volume

Trong trường hợp volume báo lỗi `Error deleting`. Thử câu lệnh này trước

`cinder reset-state --state available $volume_uuid`

Sau đó xóa lại bằng câu lệnh

`cinder delete $VOLUME_ID`

Hoặc nếu bạn có quyền admin

`cinder force-delete $VOLUME_ID`

Nếu không được, hãy check backend của bạn xem điều gì đã xảy ra với volume của bạn và check xem nó đã bị remove hay chưa. Nếu nó chưa bị remove, hãy remove nó và update db bằng query sau

```
$ mysql cinder_db> update volumes set deleted=1,status='deleted',deleted_at=now(),updated_at=now() where deleted=0 and id='$volume_uuid';
```

**Một lần nữa, những gì ở bài viết này là hoàn toàn không khuyến cáo, hãy chắc rằng bạn đã check tất cả các cách cũng như nguyên nhân trước khi thực hiện**
