# This file generates VNF topology
# 

import glob
import sys
import random
import os
from crt_map import call_gen_map
from crt_reqs import call_gen_reqs

def exc(test_nodes,test_domains,test_maps,test_dcons,expdir,rep):
	for domain in test_domains:
		for num_nodes in test_nodes:
			scenario = expdir+"/d"+str(domain)+"n"+str(num_nodes)
			if not os.path.exists(scenario):
				os.makedirs(scenario)

			for mapx in test_maps:
				filepath = scenario+"/map"+str(mapx)+".dzn"
				call_gen_map(filepath,domain,num_nodes)

			for dc in test_dcons:
				req_dir = scenario + "/req"+str(dc)
				if not os.path.exists(req_dir):
					os.makedirs(req_dir)

				req_path = req_dir+"/request"
				call_gen_reqs( domain,rep,req_path,dc)


def main(args):
	# print "1111"
	# test_nodes = range(100,101)
	# test_nodes = range(200,201)
	# test_nodes = range(300,301)
	test_nodes = range(150,151)

	# test_domains = range(3,31)
	test_domains = range(15,16)

	test_maps = range(1,11)

	test_dcons = range(0,16)
	# test_dcons = range(2,3)
	parts = os.path.abspath(__file__).split("/")
	parts = parts[:-2]
	expdir = '/'.join(parts) + "/testbed/data-exp-n"+str(test_nodes[-1])+"-d"+str(test_domains[-1])
	# expdir = '/'.join(parts) + "/data-exp-n"+str(test_nodes[-1])+"-d"+str(test_domains[-1])

	rep = 10
	# print '1'
	exc(test_nodes,test_domains,test_maps,test_dcons,expdir,rep)


if __name__ == '__main__':
  main(sys.argv[1:])



