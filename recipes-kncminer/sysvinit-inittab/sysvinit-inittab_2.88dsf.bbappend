FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-1.0:"

PRINC := "${@int(PRINC) + 1}"

do_install_append() {
        echo "dcdc:2345:respawn:${base_sbindir}/monitordcdc" >> ${D}${sysconfdir}/inittab
        echo "loop:2345:respawn:${bindir}/loop.sh" >> ${D}${sysconfdir}/inittab
        echo "cg:2345:boot:${bindir}/cgminer_kick.sh" >> ${D}${sysconfdir}/inittab
}
