# vnf link list structure
# all gateway connection

import glob
import sys
import random
testFile = "test.dzn"


KEY_TYPE = 1
KEY_DOMAIN = 7
BORDER = 1;
WANA = 2;
DPI = 3;
SHAPER = 4;

start = 1; 
target = 50;  
M = 10;    
n_domains = 15;

lb_domain_vnfs = 8
up_domain_vnfs = 25
vnfs = [];



# init vnfs
for i in xrange(1,n_domains+1):
	numVnf = random.randint(lb_domain_vnfs, up_domain_vnfs)

	# append others
	for j in xrange(1,numVnf+1):
		idx = len(vnfs) + 1
		vnfs.append([idx,0, 0, 0, 0, 0, 1, i])

	# append border node
	idx = len(vnfs) + 1
	vnfs.append([idx,BORDER, 0, 0, 0, 0, 1, i])


n_vnfs = len(vnfs);

assert target-1 < n_vnfs
assert vnfs[start-1][KEY_DOMAIN] != vnfs[target-1][KEY_DOMAIN]

# init active domains
active_domains =  random.sample(range(n_domains), n_domains/2)
active_domains.append(vnfs[start-1][7]-1)
active_domains.append(vnfs[target-1][7]-1)

# init domain costs
domain_costs = [[0 for x in range(n_domains)] for y in range(n_domains)] 

for x in range(n_domains):
	for y in range(n_domains):
		if x < y:
			tmpcost = random.randint(2, 8)
			domain_costs[x][y] = tmpcost
			domain_costs[y][x] = tmpcost


# properties assignments: WANAs, DPI, SHAPER 
# ----------------------------

# --- DPI
unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[KEY_TYPE] == 0]
dpi_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
for x in range(n_vnfs):
	if vnfs[x][0] in dpi_vnf and vnfs[x][KEY_TYPE] == 0:
		vnfs[x][KEY_TYPE] = DPI

# --- WANA
unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[KEY_TYPE] == 0]
selected_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
for x in range(n_vnfs):
	if vnfs[x][0] in selected_vnf and vnfs[x][KEY_TYPE] == 0:
		vnfs[x][KEY_TYPE] = WANA

# --- SHAPER
unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[KEY_TYPE] == 0]
selected_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
for x in range(n_vnfs):
	if vnfs[x][0] in selected_vnf and vnfs[x][KEY_TYPE] == 0:
		vnfs[x][KEY_TYPE] = SHAPER


vnfs[start-1][KEY_TYPE] = 0
vnfs[target-1][KEY_TYPE] = 0

print "\nReport\n=========="
print "number of PDI", sum(1 for vnf in vnfs if vnf[KEY_TYPE] == DPI)
print "number of WANA", sum(1 for vnf in vnfs if vnf[KEY_TYPE] == WANA)
print "number of SHAPER", sum(1 for vnf in vnfs if vnf[KEY_TYPE] == SHAPER)
print "WANA in start domain ", sum(1 for vnf in vnfs if vnf[KEY_TYPE] == WANA and vnf[KEY_DOMAIN] == vnfs[start-1][KEY_DOMAIN])
print "WANA in target domain ", sum(1 for vnf in vnfs if vnf[KEY_TYPE] == WANA and vnf[KEY_DOMAIN] == vnfs[target-1][KEY_DOMAIN])

# DPI requests generation
# ----------------------------
max_dpi = 0
domain_max_dpi = [0 for x in range(n_domains)]
tester = []
for idx in range(n_domains):
	i = idx + 1
	num_max_dpi_domain = len([vnf for vnf in vnfs if vnf[KEY_TYPE] == DPI and  vnf[KEY_DOMAIN] == i])
	num_dpi_domain = random.randint(0, num_max_dpi_domain)
	tester.append(num_max_dpi_domain)
	if idx in active_domains:
		domain_max_dpi[idx] = num_dpi_domain
	else:
		domain_max_dpi[idx] = 0

	# print i, num_max_dpi_domain,num_dpi_domain

lb_max_dpi_num = sum(1 for item in domain_max_dpi if item > 0)
up_max_dpi_num = sum(item for item in domain_max_dpi)
# print lb_max_dpi_num, up_max_dpi_num
max_dpi = random.randint(lb_max_dpi_num, up_max_dpi_num)
# print max_dpi, domain_max_dpi, active_domains,tester



