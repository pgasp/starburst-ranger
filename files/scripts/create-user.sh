#!/bin/bash

set -euo pipefail

ranger_admin_url="http://localhost:6080"

function usage() {
	cat <<EOF
$(basename $0) [OPTIONS...] <app_user> <app_password>
If app_user does not exist, create it.
-l; Set Ranger Admin server url (default: ranger_admin_url variable)
-u; Set Ranger Admin username (default: ranger_username variable)
-p; Set Ranger Admin user password (default: ranger_password variable). If password is not given it's asked from the tty.
EOF
}

while getopts ":l:u:p:h" arg; do
	case $arg in
		l)
			ranger_admin_url=${OPTARG}
			;;
		u)
			ranger_username=${OPTARG}
			;;
		p)
			ranger_password=${OPTARG}
			;;
		h)
			usage
			exit 0
			;;
		"")
			break
			;;
		*)
			echo "Unknown option provided ${1:-}"
			usage
			exit 1
			;;
	esac
done

shift $((OPTIND - 1))

if [ $# != 2 ]; then
	echo "Invalid arguments." >&2
	usage
	exit 1
fi

if [ -z "${ranger_password:-}" ]; then
	read -rsp "Enter Password: " ranger_password
	printf "\n"
fi
app_user="${1}"
app_password="${2}"

check_user() {
	curl \
		--silent \
		--fail \
		--output /dev/null \
		--user "${app_user}:${app_password}" \
		--header 'Accept: application/json' \
		"${ranger_admin_url}/service/xusers/users"
}

create_user() {
	curl \
		-X POST \
		--silent \
		--show-error \
		--user "${ranger_username}:${ranger_password}" \
		--header 'Content-Type: application/json' \
		--data '{
            "name":"'${app_user}'",
            "firstName":"'${app_user}'",
            "lastName": null,
            "emailAddress" : null,
            "description" : "Do not change password",
            "password" : "'${app_password}'",
            "groupIdList":[],
            "status":1,
            "isVisible":0,
            "userRoleList": [ "ROLE_SYS_ADMIN" ],
            "userSource": 0
            }' \
		"${ranger_admin_url}/service/xusers/secure/users"
}

if check_user; then
	echo "User ${app_user} already exists"
else
	create_user
	if check_user; then
		echo -e "\nUser ${app_user} created"
	else
		echo -e "\nCannot create user ${app_user}" >&2
		exit 2
	fi
fi
