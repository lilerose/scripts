#!/usr/bin/env python
#encoding:utf-8
import paramiko
import os
import threading
import string
import sys
def ssh2(ip,username,passwd,cmd,hostname):
	if semaphore.acquire():
        	try:
			global v
                	ssh = paramiko.SSHClient()
                	ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy()) 
                	ssh.connect(ip,22,username,passwd,timeout=1000)
                	stdin, stdout, stderr = ssh.exec_command(cmd)   #执行的命令
                	out = stdout.readlines()
			print "\n"                                #输出结果
			print '\033[1;32;40m'
                	ip = ip + "\t is ok"
			v=v+1
			print "%d、%s %s" %(v,hostname,ip)
			print '\033[0m'
			print '#########################################'
                	for getout in out:
                        	print getout,
			print '#########################################'
                	semaphore.release()
			ssh.close()


        	except:
			ip = ip + "\t is wrong"
			semaphore.release()
			v=v+1
                	print '\033[1;31;40m'
                	print "%d、%s %s" %(v,hostname,ip)
                	print '\033[0m'


if __name__=='__main__':
	semaphore = threading.Semaphore(20)
	host_argv=sys.argv[1]
	ip = []
	global v
	v = 0 
	passwd = []     
        hostname = [] 
	if os.path.isfile(sys.argv[1]):
		num = 0 
		file_object = open(sys.argv[1],'r')
		ip_passwd = file_object.readlines()
		for line in ip_passwd:
        		ip.append(line.split()[1])
        		passwd.append(line.split()[2])
			hostname.append(line.split()[0])
		cmd = sys.argv[2]        
        	username = 'root1'
        	threads = []
        	for i in range(len(ip)):
                	a = threading.Thread(target=ssh2, args=(ip[i],username,passwd[i],cmd,hostname[i]))
                	threads.append(a)
        	for i in range(len(ip)):
                	threads[i].start()
        	for i in range(len(ip)):
                	threads[i].join()
	else:
		file_object = open('/home/tanxiaohang/tan/py/zhibo_passwd_20151105.txt','r')
                host_ip_passwd = file_object.readlines()
                host_argv_num = len(sys.argv) - 2
                host_argv_num1 = len(sys.argv) - 1
                for j in range(1, host_argv_num + 1):
                        count=0
                        for line in host_ip_passwd:
                                if sys.argv[j] in line:
                                        ip.append(line.split()[1])
                                        passwd.append(line.split()[2])
                                        hostname.append(line.split()[0])
                                        count = 1
                                if(count==1):
                                        break 
                cmd = sys.argv[host_argv_num1]
                username = 'root1'
                threads = []
                for i in range(len(ip)):
                        a = threading.Thread(target=ssh2, args=(ip[i],username,passwd[i],cmd,hostname[i]))
                        threads.append(a)
                for i in range(len(ip)):
                        threads[i].start()
                for i in range(len(ip)):
                        threads[i].join()
