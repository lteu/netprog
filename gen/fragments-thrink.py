# vnf link list
# full gateway connection

import glob
import sys
import random

def createVNFs():
	for i in xrange(1,n_domains+1):
		numVnf = random.randint(lb_domain_vnfs, up_domain_vnfs)

		# append others
		for j in xrange(1,numVnf+1):
			idx = len(vnfs) + 1
			vnfs.append([idx,0, 0, 0, 0, 0, 1, i])

		# append border node
		idx = len(vnfs) + 1
		vnfs.append([idx,BORDER, 0, 0, 0, 0, 1, i])
		vnfs.append([idx+1,ENDPOINT, 0, 0, 0, 0, 1, i])
	return vnfs

def createDomainInfo():
	# init active domains
	active_domains =  random.sample(range(n_domains), n_domains/2)
	active_domains.append(start_domain-1)
	active_domains.append(target_domain-1)

	# init domain costs
	domain_costs = [[0 for x in range(n_domains)] for y in range(n_domains)] 

	for x in range(n_domains):
		for y in range(n_domains):
			if x < y:
				tmpcost = random.randint(2, 8)
				domain_costs[x][y] = tmpcost
				domain_costs[y][x] = tmpcost
	return active_domains,domain_costs

def createVNFproperties():

	# --- DPI
	unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[VNF_KEY_TYPE] == 0]
	dpi_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
	for x in range(n_vnfs):
		if vnfs[x][0] in dpi_vnf and vnfs[x][VNF_KEY_TYPE] == 0:
			vnfs[x][VNF_KEY_TYPE] = DPI
			vnfs[x][VNF_KEY_TERMINATING] = 1
			vnfs[x][VNF_KEY_PATHSENSITIVE] = 0
			vnfs[x][VNF_KEY_MIRRORED] = 0

	# --- WANA
	unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[VNF_KEY_TYPE] == 0]
	selected_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
	for x in range(n_vnfs):
		if vnfs[x][0] in selected_vnf and vnfs[x][VNF_KEY_TYPE] == 0:
			vnfs[x][VNF_KEY_TYPE] = WANA
			vnfs[x][VNF_KEY_TERMINATING] = 0
			vnfs[x][VNF_KEY_PATHSENSITIVE] = 0 # or not
			vnfs[x][VNF_KEY_MIRRORED] = 1

	# --- SHAPER
	unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[VNF_KEY_TYPE] == 0]
	selected_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
	for x in range(n_vnfs):
		if vnfs[x][0] in selected_vnf and vnfs[x][VNF_KEY_TYPE] == 0:
			vnfs[x][VNF_KEY_TYPE] = SHAPER
			vnfs[x][VNF_KEY_TERMINATING] = 0
			vnfs[x][VNF_KEY_PATHSENSITIVE] = 0 # or not
			vnfs[x][VNF_KEY_MIRRORED] = 0
	return vnfs

def createVNFLinks(vnfs,VNF_KEY_TYPE,BORDER,VNF_KEY_DOMAIN,WANA,SHAPER,DPI):
		
	# vnf link creation 1: same domain 
	# ----------------------------
	vnf_links = []
	for i in [idx for idx, vnf in enumerate(vnfs) if vnf[VNF_KEY_TYPE] == BORDER]:
		for j in [idx for idx, vnf in enumerate(vnfs) if vnf[VNF_KEY_TYPE] != BORDER and  vnf[VNF_KEY_DOMAIN] == vnfs[i][VNF_KEY_DOMAIN] ]:
			vnf_links.append([vnfs[i][0],vnfs[j][0]])
			vnf_links.append([vnfs[j][0],vnfs[i][0]])


	# vnf link creation 2: gatway borders vnfs
	# ----------------------------

	for i in range(n_vnfs):
		for j in range(n_vnfs):
			if i != j and vnfs[i][VNF_KEY_DOMAIN] != vnfs[j][VNF_KEY_DOMAIN] and vnfs[i][VNF_KEY_TYPE] == BORDER and vnfs[j][VNF_KEY_TYPE] == BORDER :
				vnf_links.append([vnfs[i][0],vnfs[j][0]])

	return vnf_links



