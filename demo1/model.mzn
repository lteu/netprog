% 
%
% # Intent-based multi-domain function chain programming with Minizinc
% This script, derived from spanning tree model, deals with routing problems.
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
array[1..n_domains, 1..n_domains] of 0..M: domain_link_weights;        % distance matrix
array[1..n_domains] of 0..1: domain_activated;            % domains where lie the start and target vnf
array[1..3] of int: params;                               % service parameters



array[1..n_domains, 1..n_domains] of var 0..1: domain_link_selection;  % the resulting connection matrix
array[1..n_domains] of var 0..10: domain_outFlow;                   % out-flow array
array[1..n_domains] of var 0..2: domain_inFlow;                     % in-flow array


array[1..n_vnfs, 1..n_vnfs] of var 0..1: vnf_link_selection;  % the resulting connection matrix
array[1..n_vnfs] of var 0..10: vnf_outFlow;                   % out-flow array
array[1..n_vnfs] of var 0..1: vnf_inFlow;                    % in-flow array


% objective to minimize
var int: total_cost = sum(i in 1..n_domains, j in 1..n_domains where domain_link_weights[i,j] < M) ( domain_link_weights[i,j]* domain_link_selection[i,j] );

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------


% DOMAIN RELATED
% ------------------------------------

%
% Ensure DOMA presence
%
predicate domain_path_member(array [int] of var int: domain_inFlow, int: aDomain) =
  if aDomain != vnfs[start,VNF_DOMAIN_KEY] then
  exists ( i in index_set(domain_inFlow) ) (domain_inFlow[i]==2 /\ i = aDomain)
  else
    true
  endif;


%
% DPI
%
predicate enable_domain_dpi(array[int] of var int: domain_inFlow) =
  forall(j in 1..n_domains where domain_activated[j] = 1)(
    if exists (i in 1..n_vnfs where vnfs[i,VNF_DOMAIN_KEY] = j)
              (vnfs[i,VNF_DPI_KEY] == 1)
    then              
              domain_path_member(domain_inFlow,j)
    else 
        true
    endif
  );


% VNF RELATED
% ------------------------------------

predicate vnf_path_member(array [int] of var int: vnf_inFlow, int: aVNF) =
  exists ( i in index_set(vnf_inFlow) ) (vnf_inFlow[i]==1 /\ i = aVNF);


%
% DPI, domain contain DPIs must have a spare VNF
%
predicate enable_dpi(array[int] of var int: vnf_inFlow) =
  forall(i in 1..n_domains where domain_activated[i] == 1)(
    if exists (j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] == i)( vnfs[j,VNF_DPI_KEY] == 0)
    then
      forall(j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] == i /\ vnfs[j,VNF_DPI_KEY] == 1)(
          vnf_path_member(vnf_inFlow,j)
      )
    else
      true
    endif
  );
  

%
% test WANA FEASIBILITY, i.e., at least, S and T domains must have WANA vnf.
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

predicate enable_wana(array[int] of var int: vnf_inFlow) =
    forall(i in 1..n_domains where domain_activated[i] = 1 )(
      exists ( j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] = i /\ vnfs[j,VNF_WANA_KEY] = 1)
      (vnf_path_member(vnf_inFlow,j))
    )
;

%
% test if a vnf is relevant vnf
%
test if_relevent_vnf(1..n_vnfs: aVNF) =
  if vnfs[aVNF,VNF_DPI_KEY] == 1 \/ vnfs[aVNF,VNF_WANA_KEY] == 1 \/ aVNF = target
  then
    true
  else 
    false
  endif;

% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------


% VNF RELATED
% ------------------------------------
% no selection in inactive domain
constraint 
  forall(i,j in 1..n_vnfs where i < j) (
    if domain_activated[ vnfs[i,VNF_DOMAIN_KEY] ] == 0 then
        vnf_link_selection[i,j] = 0 /\ vnf_link_selection[j,i] = 0
     else 
        true
     endif
  );


% no selection in non-adijacent domain
constraint 
  forall(i,j in 1..n_vnfs) (
    domain_link_selection[vnfs[i,VNF_DOMAIN_KEY],vnfs[j,VNF_DOMAIN_KEY] ] == 0 /\ vnf_link_selection[i,j] = 0
    \/
    domain_link_selection[vnfs[i,VNF_DOMAIN_KEY],vnfs[j,VNF_DOMAIN_KEY] ] == 1 
  );


% domain connection only one link
constraint 
  forall(i,j in 1..n_domains where i != j) (
    sum(n,m in 1..n_vnfs where vnfs[n,VNF_DOMAIN_KEY] = i /\ vnfs[m,VNF_DOMAIN_KEY] = j) (vnf_link_selection[n,m])
    <=
    domain_link_selection[i,j]
  );

% domain self connection only necessary vnf
constraint 
  forall(n,m in 1..n_vnfs where m != n /\ vnfs[n,VNF_DOMAIN_KEY] ==  vnfs[m,VNF_DOMAIN_KEY ]) (
    if not if_relevent_vnf(m) /\ m != target then
      vnf_link_selection[n,m] = 0 
    else
      true
    endif
  );

predicate vnf_start_target_properties(array[int] of var int: vnf_inFlow, array[int] of var int: vnf_outFlow) =
  vnf_inFlow[start] = 0 /\ vnf_outFlow[start] > 0
  /\
  vnf_inFlow[target] > 0 /\ vnf_outFlow[target] = 0
;

