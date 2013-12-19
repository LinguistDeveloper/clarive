SERVER=`hostname`
sar -u 2 10000 > /tmp/cpu_$1_$SERVER.csv &
sar -r 2 10000 > /tmp/mem_$1_$SERVER.csv &
sar -n ALL 2 10000 > /tmp/net_$1_$SERVER.csv &
