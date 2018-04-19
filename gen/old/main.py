# This file generates VNF topology
# 

import glob
import sys
import random
import os
from crt_map import call_gen_map
from crt_reqs import call_gen_reqs

num_nodes = 200
num_domains = 5
test_domains = range(2,21)
test_maps = range(1,11)
parts = os.path.abspath(__file__).split("/")
parts = parts[:-2]
expdir = '/'.join(parts) + "/data-exp"

rep = 10

for domain in test_domains:
	scenario = expdir+"/d"+str(domain)+"n"+str(num_nodes)
	if not os.path.exists(scenario):
		os.makedirs(scenario)

	for mapx in test_maps:
		filepath = scenario+"/map"+str(mapx)+".dzn"
		call_gen_map(filepath,domain,num_nodes)

	req_dir = scenario + "/req"
	if not os.path.exists(req_dir):
		os.makedirs(req_dir)

	req_path = req_dir+"/request"
	# print req_path
	call_gen_reqs( domain,rep,req_path,10)
	# print filepath
#example
# parts = os.path.abspath(__file__).split("/")
# parts = parts[:-2]
# filepath = '/'.join(parts)+"/data-exp/test.dzn"
# print filepath






