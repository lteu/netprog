# this file generates 'n' simulated requests

import glob
import sys
from random import randint,sample

def genReq(n_domains):

	active_domains =  sample(range(n_domains), 2)
	  
	start = active_domains[0] + 1; 
	target = active_domains[1] + 1;  

	# print range(n_domains),active_domains

	acc_request = []
	dis_request = []
	src_request = []
	end_request = []
	for x in xrange(5):
		acc_request.append([0,0])
		dis_request.append([0,0])
		src_request.append([0,0])
		end_request.append([0,0])


	# DPI
	src_request[0] = [randint(0,1),randint(1,2)]
	end_request[0] = [randint(0,1),randint(1,2)]
	dis_request[0] = [0,randint(0,3)]
	acc_request[0] = [0,randint(0,8)]

	# WANA
	src_request[1] = [1,1]
	end_request[1] = [1,1]
	tmp = randint(0,1)
	dis_request[1] = [tmp,tmp]
	acc_request[1] = [2,5]

	# SHAPER
	tmp = randint(0,1)
	src_request[2] = [tmp,tmp]
	end_request[2] = [0,0]
	tmp = randint(0,1)
	dis_request[2] = [tmp,tmp]
	acc_request[2] = [0,randint(0,6)]

	# VPN
	src_request[3] = [1,1]
	end_request[3] = [1,1]
	dis_request[3] = [1,1]
	acc_request[3] = [2,10]

	# NAT
	src_request[4] = [0,0]
	end_request[4] = [1,1]
	tmp = randint(0,1)
	dis_request[4] = [tmp,tmp]
	acc_request[4] = [1,randint(1,5)]


	for x in xrange(5):
		if sample([0,1], 1) == [0]:
			acc_request[x] = [0,0]
			dis_request[x] = [0,0]
			src_request[x] = [0,0]
			end_request[x] = [0,0]


	# stringfy acc
	# ----------------------------
	str_acc_range = "[|";
	for x in xrange(0,len(acc_request)):
		for y in xrange(2):
			str_acc_range += str(acc_request[x][y])+","
		str_acc_range = str_acc_range[:-1]
		str_acc_range += "|"
	str_acc_range += "]"

	# stringfy dis
	# ----------------------------
	str_dis_range = "[|";
	for x in xrange(0,len(dis_request)):
		for y in xrange(2):
			str_dis_range += str(dis_request[x][y])+","
		str_dis_range = str_dis_range[:-1]
		str_dis_range += "|"
	str_dis_range += "]"

	# stringfy src
	# ----------------------------
	str_src_range = "[|";
	for x in xrange(0,len(src_request)):
		for y in xrange(2):
			str_src_range += str(src_request[x][y])+","
		str_src_range = str_src_range[:-1]
		str_src_range += "|"
	str_src_range += "]"

	# stringfy end
	# ----------------------------
	str_end_range = "[|";
	for x in xrange(0,len(end_request)):
		for y in xrange(2):
			str_end_range += str(end_request[x][y])+","
		str_end_range = str_end_range[:-1]
		str_end_range += "|"
	str_end_range += "]"


	out = ""
	out += "start_domain = "+str(start)+";\n"
	out += "target_domain = "+str(target)+";\n"
	out += "acc_request = "+str(str_acc_range)+";\n"
	out += "dis_request = "+str(str_dis_range)+";\n"
	out += "src_request = "+str(str_src_range)+";\n"
	out += "end_request = "+str(str_end_range)+";\n"
	out += "service_request = [1,1,1,1,1];\n"

	return out


n_domains = 8

for x in xrange(1,20):
	outfilepath = "../data-exp/requests/request"+str(x)+".dzn"
	outstr = genReq(n_domains)
	with open(outfilepath, 'w+') as outfile:
		outfile.write(outstr)

