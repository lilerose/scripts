#!/bin/bash
##################################
#   Author: liukai               #
#   Date: 2015/12/02             #
#   Function: Auto login         #
##################################

Passbank=/home/liukai/dcdn_passwd
function auto {
expect -c "
set timeout 90
set env(TERM)
spawn  ssh root@$1
expect "*?\(yes/no\)*" {
        send -- "yes\\r"
        expect "*?assword:*"
        send -- "$2\\r"
} "*?assword:*"  {
        send -- "$2\\r"
} 
interact
"
}
cat dcdn_passwd | grep $1 > /dev/null
if [[ $? == 0 ]]; then
	PASS1=`grep -1 $1 /home/liukai/dcdn_passwd | awk '{print $2}' | awk  'BEGIN {FS=":";}{print $2;}'`
	auto $1 $PASS1
else
        echo -e $1 >> /home/liukai/dcdn_passwd
        ssh liukai@t2333.sandai.net "python /usr/local/bin/PasswdTools.py $1" >> /home/liukai/dcdn_passwd
	PASS2=`grep -1 $1 /home/liukai/dcdn_passwd | awk '{print $2}' | awk  'BEGIN {FS=":";}{print $2;}'`
	auto $1 $PASS2
fi
