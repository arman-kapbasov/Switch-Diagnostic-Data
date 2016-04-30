#!/bin/bash
#Arman Kapbasov
#Parts adapted from www.stackoverflow.com 

#================USAGE============
#To run..
#        ./diagnosicsData.sh [IP/Hostname]

#add -h for HELP menu

#Default output..
#        [hostname]_[date]_opsDiag.tar.gz

#You can change port by adding 2nd command line argument (optional)..
#        ./diagnosicsData.sh [IP/Hostname] [port]

#extract tar/output file with: tar -zxvf [filename]         
#=================================

timedate=$(date +"%Y.%m.%d-%H.%M")

#==========Flags==========
#HELP Function
function HELP {
  echo -e \\n"To run:"\\n"     ./diagnosicsData.sh [IP/Hostname] [port *optional]"\\n
  echo -e "Add port number:
     ./diagnosicsData.sh [IP/Hostname] [port]"\\n
  echo -e "Prompt HELP menu:
     ./diagnosicsData.sh -h"\\n
  echo -e "Extract tar/output file with:
     tar -zxvf [filename]"\\n
  exit 1
}

while getopts "hod:f:" opt; do
        case $opt in
        h)
                HELP
            exit 1
        ;;
        \?)
                echo -e \\n"Unrecognized option -$OPTARG"
                HELP
                exit 1
        ;;
        esac
done

