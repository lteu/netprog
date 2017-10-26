# 
#
#
# ref about color: https://stackoverflow.com/questions/27030473/how-to-set-colors-for-nodes-in-networkx-python
# ref network: https://www.python-course.eu/networkx.php

import networkx as nx
import matplotlib.pyplot as plt
import numpy as np
import operator

def getRangeAndArray(raw):
	pieces = raw.strip().split("(")    
	range1 = pieces[1].split(",")[0]  
	low  = int(range1.split("..")[0])
	high  = int(range1.split("..")[1])

	tmp1 = pieces[1].split("[")[1] 
	tmp2 = tmp1.split("]")[0]  
	arr = tmp2.split(",")
	arr = [int(x) for x in arr]

	return arr,low,high

def getVNFlinks(raw):
	pieces = raw.strip().split("|") 
	return pieces[1:-1]
def getVNFNodes(list_of_links):
	nodes_dup = [item.split(",")  for item in list_of_links]
	# flat_list = [item for sublist in nodes_dup]
	return set(reduce(operator.concat, nodes_dup))

testFile = "rlt.txt"

with open(testFile, 'r') as content_file:
    content = content_file.read()


link_selection = []
low = 0
hight = 0
pieces = content.strip().split(";")      
for piece in pieces:
	if 'link_selection' in piece.lower():
		link_selection,low,high = getRangeAndArray(piece)
	if 'vnf_links' in piece.lower():
		vnf_links = getVNFlinks(piece)

link_indexes = [idx for idx, val in enumerate(link_selection) if val != 0] # list index and value with filters

selected_edges = [edge for idx, edge in enumerate(vnf_links) if idx in link_indexes]
links =  selected_edges
nodes =  list(getVNFNodes(selected_edges))

# # print links,nodes

G=nx.DiGraph()
for x in xrange(len(nodes)):
	nd = nodes[x]
	G.add_node(nd)

for x in xrange(len(links)):
	linkpiece = links[x].split(",")
	a = linkpiece[0]
	b = linkpiece[1]
	G.add_edge(a,b)

G.add_edge("50","62")
G.add_edge("62","50")

# color_map = ["blue","blue","blue","blue","green","green","green","green","green"]
color_map = []
nx.draw(G,node_color = color_map,with_labels = True)
# # # plt.savefig("simple_path.png") # save as png
plt.show() # display

