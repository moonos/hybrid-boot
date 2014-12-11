#!/bin/sh

# set -e

Hybrid ()
{
	if [ -x /scripts/local-top/cryptroot ]
	then
		/scripts/local-top/cryptroot
	fi

	exec 6>&1
	exec 7>&2
	exec > boot.log
	exec 2>&1
	tail -f boot.log >&7 &
	tailpid="${!}"

	HYBRID_BOOT_CMDLINE="${HYBRID_BOOT_CMDLINE:-$(cat /proc/cmdline)}"
	Cmdline_old

	Debug

	Read_only

	Select_eth_device

	if [ -e /conf/param.conf ]
	then
		. /conf/param.conf
	fi

	if [ ! -z "${ROOT}" ]
	then
		# Do a local boot from hd
		if check_dev "${ROOT}"
		then
		    hybridfs_root=${mountpoint}
		fi
	else
		if [ -x /usr/bin/memdiskfind ]
        then
			MEMDISK=$(/usr/bin/memdiskfind)

			if [ $? -eq 0 ]
			then
					# We found a memdisk, set up phram
				modprobe phram phram=memdisk,${MEMDISK}

				# Load mtdblock, the memdisk will be /dev/mtdblock0
				modprobe mtdblock
			fi
		fi

		# Scan local devices for the image
		i=0
		while [ "$i" -lt 60 ]
		do
			hybridfs_root=$(find_hybridfs ${i})

			if [ -n "${hybridfs_root}" ]
			then
				break
			fi

			sleep 1
			i="$(($i + 1))"
		done
	fi

	if [ -z "${hybridfs_root}" ]
	then
		panic "Unable to find a medium containing a hybrid file system"
	fi

	Verify_checksums "${hybridfs_root}"

	mac="$(get_mac)"
	mac="$(echo ${mac} | sed 's/-//g')"
	mount_images_in_directory "${hybridfs_root}" "${rootmnt}" "${mac}"

	# At this point /root should contain the final root filesystem.
	# Move all mountpoints below /hybrid into /root/lib/hybrid/mount.
	# This has to be done after mounting the root filesystem to /
	# otherwise these mount points won't be accessible from the running system.
	for _MOUNT in $(cat /proc/mounts | cut -f 2 -d " " | grep -e "^/hybrid/")
	do
		local newmount
		newmount="${rootmnt}/lib/hybrid/mount/${_MOUNT#/hybrid/}"
		mkdir -p "${newmount}"
		mount -o move "${_MOUNT}" "${newmount}" > /dev/null 2>&1 || \
		mount -o bind "${_MOUNT}" "${newmount}" > /dev/null || \
		log_warning_msg "W: failed to move or bindmount ${_MOUNT} to ${newmount}"
	done

	if [ -n "${ROOT_PID}" ]
	then
		echo "${ROOT_PID}" > "${rootmnt}"/lib/hybrid/root.pid
	fi

	log_end_msg

	# unionfs-fuse needs /dev to be bind-mounted for the duration of
	# hybrid-bottom; udev's init script will take care of things after that
	case "${UNIONTYPE}" in
		unionfs-fuse)
			mount -n -o bind /dev "${rootmnt}/dev"
			;;
	esac


	# aufs2 in kernel versions around 2.6.33 has a regression:
	# directories can't be accessed when read for the first the time,
	# causing a failure for example when accessing /var/lib/fai
	# when booting FAI, this simple workaround solves it
	ls /root/* >/dev/null 2>&1

	# if we do not unmount the ISO we can't run "fsck /dev/ice" later on
	# because the mountpoint is left behind in /proc/mounts, so let's get
	# rid of it when running from RAM
	if [ -n "$FINDISO" ] && [ "${TORAM}" ]
	then
		losetup -d /dev/loop0

		if is_mountpoint /root/lib/hybrid/mount/findiso
		then
			umount /root/lib/hybrid/mount/findiso
			rmdir --ignore-fail-on-non-empty /root/lib/hybrid/mount/findiso \
				>/dev/null 2>&1 || true
		fi
	fi

	if [ -L /root/etc/resolv.conf ] ; then
		# assume we have resolvconf
		DNSFILE="${rootmnt}/etc/resolvconf/resolv.conf.d/base"
	else
		DNSFILE="${rootmnt}/etc/resolv.conf"
	fi
	if [ -f /etc/resolv.conf ] && [ ! -s ${DNSFILE} ]
	then
		log_begin_msg "Copying /etc/resolv.conf to ${DNSFILE}"
		cp -v /etc/resolv.conf ${DNSFILE}
		log_end_msg
	fi

	if ! [ -d "/lib/hybrid/boot" ]
	then
		panic "A wrong rootfs was mounted."
	fi

	Fstab
	Netbase

	Swap

	case "${UNIONFS}" in
		unionfs-fuse)
			umount "${rootmnt}/dev"
			;;
	esac

	exec 1>&6 6>&-
	exec 2>&7 7>&-
	kill ${tailpid}
	[ -w "${rootmnt}/var/log/" ] && mkdir -p "${rootmnt}/var/log/hybrid" && cp boot.log "${rootmnt}/var/log/hybrid" 2>/dev/null
}
