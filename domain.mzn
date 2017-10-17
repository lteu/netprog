% 
% tentative routing without domain connection
%
% # Intent-based network programming with Minizinc
% This script, derived from spanning tree model, deals with SDN routing problems.
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

int: n_vnfs;      % number of nodes in the matrix
int: start;       % start node
int: target;      % end node
int: M;           % edge cost's upper bound
int: n_domains;   % num of domains

array[1..n_vnfs, 1..8] of int: vnfs;                      % vnf nodes
array[1..n_vnfs, 1..n_vnfs] of 0..M: link_weights;        % distance matrix
array[1..n_domains] of 0..1: domain_activated;            % domains where lie the start and target vnf
array[1..3] of int: params;                               % service parameters

array[1..n_vnfs, 1..n_vnfs] of var 0..1: link_selection;  % the resulting connection matrix
array[1..n_vnfs] of var 0..10: outFlow;                   % out-flow array
array[1..n_vnfs] of var 0..1: inFlow;                    % in-flow array

% objective to minimize
var int: total_cost = sum(i in 1..n_vnfs, j in 1..n_vnfs where link_weights[i,j] < M) ( link_weights[i,j]* link_selection[i,j] );

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------

%
% Ensure VNF presence
%
predicate path_member(array [int] of var int: inFlow, int: aVNF) =
  exists ( i in index_set(inFlow) ) (inFlow[i]==1 /\ i = aVNF);

%
% DPI
%
predicate enable_dpi(array[int] of var int: inFlow) =
  forall(j in 1..n_vnfs where domain_activated[vnfs[j,VNF_DOMAIN_KEY]] = 1 /\ vnfs[j,VNF_DPI_KEY] = 1)(
    path_member(inFlow,j)
  );

%
% WANA
%
test can_wana() =
  if 
  exists (i in 1..n_vnfs % same domain of START
    where vnfs[i,VNF_DOMAIN_KEY] = vnfs[start,VNF_DOMAIN_KEY] /\ domain_activated[vnfs[i,VNF_DOMAIN_KEY]] = 1)
    ( vnfs[i,VNF_WANA_KEY] = 1)
  /\
  exists (i in 1..n_vnfs % different domain of START
    where vnfs[i,VNF_DOMAIN_KEY] != vnfs[start,VNF_DOMAIN_KEY] /\ domain_activated[vnfs[i,VNF_DOMAIN_KEY]] = 1)
    ( vnfs[i,VNF_WANA_KEY] = 1)
  then
    true
  else 
    false
  endif;

predicate enable_wana(array[int] of var int: inFlow) =
    forall(i in 1..n_domains where domain_activated[i] = 1 )(
      exists ( j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] = i /\ vnfs[j,VNF_WANA_KEY] = 1)
      (path_member(inFlow,j))
    )
;


% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------

constraint 
  forall(i,j in 1..n_vnfs where i < j) (
    if domain_activated[ vnfs[i,VNF_DOMAIN_KEY] ] == 0 then
        link_selection[i,j] = 0 /\ link_selection[j,i] = 0
     else 
        true
     endif
  );


predicate start_target_properties(array[int] of var int: inFlow, array[int] of var int: outFlow) =
  inFlow[start] = 0 /\ outFlow[start] > 0
  /\
  inFlow[target] > 0 /\ outFlow[target] = 0
;

predicate link_selection_properties(array[int,int] of var int: link_selection) =
     % no self loop
  forall(i in 1..n_vnfs) (
     link_selection[i,i] = 0
  )
  /\ % no neighbour loop
  forall(i,j in 1..n_vnfs where i < j) (
     not (link_selection[i,j] == 1 /\ link_selection[j,i] == 1)
  )
  /\ % no link_selection if no connection (M)
  forall(i,j in 1..n_vnfs) (
     if link_weights[i,j] == M then
        link_selection[i,j] = 0
     else 
        true
     endif
  )
  /\ % assert that all x values is >= 0
  forall(i in 1..n_vnfs, j in 1..n_vnfs where link_weights[i,j] < M) (
         link_selection[i,j] >= 0
  ) 
