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

array[1..n_domains,1..n_domains] of 0..1: domain_link_selection;            % domains where lie the start and target vnf
array[1..num_vnf_links] of var 0..1: link_selection;  % the resulting connection matrix
array[1..n_vnfs] of var 0..10: outFlow;                   % out-flow array
array[1..n_vnfs] of var 0..10: inFlow;                     % in-flow array

array[1..n_domains] of var 0..n_vnfs: sum_domain_dpi;
array[1..n_domains] of var 0..n_vnfs: sum_domain_wana;
array[1..n_domains] of var 0..n_vnfs: sum_domain_shaper;


% -------------------------------------------------
%       domain effective VNF counter
% -------------------------------------------------

constraint
  forall(i in 1..n_domains) (
    sum_domain_shaper[i] = sum(j in 1..num_vnf_links 
      where vnfs[vnf_links[j,2], VNF_DOMAIN_KEY] == i
      /\ vnfs[vnf_links[j,2], VNF_TYPE] == SHAPER ) 
      (link_selection[j])
  );


constraint
  forall(i in 1..n_domains) (
    sum_domain_wana[i] = sum(j in 1..num_vnf_links 
      where vnfs[vnf_links[j,2], VNF_DOMAIN_KEY] == i
      /\ vnfs[vnf_links[j,2], VNF_TYPE] == WANA ) 
      (link_selection[j])
  );

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------



predicate enable_shaper() =
  forall(i in 1..n_domains) (
    true
    % sum_domain_shaper[i] == domain_req_shaper[i]
  )
;

predicate enable_wana() =
  % true
  % sum_domain_wana[1] == 1
  forall(i in 1..n_domains)  (
    if exists (j in 1..n_vnfs where vnfs[j,VNF_DOMAIN_KEY] = i)( vnfs[j,VNF_TYPE] = WANA) 
      /\ domain_activated[i] == 1 then
      sum_domain_wana[i] == 1
    else
      sum_domain_wana[i] == 0 
    endif
  )
;

constraint 
  link_selection[1] = 1;
constraint 
  link_selection[2] = 1;
constraint 
  link_selection[3] = 1;
constraint 
  link_selection[4] = 1;
constraint 
  link_selection[5] = 1;
constraint 
  link_selection[6] = 1;
constraint 
  link_selection[7] = 1;
constraint 
  link_selection[8] = 1;
constraint 
  link_selection[9] = 1;


%   constraint 
%   link_selection[6] = 1 /\ link_selection[7] = 1;
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


%
% test if a vnf is relevant vnf
%
test if_relevent_vnf(1..n_vnfs: aVNF) =
  if vnfs[aVNF,VNF_TYPE] == DPI 
  \/ vnfs[aVNF,VNF_TYPE] == WANA 
  \/ aVNF = target 
  \/ vnfs[aVNF,VNF_TYPE] == GATEWAY 
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

% no selection in inactive domain
% constraint 
%   forall(i in 1..num_vnf_links) (
%     if domain_activated[ vnfs[vnf_links[i,1],VNF_DOMAIN_KEY] ] == 0 \/ domain_activated[ vnfs[vnf_links[i,2],VNF_DOMAIN_KEY] ] == 0 then
%         link_selection[i] = 0
%      else 
%         true
%      endif
%   );

% % no selection in non-adijacent domain
% constraint 
%   forall(i in 1..num_vnf_links where 
%     domain_link_selection[
%       vnfs[vnf_links[i,1],VNF_DOMAIN_KEY],
%       vnfs[vnf_links[i,2],VNF_DOMAIN_KEY] ] == 0) (

%     link_selection[i] = 0
%   );

% % domain self connection only necessary vnf
% constraint 
%   forall(i in 1..num_vnf_links where vnfs[vnf_links[i,1],VNF_DOMAIN_KEY] ==  vnfs[vnf_links[i,2],VNF_DOMAIN_KEY]) (
%     if not if_relevent_vnf(vnf_links[i,2]) then
%       link_selection[i] = 0 
%     else
%       true
%     endif
%   );

% predicate start_target_properties(array[int] of var int: inFlow, array[int] of var int: outFlow) =
% % true
%   inFlow[start] = 0 /\ outFlow[start] > 0
%   /\
%   inFlow[target] > 0 /\ outFlow[target] = 0
% ;

predicate flow_control(array[int] of var int: inFlow, array[int] of var int: outFlow) =
    % outflow definition
  forall(i in 1..n_vnfs) (
    outFlow[i] = sum(j in 1..num_vnf_links where vnf_links[j,1] == i) (link_selection[j])
  )
  /\ % inflow definition
  forall(i in 1..n_vnfs) (
    inFlow[i] = sum(j in 1..num_vnf_links where vnf_links[j,2] == i) (link_selection[j])
  )
  % /\ % generic VNF - flow through
  % forall(i in 1..n_vnfs where i != start /\ i != target /\ vnfs[i,VNF_TYPE] != DPI /\  vnfs[i,VNF_TYPE] != GATEWAY) (
  %   (outFlow[i] > 0 /\ inFlow[i] > 0) \/ (outFlow[i] == 0 /\ inFlow[i] == 0)
  % )
  % /\ % DPI - flow terminates
  % forall(i in 1..n_vnfs where vnfs[i,VNF_TYPE] == DPI) (outFlow[i] == 0)
;

constraint
  % start_target_properties(inFlow,outFlow)
  % /\
  flow_control(inFlow,outFlow)
  /\
  if params[WANA_KEY] == 1 /\ can_wana() then enable_wana() else true endif
  /\
  if params[SHAPER_KEY] == 1 then enable_shaper() else true endif
;

solve satisfy;


output[ show(link_selection)];
output[ show(sum_domain_wana), show(sum_domain_shaper)];
output[ show(inFlow ), show(outFlow)];