predicate link_selection_properties(array[int,int] of var int: vnf_link_selection) =
     % no self loop
  forall(i in 1..n_vnfs) (
     vnf_link_selection[i,i] = 0
  )
  /\ % no neighbour loop
  forall(i,j in 1..n_vnfs where i < j) (
     not (vnf_link_selection[i,j] == 1 /\ vnf_link_selection[j,i] == 1)
  )

;

predicate vnf_flow_control(array[int] of var int: vnf_inFlow, array[int] of var int: vnf_outFlow) =
    % outflow definition
  forall(i in 1..n_vnfs) (
    vnf_outFlow[i] = sum(j in 1..n_vnfs) (vnf_link_selection[i,j])
  )
  /\ % inflow definition
  forall(j in 1..n_vnfs) (
    vnf_inFlow[j]  = sum(i in 1..n_vnfs) (vnf_link_selection[i,j])
  )
  /\ % generic VNF - flow through
  forall(i in 1..n_vnfs where i != start /\ i != target /\ vnfs[i,VNF_DPI_KEY] != 1 ) (
    (vnf_outFlow[i] > 0 /\ vnf_inFlow[i] > 0) \/ (vnf_outFlow[i] == 0 /\ vnf_inFlow[i] == 0)
  )
  /\ % DPI - flow terminates
  forall(i in 1..n_vnfs where vnfs[i,VNF_DPI_KEY] == 1) (vnf_outFlow[i] == 0)
;

constraint
  vnf_start_target_properties(vnf_inFlow,vnf_outFlow)
  /\
  link_selection_properties(vnf_link_selection)
  /\
  vnf_flow_control(vnf_inFlow,vnf_outFlow)
  /\
  if params[WANA_KEY] == 1 /\ can_wana() then enable_wana(vnf_inFlow) else true endif
  /\
  if params[DPI_KEY] == 1 then enable_dpi(vnf_inFlow) else true endif
;



% dominio RELATED
% ------------------------------------

% no selection in inactive domain
constraint 
  forall(i,j in 1..n_domains where i < j) (
    if domain_activated[ i ] == 0 then
        domain_link_selection[i,j] = 0 /\ domain_link_selection[j,i] = 0
     else 
        true
     endif
  );


predicate start_target_properties(array[int] of var int: domain_inFlow, array[int] of var int: domain_outFlow) =
  domain_inFlow[vnfs[start,VNF_DOMAIN_KEY]] = 1 
  /\ 
  domain_outFlow[vnfs[start,VNF_DOMAIN_KEY]] > 0
  /\
  domain_inFlow[vnfs[target,VNF_DOMAIN_KEY]] = 2 
  /\ 
  domain_outFlow[vnfs[target,VNF_DOMAIN_KEY]] = 1
;

predicate domain_link_selection_properties(array[int,int] of var int: domain_link_selection) =
     % no self loop
  forall(i in 1..n_domains) (
     domain_link_selection[i,i] = 1
  )
  /\ % no neighbour loop
  forall(i,j in 1..n_domains where i < j) (
     not (domain_link_selection[i,j] == 1 /\ domain_link_selection[j,i] == 1)
  )
  /\ % no domain_link_selection if no connection (M)
  forall(i,j in 1..n_domains) (
     if domain_link_weights[i,j] == M then
        domain_link_selection[i,j] = 0
     else 
        true
     endif
  )
  /\ % assert that all x values is >= 0
  forall(i in 1..n_domains, j in 1..n_domains where domain_link_weights[i,j] < M) (
         domain_link_selection[i,j] >= 0
  ) 
;

predicate flow_control(array[int] of var int: domain_inFlow, array[int] of var int: domain_outFlow) =
    % domain_outFlow definition
  forall(i in 1..n_domains) (
    domain_outFlow[i] = sum(j in 1..n_domains where domain_link_weights[i,j] < M) (domain_link_selection[i,j])
  )
  /\ % domain_inFlow definition
  forall(j in 1..n_domains) (
    domain_inFlow[j]  = sum(i in 1..n_domains where domain_link_weights[i,j] < M) (domain_link_selection[i,j])
  )
  /\ % DPI - flow terminates
  forall(i in 1..n_domains where i != vnfs[start,VNF_DOMAIN_KEY] /\ i != vnfs[target,VNF_DOMAIN_KEY]) (
    (domain_outFlow[i] > 1 /\ domain_inFlow[i] > 1) \/ (domain_outFlow[i] == 1 /\ domain_inFlow[i] >= 1)
  )
  % /\ % generic VNF - flow through
  % forall(i in 1..n_vnfs where i != start /\ i != target /\ vnfs[i,VNF_DPI_KEY] != 1 ) (
  %   (domain_outFlow[i] > 0 /\ domain_inFlow[i] > 0) \/ (domain_outFlow[i] == 0 /\ domain_inFlow[i] == 0)
  % )
  % /\ % DPI - flow terminates
  % forall(i in 1..n_vnfs where vnfs[i,VNF_DPI_KEY] == 1) (domain_outFlow[i] == 0)
;

constraint
  start_target_properties(domain_inFlow,domain_outFlow)
  /\
  domain_link_selection_properties(domain_link_selection)
  /\
  flow_control(domain_inFlow,domain_outFlow)
  % /\
  % if params[WANA_KEY] == 1 /\ can_wana() then enable_wana(domain_inFlow) else true endif
  /\
  if params[DPI_KEY] == 1 then enable_domain_dpi(domain_inFlow) else true endif
;

% solve minimize total_cost;
% alternative solve statement
solve :: int_search([domain_link_selection[i,j] | i,j in 1..n_domains], first_fail, indomain, complete) minimize total_cost;


output[ show(domain_inFlow), show(domain_outFlow), show(domain_link_selection)];

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