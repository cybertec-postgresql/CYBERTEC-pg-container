#!/bin/bash

# Define some needed ENVs & Variables
export NSS_USERNAME=${NSS_USERNAME:-'postgres'}
export NSS_USERDESC=${NSS_USERDESC:-'PostgreSQL Server'}
export CURRENT_USER=$(id -u)
export CURRENT_GROUP=$(id -g)

# Prepare Folders and Files
NSS_ROOT_DIR="/tmp/nss_wrapper"
NSS_PASSWD="${NSS_ROOT_DIR}/passwd"
NSS_GROUP="${NSS_ROOT_DIR}/group"

mkdir -p ${NSS_ROOT_DIR}
chmod g+rwx ${NSS_ROOT_DIR}

[[ -f "${NSS_PASSWD}" ]] || cp "/etc/passwd" "${NSS_PASSWD}"
[[ -f "${NSS_GROUP}" ]] || cp "/etc/group" "${NSS_GROUP}"

# Check if User and Group already exists, if not add it
if [[ ! $(cat "${NSS_PASSWD}") =~ ${NSS_USERNAME}:x:${CURRENT_USER} ]]; then
    passwd_tmp="${NSS_WRAPPER_DIR}/passwd_tmp"
    cp "${NSS_PASSWD}" "${NSS_PASSWD}.tmp"
    sed -i "/${NSS_USERNAME}:x:/d" "${NSS_PASSWD}.tmp"
    sed -i "/${CURRENT_USER}:x:/d" "${NSS_PASSWD}.tmp"
    echo '${NSS_USERNAME}:x:${CURRENT_USER}:${CURRENT_GROUP}:${NSS_USERDESC}:${HOME}:/bin/bash\n' >> "${NSS_PASSWD}.tmp"
    envsubst < "${NSS_PASSWD}.tmp" > "${NSS_PASSWD}"
    rm "${NSS_PASSWD}.tmp"
    echo "User was added via nss_wrapper"
fi

if [[ ! $(cat "${NSS_GROUP}") =~ ${NSS_USERNAME}:x:${CURRENT_USER} ]]; then
    cp "${NSS_GROUP}" "${NSS_GROUP}.tmp"
    sed -i "/${NSS_USERNAME}:x:/d" "${NSS_GROUP}.tmp"
    printf '${NSS_USERNAME}:x:${CURRENT_USER}:${NSS_USERNAME}\n' >> "${NSS_GROUP}.tmp"
    envsubst < "${NSS_GROUP}.tmp" > "${NSS_GROUP}"
    rm "${NSS_GROUP}.tmp"
    echo "Group was added via nss_wrapper"
fi

export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
export NSS_WRAPPER_PASSWD="${NSS_PASSWD}"
export NSS_WRAPPER_GROUP="${NSS_GROUP}"

exec "$@"

