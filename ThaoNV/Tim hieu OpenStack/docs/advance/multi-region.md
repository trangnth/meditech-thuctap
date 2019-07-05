# OpenStack multi region

## Mô hình

<img src="https://i.imgur.com/JqKqewk.png">

Mô hình multi region được sử dụng khi bạn có nhiều hơn 1 cụm OpenStack được đặt tại các vị trí khác nhau. Hoặc các cụm đó khác nhau về hypervisor sử dụng,...và bạn muốn quản lý chúng một cách tập trung.

## Các bước thực hiện

- Tạo ra endpoint cho region thứ 2 (RegionTwo) trỏ về ip của RegionOne.

- Tiếp tục tạo các service endpoints khác cho RegionTwo.

- Chỉnh sửa hoặc tạo mới cấu hình cho các service của RegionTwo

IP RegionOne: 192.168.40.15

IP RegionTwo: 192.168.40.23

### Tạo endpoint cho region 2

- Trên region 1

```
keystone-manage bootstrap --bootstrap-password meditech2019 \
  --bootstrap-admin-url http://192.168.40.15:5000/v3/ \
  --bootstrap-internal-url http://192.168.40.15:5000/v3/ \
  --bootstrap-public-url http://192.168.40.15:5000/v3/ \
  --bootstrap-region-id RegionTwo
```

### Cấu hình các dịch vụ khác

- Cấu hình keystone

Có thể bỏ.

Cập nhật file biến môi trường trên cả 2 region

Thêm

`export OS_REGION_NAME=RegionOne`

vs

`export OS_REGION_NAME=RegionTwo`

- Cập nhật các cấu hình khác

Tạo các endpoint

```
openstack endpoint create --region RegionTwo \
  image public http://192.168.40.23:9292
openstack endpoint create --region RegionTwo \
  image admin http://192.168.40.23:9292
openstack endpoint create --region RegionTwo \
  image internal http://192.168.40.23:9292

openstack endpoint create --region RegionTwo \
  compute public http://192.168.40.23:8774/v2.1
openstack endpoint create --region RegionTwo \
  compute admin http://192.168.40.23:8774/v2.1
openstack endpoint create --region RegionTwo \
  compute internal http://192.168.40.23:8774/v2.1

openstack endpoint create --region RegionTwo placement public http://192.168.40.23:8778
openstack endpoint create --region RegionTwo placement admin http://192.168.40.23:8778
openstack endpoint create --region RegionTwo placement internal http://192.168.40.23:8778

openstack endpoint create --region RegionTwo \
  network public http://192.168.40.23:9696
openstack endpoint create --region RegionTwo \
  network internal http://192.168.40.23:9696
openstack endpoint create --region RegionTwo \
  network admin http://192.168.40.23:9696

openstack endpoint create --region RegionTwo \
  volumev2 public http://192.168.40.23:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionTwo \
  volumev2 internal http://192.168.40.23:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionTwo \
  volumev2 admin http://192.168.40.23:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionTwo \
  volumev3 public http://192.168.40.23:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionTwo \
  volumev3 internal http://192.168.40.23:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionTwo \
  volumev3 admin http://192.168.40.23:8776/v3/%\(project_id\)s
```

Chỉnh sửa cấu hình

Thay đổi thông tin xác thực, cũng như các url endpoint

Thêm vào `region_name = RegionTwo`

Ví dụ glance-api.conf

```
[DEFAULT]
bind_host = 192.168.40.23
registry_host = 192.168.40.23
show_image_direct_url = True
enable_v1_api=False
enable_v2_api=True
[cinder]
cinder_os_region_name = RegionTwo
[cors]
[database]
connection = mysql+pymysql://glance:meditech2019@192.168.40.23/glance
[file]
[glance.store.http.store]
[glance.store.rbd.store]
[glance.store.sheepdog.store]
[glance.store.swift.store]
[glance.store.vmware_datastore.store]
[glance_store]
default_store = rbd
stores = file,http,rbd
rbd_store_pool = images2
rbd_store_user = glance2
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_chunk_size = 8
[image_format]
[keystone_authtoken]
region_name = RegionTwo
www_authenticate_uri  = http://192.168.40.15:5000
auth_url = http://192.168.40.15:5000
memcached_servers = 192.168.40.23:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = meditech2019
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[paste_deploy]
flavor = keystone
[profiler]
[store_type_location_strategy]
[task]
[taskflow_executor]
```
nova.conf