# SHAPER requests generation
# ----------------------------
domain_shaper = [0 for x in range(n_domains)]
for idx in range(n_domains):
	if idx in active_domains:
		domain_shaper[idx] = random.randint(0, 1)

# print domain_shaper

# print ', '.join('\n{}'.format( i) for v, i in enumerate(domain_costs))
# print ', '.join('\n{}'.format( i) for v, i in enumerate(link_weights))
# print ', '.join('\n{}'.format( i) for v, i in enumerate(vnfs))

# vnf link creation 1: same domain 
# ----------------------------
vnf_links = []
for i in [idx for idx, vnf in enumerate(vnfs) if vnf[KEY_TYPE] == BORDER]:
	for j in [idx for idx, vnf in enumerate(vnfs) if vnf[KEY_TYPE] != BORDER and  vnf[KEY_DOMAIN] == vnfs[i][KEY_DOMAIN] ]:
		# print '.',
		if  vnfs[j][0] == start:
			# print "start"
			vnf_links.append([vnfs[j][0],vnfs[i][0]])
		elif vnfs[j][0] == target:
			# print "target"
			vnf_links.append([vnfs[i][0],vnfs[j][0]])
		elif vnfs[j][KEY_TYPE] == DPI:
			vnf_links.append([vnfs[i][0],vnfs[j][0]])
		elif vnfs[j][KEY_TYPE] == WANA or vnfs[j][KEY_TYPE] == SHAPER:
			vnf_links.append([vnfs[i][0],vnfs[j][0]])
			vnf_links.append([vnfs[j][0],vnfs[i][0]])


# print ', '.join('\n{}'.format( i) for v, i in enumerate(vnf_links))


# vnf link creation 2: gatway borders vnfs
# ----------------------------

for i in range(n_vnfs):
	for j in range(n_vnfs):
		if i != j and vnfs[i][KEY_DOMAIN] != vnfs[j][KEY_DOMAIN] and vnfs[i][KEY_TYPE] == BORDER and vnfs[j][KEY_TYPE] == BORDER :
			vnf_links.append([vnfs[i][0],vnfs[j][0]])

# print vnf_links


num_vnf_links = len(vnf_links)
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


# stringfy max domain dpis
# ----------------------------
str_domain_dpis = "[";
for x in domain_max_dpi:
	str_domain_dpis += str(x)+","
str_domain_dpis = str_domain_dpis[:-1]
str_domain_dpis += "]"


# stringfy domain shaper
# ----------------------------
str_domain_shapers = "[";
for x in domain_shaper:
	str_domain_shapers += str(x)+","
str_domain_shapers = str_domain_shapers[:-1]
str_domain_shapers += "]"


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


# stringfy link weights
# ----------------------------
# str_link_weights = "[|";
# for x in xrange(0,n_vnfs):
# 	for y in xrange(0,n_vnfs):
# 		str_link_weights += str(link_weights[x][y])+","
# 	str_link_weights = str_link_weights[:-1]
# 	str_link_weights += "|"
# str_link_weights += "]"






# stringfy link weights
# ----------------------------
str_vnf = "[|";
for x in xrange(0,len(vnfs)):
	for y in xrange(0,len(vnfs[0])):
		str_vnf += str(vnfs[x][y])+","
	str_vnf = str_vnf[:-1]
	str_vnf += "|"
str_vnf += "]"


out = "n_vnfs = "+str(n_vnfs)+";\n"
out += "start = "+str(start)+";\n"
out += "target = "+str(target)+";\n"
out += "M = "+str(M)+";\n"
out += "max_dpi = "+str(max_dpi)+";\n"
out += "domain_req_dpi = "+str(str_domain_dpis)+";\n"
out += "domain_req_shaper = "+str(str_domain_shapers)+";\n"
out += "n_domains = "+str(n_domains)+";\n"
out += "domain_link_weights = "+str(str_domain_link_weights)+";\n"
out += "params = [1,1,0];\n"
out += "domain_activated = "+str_active_domains+";\n"
out += "num_vnf_links = "+str(num_vnf_links)+";\n"
out += "vnf_links = "+str_vnf_link+";\n"
out += "vnfs = "+str_vnf+";\n"

with open(testFile, 'w+') as outfile:
	outfile.write(out)