# This file generates VNF topology
# 

import glob
import sys
import random
import os
from crt_map import call_gen_map
from crt_reqs import call_gen_reqs
from main import exc



test_nodes = range(30,800,30)

# test_domains = range(5,6)
# test_domains = range(10,11)
test_domains = range(15,16)

test_maps = range(1,11)

test_dcons = range(2,3)
parts = os.path.abspath(__file__).split("/")
parts = parts[:-2]
expdir = '/'.join(parts) + "/testbed/data-exp-n"+str(test_nodes[-1])+"-d"+str(test_domains[-1])

rep = 10

exc(test_nodes,test_domains,test_maps,test_dcons,expdir,rep)





