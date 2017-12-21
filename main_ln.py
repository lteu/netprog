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
				marked_vnf = [vnf for vnf in vnfs if vnf[0] == elem][0]
				blacklist.append(marked_vnf)
				print marked_vnf
				# print marked_vnf
				if int(marked_vnf[1]) < 8: # function-type vnf
					vnfs[int(marked_vnf[0])-1][6] = '0' #disactive
				
	# print blacklist
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

testMap = "data-exp/map-d15-n779.dzn"

# copy network map file

# infile = testMap.split(".")  
# testlog = infile[0]+"-log.dzn"
infile = testMap.split("/")  
infile_sel = infile[:-1]
testlog = "/".join(infile_sel)+"/maplog.dzn"
# print testlog
# sys.exit()
copyfile(testMap, testlog)

# with open(outfilename, "a") as myfile:
# 	myfile.write(relevant_str+";")

# get original link information

parsed_link, parsed_vnf =  getVNFLinksFromFile(testlog)
# print parsed_link


solved_times = []
unsolved_times = []
for x in xrange(0,20):

	print "======================================"

	start = time.time()

	testIst = "data-exp/requests/request"+str(x)+".dzn"

	cmd ="minizinc-2.1.2/bin/mzn2fzn -I mznlib fg-domain.mzn "+testMap+" "+testIst+" -o xxx.fzn"
	print cmd
	compileinfo = os.popen(cmd).read() 

	isSuccess = True
	failed_msg = ""
	if compileinfo != "":
		isSuccess = False
		failed_msg = "err1 compiling fg-domain.mzn"
		print "COMPILE ERROR 1",compileinfo


	if isSuccess:
		
		cmd = "./fzn_chuffed xxx.fzn"
		print cmd
		rlt = os.popen(cmd).read()
		
		if not checkMZNResult(rlt):
			failed_msg = "err2 solving fg-domain.mzn"
			isSuccess = False


		if isSuccess:
			relevant_str =  getDomainLinkSel(rlt)
			outfilename = generateOutFile(relevant_str,testlog)

			cmd = "minizinc-2.1.2/bin/mzn2fzn -I mznlib fg-vnf.mzn "+outfilename+" "+testIst+" -o yyy.fzn"
			print cmd
			compileinfo = os.popen(cmd).read() 

			if compileinfo != "":
				# print "COMPILE ERR 2",compileinfo
				failed_msg = "err3 compiling fg-vnf.mzn"
				isSuccess = False
			

			if isSuccess:
				cmd = "./fzn_chuffed yyy.fzn"
				print cmd
				rlt = os.popen(cmd).read() # This will run the command and return any output
				
				# if not checkMZNResult(rlt): sys.exit("\nexecution err2: "+rlt)
				if not checkMZNResult(rlt): 
					failed_msg = "err4 solving fg-vnf.mzn"
					isSuccess = False
				
				if isSuccess:
					link_info  = getVNFLinkSel(rlt)
					# update link with results
					mzn_arr, mzn_low, mzn_high = parseMZNResult(link_info)
					vnfs = getUpdatedLinks(mzn_arr,parsed_link,parsed_vnf)
					outstr = toMZNString(vnfs)

					# update maplog
					updateMaplog(testlog,outstr)

	print "---"
	time_lapse = time.time()-start

	if isSuccess:
		solved_times.append(time_lapse)
		print "Success,",failed_msg
	else:
		unsolved_times.append(time_lapse)
		print "Failed, ",
	
	print 'runtime:', time_lapse, 'seconds.'

if len(solved_times) != 0:
	print "avg solved time", reduce(lambda x, y: x + y, solved_times) / len(solved_times)
if len(unsolved_times) != 0:
	print "avg unsolved time", reduce(lambda x, y: x + y, unsolved_times) / len(unsolved_times)

print "solved count",len(solved_times), "unsolved count",len(unsolved_times)
print "Scenario file",testMap