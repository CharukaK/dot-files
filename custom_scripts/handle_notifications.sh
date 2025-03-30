#!/bin/sh

case "$1" in
	action)
		makoctl menu fuzzel -d -p 'Choose Action: '
		;;
	dismiss)
		makoctl dismiss
		;;
	*)
		echo "Usage: $0 {action|dismiss}"
        	exit 2
esac

exit 0

