#!/bin/bash

set -e

# environment variables
: ${CIFS_DISK_IMAGE_SIZE_MB:=1024}
: ${CIFS_DISK_IMAGE_PATH:=/var/cifs-data}

: ${EXPORT_PATH:="/data/cifs"}

create_cifs_disk_image() {
	mkdir -p ${CIFS_DISK_IMAGE_PATH}
	dd if=/dev/zero of="${CIFS_DISK_IMAGE_PATH}/data.img" count="${CIFS_DISK_IMAGE_SIZE_MB}" bs=1M
	mkfs.ext4 -F "${CIFS_DISK_IMAGE_PATH}/data.img"
	mount "${CIFS_DISK_IMAGE_PATH}/data.img" ${EXPORT_PATH}
	chmod 777 "${EXPORT_PATH}"
}

bootstrap_config() {
	echo "* Writing configuration"
cat <<END >>/etc/samba/smb.conf
[backupstore]
   comment = backupstore
   path = "${EXPORT_PATH}"
   read only = no
   public = yes
   guest only = yes
   writable = yes
   force create mode = 0666
   force directory mode = 0777
   browseable = yes
END
}


if [ ! -f ${EXPORT_PATH} ]; then
	mkdir -p "${EXPORT_PATH}"
fi


echo "Creating CIFS disk image with size ${CIFS_DISK_IMAGE_SIZE_MB}MB ..."
create_cifs_disk_image
bootstrap_config

bash /usr/bin/samba.sh

