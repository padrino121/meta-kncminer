#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

use_bfgminer=
if [ -f /config/miner.conf ]; then
	. /config/miner.conf
fi
if [ "$use_bfgminer" = true ] ; then
	DAEMON=/usr/bin/bfgminer
	NAME=bfgminer
	DESC="BFGMiner daemon"
	EXTRA_OPT="-S knc:auto"
else
	DAEMON=/usr/bin/cgminer
	NAME=cgminer
	DESC="Cgminer daemon"
	EXTRA_OPT=
fi

set -e

test -x "$DAEMON" || exit 0

json=""
if [ -f /config/advanced.conf ]; then
        json=$(cat /config/advanced.conf)
fi

get_freq()
{
echo $json | awk -v k="text" '{n=split($0,a,"}"); for (i=1; i<=n; i++) print a[i]}' \
 | grep asic_$1_frequency \
 | awk -v k="text" '{n=split($0,a,"{"); for (i=1; i<=n; i++) print a[i]}' \
 | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' \
 | grep die$2 | sed 's/ //g' | sed 's/"//g' | awk -F':' '{print $2}'
}

do_clocks() {
  for c in 0 1 2 3 ; do
          port=$(($1 + 1))
          die=$(($c + 1))
          INDEX=""
          INDEX=$(get_freq $port $die)
          case $INDEX in
            *0x*)
                # Re-enable PLL
                #i2cset -y 2 0x71 1 $(($1+1))
                cmd=$(printf "0x84,0x%02X,0,0" $c)
                spi-test -s 50000 -OHC -D /dev/spidev1.0 $cmd >/dev/null
                ONE=${INDEX:2:1}
                TWO=${INDEX:3:2}
                cmd=$(printf "0x86,0x%02X,0x0$ONE,0x$TWO" $c)
                spi-test -s 50000 -OHC -D /dev/spidev1.0 $cmd >/dev/null
                cmd=$(printf "0x85,0x%02X,0,0" $c)
                spi-test -s 50000 -OHC -D /dev/spidev1.0 $cmd >/dev/null ;;
          esac
  done
}

do_start() {
	/usr/bin/waas -c /config/advanced.conf > /dev/null
	sleep 5
	# Stop SPI poller
	spi_ena=0
	i2cset -y 2 0x71 2 $spi_ena

	good_ports=""
	bad_ports=""

	# CLear faults in megadlynx's
	for b in 3 4 5 6 7 8 ; do
		for d in 0 1 2 3 4 5 6 7 ; do
			i2cset -y $b 0x1$d 3 >/dev/null 2>&1 || true
		done
	done

	for p in 0 1 2 3 4 5 ; do
		i2cset -y 2 0x71 1 $((p+1))
		good_flag=0
		ar="$(spi-test -s 50000 -OHC -D /dev/spidev1.0 0x80,3,0,0,0,0,0,0 | tail -c 13)"
                if [ "x$ar" = "x00 30 A0 01" ] ; then
			good_flag=1
		fi
		ar="$(spi-test -s 50000 -OHC -D /dev/spidev1.0 0x80,2,0,0,0,0,0,0 | tail -c 13)"
                if [ "x$ar" = "x00 30 A0 01" ] ; then
			good_flag=1
		fi
		ar="$(spi-test -s 50000 -OHC -D /dev/spidev1.0 0x80,1,0,0,0,0,0,0 | tail -c 13)"
                if [ "x$ar" = "x00 30 A0 01" ] ; then
			good_flag=1
		fi
		ar="$(spi-test -s 50000 -OHC -D /dev/spidev1.0 0x80,0,0,0,0,0,0,0 | tail -c 13)"
                if [ "x$ar" = "x00 30 A0 01" ] ; then
			good_flag=1
		fi

		if [ "$good_flag" = "1" ] ; then
			good_ports=$good_ports" $p"
		else
			bad_ports=$bad_ports" $p"
		fi
	done

	if [ -n "$good_ports" ] ; then
		for p in $good_ports ; do
			i2cset -y 2 0x71 1 $((p+1))
			do_clocks $p

			# re-enable all cores
			i=0
			while [[ $i -lt 192 ]] ; do
				i2cset -y 2 0x2$p $i 1
				i=$((i+1))
			done
			spi_ena=$(( spi_ena | (1 << $p) ))
		done
	fi
	if [ -n "$bad_ports" ] ; then
		for p in $bad_ports ; do
			# disable all cores
			i=0
			while [[ $i -lt 192 ]] ; do
				i2cset -y 2 0x2$p $i 0
				i=$((i+1))
			done
			spi_ena=$(( spi_ena & ~(1 << $p) ))
		done
	fi

	# Disable direct SPI
	i2cset -y 2 0x71 1 0

	# Enable SPI poller
	i2cset -y 2 0x71 2 $spi_ena

	start-stop-daemon -b -S -x screen -- -S cgminer -t cgminer -m -d "$DAEMON" --api-listen -c /config/cgminer.conf $EXTRA_OPT
}

do_stop() {
	killall -9 bfgminer cgminer 2>/dev/null || true
}
case "$1" in
  start)
        echo -n "Starting $DESC: "
		do_start
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
		do_stop
        echo "$NAME."
        ;;
  restart|force-reload)
        echo -n "Restarting $DESC: "
        do_stop
		do_stop
        do_start
        echo "$NAME."
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
