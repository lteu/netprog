import glob
import os
import time
import sys
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

def getVNFLinkSel(raw):
	pieces = raw.split("----------")  
	pieces2 = pieces[-2].split(";")  
	relevant_str = ""
	for x in xrange(len(pieces2)):
		if "link_selection" in pieces2[x]:
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

def parseVNFlinkInArray(raw):
	pieces = raw.strip().split("|") 
	tuples = pieces[1:-1]
	return [item.split(",") for item in tuples]

def getVNFLinksFromFile(dznfile):
	content = ""
	parsed_link = []
	parsed_vnf = []
	with open(dznfile, 'r') as content_file:
		content = content_file.read()

	pieces = content.strip().split("\n")
	for piece in pieces:
		if piece.startswith( 'vnf_links' ):
			parsed_link = parseVNFlinkInArray(piece)
		elif piece.startswith( 'vnfs' ) :
			parsed_vnf = parseVNFlinkInArray(piece)

	return parsed_link,parsed_vnf

def toMZNString(vnflink_arr):
	# print len(vnflink_arr)
	# flattened = [','.join(x for x in item)  for item in vnflink_arr]
	# outstr = "vnf_links = [|"+ '|'.join(x for x in flattened) + "|];"
	# outstr_num = "num_vnf_links = " + str(len(vnflink_arr)) +";"
	flattened = [','.join(x for x in item)  for item in vnflink_arr]
	outstr = "vnfs = [|"+ '|'.join(x for x in flattened) + "|];"
	# print outstr,outstr_num
	return outstr
	
def parseMZNResult(raw):
	pieces = raw.strip().split("(")    
	range1 = pieces[1].split(",")[0]  
	low  = int(range1.split("..")[0])
	high  = int(range1.split("..")[1])

	tmp1 = pieces[1].split("[")[1] 
	tmp2 = tmp1.split("]")[0]  
	arr = tmp2.split(",")
	arr = [int(x) for x in arr]

	return arr,low,high

def getUpdatedLinks(mzn_arr,vnflinks,vnfs):
	arr = []
	blacklist = []
	for x in xrange(len(vnflinks)):
		if mzn_arr[x] == 1:
			pair = vnflinks[x]
			for elem in pair:
				prop = [vnf for vnf in vnfs if vnf[0] == elem][0]
				# print prop
				if int(prop[1]) < 8: # function-type vnf
					vnfs[int(prop[0])-1][6] = '0' #disactive
				
			# need analysis
			# arr.append()
	return vnfs


def updateMaplog(testlog,outstr):
	content_arr = []
	with open(testlog, 'r') as content_file:
		content = content_file.read()

	pieces = content.strip().split("\n")
	for piece in pieces:
		# if 'vnf_links' not in piece.lower() and 'num_vnf_links' not in piece.lower():
		if not piece.startswith( 'vnfs' ):
			content_arr.append(piece)
	
	content_arr.append(outstr)

	content = "\n".join(content_arr)

	with open(testlog, 'w') as f:
		f.write(content)

def checkMZNResult(raw):
	if "----------" not in raw:
		return False
	else:
		return True

def checkMZNCompile(raw):
	if raw == "":
		return True
	else:
		return False
# ==============================
# 			MAIN
# ==============================

testMap = "data-exp/map.dzn"

# copy network map file

infile = testMap.split(".")  
testlog = infile[0]+"-log.dzn"
copyfile(testMap, testlog)

# with open(outfilename, "a") as myfile:
# 	myfile.write(relevant_str+";")

# get original link information

parsed_link, parsed_vnf =  getVNFLinksFromFile(testlog)
# print parsed_link


# - START
for x in xrange(1,4):
	print "======================================"
	start = time.time()

	testIst = "data-exp/request"+str(x)+".dzn"

	cmd ="mzn2fzn -I mznlib fg-domain.mzn "+testMap+" "+testIst+" -o xxx.fzn"
	print cmd
	compileinfo = os.popen(cmd).read() 

	if compileinfo != "":
		print "COMPILE ERROR 1",compileinfo
		sys.exit();

	# print compile1
	# os.system(cmd1) # run command
	
	cmd = "./fzn_chuffed.dms xxx.fzn"
	print cmd
	rlt = os.popen(cmd).read() # This will run the command and return any output
	

	if not checkMZNResult(rlt): sys.exit("\nexecution err1: "+rlt)

	relevant_str =  getDomainLinkSel(rlt)
	outfilename = generateOutFile(relevant_str,testlog)

	cmd = "mzn2fzn -I mznlib fg-vnf.mzn "+outfilename+" "+testIst+" -o yyy.fzn"
	print cmd
	compileinfo = os.popen(cmd).read() 

	if compileinfo != "":
		print "COMPILE ERR 2",compileinfo
		sys.exit();

	cmd = "./fzn_chuffed.dms yyy.fzn"
	print cmd
	rlt = os.popen(cmd).read() # This will run the command and return any output
	
	if not checkMZNResult(rlt): sys.exit("\nexecution err2: "+rlt)
	
	link_info  = getVNFLinkSel(rlt)

	# - END

	# update link with results
	mzn_arr, mzn_low, mzn_high = parseMZNResult(link_info)

	# testing
	# mzn_arr[len(mzn_arr) -1] = 1
	# print parsed_link, mzn_arr

	vnfs = getUpdatedLinks(mzn_arr,parsed_link,parsed_vnf)
	outstr = toMZNString(vnfs)
	# print outstr
	# sys.exit()
	# print outstr,outstr_num
	# update maplog
	updateMaplog(testlog,outstr)

	print 'runtime:', time.time()-start, 'seconds.'

