#!/bin/bash
##########################################
#  用途：采集机器带宽
#  作者：hzy
#  日期：2013-10-31
##########################################
#2015-03-30 增加packets采集
#2015-05-21 适应大矿机用户机器,增加对多IP支持
#2015-10-09 考虑网卡异常情况，设置最多3倍设置带宽
export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/root1/bin"

HOST=`hostname`
day=`date +%Y-%m-%d`
log_time=`date "+%Y-%m-%d %d"`
#计算带宽间隔
diff=1
DATE_BASE=$((`date +%s`/60*60))
DATE_BASE_diff=$((`date +%s -d "$diff mins ago"`/60*60))
day=`date +%Y-%m-%d -d @$DATE_BASE`
log_time=`date "+%Y-%m-%d %H:%M:%S" -d @$DATE_BASE`
HOSTNAME=`hostname | awk -F. '{print $1}' | sed 's/-//g'`
if [ ! -d /usr/local/caiji/log_tmp ];then
	mkdir -p /usr/local/caiji/bin/ /usr/local/caiji/log/ /usr/local/caiji/log_tmp/ 
fi
cd /usr/local/caiji

#区分内外网名称
ips=`ifconfig | grep "inet addr:" | awk -F"[: ]+" '{print $4}' | grep -v -P "^127.0|^10.[0-9]|^192.[0-9]|^172.[0-9]"`
ips1=`ifconfig | grep "inet addr:" | awk -F"[: ]+" '{print $4}' | grep -v -P "^127.0|^10.[0-9]|^192.[0-9]|^172.[0-9]" | head -n1`
#wai1=`ifconfig | grep -B 1 "inet addr:${ips}" | awk '/Link encap/{print $1}' | grep -v "^lo"`
#modified 20160226 hzy
#解决一个网卡绑定多个外网IP的重置计算问题
#wai1=`ifconfig | grep -B 1 "inet addr:${ips}" | awk '/Link encap/{print $1}' | grep -v -P "^lo|:"`
#解决bond网卡 同时配置内网IP 和外网IP的问题
wai1=`ifconfig | grep -B 1 "inet addr:${ips}" | awk '/Link encap/{print $1}' | grep -v -P "^lo" | awk -F: '{print $1}' | sort | uniq`
if [ ! -f log/network.ip.log ];then
    echo -n > log/network.ip.log
fi
for ip in ${ips};do
    eth=`ifconfig | grep -B 1 "inet addr:${ip}" | awk '/Link encap/{print $1}' | awk -F: '{print $1}'`
    count=`grep -c "$eth $ip" log/network.ip.log`
    if [ $count -lt 1 ];then
        echo $eth $ip >> log/network.ip.log
    fi
