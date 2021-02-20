#!/bin/sh
ifconfig -a | grep eth0
RESULT=$?
if [ $RESULT -eq 0 ]; then
	ifconfig eth0 10.113.5.6 netmask 255.255.0.0
	piradio&
	rftool
fi
