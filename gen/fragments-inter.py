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

assert target < n_vnfs
assert vnfs[start][7] != vnfs[target][7]


# init domain costs
domain_costs = [[0 for x in range(n_domains)] for y in range(n_domains)] 

for x in range(n_domains):
	for y in range(n_domains):
		if x < y:
			tmpcost = random.randint(2, 8)
			domain_costs[x][y] = tmpcost
			domain_costs[y][x] = tmpcost


# in sequence, init link costs
# link_weights = [[0 for x in range(n_vnfs)] for y in range(n_vnfs)] 

# for x in range(n_vnfs):
# 	for y in range(n_vnfs):
# 		if x < y:
# 			tmpcost = domain_costs[vnfs[x][7]-1][vnfs[y][7]-1]
# 			link_weights[x][y] = tmpcost+1
# 			link_weights[y][x] = tmpcost+1


# properties assignments: WANAs, DPI, SHAPER 
# ----------------------------
unassigned_vnf_ids = [tmp[0] for tmp in vnfs if tmp[KEY_TYPE] == 0]
dpi_vnf =  random.sample(unassigned_vnf_ids, len(unassigned_vnf_ids)/5)
for x in range(n_vnfs):
	if vnfs[x][0] in dpi_vnf and vnfs[x][KEY_TYPE] == 0:
		vnfs[x][KEY_TYPE] = DPI


vnfs[start][KEY_TYPE] = 0
vnfs[target][KEY_TYPE] = 0
# print ', '.join('\n{}'.format( i) for v, i in enumerate(domain_costs))
# print ', '.join('\n{}'.format( i) for v, i in enumerate(link_weights))
# print ', '.join('\n{}'.format( i) for v, i in enumerate(vnfs))

# vnf link creation 1: same domain 
# ----------------------------
vnf_links = []
for i in range(n_vnfs):
	for j in range(n_vnfs):
		if i != j and vnfs[i][KEY_DOMAIN] == vnfs[j][KEY_DOMAIN] and vnfs[i][KEY_TYPE] != DPI and vnfs[i][0] != target and vnfs[j][0] != start:
			vnf_links.append([vnfs[i][0],vnfs[j][0]])


# print ', '.join('\n{}'.format( i) for v, i in enumerate(vnf_links))


# vnf link creation 2: boder vnfs
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
active_domains =  random.sample(range(n_domains), n_domains/2)
active_domains.append(vnfs[start-1][7]-1)
active_domains.append(vnfs[target-1][7]-1)
str_active_domains = "[";
for x in xrange(0,n_domains):
	if x in active_domains:
		str_active_domains += "1,"
	else:
		str_active_domains += "0,"
str_active_domains = str_active_domains[:-1]
str_active_domains += "]"


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
out += "n_domains = "+str(n_domains)+";\n"
out += "domain_link_weights = "+str(str_domain_link_weights)+";\n"
out += "params = [1,1,0];\n"
out += "domain_activated = "+str_active_domains+";\n"
out += "num_vnf_links = "+str(num_vnf_links)+";\n"
out += "vnf_links = "+str_vnf_link+";\n"
out += "vnfs = "+str_vnf+";\n"

with open(testFile, 'w+') as outfile:
	outfile.write(out)