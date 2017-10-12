% 
% # Intent-based network programming with Minizinc
% This model, derived from spanning tree model, deals with SDN routing problems.
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
% Credits: Hakank - shortest path model with adjacency matrix
% https://raw.githubusercontent.com/hakank/hakank/master/minizinc/shortest_path_model.mzn
%

include "in_params.mzn"; 


int: n;     % number of nodes in the matrix
int: start; % start node
int: target;   % end node
int: M;     % edge cost's upper bound



array[1..n, 1..n] of 0..M: d; % distance matrix

% objective to minimize
var int: total_cost = sum(i in 1..n, j in 1..n where d[i,j] < M) ( d[i,j]*x[i,j] );

array[1..n, 1..n] of var 0..1: x; % the resulting connection matrix
array[1..n] of var 0..10: outFlow; % out flow array
array[1..n] of var 0..10: inFlow;  % in flow array
array[1..n] of var -1..1: rhs;  % indicating start/end nodes

int:num_domains;
array[1..n, 1..8] of int: vnfs;                    % vnf nodes
array[1..num_domains] of 0..1: domain_activated;          % domains where lie the start and target vnf
array[1..3] of int: params;    

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------

%
% ensure that a VNF is presented in the path
%
predicate path_member(array [int] of var int: inFlow, int: aVNF) =
  exists ( i in index_set(inFlow) ) (inFlow[i]==1 /\ i = aVNF);


%
% DPI
%
% constraint 
%  path_member(inFlow,3);
constraint
  if params[DPI_KEY] = 1 then
    forall(j in 1..n where domain_activated[vnfs[j,VNF_DOMAIN_KEY]] = 1 /\ vnfs[j,VNF_DPI_KEY] = 1)(
      path_member(inFlow,j)
    )
  else
    true
  endif;

%
% WANA check and 
%
constraint
  if sum(i in 1..num_domains where domain_activated[i] = 1) (
    if exists (j in 1..n where vnfs[j,VNF_DOMAIN_KEY] = i)( vnfs[j,VNF_WANA_KEY] = 1)then 
      1 
    else 
      0 
    endif
  ) = 2 /\ params[WANA_KEY] = 1 then
    forall(i in 1..num_domains where domain_activated[i] = 1 )(
      exists ( j in 1..n where vnfs[j,VNF_DOMAIN_KEY] = i /\ vnfs[j,VNF_WANA_KEY] = 1)
      (path_member(inFlow,j))
    )
  else 
      true
  endif;


% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------


constraint 
     % set rhs for start/end nodes
     forall(i in 1..n) ( 
       if i = start then 
         rhs[i] = 1
       elseif i = target then 
         rhs[i] = -1
       else  
         rhs[i] = 0
       endif
    )
    /\ % assert that all x values is >= 0
   forall(i in 1..n, j in 1..n where d[i,j] < M) (
         x[i,j] >= 0
   ) 
   /\ % calculate out flow
   forall(i in 1..n) (
      outFlow[i] = sum(j in 1..n where d[i,j] < M) (x[i,j])
   )
   /\ % calculate in flow
  forall(j in 1..n) (
    inFlow[j]  = sum(i in 1..n where d[i,j] < M) (x[i,j])
  )
  /\ % outflow = inflow
  forall(i in 1..n where i = start \/ i = target) (outFlow[i] - inFlow[i] = rhs[i])
  /\ % outflow = inflow
  forall(i in 1..n where i != start /\ i != target /\ vnfs[i,VNF_DPI_KEY] != 1 ) ((outFlow[i] > 0 /\ inFlow[i] > 0)\/ 
    (outFlow[i] == 0 /\ inFlow[i] == 0))
  /\ % outflow = inflow
  forall(i in 1..n where vnfs[i,VNF_DPI_KEY] == 1) (outFlow[i] == 0)
  /\
  forall(i,j in 1..n where i < j) (
     not (x[i,j] == 1 /\ x[j,i] == 1)
  )
  /\ % do not loops
  forall(i in 1..n) (
     x[i,i] = 0
  )
  /\ % sanity: there can be no connection in x if there is not
     % connection in d
  forall(i,j in 1..n) (
     if d[i,j] = M then
        x[i,j] = 0
     else 
        true
     endif
  )
   
;

% solve satisfy;
solve minimize total_cost;
% alternative solve statement
% solve :: int_search([ x[i,j] | i,j in 1..n], "first_fail", "indomain", "complete") minimize total_cost;

output[ show(inFlow), show(outFlow)];

% output [ show(x[i,j]) ++ " " ++
% if i == n then "\n" else "" endif | i,j in 1..n ];


% output [
%     show([x[i,j] | i,j in 1..n])
%   ];


output [

    "\([x[i,i] | i in 1..n])\n"
  ];

% output [
%     "z: \(z)\n",
%     "x: \(x)  values:\([diffs[i,x[i]] | i in 1..m])\n"
%   ];
% dataset


n = 10;     % number of nodes in the matrix
start = 1; % start node
target = 10;   % end node
M = 9;     % TOP cost

d = array2d(1..n, 1..n, [
          0, 1, 1, 3, 3, 3, 4, 4, 4, 4, % 1
          1, 0, 1, 3, 3, 3, 4, 4, 4, 4, % 2
          1, 1, 0, 3, 3, 3, 4, 4, 4, 4, % 3
          3, 3, 3, 0, 1, 1, 3, 3, 3, 3, % 4
          3, 3, 3, 1, 0, 1, 3, 3, 3, 3, % 5
          3, 3, 3, 1, 1, 0, 3, 3, 3, 3, % 6
          4, 4, 4, 3, 3, 3, 0, 1, 1, 1, % 7
          4, 4, 4, 3, 3, 3, 1, 0, 1, 1, % 8
          4, 4, 4, 3, 3, 3, 1, 1, 0, 1, % 9
          4, 4, 4, 3, 3, 3, 1, 1, 1, 0  % 10
          ]);

% % 1:dpi, 2:wanna, 3:shaper
params =  [1,1,0];
num_domains = 3;
domain_activated = [
              1,
              0,
              1
              ];

% 1 ID(nat), 2 Type(nat), 3 Terminating(bool, DPI), 4 Path Sense(bool), 
% 5 Mirrored(bool, WANA), 6 Weight(Nat), 7 Active(bool), 8 domain_id
vnfs =  array2d(1..n, 1..8, [
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