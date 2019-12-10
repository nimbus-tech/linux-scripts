#!/bin/sh

# Title 	: VM Contextualization for PFSense on OpenNebula
# Version	: 1.1
# Date		: 2019/03/05
# Author	: Michael Choo
# Modified from : https://github.com/trivago/one-freebsd

# Release Info
# 1.0 - 2019/03/05 Initial release
# 1.1 - 2019/05/27 Added code to check for PFsense/OPNsense

# Instructions for PFsense
# 1. Rename file to vmcontext
# 2. Copy file to : /usr/bin in PFSense VM
# 3. Make file executable
# 4. edit /conf/config.xml and add the following line before </system>
# 	<earlyshellcmd>/usr/bin/vmcontext</earlyshellcmd>
# earlyshellcmd will get executed before the rest of the configuration is loaded.

# Instructions for OPNsense
# 1. Rename file to 01-vmcontext
# 2. Copy file to : /usr/local/etc/rc.syshook.d/early
# 3. Make file executable

date=$(which date|sh)

debug()
    if [ "$DEBUG" == true ] ; then
		set -x
	        echo "################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE################################################DEBUG ENABLED HERE"
		echo "debug logs for $date--------debug logs for $date--------debug logs for $date-------- "
		exec 3>&1 4>&2
		trap 'exec 2>&4 1>&3' 0 1 2 3
		exec 1>/tmp/vmcontext.log 2>&1
	fi

export_rc_vars()
{
    if [ -f $1 ] ; then
        ONE_VARS=`cat $1 | egrep -e '^[a-zA-Z\-\_0-9]*=' | sed 's/=.*$//'`

        . $1

        for v in $ONE_VARS; do
            export $v
        done
    fi
}

mask2cidr() {
	# Convert Netmask to CIDR
        case $1 in
        "255.255.255.255")      CIDR=32;;
        "255.255.255.254")      CIDR=31;;
        "255.255.255.252")      CIDR=30;;
        "255.255.255.248")      CIDR=29;;
        "255.255.255.240")      CIDR=28;;
        "255.255.255.224")      CIDR=27;;
        "255.255.255.192")      CIDR=26;;
        "255.255.255.128")      CIDR=25;;
        "255.255.255.0")        CIDR=24;;
        "255.255.254.0")        CIDR=23;;
        "255.255.252.0")        CIDR=22;;
        "255.255.248.0")        CIDR=21;;
        "255.255.240.0")        CIDR=20;;
        "255.255.224.0")        CIDR=19;;
        "255.255.192.0")        CIDR=18;;
        "255.255.128.0")        CIDR=17;;
        "255.255.0.0")          CIDR=16;;
        "255.254.0.0")          CIDR=15;;
        "255.252.0.0")          CIDR=14;;
        "255.248.0.0")          CIDR=13;;
        "255.240.0.0")          CIDR=12;;
        "255.224.0.0")          CIDR=11;;
        "255.192.0.0")          CIDR=10;;
        "255.128.0.0")          CIDR=9;;
        "255.0.0.0")            CIDR=8;;
        "254.0.0.0")            CIDR=7;;
        "252.0.0.0")            CIDR=6;;
        "248.0.0.0")            CIDR=5;;
        "240.0.0.0")            CIDR=4;;
        "224.0.0.0")            CIDR=3;;
        "192.0.0.0")            CIDR=2;;
        "128.0.0.0")            CIDR=1;;
        "0.0.0.0")              CIDR=0;;
        *)                      CIDR=0;;
        esac
        echo "$CIDR"
}

