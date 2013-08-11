#!/bin/bash
# -----------------------------------
# read1wtemp.sh
# Copyright 2013 Kevin Anthony
# kevin@anthonynet.org
# v1.0
#
# Released under Modified BSD License
# -----------------------------------
# Reads 1-wire Temperature sensors on Raspberry Pi and reports to Graphite
# Requires Netcat be installed as well as w1_therm and w1_gpio modules loaded

SENSORNAME=$1
SENSORVALUE=$2
GRAPHITESERVER=$3

# Print usage if we didn't get the right number of params
if [[ $# != 3 ]]; then
	echo "Usage: read1wtemp.sh sensor_name w1_device_name graphite_server" >&2
	exit 1
fi

# Check that carbon is listening at the provided address
if ! nc -w 2 -z $GRAPHITESERVER 2003; then
	echo "Cannot connect to Carbon at ${GRAPHITESERVER}:2003" >&2
	exit 1
fi

# Only proceed if the sensor actually exists
if [[ -d /sys/bus/w1/devices/${SENSORVALUE} ]]; then
	# Date in epoch timestamp format
	DATENOW=`date +%s`

	# Grep out the value and divide by 1000 to get the proper vlaue
	TEMPNOW=`grep 't=' /sys/bus/w1/devices/${SENSORVALUE}/w1_slave | awk -F'=' '{ print $2 / 1000 }'`

	# Not sure why we get this -0.062 value now and then, filtering it out either way
	if [[ $TEMPNOW != -0.062 ]]; then
		echo "${SENSORNAME} ${TEMPNOW} ${DATENOW}" | nc ${GRAPHITESERVER} 2003
	fi
else
	echo "Cannot find /sys/bus/w1/devices/${SENSORVALUE}" >&2
	exit 1
fi
