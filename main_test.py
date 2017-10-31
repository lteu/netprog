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

	relevant_str = relevant_str.replace('domain_link_selection', 'domain_connection')
	return relevant_str



def generateOutFile(relevant_str,input_file):
	infile = input_file.split(".")  
	outfilename = infile[0]+"dom.dzn"
	copyfile(input_file, outfilename)

	with open(outfilename, "a") as myfile:
		myfile.write(relevant_str+";")

	return outfilename



startreg = False
links = []

start = time.time()


os.system("mzn2fzn -I mznlib fg-vnf.mzn data/test291dom.dzn -o xxx.fzn") # run command
rlt2 = os.popen("./fzn_chuffed.dms xxx.fzn").read() # This will run the command and return any output

print rlt2

print 'runtime:', time.time()-start, 'seconds.'

