export IMAGE_BASENAME = "kncminer"
IMAGE_FSTYPES = "cpio.gz"
IMAGE_INSTALL = " busybox base-files base-passwd initscripts sysvinit sysvinit-pidof angstrom-version tinylogin i2c-tools screen dropbear libcurl lighttpd cgminer angstrom-packagegroup-boot"
inherit image
