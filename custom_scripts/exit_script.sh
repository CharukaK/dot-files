#!/bin/bash

options=("lock" "logout" "reboot" "shutdown")

result=$(printf "%s\n" "${options[@]}" | fuzzel -d -p 'Hyprland Exit: ')

case "$result" in
	lock)
		# i3lock-fancy
        hyprlock
		;;
	logout)
		# i3-msg exit
        hyprctl dispatch exit
		;;
	reboot)
		reboot
		;;
	shutdown)
		poweroff
		;;
	*)
		echo "Usage: $0 {lock|logout|suspend|hibernate|reboot|shutdown}"
        	exit 2
esac

exit 0

