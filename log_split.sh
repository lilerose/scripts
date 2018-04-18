#!/bin/sh
#set -x

#pid_path=/usr/local/openresty/nginx/logs/nginx.pid
#logdir=/usr/local/openresty/nginx/logs
pid_path=/data/dcdn_nginx_data/nginx/logs/nginx.pid
logdir=/data/dcdn_nginx_data/nginx/logs

dt_day=`date +"%Y-%m-%d"`
dt=`date +"%Y%m%d_%H"`
dtpre=`date +"%Y%m%d_%H" -d "1 hour ago"`

files=("error.log" "access.log")

for file in ${files[@]};
do
     // handle last hour log, first time
     if [ ! -e "$logdir/$file{,.$dtpre}" ]; then
          mv $logdir/$file{,.$dtpre}
     fi

     touch $logdir/${file}.${dt}
     ln -s -f $logdir/$file{.$dt,}
done

kill -USR1 `cat ${pid_path}`

for oldfiles in `find /data/ -type f -name "*.log*" -mtime +7 | xargs -n 1`
do
echo $oldfiles
rm -rf $oldfiles
done
