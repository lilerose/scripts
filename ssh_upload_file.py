#!/usr/bin/env python 
#encoding:utf-8
import paramiko 
import os 
import datetime
import threading
import string
import sys 
#hostname='61.136.166.122' 
#username='root' 
#password='ipH18JPxo2KrwJj' 
#port=22 
#local_dir='/home/tanxiaohang/tan/py/file/' 
#remote_dir='/root/' 
def up_file(ip,port,username,passwd,local_dir,remote_dir,hostname):
	try:
		 global up_num
		 t=paramiko.Transport((ip,port))
		 t.connect(username=username,password=passwd)
		 sftp=paramiko.SFTPClient.from_transport(t)
		 files=os.listdir(local_dir) 
       		 for f in files:
                	#print '#########################################' 
                	#print 'Beginning to upload file %s ' % datetime.datetime.now() 
                	#print 'Uploading file:',os.path.join(local_dir,f) 
 
               		# sftp.get(os.path.join(dir_path,f),os.path.join(local_path,f)) 
                	sftp.put(os.path.join(local_dir,f),os.path.join(remote_dir,f)) 
                	print "\n"                                #输出结果
               	        print '\033[1;32;40m'
               	        ip = ip + "\t is ok"
                        up_num=up_num+1
                        print "%d、%s %s" %(up_num,hostname,ip)
                        print '\033[0m'
			print 'Upload file success %s ' % datetime.datetime.now()
                	#print '##########################################'
                	print ''	 
		 t.close()


	except:
		ip = ip + "\t is wrong"
                up_num=up_num+1
                print '\033[1;31;40m'
                print "%d、%s %s" %(up_num,hostname,ip)
                print '\033[0m'

if __name__=="__main__": 
 #    try:
	port=22
	local_dir='/home/liukai/python/file/'
	#remote_dir='/root/'
 	host_argv=sys.argv[1]
        ip = []
	global up_num
	
	up_num=0
        passwd = []
        hostname = []
        if host_argv.find(".txt") > 1:
                num = 0
		remote_dir=sys.argv[2]
                file_object = open(host_argv,'r')
                host_ip_passwd = file_object.readlines()
                for line in host_ip_passwd:
                        ip.append(line.split()[1])
                        passwd.append(line.split()[2])
                        hostname.append(line.split()[0])
                cmd = sys.argv[2]
                username = 'root1'
                threads = []
		for i in range(len(ip)):
                	a = threading.Thread(target=up_file, args=(ip[i],port,username,passwd[i],local_dir,remote_dir,hostname[i]))
                	threads.append(a)
        	for i in range(len(ip)):
                	threads[i].start()
        	for i in range(len(ip)):
                	threads[i].join()	
	
	else:
                file_object = open('/home/liukai/python/pass','r')
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
					count=1
				if(count==1):
					break
                remote_dir = sys.argv[host_argv_num1]
                username = 'root1'
                threads = []
                for i in range(len(ip)):
                        a = threading.Thread(target=up_file, args=(ip[i],port,username,passwd[i],local_dir,remote_dir,hostname[i]))
			threads.append(a)
                for i in range(len(ip)):
                        threads[i].start()
                for i in range(len(ip)):
                        threads[i].join()

