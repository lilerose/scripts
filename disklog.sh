#/bin/bash
#��;�����Զ�������Ĵ���ʹ�����
logfile="diskusage.log"   ####����ű�����˲���������д�������û����д��diskusage.log
if [[ -n $1 ]]
   then
      logfile=$1
fi
if [ ! -e $logfile ]
then
   printf "%-8s %-18s %-9s %-12s %-6s %-6s %-6s %s\n" "Date" "IP address" "Device" "Capactity" "Used" "Free" "Percent" "Status" > $logfile
fi
IP_LIST="127.0.0.1 192.168.191.188"
#�ṩԶ������IP��ַ�б�
(for ip in $IP_LIST
do 
  ssh $ip 'df -H'| grep ^/dev/|grep -v hdc > /tmp/$$.d
  while read line
  do
        cur_date=$(date +%D)
        printf "%-8s %-19s" $cur_date $ip
        echo $line |awk '{printf("%-12s %-10s %-6s %-6s %-8s",$1,$2,$3,$4,$5);}'

        pusg=$(echo $line|egrep -o "[0-9]+%")
            pusg=${pusg/\%/}
            if [ $pusg -lt 80 ]
            then
                echo SAFE
            else
                echo ALERT
            fi
   done< /tmp/$$.df
done
) >> $logfile 