# ==============================================
# 	M A I N
# ==============================================

testFile = "test.dzn"

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
BORDER = 9;
ENDPOINT = 10;
WANA = 2;
DPI = 1;
SHAPER = 3;
M = 10;   # max domain cost
n_domains = 15;

# vnf range in domain
lb_domain_vnfs = 8
up_domain_vnfs = 25

vnfs = [];

endpoint_domains = random.sample(range(n_domains), 2)
start_domain = endpoint_domains[0]
target_domain = endpoint_domains[1]

# init vnfs
vnfs = createVNFs()
n_vnfs = len(vnfs)

# init domains
active_domains,domain_costs = createDomainInfo()


# assign properties: WANAs, DPI, SHAPER 
vnfs = createVNFproperties()

print "\nReport\n=========="
print "number of PDI", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == DPI)
print "number of WANA", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == WANA)
print "number of SHAPER", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == SHAPER)
print "WANA in start domain ", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == WANA and vnf[VNF_KEY_DOMAIN] == start_domain)
print "WANA in target domain ", sum(1 for vnf in vnfs if vnf[VNF_KEY_TYPE] == WANA and vnf[VNF_KEY_DOMAIN] == target_domain)

# create VNF links
vnf_links = createVNFLinks(vnfs,VNF_KEY_TYPE,BORDER,VNF_KEY_DOMAIN,WANA,SHAPER,DPI)
num_vnf_links = len(vnf_links)

# Requests Generation
# -----------
total_dpi = len([vnf for vnf in vnfs if vnf[VNF_KEY_TYPE] == DPI])
dpi_ub = random.randint(2, 2+total_dpi/2)
acc_dpi = [1,dpi_ub]
dis_dpi = [0,5]

acc_wana = [2,n_domains]
dis_wana = [1,1]

acc_shaper = [1,n_domains]
dis_shaper = [0,1]

acc_service_range = [acc_dpi,acc_wana,acc_shaper]
dis_service_range = [dis_dpi,dis_wana,dis_shaper]
# =======================================
# 			Stringification
# =======================================


# stringfy active domains
# ----------------------------
str_active_domains = "[";
for x in xrange(0,n_domains):
	if x in active_domains:
		str_active_domains += "1,"
	else:
		str_active_domains += "0,"
str_active_domains = str_active_domains[:-1]
str_active_domains += "]"


# stringfy acc
# ----------------------------
str_acc_range = "[|";
for x in xrange(0,len(acc_service_range)):
	for y in xrange(2):
		str_acc_range += str(acc_service_range[x][y])+","
	str_acc_range = str_acc_range[:-1]
	str_acc_range += "|"
str_acc_range += "]"

# stringfy dis
# ----------------------------
str_dis_range = "[|";
for x in xrange(0,len(dis_service_range)):
	for y in xrange(2):
		str_dis_range += str(dis_service_range[x][y])+","
	str_dis_range = str_dis_range[:-1]
	str_dis_range += "|"
str_dis_range += "]"


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


out = "n_vnfs = "+str(n_vnfs)+";\n"
out += "start_domain = "+str(start_domain)+";\n"
out += "target_domain = "+str(target_domain)+";\n"
out += "M = "+str(M)+";\n"
out += "acc_request = "+str(str_acc_range)+";\n"
out += "dis_request = "+str(str_dis_range)+";\n"
out += "n_domains = "+str(n_domains)+";\n"
out += "domain_link_weights = "+str(str_domain_link_weights)+";\n"
out += "service_request = [1,1,0];\n"
out += "domain_activated = "+str_active_domains+";\n"
out += "num_vnf_links = "+str(num_vnf_links)+";\n"
out += "vnf_links = "+str_vnf_link+";\n"
out += "vnfs = "+str_vnf+";\n"

with open(testFile, 'w+') as outfile:
	outfile.write(out)