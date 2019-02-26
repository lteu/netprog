# This file generates VNF topology
# 

import glob
import sys
import random
import os


def initVNFs(vnf_ids):
	vnfs = []
	for idx in vnf_ids:
		vnfs.append([idx+1,0, 0, 0, 0, 0, 1, 0])
	return vnfs

def createDomainInfo(M,n_domains):
	# init domain costs
	domain_costs = [[0 for x in range(n_domains)] for y in range(n_domains)] 

	for x in range(n_domains):
		for y in range(n_domains):
			if x < y:
				tmpcost = random.randint(1, M)
				domain_costs[x][y] = tmpcost
				domain_costs[y][x] = tmpcost
	return domain_costs


def createVNFLinks(n_vnfs,vnfs,VNF_KEY_TYPE,GATEWAY,VNF_KEY_DOMAIN,WANA,SHAPER,DPI):
		
	# vnf link creation 1: same domain 
	# ----------------------------
	vnf_links = []
	for i in [idx for idx, vnf in enumerate(vnfs) if vnf[VNF_KEY_TYPE] == GATEWAY]:
		for j in [idx for idx, vnf in enumerate(vnfs) if vnf[VNF_KEY_TYPE] != GATEWAY and  vnf[VNF_KEY_DOMAIN] == vnfs[i][VNF_KEY_DOMAIN] ]:
			vnf_links.append([vnfs[i][0],vnfs[j][0]])
			vnf_links.append([vnfs[j][0],vnfs[i][0]])


	# vnf link creation 2: gatway GATEWAYs vnfs
	# ----------------------------

	for i in range(n_vnfs):
		for j in range(n_vnfs):
			if i != j and vnfs[i][VNF_KEY_DOMAIN] != vnfs[j][VNF_KEY_DOMAIN] and vnfs[i][VNF_KEY_TYPE] == GATEWAY and vnfs[j][VNF_KEY_TYPE] == GATEWAY :
				vnf_links.append([vnfs[i][0],vnfs[j][0]])

	return vnf_links


def call_gen_map(filepath,n_domains,n_vnfs):
	global M,VNF_KEY_TYPE,VNF_KEY_DOMAIN,GATEWAY,ENDPOINT,WANA,SHAPER,DPI,type_list

	vnf_ids = range(n_vnfs);
	domain_ids = range(1,n_domains+1);
	vnfs = initVNFs(vnf_ids)
	# shuffle then k gateway and k endpoint
	random.shuffle(vnf_ids)

	for d in range(n_domains):
		tmpid = vnf_ids[0]
		vnfs[tmpid][VNF_KEY_TYPE] = GATEWAY
		vnfs[tmpid][VNF_KEY_DOMAIN] = d+1
		del vnf_ids[0]

	# k endpoint
	for d in range(n_domains):
		tmpid = vnf_ids[0]
		vnfs[tmpid][VNF_KEY_TYPE] = ENDPOINT
		vnfs[tmpid][VNF_KEY_DOMAIN] = d+1
		del vnf_ids[0]

	# shuffle the rest
	random.shuffle(vnf_ids)
	for tmpid in vnf_ids:
		aType = random.choice(type_list)
		aDomain = random.choice(domain_ids)
		vnfs[tmpid][VNF_KEY_TYPE] = aType
		vnfs[tmpid][VNF_KEY_DOMAIN] = aDomain

	# init domains
	domain_costs = createDomainInfo(M,n_domains)

	print "\nReport\n=========="
	print "Num vnfs",len(vnfs),"Num domains",len(domain_ids)
	print "number of DPI", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == DPI)
	print "number of WANA", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == WANA)
	print "number of SHAPER", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == SHAPER)
	print "number of VPN", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == VPN)
	print "number of NAT", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == NAT)

	# # create VNF links
	vnf_links = createVNFLinks(n_vnfs,vnfs,VNF_KEY_TYPE,GATEWAY,VNF_KEY_DOMAIN,WANA,SHAPER,DPI)
	num_vnf_links = len(vnf_links)

	# # =======================================
	# # 			Stringification
	# # =======================================


	# stringfy domain link weights
	# ----------------------------
	str_domain_link_weights = "[|";
	for x in xrange(0,n_domains):
		for y in xrange(0,n_domains):
			str_domain_link_weights += str(domain_costs[x][y])+","
		str_domain_link_weights = str_domain_link_weights[:-1]
		str_domain_link_weights += "|"
	str_domain_link_weights += "]"



	# stringfy link weights
	# ----------------------------
	str_vnf_link = "[|";
	for i in range(len(vnf_links)):
		str_vnf_link += str(vnf_links[i][0])+","+str(vnf_links[i][1]) + "|"

	str_vnf_link = str_vnf_link[:-1]
	str_vnf_link += "|"
	str_vnf_link += "]"


	# stringfy vnfs
	# ----------------------------
	str_vnf = "[|";
	for x in xrange(0,len(vnfs)):
		for y in xrange(0,len(vnfs[0])):
			str_vnf += str(vnfs[x][y])+","
		str_vnf = str_vnf[:-1]
		str_vnf += "|"
	str_vnf += "]"


	out = "n_nodes = "+str(n_vnfs)+";\n"
	out += "M = "+str(M)+";\n"
	out += "n_domains = "+str(n_domains)+";\n"
	out += "domain_link_weights = "+str(str_domain_link_weights)+";\n"
	out += "num_node_links = "+str(num_vnf_links)+";\n"
	out += "node_links = "+str_vnf_link+";\n"
	out += "nodes = "+str_vnf+";\n"

	with open(filepath, 'w+') as outfile:
		outfile.write(out)

# ==============================================
# 	M A I N
# ==============================================


# 	Configuration Parameters
# ===========================

# VNF attribute KEYs
VNF_KEY_ID = 0
VNF_KEY_TYPE = 1
VNF_KEY_TERMINATING = 2
VNF_KEY_PATHSENSITIVE = 3
VNF_KEY_MIRRORED = 4
VNF_KEY_WEIGHT = 5
VNF_KEY_ACTIVE = 6
VNF_KEY_DOMAIN = 7

# VNF type IDs
GATEWAY = 9;
ENDPOINT = 10;
WANA = 2;
DPI = 1;
SHAPER = 3;
VPN = 4;
NAT = 5;
type_list = [DPI,WANA,SHAPER,VPN,NAT]
M = 100;   # max domain cost


if __name__ == '__main__':
	#example
	n_domains = 10
	n_vnfs = 400
	parts = os.path.abspath(__file__).split("/")
	parts = parts[:-2]
	exp_folder = '/'.join(parts)+"/testbed/"
	if not os.path.exists(exp_folder):
		os.makedirs(exp_folder)
	filepath = exp_folder+"example.dzn"


	call_gen_map(filepath,n_domains,n_vnfs)
	print 'The following file has been created:'
	print filepath






