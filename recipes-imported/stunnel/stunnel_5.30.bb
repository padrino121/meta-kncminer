SUMMARY = "SSL encryption wrapper between remote client and local (inetd-startable) or remote server."
SECTION = "net"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=45e8e7befe9a0f7e0543b78dfeebde20"
DEPENDS = "openssl"

SRC_URI = "https://www.stunnel.org/downloads/${BP}.tar.gz"

SRC_URI[md5sum] = "7bbf27296a83c0b752f6bb6d1b750b19"
SRC_URI[sha256sum] = "7d6eb389f6a1954b3bcf6c71d4ae3c5f9dde1990dd0b9e0cb1c7caf138d60570"

inherit autotools

EXTRA_OECONF += "--with-ssl='${STAGING_INCDIR}' --disable-fips"
