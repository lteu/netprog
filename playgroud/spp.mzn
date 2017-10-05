% REF. https://github.com/hakank/hakank/blob/master/minizinc/spp.mzn
%
% Given a directed graph G = (V,E), its edge weight weight(i,j) for all
% (i,j) in E, and two nodes s, t in V, the Shortest Path Problem (SPP)
% is to find a directed path from s to t whose length is minimal. */
%
% 
% command:
% minizinc-2.1.2/bin/mzn2fzn -I solver-chuffed/mznlib net.mzn -o xxx.fzn
% solver-chuffed/bin/solve xxx.fzn
%

int: n; % number of nodes > 0
int: m; % number of edges 

% weight[i,j] is weight of edge (i,j); note that edge lengths are allowed
%   to be of any sign (positive, negative, or zero)
array[1..m] of int: weight;
array[1..m, 1..2] of 1..n: edge; 

% source node 
1..n: s;

% target node 
1..n: t;

% edge_selection[i,j] = 1 means that edge (i,j) belong to shortest path;
% edge_selection[i,j] = 0 means that edge (i,j) does not belong to shortest path;
array[1..m] of var 0..1: edge_selection;


% conservation conditions for unity flow from s to t; every feasible, solution is a path from s to t
constraint 
  forall(i in 1..n) (
         sum(k in 1..m where edge[k,2] = i) (edge_selection[k]) + (if i = s then 1 else 0 endif)
    = 
         sum(k in 1..m where edge[k,1] = i) (edge_selection[k]) + (if i = t then 1 else 0 endif)
  )
;

% Tong: eunsure that a node is present in result path
predicate path_member(array [int] of var int: x, array [int,int] of var int: edge, int: y) =
  exists ( i in index_set(x) ) (x[i]==1 /\ (edge[i,1]==y \/ edge[i,2]==y) );


% Tong: example, an edge 2->4 must be included. 
% constraint edge_selection[4] = 1;

% Tong: example, a node must be included in the path.
constraint path_member(edge_selection,edge,4);

% cost definition (path cost)
var int: cost = sum(i in 1..m) (weight[i] * edge_selection[i]);

solve minimize cost;


%
% data
%
% """
% Optimal solution is 20 that corresponds to the following shortest
% 
% path: s = 1 -> 2 -> 4 -> 8 -> 6 = t
% """
% I.e. edge [1, 4, 11, 14] is the shortest path
% 
n = 8;
s = 1;
t = 6;
m = 15;
edge = array2d(1..m, 1..2, [
       1, 2, % 1  *
       1, 4, % 2 
       1, 7, % 3
       2, 4, % 4  *
       3, 2, % 5
       3, 4, % 6
       3, 5, % 7
       3, 6, % 8
       4, 5, % 9
       4, 8, % 10 *
       5, 8, % 11
       6, 5, % 12
       7, 4, % 13
       8, 6, % 14 *
       8, 7  % 15
]);
weight = [1, 8, 6, 2, 14, 10, 6, 19, 8, 13, 12, 7, 5, 4, 10];
output
[
  "edge seletion: " ++ show(edge_selection) ++ "\n" ++
  "cost: " ++ show(cost) ++ "\n" 
];