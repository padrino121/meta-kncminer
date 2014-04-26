#!/bin/sh
#set -x

trap atexit 0

lock_file=/var/run/lighttpd_advanced.cgi

asic_stat_file=/var/run/stats.knc

input=`cat /dev/stdin`

atexit() {
	rm -f $lock_file 2&> /dev/null
}

get_current_config()
{
    if [ ! -f /config/advanced.conf ] ; then
	#let waas  create conf file with defaults
	waas -d -o /config/advanced.conf
    fi
    cat /config/advanced.conf
}

if [ ! -f $lock_file ] ; then
    touch $lock_file 2&> /dev/null
fi

FREQ_OCT='"valid_die_frequencies" : 
[
"400",
"425",
"450",
"475",
"500",
"525",
"550",
"575",
"600",
"625",
"650",
"675",
"700",
"725",
"750",
"775",
"0x1F1",
"0x201",
"0x211",
"0x221",
"0x231",
"0x235",
"0x241",
"0x245",
"0x251",
"0x265",
"0x271",
"0x275",
"0x281",
"0x285",
"0x291",
"0x295"
]'

FREQ_NOV='"valid_die_frequencies" :                   
[                                        
"400",                                             
"425",          
"450",      
"475",                                                            
"500",                                      
"525",                                                            
"550",
"575",
"600",
"625",      
"650",                   
"675",           
"700",                             
"725",
"750",               
"775",              
"800",
"825",                               
"850",                           
"875",                                       
"900",                                                              
"925",              
"950",      
"975",
"1000",
"0x291",
"0x2A1",
"0x2B1",
"0x2C1",
"0x2D1",
"0x2E1",
"0x2F1",
"0x301",
"0x305",
"0x311",
"0x315",
"0x321",
"0x325",
"0x331",
"0x335",
"0x341",
"0x345",
"0x351",
"0x355",
"0x361"
]'

fetch_advanced_settings_and_ranges()
{
    TMP=`waas -i valid-ranges`

    echo "{"

    # valid_ranges
    if [ -z "${TMP##*1000*}" ] ; then
         echo $TMP | perl -pe "BEGIN{undef $/;} s/\"valid_die_f.*]/${FREQ_NOV}/smg"
    else
         echo $TMP | perl -pe "BEGIN{undef $/;} s/\"valid_die_f.*]/${FREQ_OCT}/smg"
    fi
    echo ","
    
    # enabled asics
    echo "\"enabled_asics\" : "
    echo "["
    if [ -f $asic_stat_file ] ; then
	i=0

	OIFS=$IFS
	IFS="="
	noof_enabled=`cat $asic_stat_file|grep asic|grep -v OFF|wc -l`
	while read status ; do
	    set -- $status
	    if [ "$1" != "" ] ; then  
		if [ "$2" != "OFF" ] ; then
		    i=`expr $i + 1`
		    if [ $i -lt $noof_enabled ] ; then
			 echo "\"$1\", "
		    else
			 echo "\"$1\""
		    fi
		fi
	    fi
	    
	done <  $asic_stat_file
	IFS=$OIFS
    fi
    echo "],"
	
    # current status
    echo "\"current_status\" : "
    waas -g all-asic-info 
    echo ","

    # current settings
    echo "\"current_settings\" : "

    get_current_config

    echo "}"
}

if [ "$input" = "fetch-advanced-settings-and-ranges" ] ; then
    fetch_advanced_settings_and_ranges
elif [ "$input" = "FactoryDefault" ] ; then
    rm -f /config/advanced.conf 2&> /dev/null
    killall monitordcdc 2&> /dev/null
    killall monitordcdc.ge 2&> /dev/null
    killall monitordcdc.ericsson 2&> /dev/null
    get_current_config
elif [ "$input" = "get-current-status" ] ; then
    waas -g all-asic-info 
elif [ "$input" = "recreate-config-file" ] ; then
    waas -r -o /config/advanced.conf
    get_current_config
elif [ "$input" != "null" ] && [ "$input" != "" ] ; then
    echo "$input" > /config/advanced.conf
    # let waas apply settings
    #waas -c /config/advanced.conf > /dev/null
    killall monitordcdc 2&> /dev/null
    killall monitordcdc.ge 2&> /dev/null
    killall monitordcdc.ericsson 2&> /dev/null
	/etc/init.d/cgminer.sh restart 2&> /dev/null
    get_current_config
fi

rm $lock_file 2&> /dev/null
