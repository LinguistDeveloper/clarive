sar -u 2 10000 > /tmp/cpu_$1.csv &
sar -r 2 10000 > /tmp/mem_$1.csv &
sar -n ALL 2 10000 > /tmp/net_$1.csv &