```
[DEFAULT]
my_ip = 192.168.40.23
enabled_apis = osapi_compute,metadata
use_neutron = True
osapi_compute_listen=192.168.40.23
metadata_host=192.168.40.23
metadata_listen=192.168.40.23
metadata_listen_port=8775
firewall_driver = nova.virt.firewall.NoopFirewallDriver
transport_url = rabbit://openstack:meditech2019@192.168.40.23:5672
[api]
auth_strategy = keystone
[api_database]
connection = mysql+pymysql://nova:meditech2019@192.168.40.23/nova_api
[barbican]
[cache]
backend = oslo_cache.memcache_pool
enabled = true
memcache_servers = 192.168.40.23:11211
[cells]
[cinder]
os_region_name = RegionTwo
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[database]
connection = mysql+pymysql://nova:meditech2019@192.168.40.23/nova
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://192.168.40.23:9292
[guestfs]
[healthcheck]
[hyperv]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
region_name = RegionTwo
auth_url = http://192.168.40.15:5000/v3
memcached_servers = 192.168.40.23:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = meditech2019
[libvirt]
[matchmaker_redis]
[metrics]
[mks]
[neutron]
url = http://192.168.40.23:9696
auth_url = http://192.168.40.15:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionTwo
project_name = service
username = neutron
password = meditech2019
service_metadata_proxy = true
metadata_proxy_shared_secret = meditech2019
[notifications]
[osapi_v21]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[pci]
[placement]
region_name = RegionTwo
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://192.168.40.15:5000/v3
username = placement
password = meditech2019
[placement_database]
connection = mysql+pymysql://placement:meditech2019@192.168.40.23/placement
[powervm]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
discover_hosts_in_cells_interval = 300
[serial_console]
[service_user]
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
novncproxy_host=192.168.40.23
enabled = true
#vncserver_listen = 192.168.40.23
#vncserver_proxyclient_address = 192.168.40.23
novncproxy_base_url = http://192.168.40.23:6080/vnc_auto.html
[workarounds]
[wsgi]
[xenserver]
[xvp]
[zvm]
```

**Lưu ý:**

Option `os_region_name` cần được cấu hình trên cả node compute

neutron.conf

```
[DEFAULT]
bind_host = 192.168.40.23
core_plugin = ml2
service_plugins = router
transport_url = rabbit://openstack:meditech2019@192.168.40.23:5672
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
allow_overlapping_ips = True
dhcp_agents_per_network = 2
[agent]
[cors]
[database]
connection = mysql+pymysql://neutron:meditech2019@192.168.40.23/neutron
[keystone_authtoken]
region_name = RegionTwo
www_authenticate_uri = http://192.168.40.15:5000
auth_url = http://192.168.40.15:5000
memcached_servers = 192.168.40.23:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = meditech2019
[matchmaker_redis]
[nova]
auth_url = http://192.168.40.15:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionTwo
project_name = service
username = nova
password = meditech2019
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[quotas]
[ssl]
```

cinder.conf

```
[DEFAULT]
my_ip = 192.168.40.23
transport_url = rabbit://openstack:meditech2019@192.168.40.23:5672
auth_strategy = keystone
osapi_volume_listen = 192.168.40.23
enable_v3_api = True
notification_driver = messagingv2
enabled_backends = ceph
glance_api_servers = http://192.168.40.23:9292
glance_api_version = 2
host=ceph
[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]
[database]
connection = mysql+pymysql://cinder:meditech2019@192.168.40.23/cinder
[fc-zone-manager]
[healthcheck]
[key_manager]
[keystone_authtoken]
region_name = RegionTwo
auth_uri = http://192.168.40.15:5000
auth_url = http://192.168.40.15:5000
memcached_servers = 192.168.40.23:11211
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = cinder
password = meditech2019
[matchmaker_redis]
[nova]
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[oslo_versionedobjects]
[profiler]
[service_user]
[ssl]
[vault]
[ceph]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
volume_backend_name = ceph
rbd_pool = volumes2
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
rbd_user = cinder2
rbd_secret_uuid = a8b264e0-a34f-4dff-b8e4-0104221ba6a0
report_discard_supported = true
```

**Lưu ý:**

Bổ sung option `glance_api_servers`

<img src="https://i.imgur.com/mfWNkqA.png">
