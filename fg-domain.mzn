% 
% Find optimal domain connection while satisfying VNF chain requirements
%
% Contact: t.liu@unibo.it 
%

include "in_params.mzn"; 

array[1..n_domains] of var 1..10: outFlow;                              % domain out-flow limit
array[1..n_domains] of var 1..2: inFlow;                                % domain in-flow limit
array[1..n_domains, 1..n_domains] of var 0..1: domain_link_selection;   % resulting domain connection
array[1..n_domains] of var 0..1: selected_domain;                       % effective domains which are connected
array[1..n_services,1..n_domains] of var 0..n_vnfs: count_serivce;      % number of services in domains

% objective to minimize
var int: total_cost = sum(i in 1..n_domains, j in 1..n_domains where domain_link_weights[i,j] < M) ( domain_link_weights[i,j]* domain_link_selection[i,j] );

% -------------------------------------------------
%       Intent-based Model Specification
% -------------------------------------------------

% selected domain value definition ( to improve )
constraint 
  forall(i,j in 2..n_domains where i != j) (
    (selected_domain[i] == 1 /\ inFlow[i] > 1) \/ (selected_domain[i] == 0 /\ inFlow[i] == 1)
  ) /\ selected_domain[1] == 1;

% count type services by domain
constraint 
  forall(k in 1..n_services)(
    forall(i in 1..n_domains) (
      count_serivce[k,i] = sum(j in 1..n_vnfs where vnfs[j,VNF_TYPE] == k /\ vnfs[j,VNF_DOMAIN_KEY] == i) (1)
    )
  );

% check service distribution
predicate service_check() =
  forall(i in 1..n_services) (
    if service_request[ i ] == 1 then
        accumulative_constraint(i) /\ distributive_constraint(i)
     else 
        true
     endif
  )
;

predicate accumulative_constraint(var int: service_id) =
  let { var 1..n_vnfs: acc = sum(i in 1..n_domains)(
       selected_domain[i] * count_serivce[service_id,i]  
   ) } in (
    acc >= acc_request[service_id,1]
  )
;

predicate distributive_constraint(var int: service_id) =
  dis_request[service_id,1] > 0 ->
  forall(i in 1..n_domains)(
      selected_domain[i] == 0
      \/
      (
        selected_domain[i] == 1
        /\
        count_serivce[service_id,i] >= dis_request[service_id,1]
      )
  )
;

% -------------------------------------------------
%       Core - Graph Shortest Path Problem
% -------------------------------------------------
constraint assert(domain_activated[start_domain] == 1 /\domain_activated[target_domain] == 1 ,"Domain must be actived");

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
  inFlow[start_domain] = 1 
  /\ 
  outFlow[start_domain] > 0
  /\
  inFlow[target_domain] = 2 
  /\ 
  outFlow[target_domain] = 1
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
  /\ % generic definition
  forall(i in 1..n_domains where i != start_domain /\ i != target_domain) (
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
  service_check()
;

% solve minimize total_cost;
solve :: int_search([domain_link_selection[i,j] | i,j in 1..n_domains], first_fail, indomain, complete) minimize total_cost;

output[ show(inFlow), show(outFlow), show(domain_link_selection),show(selected_domain)];
