% 
% # Intent-based network programming with Minizinc
% This model deals with SDN routing problems with Constraint Programming
% 
% Authors: 
%
% Tong Liu:             t.liu [at] unibo.it
% Maurizio Gabbrielli:  maurizio.gabbrielli [at] unibo.it
%
% References:
%
% Cerroni,et al. "Intent-based management and orchestration of heterogeneous openflow/IoT SDN domains." 
% Network Softwarization (NetSoft), 2017 IEEE Conference on. IEEE, 2017.
% 
% Credits: Hakank
% https://github.com/hakank/hakank/blob/master/minizinc/shortest_path_graph.mzn
%

% include "globals.mzn"; 
include "in_params.mzn"; 

int: num_vnf_links;
int: num_vnfs;
int: num_domains;
int: num_vnftypes;


array[1..num_vnftypes] of int: vnf_types; 
array[1..num_vnf_links, 1..2] of 1..num_vnfs: vnf_links;  % edges
array[1..num_vnf_links] of int: vnf_link_weight;          % edge weight
array[1..num_vnfs, 1..8] of int: vnfs;                    % vnf nodes
array[1..num_domains] of 0..1: domain_activated;          % domains where lie the start and target vnf
array[1..3] of int: params;                               % config. params (WANA, SHAPER, DPI ...)

int: start;
int: target;

% decision variables
array[1..num_vnfs] of var 0..num_vnfs: vnf_order; % resulting vnf path 
array[1..num_vnfs] of var 0..10000: vnf_rcost;    % cost to reach i-th vnf from its neighbour

var int: cost; 
constraint cost = sum(i in 1..num_vnfs)( vnf_rcost[i] );


% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------

%
% ensure that a VNF is presented in the path
%
predicate path_member(array [int] of var int: vnf_order, int: aVNF) =
  exists ( i in index_set(vnf_order) ) (vnf_order[i]==aVNF);

%
% DPI
%
constraint
  if params[DPI_KEY] = 1 then
    forall(j in 1..num_vnfs where domain_activated[vnfs[j,VNF_DOMAIN_KEY]] = 1 /\ vnfs[j,VNF_DPI_KEY] = 1)(
      path_member(vnf_order,j)
    )
  else
    true
  endif;

%
% WANA check and 
%
constraint
  if sum(i in 1..num_domains where domain_activated[i] = 1) (
    if exists (j in 1..num_vnfs where vnfs[j,VNF_DOMAIN_KEY] = i)( vnfs[j,VNF_WANA_KEY] = 1)then 
      1 
    else 
      0 
    endif
  ) = 2 /\ params[WANA_KEY] = 1 then
    forall(i in 1..num_domains where domain_activated[i] = 1 )(
      exists ( j in 1..num_vnfs where vnfs[j,VNF_DOMAIN_KEY] = i /\ vnfs[j,VNF_WANA_KEY] = 1)
      (path_member(vnf_order,j))
    )
  else 
      true
  endif;

% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------

%
% in vnf_order, "target" is the last element which is > 0, all after "target" are 0.
%
predicate last_not_0(array[int] of var int: vnf_order, var int: y) =
   exists(i in 2..length(vnf_order)) (
      vnf_order[i] = y
      /\
      forall(j in i+1..num_vnfs) (vnf_order[j] = 0)
      /\ % all elements in x before y are > 0
      forall(j in 1..i) (vnf_order[j] > 0)
   )
;


% 
% in vnf_order, all values are different or 0
% (note: more efficient than built-in alldifferent_except_0)
% 
predicate all_different_except_0(array[int] of var int: vnf_order) =
  let {
      int: n = length(vnf_order)
   }
   in
   forall(i,j in 1..n where i < j) (
        (vnf_order[i] > 0 /\ vnf_order[j] > 0) -> vnf_order[i] != vnf_order[j]
   )
;


%
% in vnf_order, all values are > 0 or 0
% when > 0, link and weight are identified.
%
predicate all_paths(array[int] of var int: vnf_order, 
                    array[int, 1..2] of var int: vnf_links) =
   forall(i in 2..length(vnf_order)) (
     (vnf_order[i] = 0 /\ vnf_rcost[i] = 0)
     \/
     (
       vnf_order[i] > 0
       /\
       vnf_order[i-1] > 0
       /\
       exists(j in index_set_1of2(vnf_links)) (
         ( vnf_links[j,1] = vnf_order[i-1] /\ vnf_links[j,2] =vnf_order[i] /\ vnf_rcost[i] = vnf_link_weight[j]  )
         \/
         ( vnf_links[j,1] = vnf_order[i]   /\ vnf_links[j,2] = vnf_order[i-1] /\ vnf_rcost[i] = vnf_link_weight[j])
       )
     )
   )
;

constraint
    all_different_except_0(vnf_order)
    /\
    vnf_order[1] = start
    /\
    last_not_0(vnf_order, target)
    /\
    all_paths(vnf_order, vnf_links)
;


solve :: int_search(vnf_order, first_fail, indomain, complete) minimize cost;
% solve minimize cost;


output [
show(vnf_order),
show(cost)
  % "cost: \(cost)\n: x: \([x[i] | i in 1..n where fix(x[i]) > 0])\n"
];


% -------------------------------------------------
%       Problem Instance
% -------------------------------------------------

num_vnfs = 10;
num_vnf_links = 90;
start = 1;
target = 10;