;

predicate flow_control(array[int] of var int: inFlow, array[int] of var int: outFlow) =
    % outflow definition
  forall(i in 1..n_vnfs) (
    outFlow[i] = sum(j in 1..n_vnfs where link_weights[i,j] < M) (link_selection[i,j])
  )
  /\ % inflow definition
  forall(j in 1..n_vnfs) (
    inFlow[j]  = sum(i in 1..n_vnfs where link_weights[i,j] < M) (link_selection[i,j])
  )
  /\ % generic VNF - flow through
  forall(i in 1..n_vnfs where i != start /\ i != target /\ vnfs[i,VNF_DPI_KEY] != 1 ) (
    (outFlow[i] > 0 /\ inFlow[i] > 0) \/ (outFlow[i] == 0 /\ inFlow[i] == 0)
  )
  /\ % DPI - flow terminates
  forall(i in 1..n_vnfs where vnfs[i,VNF_DPI_KEY] == 1) (outFlow[i] == 0)
;

constraint
  start_target_properties(inFlow,outFlow)
  /\
  link_selection_properties(link_selection)
  /\
  flow_control(inFlow,outFlow)
  /\
  if params[WANA_KEY] == 1 /\ can_wana() then enable_wana(inFlow) else true endif
  /\
  if params[DPI_KEY] == 1 then enable_dpi(inFlow) else true endif
;

% solve minimize total_cost;
% alternative solve statement
solve :: int_search([link_selection[i,j] | i,j in 1..n_vnfs], first_fail, indomain, complete) minimize total_cost;


output[ show(inFlow), show(outFlow), show(link_selection)];

%
%  instance dataset
%

% n_vnfs = 10;     % number of nodes in the matrix
% start = 1; % start node
% target = 10;   % end node
% M = 9;     % TOP cost

% link_weights = array2d(1..n_vnfs, 1..n_vnfs, [
%           0, 1, 1, 3, 3, 3, 4, 4, 4, 4, % 1
%           1, 0, 1, 3, 3, 3, 4, 4, 4, 4, % 2
%           1, 1, 0, 3, 3, 3, 4, 4, 4, 4, % 3
%           3, 3, 3, 0, 1, 1, 3, 3, 3, 3, % 4
%           3, 3, 3, 1, 0, 1, 3, 3, 3, 3, % 5
%           3, 3, 3, 1, 1, 0, 3, 3, 3, 3, % 6
%           4, 4, 4, 3, 3, 3, 0, 1, 1, 1, % 7
%           4, 4, 4, 3, 3, 3, 1, 0, 1, 1, % 8
%           4, 4, 4, 3, 3, 3, 1, 1, 0, 1, % 9
%           4, 4, 4, 3, 3, 3, 1, 1, 1, 0  % 10
%           ]);

% % % 1:dpi, 2:wanna, 3:shaper
% params =  [1,1,0];
% n_domains = 3;
% domain_activated = [
%               1,
%               0,
%               1
%               ];

% % 1 ID(nat), 2 Type(nat), 3 Terminating(bool, DPI), 4 Path Sense(bool), 
% % 5 Mirrored(bool, WANA), 6 Weight(Nat), 7 Active(bool), 8 domain_id
% vnfs =  array2d(1..n_vnfs, 1..8, [
%        1, 3, 0, 0, 0, 0, 1, 1,
%        2, 7, 0, 1, 1, 1, 1, 1,
%        3, 6, 0, 0, 0, 2, 1, 1,
%        4, 7, 0, 1, 1, 1, 1, 2,
%        5, 5, 1, 0, 0, 1, 1, 2,
%        6, 5, 1, 0, 0, 2, 1, 2,
%        7, 7, 0, 1, 1, 1, 1, 3,
%        8, 5, 1, 0, 0, 2, 1, 3,
%        9, 6, 0, 0, 0, 1, 1, 3,
%       10, 3, 0, 0, 0, 0, 1, 3
% ]);