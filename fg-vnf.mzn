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
int: num_vnf_links;

array[1..n_domains, 1..n_domains] of 0..M: domain_link_weights;        % USELESS
array[1..n_vnfs, 1..8] of int: vnfs;                      % vnf nodes
array[1..n_domains] of 0..1: domain_activated;            % domains where lie the start and target vnf
array[1..3] of int: params;                               % service parameters

array[1..n_domains,1..n_domains] of 0..1: domain_link_selection;            % domains where lie the start and target vnf

array[1..num_vnf_links, 1..2] of 1..n_vnfs: vnf_links;   

array[1..num_vnf_links] of var 0..1: link_selection;  % the resulting connection matrix
array[1..n_vnfs] of var 0..10: outFlow;                   % out-flow array
array[1..n_vnfs] of var 0..1: inFlow;                    % in-flow array

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------

% constraint total_cost < 25;
%
% Ensure VNF presence
%
predicate path_member(array [int] of var int: inFlow, int: aVNF) =
  exists ( i in 1..n_vnfs where i == aVNF ) (inFlow[i]==1 );

predicate path_member(int: aVNF) =
  exists ( i in 1..num_vnf_links) (vnf_links[i,2]==aVNF /\ link_selection[i] == 1);
%
% DPI, domain contain DPIs must have a spare VNF
%
predicate enable_dpi() =
  forall(i in 1..n_domains where domain_activated[i] == 1 /\ i != 13)(
    if exists (j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] == i)( vnfs[j,VNF_TYPE] == DPI)
    then
    % true
      forall(j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] == i /\ vnfs[j,VNF_TYPE] == DPI)(
          % path_member(inFlow,j)
          path_member(j)
      )
    else
      true
    endif
  );

% predicate enable_dpi(array[int] of var int: inFlow) =
%   forall(i in 1..n_domains where domain_activated[i] == 1)(
%     if exists (j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] == i)( vnfs[j,VNF_TYPE] == DPI)
%     then
%       forall(j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] == i /\ vnfs[j,VNF_TYPE] == DPI)(
%           path_member(inFlow,j)
%       )
%     else
%       true
%     endif
%   );
  

%
% WANA
%
test can_wana() =
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

predicate enable_wana(array[int] of var int: inFlow) =
    forall(i in 1..n_domains where domain_activated[i] = 1 )(
      exists ( j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] = i /\ vnfs[j,VNF_TYPE] = WANA)
      (path_member(j))
    )
;

%
% test if a vnf is relevant vnf
%
test if_relevent_vnf(1..n_vnfs: aVNF) =
  if vnfs[aVNF,VNF_TYPE] == DPI 
  \/ vnfs[aVNF,VNF_TYPE] == WANA 
  \/ aVNF = target 
  \/ vnfs[aVNF,VNF_TYPE] == BORDER 
  \/ vnfs[aVNF,VNF_TYPE] == SHAPER 
  then
    true
  else 
    false
  endif;


% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------

constraint assert(vnfs[start,VNF_DOMAIN_KEY] != vnfs[target,VNF_DOMAIN_KEY],"Input Data error: start and target VNFs must be in different domains");
             % assert(sum(i in 1..num_vnf_links)(if vnf_links[i,0]=start then 1 else 0 endif) >= 0 ,"aaa");
% constraint assert( exists ( i in 1..num_vnf_links  ) (vnf_links[i,0]==start ) ,"Start VNF must have outward link");
% constraint assert( exists ( i in 1..num_vnf_links  ) (vnf_links[i,1]==target ) ,"Target VNF must have inward link");

% no selection in inactive domain
constraint 
  forall(i in 1..num_vnf_links) (
    if domain_activated[ vnfs[vnf_links[i,1],VNF_DOMAIN_KEY] ] == 0 \/ domain_activated[ vnfs[vnf_links[i,2],VNF_DOMAIN_KEY] ] == 0 then
        link_selection[i] = 0
     else 
        true
     endif
  );

% no selection in non-adijacent domain
constraint 
  forall(i in 1..num_vnf_links where 
    domain_link_selection[
      vnfs[vnf_links[i,1],VNF_DOMAIN_KEY],
      vnfs[vnf_links[i,2],VNF_DOMAIN_KEY] ] == 0) (

    link_selection[i] = 0
  );



% domain self connection only necessary vnf
constraint 
  forall(i in 1..num_vnf_links where vnfs[vnf_links[i,1],VNF_DOMAIN_KEY] ==  vnfs[vnf_links[i,2],VNF_DOMAIN_KEY]) (
    if not if_relevent_vnf(vnf_links[i,2]) then
      link_selection[i] = 0 
    else
      true
    endif
  );


predicate start_target_properties(array[int] of var int: inFlow, array[int] of var int: outFlow) =
  inFlow[start] = 0 /\ outFlow[start] > 0
  /\
  inFlow[target] > 0 /\ outFlow[target] = 0
;

predicate link_selection_properties(array[int] of var int: link_selection) =
  % no neighbour loop
  forall(i,j in 1..num_vnf_links where i != j /\ vnf_links[i,1] == vnf_links[j,2] /\ vnf_links[j,1] == vnf_links[i,2]) (
     not (link_selection[i] == 1 /\ link_selection[j] == 1 ) 
  )

;

predicate flow_control(array[int] of var int: inFlow, array[int] of var int: outFlow) =
    % outflow definition
  forall(i in 1..n_vnfs) (
    outFlow[i] = sum(j in 1..num_vnf_links where vnf_links[j,1] == i) (link_selection[j])
  )
  /\ % inflow definition
  forall(i in 1..n_vnfs) (
    inFlow[i] = sum(j in 1..num_vnf_links where vnf_links[j,2] == i) (link_selection[j])
  )
  /\ % generic VNF - flow through
  forall(i in 1..n_vnfs where i != start /\ i != target /\ vnfs[i,VNF_TYPE] != DPI /\  vnfs[i,VNF_TYPE] != BORDER) (
    (outFlow[i] > 0 /\ inFlow[i] > 0) \/ (outFlow[i] == 0 /\ inFlow[i] == 0)
  )
  /\ % DPI - flow terminates
  forall(i in 1..n_vnfs where vnfs[i,VNF_TYPE] == DPI) (outFlow[i] == 0)
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
  if params[DPI_KEY] == 1 then enable_dpi() else true endif
;

solve satisfy;


output[ show(vnf_links), show(link_selection)];

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