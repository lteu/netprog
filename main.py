import glob
import os
import time
testFile = "data.dzn"

startreg = False
links = []
# with open(testFile) as ff:
# 	for line in ff:
# 		if 'vnf_links = [|' in line.lower():
# 			startreg = True
# 		elif  '];' in line.lower() and startreg:
# 			startreg = False
# 			break
		

# 		if startreg:
# 			pieces = line.strip().split("|")  
# 			pieces2 = pieces[1].split(",")  
# 			links.append([int(pieces2[0].strip()),int(pieces2[1].strip())])

# 		else:
# 			True

# print links

start = time.time()


os.system("mzn2fzn -I mznlib vnf.mzn -o xxx.fzn") # run command
rlt = os.popen("./fzn_chuffed.dms xxx.fzn").read() # This will run the command and return any output

# os.system("mzn2fzn -I mznlib vnf.mzn data.dzn -o xxx.fzn") # run command
# rlt = os.popen("./fzn_chuffed.dms xxx.fzn").read() # This will run the command and return any output


print rlt


# pieces = rlt.split("----------")  
# pieces2 = pieces[-2].split("[")  
# pieces3 = pieces2[1].split("]")  
# sel_edges = pieces3[0].split(",")  

# sel_edges = [int(x) for x in sel_edges]
# print sel_edges
# linkids = [ind for ind, p in enumerate(sel_edges) if p != 0]

# for idx in linkids:
# 	print links[idx]

print 'runtime:', time.time()-start, 'seconds.'

