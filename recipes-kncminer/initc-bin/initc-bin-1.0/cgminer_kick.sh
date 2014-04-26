#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
sleep 30
#curl -u "admin:admin" --digest --data-urlencode "RestartCGMiner" http://localhost/cgi-bin/fetch_cgminer_conf.cgi
/etc/init.d/cgminer.sh restart