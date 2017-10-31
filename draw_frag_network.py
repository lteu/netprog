# Used for link-list based version
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

def getVNFinfo(raw):
	pieces = raw.strip().split("|") 
	tuples = pieces[1:-1]
	return [item.split(",") for item in tuples]

def getVNFNodes(list_of_links):
	nodes_dup = [item.split(",")  for item in list_of_links]
	# flat_list = [item for sublist in nodes_dup]
	return set(reduce(operator.concat, nodes_dup))

def assignColorByType(vnf):
	return {
        'a': 1,
        'b': 2,
    }[x]

testFile = "rlt.txt"

with open(testFile, 'r') as content_file:
    content = content_file.read()


link_selection = []
vnf_info = []
vnf_links = []
low = 0
hight = 0
VNF_DOMAIN_KEY = 7


color =	{
		'0': "red",
        '1': "grey",
        '2': "blue",
        '3': "yellow",
        '4': "green"
}
# color_set = ["red","grey","orange","yellow","green","blue","pink","purple"]
color_set = ["red","grey","orange","green","blue","pink","purple"]
pieces = content.strip().split(";")      
for piece in pieces:
	if 'link_selection' in piece.lower():
		link_selection,low,high = getRangeAndArray(piece)
	if 'vnf_links' in piece.lower():
		vnf_links = getVNFlinks(piece)
	if 'vnfs' in piece.lower():
		vnf_info = getVNFinfo(piece)

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

# nodes color
color_map_node = []
color_map_edge = []
if vnf_info:
	for nd in G:
		vnf_type = vnf_info[int(nd)-1][1]
		vnf_color = color[vnf_type]
		color_map_node.append(vnf_color)
		print nd, vnf_color, vnf_info[int(nd)-1]

	for lk in G.edges():
		print lk, lk[0],lk[1]
		print vnf_info[int(lk[0])-1],vnf_info[int(lk[1])-1]
		domain1 = vnf_info[int(lk[0])-1][VNF_DOMAIN_KEY]
		domain2 = vnf_info[int(lk[1])-1][VNF_DOMAIN_KEY]
		if domain1 == domain2:
			color_map_edge.append(color_set[int(domain1)%len(color_set)])
		else:
			color_map_edge.append("black")


# color_map_edge = []
nx.draw(G,node_color = color_map_node, edge_color=color_map_edge, with_labels = True)
# # # plt.savefig("simple_path.png") # save as png
plt.show() # display

