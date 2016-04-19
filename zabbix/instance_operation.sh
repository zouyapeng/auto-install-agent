#!/bin/bash

virsh="virsh -c qemu:///system"

if [ ! -f "/opt/zabbix/instances/$1" ]; then 
    touch "/opt/zabbix/instances/$1" 
    echo 'disk_read 0' >> /opt/zabbix/instances/$1
    echo 'disk_write 0' >> /opt/zabbix/instances/$1
    echo 'interface_read 0' >> /opt/zabbix/instances/$1
    echo 'interface_write 0' >> /opt/zabbix/instances/$1
fi

function check_exist(){
    exist=`$virsh list --all --uuid | grep -c $1`
    if [ "$exist" = "1" ];then
        state=`$virsh domstate $1`
        if [ "$state" != 'running' ];then
            echo '2'
        else
            echo '1'
        fi 
    else
        echo '0'
    fi 

}


function instance_status(){
    if [ `check_exist $1` = "1" -o `check_exist $1` = "2" ];then
        echo `$virsh domstate $1`
    else
        echo 'deleted'
    fi
}

function get_disk(){
    echo `$virsh domblklist $1 | sed -e '1,2d' | awk '{print $1}'`
}

function get_interface(){
    echo `$virsh domiflist $1 | sed -e '1,2d' | awk '{print $1}'`
}

function instance_disk_write(){
    if [ `check_exist $1` != "1" ];then
        last=`awk '/disk_write/{print $2}' /opt/zabbix/instances/$1`
        echo $last
	return
    fi
    disks=(`get_disk $1`)
    values=0
    for disk in ${disks[@]}
    do
        value=`$virsh domblkstat $1 $disk | awk '/rd_bytes/{print $3}'`
        values=`expr $values + $value`
    done
    sed -i "/^disk_write/s/.*/disk_write $values/g" /opt/zabbix/instances/$1
    echo $values
}

function instance_disk_read(){
    if [ `check_exist $1` != "1" ];then
        last=`awk '/disk_read/{print $2}' /opt/zabbix/instances/$1`
        echo $last
	return
    fi
    disks=(`get_disk $1`)
    values=0
    for disk in ${disks[@]}
    do
        value=`$virsh domblkstat $1 $disk | awk '/wr_bytes/{print $3}'`
        values=`expr $values + $value`
    done
    sed -i "/^disk_read/s/.*/disk_read $values/g" /opt/zabbix/instances/$1
    echo $values
}

function instance_interface_read(){
    if [ `check_exist $1` != "1" ];then
        last=`awk '/interface_read/{print $2}' /opt/zabbix/instances/$1`
        echo $last
	return
    fi
    interfaces=(`get_interface $1`)
    values=0
    for interface in ${interfaces[@]}
    do
        value=`$virsh domifstat $1 $interface | awk '/rx_bytes/{print $3}'`
        values=`expr $values + $value`
    done
    sed -i "/^interface_read/s/.*/interface_read $values/g" /opt/zabbix/instances/$1
    echo $values
}

function instance_interface_write(){
    if [ `check_exist $1` != "1" ];then
        last=`awk '/interface_write/{print $2}' /opt/zabbix/instances/$1`
        echo $last
	return
    fi
    interfaces=(`get_interface $1`)
    values=0
    for interface in ${interfaces[@]}
    do
        value=`$virsh domifstat $1 $interface | awk '/tx_bytes/{print $3}'`
        values=`expr $values + $value`
    done
    sed -i "/^interface_write/s/.*/interface_write $values/g" /opt/zabbix/instances/$1
    echo $values
}


case $2 in
    state)
        instance_status $1
    ;;
    disk_write)
        instance_disk_write $1
    ;;
    disk_read)
        instance_disk_read $1
    ;;
    interface_write)
        instance_interface_write $1
    ;;
    interface_read)
        instance_interface_read $1
    ;;
esac
