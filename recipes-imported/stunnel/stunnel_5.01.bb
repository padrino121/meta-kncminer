SUMMARY = "SSL encryption wrapper between remote client and local (inetd-startable) or remote server."
SECTION = "net"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=45e8e7befe9a0f7e0543b78dfeebde20"
DEPENDS = "openssl"

SRC_URI = "https://www.stunnel.org/downloads/${BP}.tar.gz"

SRC_URI[md5sum] = "7b63266b6fa05da696729e245100da65"
SRC_URI[sha256sum] = "2565bf58ffe8a612304c64df621105b2e42d6e389e815ed4205dbeec4f3f886b"

inherit autotools

EXTRA_OECONF += "--with-ssl='${STAGING_INCDIR}' --disable-fips"
