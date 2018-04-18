#!/bin/bash

zone=$1
file=$2
if [ "$zone" = "liveCache" ]
then
    cache_dir=/usr/local/sandai/dcdn_live/ngx_hls_cache
fi
if [ "$zone" = "vodCache" ]
then
    cache_dir=/usr/local/sandai/dcdn_live/vod_cache
fi

if [ "$zone" = "mCache" ]
then
    cache_dir=/dev/shm/shls_cache
fi

if [ "$#" -eq 0 ]
then
    echo "please input scripts, if not, it will exit"
    sleep 2 && exit
fi
echo "what you put $mfile will delete, please wait..."

grep -ira $file $cache_dir | awk -F ':' '{print $1}' > /tmp/cache_list.txt
for j in `cat /tmp/cache_list.txt`
do
    rm -rf $j
    echo "$i $j is delete Success!"
done
rm -rf /tmp/cache_list.txt