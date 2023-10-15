#!/bin/sh
ifconfig -a | grep eth0
RESULT=$?
if [ $RESULT -eq 0 ]; then
	ifconfig eth0 down
	ifconfig eth0 192.168.1.101 up
	ifconfig eth0 down
	ifconfig eth0 192.168.1.101 up
	ifconfig eth0 192.168.1.101 netmask 255.255.255.0
	/etc/init.d/networking stop
	ifconfig eth0 hw ether 02:02:02:02:02:43
	ifconfig eth0 192.168.1.101 up
	/etc/init.d/networking start
	sleep 3

  piradio&
	rftool&
fi
echo "Done!"