set_context() 
{
	# Check if OPNsense of PFsense
	fw_type=`head -2 /conf/config.xml|tail -1|cut -b2`
	
    # Create the customised context file
    CONFIG_FILE="/tmp/myconfig.txt"
    echo "" >$CONFIG_FILE
    
    if [ "$fw_type" == "o" ];
    then
    	echo "<?php"							>> $CONFIG_FILE
    	echo "require_once(\"config.inc\");"	>> $CONFIG_FILE
    	echo "\$config = parse_config();"		>> $CONFIG_FILE
    fi
    
    # Networking
    for i in $(ifconfig -l ether)
    	do
    		case $i in
    			'lo0' | 'plip0' | 'pflog0')
    		    ;;
        		vtnet0)
        			# vtnet0 is the WAN interface
        			if [ -n "$ETH0_IP" ]; then
        				SUBNET=$(mask2cidr $ETH0_MASK)
        				echo "\$config['interfaces']['wan']['enable']=true;"			>> $CONFIG_FILE
        				echo "\$config['interfaces']['wan']['if']=vtnet0;"				>> $CONFIG_FILE
        				echo "\$config['interfaces']['wan']['ipaddr']=\"$ETH0_IP\";"	>> $CONFIG_FILE
        				echo "\$config['interfaces']['wan']['subnet']=\"$SUBNET\";"		>> $CONFIG_FILE  
        				# Set Default gateway for WAN interface      				
        				echo "\$config['interfaces']['wan']['gateway']=\"GW_WAN\";"		>> $CONFIG_FILE        				
        			fi
          		;;
        		vtnet1)
        			# vtnet1 is the LAN interface
        			if [ -n "$ETH1_IP" ]; then
        				SUBNET=$(mask2cidr $ETH1_MASK)
        				echo "\$config['interfaces']['lan']['enable']=true;"			>> $CONFIG_FILE
        				echo "\$config['interfaces']['lan']['if']=vtnet1;"				>> $CONFIG_FILE
        				echo "\$config['interfaces']['lan']['ipaddr']=\"$ETH1_IP\";"	>> $CONFIG_FILE
        				echo "\$config['interfaces']['lan']['subnet']=\"$SUBNET\";"		>> $CONFIG_FILE        				
        			fi
          		;;
          		# vtnet2 - 4 are additional interfaces if required.
        		vtnet2)
        			if [ -n "$ETH2_IP" ]; then
        				SUBNET=$(mask2cidr $ETH2_MASK)
        				echo "\$config['interfaces']['OPT1']['enable']=true;"			>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT1']['if']=vtnet2;"				>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT1']['ipaddr']=\"$ETH2_IP\";"	>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT1']['subnet']=\"$SUBNET\";"	>> $CONFIG_FILE        				
        			fi
          		;;
        		vtnet3)
        			if [ -n "$ETH3_IP" ]; then
        				SUBNET=$(mask2cidr $ETH3_MASK)
        				echo "\$config['interfaces']['OPT2']['enable']=true;"			>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT2']['if']=vtnet3;"				>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT2']['ipaddr']=\"$ETH3_IP\";"	>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT2']['subnet']=\"$SUBNET\";"	>> $CONFIG_FILE        				
        			fi
          		;;
        		vtnet4)
        			if [ -n "$ETH4_IP" ]; then
        				SUBNET=$(mask2cidr $ETH4_MASK)
        				echo "\$config['interfaces']['OPT3']['enable']=true;"			>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT3']['if']=vtnet4;"				>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT3']['ipaddr']=\"$ETH4_IP\";"	>> $CONFIG_FILE
        				echo "\$config['interfaces']['OPT3']['subnet']=\"$SUBNET\";"	>> $CONFIG_FILE        				
        			fi
          		;;
        		*)
          			echo "Unknown Interface Type"
          		;;
      		esac
    	done
    	
    # Default WAN Gateway	
    if [ -n "$ETH0_GATEWAY" ]; then    
    	echo "\$config['gateways']['gateway_item']['0']['interface']=\"wan\";"					>> $CONFIG_FILE
		echo "\$config['gateways']['gateway_item']['0']['gateway']=\"$ETH0_GATEWAY\";"			>> $CONFIG_FILE
		echo "\$config['gateways']['gateway_item']['0']['name']=\"GW_WAN\";"					>> $CONFIG_FILE
		echo "\$config['gateways']['gateway_item']['0']['weight']=1;"							>> $CONFIG_FILE
		echo "\$config['gateways']['gateway_item']['0']['descr']=\"Interface WAN Gateway\";"	>> $CONFIG_FILE
	fi
        				
	# DNS server
	[ -n "ETH0_DNS" ] && echo "\$config['system']['dnsserver']['0']=\"$ETH0_DNS\";"		>> $CONFIG_FILE
    #if [ -n "$ETH0_DNS" ]; then    
    #	echo "\$config[‘system’][‘dnsserver’][‘0’]=\"$ETH0_DNS\";\n"					>> $CONFIG_FILE
	#fi

	# Write the configuration
	if [ "$fw_type" == "o" ]
	then
		echo "write_config();"			>> $CONFIG_FILE
		echo "?>"						>> $CONFIG_FILE
		# Apply Configuration
		/usr/local/bin/php $CONFIG_FILE
		/usr/local/etc/rc.reboot
	else
		echo "write_config();" 				>> $CONFIG_FILE
		# system_reboot_sync = sync config and reboot
		#echo "reload_interfaces_sync();"	>> $CONFIG_FILE
		echo "system_reboot_sync();"		>> $CONFIG_FILE
		# Execute the commands
		echo "exec;"						>> $CONFIG_FILE
		echo "exit"							>> $CONFIG_FILE
	
		# Apply configuration
		/usr/local/sbin/pfSsh.php < $CONFIG_FILE
	fi
}

vmcontext_start()
{
    if [ -e "/dev/cd0" ]; then
        mount_cd9660 /dev/cd0 /mnt > /dev/null
        if [ -f /mnt/context.sh ]; then
            export_rc_vars /mnt/context.sh
        fi
        # If /root/context.sh does not exist, create it
        if [ ! -e /root/context.sh ]; then
        	touch /root/context.sh
        fi
        # Check if there are any changes which needs to be applied
    	diff /mnt/context.sh /root/context.sh > /dev/null
        if [ $? -ne 0 ]; then
			debug
			echo "Starting the Opennebula contextualization"
            # Save applied (new) contexts
	    	cp /mnt/context.sh /root/context.sh ;
			# Apply new contexts
            set_context
        fi
        umount /mnt
    fi
}

vmcontext_start
