#!/bin/sh

#set -e

Fstab ()
{
	# FIXME: stop hardcoding overloading of initramfs-tools functions
	. /scripts/functions
	. /lib/hybrid/boot/9990-initramfs-tools.sh

	if [ -n "${NOFSTAB}" ]
	then
		return
	fi

	log_begin_msg "Configuring fstab"

	if ! grep -qs  "^${UNIONTYPE}" /root/etc/fstab.d/hybrid
	then
		echo "${UNIONTYPE} / ${UNIONTYPE} rw 0 0" >> /root/etc/fstab.d/hybrid
	fi

	if ! grep -qs "^tmpfs /tmp" /root/etc/fstab.d/hybrid
	then
		echo "tmpfs /tmp tmpfs nosuid,nodev 0 0" >> /root/etc/fstab.d/hybrid
	fi

	log_end_msg
}
