'''
This script makes experiments on a set of instances,
runtime stats will be produced.
'''

import glob
import os
import time
import sys
from shutil import copyfile
from run.kit_run import checkMZNResult
	
start = time.time()


cmd = "mzn2fzn model/unique.mzn example/data-exp-n780-d15/d15n60/map2.dzn example/data-exp-n780-d15/d15n60/req2/request6.dzn -o xxx.fzn"
print cmd
compileinfo = os.popen(cmd).read() 

cmd = "./fzn_chuffed.dms xxx.fzn"
print cmd
rlt = os.popen(cmd).read() # This will run the command and return any output

time_lapse = time.time()-start
state = checkMZNResult(rlt)
print state,time_lapse
