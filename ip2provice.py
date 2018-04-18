#!/usr/bin/env python
# coding:utf-8

import maxminddb
import os
import sys

def cityinfo(prov, x):
    for line in open(os.path.abspath('/usr/local/bin/encode/city')):
        if line.find(prov) == -1:
            continue
        try:
            prov, city, num = line.strip().strip('\n').split()
            if num == x:
                return city
        except:
            continue

    return

def ispinfo():
    isps = {}
    for line in open(os.path.abspath('/usr/local/bin/encode/isp')):
        try:
            num, isp, isp_english = line.strip().strip('\n').split()
            #print num,isp,isp_english
            isps[str(num)] = isp_english
        except:
            continue
    return isps

def provinceinfo():
    provinces = {}
    for line in open(os.path.abspath('/usr/local/bin/encode/province')):
        try:
            num, province, province_english, zone_english, zone = line.strip('\n').split()
            provinces[str(num)] = province_english + ' ' + zone_english
        except:
            continue

    return provinces

def countryinfo():
    countrys = {}
    for line in open(os.path.abspath('/usr/local/bin/encode/country')):
        try:
            num, country = line.strip('\n').split()
            if country == '中国':
                countrys[str(num)] = "china"
            elif country == '未知':
                countrys[str(num)] = "china"
            else:
                countrys[str(num)] = "foreign"
        except:
            continue

    return countrys

def ipinfo(couns, provs, isps, data):
    coun = couns[str(data['country'])]
    isp = isps[str(data['isp'])]
    #print isp
    prov = provs[str(data['prov'])]
    #city = cityinfo(prov, str(data['city']))
    #return "%s %s %s %s" %(isp, coun, prov, city)
    return "%s %s %s" %(isp, coun, prov)

def main():
    provs = provinceinfo()
    couns = countryinfo()
    isps = ispinfo()
    reader = maxminddb.Reader(os.path.abspath('/usr/local/bin/encode/ipdb_test.mmdb'))
    c = 0
    for ip in sys.argv:
        c += 1
        if c == 1:
            continue
        try:
            data = reader.get(ip)
            #print data
            info = ipinfo(couns, provs, isps, data)
            print ip,info
        except:
            pass

main()
