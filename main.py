import glob
import os
import time
from shutil import copyfile

def getDomainLinkSel(raw):
	pieces = raw.split("----------")  
	pieces2 = pieces[-2].split(";")  
	relevant_str = ""
	for x in xrange(len(pieces2)):
		if "domain_link_selection" in pieces2[x]:
			relevant_str = pieces2[x]

	# relevant_str = relevant_str.replace('domain_link_selection', 'domain_connection')
	return relevant_str



def generateOutFile(relevant_str,input_file):
	infile = input_file.split(".")  
	outfilename = infile[0]+"dom.dzn"
	copyfile(input_file, outfilename)

	with open(outfilename, "a") as myfile:
		myfile.write(relevant_str+";")

	return outfilename

testFile = "data/test264.dzn"

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

# os.system("mzn2fzn -I mznlib vnf.mzn -o xxx.fzn") # run command
# os.system("mzn2fzn -I mznlib dvnf.mzn test28.dzn -o xxx.fzn") # run command
# os.system("mzn2fzn -I mznlib hvnf.mzn -o xxx.fzn") # run command
# os.system("mzn2fzn -I mznlib vnf-inefficient.mzn -o xxx.fzn") # run command

# unique execution sequence start
# os.system("mzn2fzn -I mznlib model.mzn "+testFile+" -o xxx.fzn") # run command
# rlt = os.popen("./fzn_chuffed.dms xxx.fzn").read() # This will run the command and return any output
# print rlt


# separate execution sequence start
cmd1 ="mzn2fzn -I mznlib fg-domain.mzn "+testFile+" -o xxx.fzn"
os.system(cmd1) # run command
print cmd1
rlt = os.popen("./fzn_chuffed.dms xxx.fzn").read() # This will run the command and return any output

relevant_str =  getDomainLinkSel(rlt)
outfilename = generateOutFile(relevant_str,testFile)

cmd2 = "mzn2fzn -I mznlib fg-vnf.mzn "+outfilename+" -o yyy.fzn"
os.system(cmd2) # run command
print cmd2
rlt2 = os.popen("./fzn_chuffed.dms yyy.fzn").read() # This will run the command and return any output

print rlt2
# separate execution sequence end



# os.system("mzn2fzn -I mznlib vnf.mzn data.dzn -o xxx.fzn") # run command
# rlt = os.popen("./fzn_chuffed.dms xxx.fzn").read() # This will run the command and return any output


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

