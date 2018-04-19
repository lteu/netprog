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
solver = "chuffed"
# solver = "ortools"
# solver = "gecode"
# solver = "cbc"
node_key = "150"
# testFile = solver+"/log_n"+node_key+"_"+node_key+"_d2_30.txt"
testFile = "results-c/"+solver+"/dc_log_n"+node_key+"_"+node_key+"_d15_15.txt"
dataset = loadDataset(testFile)
# print dataset
arr_str = []
arr_succ = []
arr_tot = []
arr_avg = []
arr_unsat  = []
for dc in range(0,16):
# for dm in range(2,31):
	keycase = ":dc"+str(dc)+"/"
	data = [entry[1] for entry in dataset if keycase in entry[0]]
	casestack = []


	# print [entry for entry in dataset if keycase in entry[0]]
	# print entry
	total_n = 0
	succ_n = 0
	for d in data:
		sa = 0 if d['optima'] ==  '' else len(d['optima'].strip().split(","))
		sb = 0 if d['unsat'] == '' else len(d['unsat'].strip().split(","))
		sc = 0 if d['failed'] == '' else len(d['failed'].strip().split(","))
		sd = 0 if d['uncompile'] == '' else len(d['uncompile'].strip().split(","))
		se = 0 if d['suboptima'] == '' else len(d['suboptima'].strip().split(","))
		casestack = casestack + d['optima'].split(",") +  d['unsat'].split(",")
		unsattack = casestack +  d['unsat'].split(",") + d['uncompile'].split(",")
		total_n = total_n + sa+sb+sc+se+se

		succ_n = succ_n + sa
	arr_str.append(keycase)
	arr_succ.append(succ_n)
	arr_tot.append(total_n)

	casestack = [float(x) for x in casestack if x != '']
	unsattack = [float(x) for x in unsattack if x != '']
	print unsattack
	if len(casestack) == 0:
		casestack = [10]
	average = sum(casestack)/len(casestack)
	unsat_average = sum(unsattack)/len(unsattack)
	arr_str.append(keycase)

	arr_avg.append(average)
	arr_unsat.append(unsat_average)


print 'avg'
print arr_avg

print 'usat avg'
print arr_unsat

rlt = []
for i in range(len(arr_tot)):
	x = round((100-float(arr_succ[i]))/100,2)
	rlt.append(x)

print rlt