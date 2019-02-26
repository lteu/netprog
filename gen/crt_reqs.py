# this file generates 'n' simulated requests

import glob
import sys
import os
from random import randint,sample
from intent_generator import loadRequests,requestToVar

def domainTodConstraints(domains_having_constraints):
	dcs = ""
	counter = 0
	for d in domains_having_constraints:
		
		id_d = d + 1
		choice = randint(1,3)
		if choice == 1:
			dcs = dcs + str(id_d)+",1,1,1|"
			counter = counter +1
		elif choice == 2:
			dcs = dcs + str(id_d)+",3,1,1|"
			counter = counter +1
		elif choice == 3:
			dcs = dcs + str(id_d)+",1,1,1|"
			dcs = dcs + str(id_d)+",3,1,1|"
			counter = counter + 2
		if counter > len(domains_having_constraints):
			break

	if dcs != "":
		dcs = "|"+dcs
	else:
		counter = 1
		dcs = "|0,0,0,0|"

	# print 'receive',len(domains_having_constraints),'return',dcs
	return dcs,counter


def genReq(n_domains,n_dConstraints):

	# choose domains
	active_domains =  sample(range(n_domains), 2)
	start = active_domains[0] + 1; 
	target = active_domains[1] + 1;  

	requests = loadRequests()
	reqIdx = randint(0,len(requests)-1)
	vnflist,vnfarcs,p_to_s,p_to_d  = requestToVar(requests[reqIdx])
	# print p_to_d


	# domain constraints
	domains_having_constraints =  sample(range(n_domains), n_dConstraints)
	str_dcst,counter = domainTodConstraints(domains_having_constraints)


	# stringfy src
	# ----------------------------
	str_vnf_arcs = "[|";
	for x in xrange(0,len(vnfarcs)):
		for y in xrange(2):
			str_vnf_arcs += str(vnfarcs[x][y])+","
		str_vnf_arcs = str_vnf_arcs[:-1]
		str_vnf_arcs += "|"
	str_vnf_arcs += "]"

	out = ""
	out += "start_domain = "+str(start)+";\n"
	out += "target_domain = "+str(target)+";\n"
	out += "vnflist_size = "+str(len(vnflist.split(",")))+";\n"
	out += "vnflist = ["+vnflist+"];\n"
	out += "vnf_arcs = "+str_vnf_arcs+";\n"
	out += "proximity_to_source = ["+",".join(p_to_s)+"];\n"
	out += "proximity_to_destination = ["+",".join(p_to_d)+"];\n"
	out += "n_domain_constraints = "+str(counter)+";\n"
	out += "domain_constraints = ["+str_dcst+"];\n"

	return out


def call_gen_reqs(n_domains,rep,path,n_dConstraints):
	for x in xrange(1,rep+1):
		outfilepath = path+str(x)+".dzn"
		outstr = genReq(n_domains,n_dConstraints)
		with open(outfilepath, 'w+') as outfile:
			outfile.write(outstr)

	return path

if __name__ == '__main__':
	# example 
	path = "../testbed/requests/"
	if not os.path.exists(path):
		os.makedirs(path)

	n_domains_constrs = 3
	path = call_gen_reqs(8,20,path,n_domains_constrs)
	print 'Done, simulated requests are generated at',path



