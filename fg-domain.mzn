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



array[1..n_domains] of var 0..10: outFlow;                   % out-flow array
array[1..n_domains] of var 0..2: inFlow;                     % in-flow array
array[1..n_domains, 1..n_domains] of var 0..1: domain_link_selection;  % the resulting connection matrix

% objective to minimize
var int: total_cost = sum(i in 1..n_domains, j in 1..n_domains where domain_link_weights[i,j] < M) ( domain_link_weights[i,j]* domain_link_selection[i,j] );

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------


%
% Ensure VNF presence
%
predicate path_member(array [int] of var int: inFlow, int: aDomain) =
  if aDomain != vnfs[start,VNF_DOMAIN_KEY] then
  exists ( i in index_set(inFlow) ) (inFlow[i]==2 /\ i = aDomain)
  else
    true
  endif;


%
% DPI
%
predicate enable_dpi(array[int] of var int: inFlow) =
  forall(j in 1..n_domains where domain_activated[j] = 1 /\ domain_req_dpi[j] > 0)(
    if exists (i in 1..n_vnfs where vnfs[i,VNF_DOMAIN_KEY] = j)
              (vnfs[i,VNF_TYPE] == DPI)
    then              
              path_member(inFlow,j)
    else 
        true
    endif
  );

%
% WANA
%
test can_wana_strict() =
  if 
  exists (i in 1..n_vnfs % same domain of START
    where vnfs[i,VNF_DOMAIN_KEY] = vnfs[start,VNF_DOMAIN_KEY] /\ domain_activated[vnfs[i,VNF_DOMAIN_KEY]] = 1)
    ( vnfs[i,VNF_TYPE] = WANA)
  /\
  exists (i in 1..n_vnfs % different domain of START
    where vnfs[i,VNF_DOMAIN_KEY] != vnfs[start,VNF_DOMAIN_KEY] /\ domain_activated[vnfs[i,VNF_DOMAIN_KEY]] = 1)
    ( vnfs[i,VNF_TYPE] = WANA)
  then
    true
  else 
    false
  endif;

test can_wana_relax() =
  if 
  exists (i,j in 1..n_vnfs where 
    i<j 
    /\ vnfs[i,VNF_DOMAIN_KEY] != vnfs[j,VNF_DOMAIN_KEY] 
    /\ domain_activated[vnfs[i,VNF_DOMAIN_KEY]] = 1
    /\ domain_activated[vnfs[j,VNF_DOMAIN_KEY]] = 1)
    ( vnfs[i,VNF_TYPE] = WANA /\ vnfs[j,VNF_TYPE] = WANA )
  then
    true
  else 
    false
  endif;


predicate enable_wana(array[int] of var int: inFlow) =
    % exists (i,j in 1..n_vnfs where 
    % i<j 
    % /\ vnfs[i,VNF_TYPE] = WANA /\ vnfs[j,VNF_TYPE] = WANA
    % /\ vnfs[i,VNF_DOMAIN_KEY] != vnfs[j,VNF_DOMAIN_KEY] 
    % /\ domain_activated[vnfs[i,VNF_DOMAIN_KEY]] = 1
    % /\ domain_activated[vnfs[j,VNF_DOMAIN_KEY]] = 1)
    % (path_member(inFlow,vnfs[i,VNF_DOMAIN_KEY]) /\ path_member(inFlow,vnfs[j,VNF_DOMAIN_KEY]))

    % if in start domain non WANA, then take a nearnest wanna
    % if in target domain non WANA, then take a nearnest wana
    % if none of them has wana, take two wana, and these two are different, and near each other 
    true
;


% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------

% no selection in inactive domain
constraint 
  forall(i,j in 1..n_domains where i < j) (
    if domain_activated[ i ] == 0 then
        domain_link_selection[i,j] = 0 /\ domain_link_selection[j,i] = 0
     else 
        true
     endif
  );


predicate start_target_properties(array[int] of var int: inFlow, array[int] of var int: outFlow) =
  inFlow[vnfs[start,VNF_DOMAIN_KEY]] = 1 
  /\ 
  outFlow[vnfs[start,VNF_DOMAIN_KEY]] > 0
  /\
  inFlow[vnfs[target,VNF_DOMAIN_KEY]] = 2 
  /\ 
  outFlow[vnfs[target,VNF_DOMAIN_KEY]] = 1
;

predicate domain_link_selection_properties(array[int,int] of var int: domain_link_selection) =
  % one self connection - vnfs in the same domain are interconnected
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

predicate flow_control(array[int] of var int: inFlow, array[int] of var int: outFlow) =
    % outflow definition
  forall(i in 1..n_domains) (
    outFlow[i] = sum(j in 1..n_domains where domain_link_weights[i,j] < M) (domain_link_selection[i,j])
  )
  /\ % inflow definition
  forall(j in 1..n_domains) (
    inFlow[j]  = sum(i in 1..n_domains where domain_link_weights[i,j] < M) (domain_link_selection[i,j])
  )
  /\ % DPI - flow terminates
  forall(i in 1..n_domains where i != vnfs[start,VNF_DOMAIN_KEY] /\ i != vnfs[target,VNF_DOMAIN_KEY]) (
    (outFlow[i] > 1 /\ inFlow[i] > 1) \/ (outFlow[i] == 1 /\ inFlow[i] >= 1)
  )
;

constraint
  start_target_properties(inFlow,outFlow)
  /\
  domain_link_selection_properties(domain_link_selection)
  /\
  flow_control(inFlow,outFlow)
  /\
  if params[WANA_KEY] == 1 /\ can_wana_strict() then enable_wana(inFlow) else true endif
  % /\
  % if params[WANA_KEY] == 1 /\ can_wana_relax() then enable_wana(inFlow) else true endif
  /\
  if params[DPI_KEY] == 1 then enable_dpi(inFlow) else true endif
;

% solve minimize total_cost;
solve :: int_search([domain_link_selection[i,j] | i,j in 1..n_domains], first_fail, indomain, complete) minimize total_cost;

output[ show(inFlow), show(outFlow), show(domain_link_selection)];
