#!/bin/bash
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    <http://www.gnu.org/licenses/>.
#

VM_UUID=$4
MYSQL_HOST=$1
MYSQL_USER=$2
MYSQL_PASSWORD=$3

if [ -z "$4" ]; then echo "Run sh delete_vm_from_db.sh \$mysql_host \$mysql_user \$mysql_password \$vm_uuid"$'\n'; echo "Eg: sh delete_vm_from_db.sh localhost root meditech2019 38a7dd00-6ba5-4572-b2ef-cdd93f976768"; exit 1; fi
Q=`cat <<EOF
SELECT display_name FROM nova.instances WHERE instances.uuid = '$VM_UUID';
EOF`
RQ=`mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD --batch --skip-column-names -e "$Q"`

VMNAME=`echo $RQ | cut -d' ' -f1`

if [ -z "$VMNAME" ]; then echo "VMNAME for $VM_UUID not found"; exit 1; fi

echo "VMNAME: $VMNAME"
echo "UUID: $VM_UUID"

echo "Delete $VMNAME? (y/n)"
read -e YN
if [ "$YN" != 'y' ]; then echo "Exiting...";exit 1;fi

Q=`cat <<EOF
DELETE FROM nova.instance_extra WHERE instance_extra.instance_uuid = '$VM_UUID';
DELETE FROM nova.instance_faults WHERE instance_faults.instance_uuid = '$VM_UUID';
DELETE FROM nova.instance_id_mappings WHERE instance_id_mappings.uuid = '$VM_UUID';
DELETE FROM nova.instance_info_caches WHERE instance_info_caches.instance_uuid = '$VM_UUID';
DELETE FROM nova.instance_system_metadata WHERE instance_system_metadata.instance_uuid = '$VM_UUID';
DELETE FROM nova.security_group_instance_association WHERE security_group_instance_association.instance_uuid = '$VM_UUID';
DELETE FROM nova.block_device_mapping WHERE block_device_mapping.instance_uuid = '$VM_UUID';
DELETE FROM nova.fixed_ips WHERE fixed_ips.instance_uuid = '$VM_UUID';
DELETE FROM nova.instance_actions_events WHERE instance_actions_events.action_id in (SELECT id from nova.instance_actions where instance_actions.instance_uuid = '$VM_UUID');
DELETE FROM nova.instance_actions WHERE instance_actions.instance_uuid = '$VM_UUID';
DELETE FROM nova.virtual_interfaces WHERE virtual_interfaces.instance_uuid = '$VM_UUID';
DELETE FROM nova.instances WHERE instances.uuid = '$VM_UUID';
EOF`
RQ=`mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD --batch --skip-column-names -e "$Q"`
echo "$RQ"