done
echo  $wai1
##############################################################
#start 开始算每一个网卡的流量
##############################################################
LOG=""
echo -n > log_tmp/max.network
for wai in ${wai1};do
    count=`echo $wai | grep -c bond`
    count1=`echo $wai | grep -c ":"`
    if [ $count -eq 1 ];then
        cat /proc/net/bonding/$wai | grep  -P "Speed" | awk '{a+=$2}END{printf("%.2f\n",a*1024*1024)}' >> log_tmp/max.network
    elif [ $count1 -eq 1 ];then
        echo 虚拟网卡不用统计流量
    else
        ethtool $wai | grep 'Mb/s' | grep -oP "[0-9]+" | awk '{printf("%.2f\n",$1*1024*1024)}' >> log_tmp/max.network
    fi

    #按时间保存内外网原始数据###############################################################################################################################
    #数据格式       外网数据                                                
    #                   进                        出                           
    #time |bytes    packets errs drop |bytes    packets errs drop | 
    #1      2           3    4    5     6         7      8     9    
    data_wai=`cat /proc/net/dev | grep $wai | sed 's/:/ /g' | awk '{printf("%.f %.f %.f %.f %.f %.f %.f %.f",$2,$3,$4,$5,$10,$11,$12,$13)}'`
    echo ${DATE_BASE} ${data_wai} >> log_tmp/caiji_network.log_tmp.${wai}

    #开始计算1分钟内的带宽平均值 包的大小
    #,b[1],(b[2]-a[2])/60*8,(b[6]-a[6])/60*8,(b[10]-a[10])/60*8,(b[14]-a[14])/60*8)
    #time bytin bytout  
    #time bytin  bytout   pktin  pktout  #pkterr  pktdrp   
    #grep -P "$DATE_BASE_diff|${DATE_BASE}" log_tmp/caiji_network.log_tmp.${wai} > log_tmp/2line.tmp.log
    tail -n2 log_tmp/caiji_network.log_tmp.${wai} | grep -P "$DATE_BASE_diff|${DATE_BASE}" > log_tmp/2line.tmp.log
    count=`cat log_tmp/2line.tmp.log | wc -l`
    if [ $count -eq 2 ];then
        band_packet=`cat log_tmp/2line.tmp.log | awk '{for(i=1;i<NF;i++)a[i]=$i;getline;for(i=1;i<NF;i++)b[i]=$i;}END{if(b[2]>a[2] && b[6]>a[6]){printf("%d %.f %.f %.f %.f\n",b[1],(b[2]-a[2])/60*8,(b[6]-a[6])/60*8,(b[3]-a[3])/60*8,(b[7]-a[7])/60*8)}else{ printf("%d %.f %.f %.f %.f\n",b[1],0,0,0,0)}}'`
    else
        echo 计算数据不足 要下一个周期才计算
        cat log_tmp/2line.tmp.log
        exit 1
    fi
    echo ${band_packet} >> log/caiji_network.log.${wai}
    LOG=$LOG" ""log/caiji_network.log.${wai}"
done
##############################################################
#end 开始算每一个网卡的流量
##############################################################




bytin=`awk '/'${DATE_BASE}'/{a+=$2}END{print a}' $LOG`
bytout=`awk '/'${DATE_BASE}'/{a+=$3}END{print a}' $LOG`
pktin=`awk '/'${DATE_BASE}'/{a+=$4}END{print a}' $LOG`
pktout=`awk '/'${DATE_BASE}'/{a+=$5}END{print a}' $LOG`

if [ "X""$bytin" == "X" -o "X""$bytout" == "X" -o "X""$pktin" == "X" -o "X""$pktout" == "X" ];then
    echo $bytin $bytout $pktin $pktout
    echo bytin bytout pktin pktout 有一个数值为空
    exit 1 
fi

#有超大数据的时候，直接取最大值
#up_band=`grep network_max_bandwidth /usr/local/dcdn_http_new/dcdn.conf | grep -oP '[0-9]{1,}' | awk '{printf("%d",$1*1024*1024*8*3)}'`
up_band=`awk '{a+=$1}END{printf("%.2f\n",a)}' log_tmp/max.network`
#let if_lager_up_band=$bytout-$up_band
if_lager_up_band=`echo $bytout $up_band | awk '{printf("%d",$1-$2)}'`
if [ $if_lager_up_band -gt 0 ];then
	bytout1=$bytout
	bytout=$up_band
	
	bytin1=$bytin
	bytin=$up_band
	
	pktin1=$pktin
	pktin=0
	
	pktout1=$pktout
	pktout=0
	
fi


echo ${DATE_BASE} $bytin $bytout $pktin $pktout $bytin1 $bytout1 $pktin1 $pktout1 >> log/caiji_network.log
echo "$log_time$HOST$ips1$bytin$bytout$pktin$pktout${DATE_BASE}">> log/caiji_network.log.$day



