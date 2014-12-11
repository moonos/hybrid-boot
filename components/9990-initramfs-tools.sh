#!/bin/sh

#set -e

log_wait_msg ()
{
	# Print a message and wait for enter
	if [ -x /bin/plymouth ] && plymouth --ping
	then
		plymouth message --text="$@"
		plymouth watch-keystroke | read nunya
	fi

	_log_msg "Waiting: ${@} ... \n"
}

# Override maybe_break from scripts/functions
maybe_break()
{
	if [ "${break}" = "$1" ]; then
		# Call original panic
		. /scripts/functions
		panic "Spawning shell within the initramfs"
	fi
}

# Override panic from scripts/functions
panic()
{
	for _PARAMETER in ${HYBRID_BOOT_CMDLINE}
	do
		case "${_PARAMETER}" in
			panic=*)
				panic="${_PARAMETER#*panic=}"
				;;
		esac
	done

	HYBRIDLOG="\033[1;37m/boot.log\033[0m"
	DEBUG="\033[1;37mdebug\033[0m"

	# Reset redirections to avoid buffering
	exec 1>&6 6>&-
	exec 2>&7 7>&-
	kill ${tailpid}

	printf "\n\n"
	printf "  \033[1;37mBOOT FAILED!\033[0m\n"
	printf "\n"
	printf "  This System image failed to boot.\n\n"

	printf "  The file ${HYBRIDLOG} contains some debugging information but booting with the\n"
	printf "  ${DEBUG} command-line parameter will greatly increase its verbosity which is\n"
	printf "  extremely useful when diagnosing issues.\n\n"

	if [ -n "${panic}" ]; then
		printf "  system will now restart your system. "
	else
		printf "  system will now start a shell. "
	fi
	printf "The error message was:\n\n    "

	# Call original panic
	. /scripts/functions
	panic "$@"
}
