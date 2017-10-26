# 
#
#
# ref about color: https://stackoverflow.com/questions/27030473/how-to-set-colors-for-nodes-in-networkx-python
# ref network: https://www.python-course.eu/networkx.php

import networkx as nx
import matplotlib.pyplot as plt
import numpy as np


def getRangeAndArray(raw):
	pieces = raw.strip().split("(")    
	range1 = pieces[1].split(",")[0]  
	low  = int(range1.split("..")[0])
	high  = int(range1.split("..")[1])

	tmp1 = pieces[1].split("[")[1] 
	tmp2 = tmp1.split("]")[0]  
	arr = tmp2.split(",")
	arr = [int(x) for x in arr]
	arraynp = np.array(arr)
	shaped = np.reshape(arraynp, (high, high))
	shaped = shaped.tolist()
	# print shaped 
	return shaped,low,high

def adjListToEdge(link_selection):
	links = []
	nodes = []
	for x in xrange(len(link_selection)):
		for y in xrange(len(link_selection)):
			if link_selection[x][y] == 1:
				links.append([x+1,y+1])
				nodes.append(x+1)
				nodes.append(y+1)
	return links, list(set(nodes))


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
		
links,nodes = adjListToEdge(link_selection)
# print links,nodes
# G=nx.Graph()

G=nx.DiGraph()
for x in xrange(len(nodes)):
	G.add_node(int(nodes[x]))

for x in xrange(len(links)):
	G.add_edge(int(links[x][0]),int(links[x][1]))

# color_map = ["blue","blue","blue","blue","green","green","green","green","green"]
color_map = []
nx.draw(G,node_color = color_map,with_labels = True,arrows=True)
plt.show() # display


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

# G=nx.Graph()
# G.add_node("a")
# G.add_nodes_from(["b","c"])

# G.add_edge(1,2)
# edge = ("d", "e")
# G.add_edge(*edge)
# edge = ("a", "b")
# G.add_edge(*edge)
# G.add_edge(1,3)
# G[1][3]['color']='blue'
# # G["d"]['color']='blue'
# print("Nodes of graph: ")
# print(G.nodes())
# print("Edges of graph: ")
# print(G.edges())

# color_map = ["blue","blue","blue","blue","green","green","green","green","green"]
# nx.draw(G,node_color = color_map,with_labels = True)
# # plt.savefig("simple_path.png") # save as png
# plt.show() # display