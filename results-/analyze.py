import numpy as np
import matplotlib.pyplot as plt
import sys


def loadDataset(testFile):
	# print a + b
	with open(testFile, 'r') as content_file:
	    content = content_file.read()


	dataset = []
	pieces = content.strip().split("======")      
	pieces = [x for x in pieces if x.strip() != '']
	for piece in pieces:
		parts = piece.split("\n")
		case = parts[1]
		dic = {}
		for part in parts:
			if part.startswith( 'optima:' ):
				runtime = part.split("optima:")[1].strip()
				dic['optima'] = runtime

			elif part.startswith( 'unsat:' ):
				runtime = part.split("unsat:")[1].strip()
				dic['unsat'] = runtime

			elif part.startswith( 'failed:' ):
				runtime = part.split("failed:")[1].strip()
				dic['failed'] = runtime
			elif part.startswith( 'uncompile:' ):
				runtime = part.split("uncompile:")[1].strip()
				dic['uncompile'] = runtime
			elif part.startswith( 'suboptima:' ):
				runtime = part.split("suboptima:")[1].strip()
				dic['suboptima'] = runtime
		dataset.append([case,dic])

	return dataset

# ============================================================
# ============================================================
# ============================================================

# ====================== success runs by varying domains ======================================


# varying domains
# solver = "chuffed"
# solver = "ortools"
# solver = "gecode"
solver = "cbc"
node_key = "100"
# testFile = solver+"/log_n"+node_key+"_"+node_key+"_d2_30.txt"
testFile = solver+"/log_n"+node_key+"_"+node_key+"_d2_15.txt"
dataset = loadDataset(testFile)
# print dataset
arr_str = []
arr_data = []
arr_tot = []
for dm in range(2,16):
# for dm in range(2,31):
	keycase = "/d"+str(dm)+"n"+node_key+"/"
	data = [entry[1] for entry in dataset if keycase in entry[0]]
	casestack = []

	# print [entry for entry in dataset if keycase in entry[0]]
	# print entry
	total_n = 0
	fail_n = 0
	for d in data:
		# print d.keys()
		sa = 0 if d['optima'] ==  '' else len(d['optima'].strip().split(","))
		sb = 0 if d['unsat'] == '' else len(d['unsat'].strip().split(","))
		sc = 0 if d['failed'] == '' else len(d['failed'].strip().split(","))
		sd = 0 if d['uncompile'] == '' else len(d['uncompile'].strip().split(","))
		se = 0 if d['suboptima'] == '' else len(d['suboptima'].strip().split(","))
		print sa
		total_n = total_n + sa+sb+sc+se+se
		fail_n = fail_n + sa
	arr_str.append(keycase)
	arr_data.append(fail_n)
	arr_tot.append(total_n)

print arr_str
# print arr_tot
print arr_data

rlt = []
for i in range(len(arr_tot)):
	# print arr_data[i],arr_tot[i]
	# x = round(float(arr_data[i])/float(arr_tot[i]),2)
	x = round((100-float(arr_data[i]))/100,2)
	# print x
	rlt.append(x)

print rlt
# ====================== varying domains ======================================


# # varying domains
# # solver = "chuffed"
# # solver = "ortools"
# # solver = "gecode"
# solver = "cbc"
# node_key = "100"
# # testFile = solver+"/log_n"+node_key+"_"+node_key+"_d2_30.txt"
# testFile = solver+"/log_n"+node_key+"_"+node_key+"_d2_15.txt"
# dataset = loadDataset(testFile)
# print dataset
# arr_str = []
# arr_data = []
# # for dm in range(2,16):
# for dm in range(2,31):
# 	keycase = "d"+str(dm)+"n"+node_key
# 	data = [entry[1] for entry in dataset if keycase in entry[0]]
# 	casestack = []
# 	for d in data:
# 		casestack = casestack + d['optima'].split(",") +  d['unsat'].split(",")

# 	# print casestack
# 	casestack = [float(x) for x in casestack if x != '']
# 	if len(casestack) == 0:
# 		casestack = [10]

# 	average = sum(casestack)/len(casestack)
# 	arr_str.append(keycase)
# 	arr_data.append(average)

# print arr_str
# print arr_data



# ====================== varying nodes ======================================

# solver = "gecode"
# solver = "cbc"
# domain_key = "10"
# testFile = solver+"/log_n30_810_d"+domain_key+"_"+domain_key+".txt"
# # testFile = "log_n30_810_d"+domain_key+"_"+domain_key+".txt"

# dataset = loadDataset(testFile)
# arr_str = []
# arr_data = []
# for nd in xrange(30,810,30):
# 	keycase = "/d"+domain_key+"n"+str(nd)+"/"
# 	data = [entry[1] for entry in dataset if keycase in entry[0]]
# 	casestack = []
# 	for d in data:
# 		casestack = casestack + d['optima'].split(",") +  d['unsat'].split(",")

# 	casestack = [float(x) for x in casestack if x != '']
# 	if len(casestack) == 0:
# 		casestack = [10]
# 	average = sum(casestack)/len(casestack)
# 	arr_str.append(keycase)
# 	arr_data.append(average)

# print arr_str
# print arr_data