num_domains = 3;
num_vnftypes = 10;

% % 1:dpi, 2:wanna, 3:shaper
params =  [1,1,0];

domain_activated = [
              1,
              0,
              1
              ];

% 1 ID(nat), 2 Type(nat), 3 Terminating(bool, DPI), 4 Path Sense(bool), 
% 5 Mirrored(bool, WANA), 6 Weight(Nat), 7 Active(bool), 8 domain_id
vnfs =  array2d(1..num_vnfs, 1..8, [
       1, 3, 0, 0, 0, 0, 1, 1,
       2, 7, 0, 1, 1, 1, 1, 1,
       3, 6, 0, 0, 0, 2, 1, 1,
       4, 7, 0, 1, 1, 1, 1, 2,
       5, 5, 1, 0, 0, 1, 1, 2,
       6, 5, 1, 0, 0, 2, 1, 2,
       7, 7, 0, 1, 1, 1, 1, 3,
       8, 5, 1, 0, 0, 2, 1, 3,
       9, 6, 0, 0, 0, 1, 1, 3,
      10, 3, 0, 0, 0, 0, 1, 3
]);

vnf_types =  [
              1, % black
              2, % brown
              3, % red
              4, % orange
              5, % yellow
              6, % green
              7, % blue
              8, % purple
              9, % gray
              10 % white
              ];


vnf_links = array2d(1..num_vnf_links, 1..2, [
       1, 2, % 1 
       1, 3, % 2
       1, 4, % 3  
       1, 5, % 4
       1, 6, % 5
       1, 7, % 6
       1, 8, % 7
       1, 9, % 8
       1, 10, % 9
       2, 1, % 1 
       2, 3, % 2
       2, 4, % 3 
       2, 5, % 4
       2, 6, % 5
       2, 7, % 6
       2, 8, % 7
       2, 9, % 8
       2, 10, % 9
       3, 1, % 1 
       3, 2, % 2
       3, 4, % 3 
       3, 5, % 4
       3, 6, % 5
       3, 7, % 6
       3, 8, % 7
       3, 9, % 8
       3, 10, % 9
       4, 1, % 1 
       4, 2, % 2
       4, 3, % 3 
       4, 5, % 4
       4, 6, % 5
       4, 7, % 6
       4, 8, % 7
       4, 9, % 8
       4, 10, % 9
       5, 1, % 1 
       5, 2, % 2
       5, 3,
       5, 4, % 3 
       5, 6, % 5
       5, 7, % 6
       5, 8, % 7
       5, 9, % 8
       5, 10, % 9
       6, 1, % 1
       6, 2, 
       6, 3, % 2
       6, 4, % 3 
       6, 5, % 4
       6, 7, % 6
       6, 8, % 7
       6, 9, % 8
       6, 10, % 9
       7, 1, % 1 
       7, 2,
       7, 3, % 2
       7, 4, % 3 
       7, 5, % 4
       7, 6, % 5
       7, 8, % 7
       7, 9, % 8
       7, 10, % 9
       8, 1, % 1 
       8, 2, % 2
       8, 3, % 3 
       8, 4,
       8, 5, % 4
       8, 6, % 5
       8, 7, % 6
       8, 9, % 8
       8, 10, % 9
       9, 1, % 1
       9, 2, 
       9, 3, % 2
       9, 4, % 3 
       9, 5, % 4
       9, 6, % 5
       9, 7, % 6
       9, 8, % 7
       9, 10, % 9
      10, 1, % 1 
      10, 2,
      10, 3, % 2
      10, 4, % 3 
      10, 5, % 4
      10, 6, % 5
      10, 7, % 6
      10, 8, % 7
      10, 9
]);

% vnf_link_weight = [0, 0, 2, 2, 2, 3, 3, 3, 3, % 1
%           0, 0, 2, 2, 2, 3, 3, 3, 3, % 2
%           0, 0, 2, 2, 2, 3, 3, 3, 3, % 3
%           2, 2, 2, 0, 0, 2, 2, 2, 2, % 4
%           2, 2, 2, 0, 0, 2, 2, 2, 2, % 5
%           2, 2, 2, 0, 0, 2, 2, 2, 2, % 6
%           3, 3, 3, 2, 2, 2, 0, 0, 0, % 7
%           3, 3, 3, 2, 2, 2, 0, 0, 0, % 8
%           3, 3, 3, 2, 2, 2, 0, 0, 0, % 9
%           3, 3, 3, 2, 2, 2, 0, 0, 0  % 10
%           ];


vnf_link_weight = [1, 1, 3, 3, 3, 4, 4, 4, 4, % 1
          1, 1, 3, 3, 3, 4, 4, 4, 4, % 2
          1, 1, 3, 3, 3, 4, 4, 4, 4, % 3
          3, 3, 3, 1, 1, 3, 3, 3, 3, % 4
          3, 3, 3, 1, 1, 3, 3, 3, 3, % 5
          3, 3, 3, 1, 1, 3, 3, 3, 3, % 6
          4, 4, 4, 3, 3, 3, 1, 1, 1, % 7
          4, 4, 4, 3, 3, 3, 1, 1, 1, % 8
          4, 4, 4, 3, 3, 3, 1, 1, 1, % 9
          4, 4, 4, 3, 3, 3, 1, 1, 1  % 10
          ];