import glob
import sys
import random
testFile = "test.dzn"


  
start = 1; 
target = 120;  
M = 10;    
n_domains = 12;

lb_domain_vnfs = 20
up_domain_vnfs = 30
vnfs = [];

# init vnfs
for i in xrange(1,n_domains+1):
	numVnf = random.randint(lb_domain_vnfs, up_domain_vnfs)
	for j in xrange(1,numVnf+1):
		idx = len(vnfs) + 1
		vnfs.append([idx,0, 0, 0, 0, 0, 1, i])


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
link_weights = [[0 for x in range(n_vnfs)] for y in range(n_vnfs)] 

for x in range(n_vnfs):
	for y in range(n_vnfs):
		if x < y:
			tmpcost = domain_costs[vnfs[x][7]-1][vnfs[y][7]-1]
			link_weights[x][y] = tmpcost+1
			link_weights[y][x] = tmpcost+1


# print ', '.join('\n{}'.format( i) for v, i in enumerate(domain_costs))
# print ', '.join('\n{}'.format( i) for v, i in enumerate(link_weights))
# print ', '.join('\n{}'.format( i) for v, i in enumerate(vnfs))


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
str_link_weights = "[|";
for x in xrange(0,n_vnfs):
	for y in xrange(0,n_vnfs):
		str_link_weights += str(link_weights[x][y])+","
	str_link_weights = str_link_weights[:-1]
	str_link_weights += "|"
str_link_weights += "]"


# stringfy WANAs and DPI
# ----------------------------
dpi_vnf =  random.sample(range(n_vnfs), n_vnfs/5)
for x in range(n_vnfs):
	if x in dpi_vnf:
		vnfs[x][2] = 1


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
out += "link_weights = "+str_link_weights+";\n"
out += "vnfs = "+str_vnf+";\n"

with open(testFile, 'w+') as outfile:
	outfile.write(out)