json_file="log_tmp/caiji_liuliang.log.3"
echo -n [ > ${json_file}
echo -n "{\"metric\": \"band.in.bit\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $bytin,\"counterType\": \"GAUGE\",\"tags\": \"\"}," >> ${json_file}
echo -n "{\"metric\": \"band.out.bit\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $bytout,\"counterType\": \"GAUGE\",\"tags\": \"\"}," >> ${json_file}
echo -n "{\"metric\": \"band.in.packet\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $pktin,\"counterType\": \"GAUGE\",\"tags\": \"\"}," >> ${json_file}
echo -n "{\"metric\": \"band.out.packet\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $pktout,\"counterType\": \"GAUGE\",\"tags\": \"\"}," >> ${json_file}

echo -n "{\"metric\": \"net.if.in.bit\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $bytin,\"counterType\": \"GAUGE\",\"tags\": \"iface=total\"}," >> ${json_file}
echo -n "{\"metric\": \"net.if.out.bit\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $bytout,\"counterType\": \"GAUGE\",\"tags\": \"iface=total\"}," >> ${json_file}
echo -n "{\"metric\": \"net.if.in.packets\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $pktin,\"counterType\": \"GAUGE\",\"tags\": \"iface=total\"}," >> ${json_file}
echo -n "{\"metric\": \"net.if.out.packets\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $pktout,\"counterType\": \"GAUGE\",\"tags\": \"iface=total\"}," >> ${json_file}


echo -n ] >> ${json_file}
sed -i 's/},]/}]/g' ${json_file}
curl -s --connect-timeout 5 --retry 5 -XPOST -d @${json_file} http://127.0.0.1:1988/v1/push



cat log/network.ip.log | while read wai ip;do
    LOG="log/caiji_network.log.${wai}"
    bytin=`awk '/'${DATE_BASE}'/{a+=$2}END{print a}' $LOG`
    bytout=`awk '/'${DATE_BASE}'/{a+=$3}END{print a}' $LOG`
    pktin=`awk '/'${DATE_BASE}'/{a+=$4}END{print a}' $LOG`
    pktout=`awk '/'${DATE_BASE}'/{a+=$5}END{print a}' $LOG`

    if [ "X""$bytin" == "X" -o "X""$bytout" == "X" -o "X""$pktin" == "X" -o "X""$pktout" == "X" ];then
        echo $bytin $bytout $pktin $pktout
        echo bytin bytout pktin pktout 有一个数值为空
        exit 1 
    fi

    #有超大数据的时候，直接取最大值
    #up_band=`grep network_max_bandwidth /usr/local/dcdn_http_new/dcdn.conf | grep -oP '[0-9]{1,}' | awk '{printf("%d",$1*1024*1024*8*3)}'`
    up_band=`ethtool $wai | grep 'Mb/s' | grep -oP "[0-9]+" | awk '{printf("%.2f\n",$1*1024*1024)}'`
    if_lager_up_band=`echo $bytout $up_band | awk '{printf("%d",$1-$2)}'`
    if [ $if_lager_up_band -gt 0 ];then
        bytout1=$bytout
        bytout=$up_band
        
        bytin1=$bytin
        bytin=$up_band
        
        pktin1=$pktin
        pktin=0
        
        pktout1=$pktout
        pktout=0
        
    fi


    echo ${DATE_BASE} $bytin $bytout $pktin $pktout $bytin1 $bytout1 $pktin1 $pktout1 >> log/caiji_network_${ip}.log


    json_file="log_tmp/caiji_liuliang.log.4"
    echo -n [ > ${json_file}
    echo -n "{\"metric\": \"net.if.in.bit\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $bytin,\"counterType\": \"GAUGE\",\"tags\": \"iface=${ip}\"}," >> ${json_file}
    echo -n "{\"metric\": \"net.if.out.bit\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $bytout,\"counterType\": \"GAUGE\",\"tags\": \"iface=${ip}\"}," >> ${json_file}
    echo -n "{\"metric\": \"net.if.in.packets\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $pktin,\"counterType\": \"GAUGE\",\"tags\": \"iface=${ip}\"}," >> ${json_file}
    echo -n "{\"metric\": \"net.if.out.packets\", \"endpoint\": \"$HOST\", \"timestamp\": $DATE_BASE,\"step\": 60,\"value\": $pktout,\"counterType\": \"GAUGE\",\"tags\": \"iface=${ip}\"}," >> ${json_file}


    echo -n ] >> ${json_file}
    sed -i 's/},]/}]/g' ${json_file}
    curl -s --connect-timeout 5 --retry 5 -XPOST -d @${json_file} http://127.0.0.1:1988/v1/push
done