#check for command line arguments
if [ $# -eq 0 ]; then
    echo -e \\n"Error:Invalid script call, opening [HELP MENU].."
    HELP
    exit 1
fi

IP=${1}
port=""
msg=""
default=$IP"_"$timedate"_opsDiag.tar.gz"

if [ $# -eq 2 ]; then
   default=$2
fi
#check IP address
#report error if no ssh connection
var=`nmap $IP -PN -p ssh | grep open`
ok="22/tcp open ssh"
if [[ $(echo $var) == $ok ]] ; then
  echo -e \\n$IP "[online], ready.."
else
  echo -e \\n"Error:" Host $IP "[cannot connect].."\\n
  exit 1
fi

#saved filename
filename=$default
echo "Target tar file <"$filename">"

#=====poll data to tar=======

#fix knownhosts issue, not host key checking
c=" -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null"

#Version
if $(scp $c root@$1:/etc/os-release $timedate.version >&/dev/null); 
	then echo ">>Copied: version" ; 
	else echo "--Failed: retrieve version"
fi
#processes
if $(ssh $c root@$1 "ps -aux" >$timedate.processes >&/dev/null ); 
	then $(ssh $c root@$1 "ps -aux" >$timedate.processes)
	echo ">>Copied: processes" ; 
	else echo "--Failed: retrieve processes"
fi
#iostat
 
if $(ssh $c root@$1 "iostat -tc" >$timedate.iostat >&/dev/null ); 
	then $(ssh $c root@$1 "iostat -tc" >$timedate.iostat)
	echo ">>Copied: iostat" ;
	else echo "--Failed: retrieve iostat"
fi
#netstat
if $(ssh $c root@$1 "netstat -an" >$timedate.netstat >&/dev/null);
	then $(ssh $c root@$1 "netstat -an" >$timedate.netstat)
	echo ">>Copied: netstat" ; 
	else echo "--Failed: retrieve netstat"
fi
#dmesg
if $(ssh $c root@$1 "dmesg" >$timedate.kernelMessageBuffer >&/dev/null ); 
	then $(ssh $c root@$1 "dmesg" >$timedate.kernelMessageBuffer)
	echo ">>Copied: kernel message buffer" ; 
	else echo "--Failed: retrieve kernel message buffer"
fi
#running-config
if $(ssh $c root@$1 "ovsdb-client dump" > $timedate.runningConfig >&/dev/null ); 
	then $(ssh $c root@$1 "ovsdb-client dump" > $timedate.runningConfig)
	echo ">>Copied: running config" ; 
	else echo "--Failed: retrieve running config"
fi
#startup config
if $(scp $c root@$1:/var/local/openvswitch/config.db  $timedate.startupConfig >&/dev/null ); 
	then echo ">>Copied: startup config" ; 
	else echo "--Failed: retrieve startup config"
fi

#coredumps recursivly copy
if $(scp -r $c root@$1:/var/lib/systemd/coredump*  $timedate.coredump >&/dev/null); 
	then echo ">>Copied: coredumps" ; 
	else echo "--Failed: retrieve coredumps"
fi 

#logs recursivly copy
if $(scp -r $c root@$1:/var/log*  $timedate.logs >&/dev/null); 
	then echo ">>Copied: logs" ; 
	else echo "--Failed: retrieve logs"
fi

#failed service units
if $(ssh $c root@$1 "systemctl list-unit-files --all --state=failed" > $timedate.failed.service.units >&/dev/null ); 
	then $(ssh $c root@$1 "systemctl list-unit-files --all --state=failed" > $timedate.failed.service.units)
	echo ">>Copied: failed service units" ; 
	else echo "--Failed: retrieve failed service units" 
fi

#===================Updated Diag=====================
#
#vtysh
#

if $(ssh $c root@$1 "echo 'show ip route' | vtysh" > $timedate.show.ip.route >&/dev/null );
        then $(ssh $c root@$1 "echo 'show ip route' | vtysh" > $timedate.show.ip.route)
	echo ">>Copied: show IP route" ;
        else echo "--Failed: retrieve show IP route"
fi


if $(ssh $c root@$1 "echo 'show ipv6 route' | vtysh" > $timedate.show.ipv6.route >&/dev/null );
        then $(ssh $c root@$1 "echo 'show ipv6 route' | vtysh" > $timedate.show.ipv6.route)
        echo ">>Copied: show IPV6" ;
        else echo "--Failed: retrieve show IPV6"
fi


if $(ssh $c root@$1 "echo 'show rib' | vtysh" > $timedate.show.rib >&/dev/null );
        then $(ssh $c root@$1 "echo 'show rib' | vtysh" > $timedate.show.rib)
        echo ">>Copied: show rib" ;
        else echo "--Failed: retrieve show rib"
fi


if $(ssh $c root@$1 "echo 'show running-config' | vtysh" > $timedate.show.running.config >&/dev/null );
        then $(ssh $c root@$1 "echo 'show running-config' | vtysh" > $timedate.show.running.config)
        echo ">>Copied: show running config" ;
        else echo "--Failed: retrieve show running config"
fi


if $(ssh $c root@$1 "echo 'show interface' | vtysh" > $timedate.show.interface >&/dev/null );
        then $(ssh $c root@$1 "echo 'show interface' | vtysh" > $timedate.show.interface)
        echo ">>Copied: show interface" ;
        else echo "--Failed: retrieve show interface"
fi

#==================bash=========
if $(ssh $c root@$1 "echo 'ip route' | ip netns exec swns bash" > $timedate.ip.route >&/dev/null );
        then $(ssh $c root@$1 "echo 'ip route' | ip netns exec swns bash" > $timedate.ip.route)
        echo ">>Copied: IP route" ;
        else echo "--Failed: retrieve IP route"
fi

if $(ssh $c root@$1 "echo 'ip -6 route' | ip netns exec swns bash" > $timedate.ip-6.route >&/dev/null );
        then $(ssh $c root@$1 "echo 'ip -6 route' | ip netns exec swns bash" > $timedate.ip-6.route)
        echo ">>Copied: ip -6 route" ;
        else echo "--Failed: retrieve ip -6 route"
fi

if $(ssh $c root@$1 "echo 'ovs-appctl plugin/debug l3route' | ip netns exec swns bash" > $timedate.ovs-appctl.plugin-debug.l3route >&/dev/null );
        then $(ssh $c root@$1 "echo 'ovs-appctl plugin/debug l3route' | ip netns exec swns bash" > $timedate.ovs-appctl.plugin-debug.l3route)
        echo ">>Copied: ovs-appctl plugin/debug l3route" ;
        else echo "--Failed: retrieve ovs-appctl plugin/debug l3route"
fi

if $(ssh $c root@$1 "echo 'ovs-appctl plugin/debug l3v6route' | ip netns exec swns bash" > $timedate.ovs-appctl.plugin-debug.l3v6route >&/dev/null );
        then $(ssh $c root@$1 "echo 'ovs-appctl plugin/debug l3v6route' | ip netns exec swns bash" > $timedate.ovs-appctl.plugin-debug.l3v6route)
        echo ">>Copied: ovs-appctl plugin/debug l3v6route" ;
        else echo "--Failed: retrieve ovs-appctl plugin/debug l3v6route"
fi
#tar and remove intermediate files
echo "[Compressing]..."
chmod -R 700 $timedate.logs 
tar -zcvf $filename $timedate*
rm -r "$timedate"*
echo -e "...[done!]"\\n
