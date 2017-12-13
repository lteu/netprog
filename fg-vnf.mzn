% 
% Based on domains connection, this script finalizes a concrete VNF function chain.
%
% Contact: t.liu@unibo.it 
%


include "in_params.mzn"; 

array[1..n_domains,1..n_domains] of 0..1: domain_link_selection;      % domain connection map computed by fg-domain.mzn
array[1..n_domains] of var 0..1: selected_domain;                     % effective domains re-computed from domain_link_selection
array[1..n_services,1..n_domains] of var 0..n_vnfs: count_serivce;    % number of services in domains

array[1..n_vnfs] of var 0..10: vnf_outFlow;                           % vnf out-flow limit
array[1..n_vnfs] of var 0..10: vnf_inFlow;                            % vnf in-flow limit
array[1..num_vnf_links] of var 0..1: link_selection;                  % resulting VNF connection links


% -------------------------------------------------
%       Functiona Chain Model Specification
% -------------------------------------------------

%   pre-compute
% -------------------------------------------------
constraint 
  forall(i in 1..n_domains) (
    if exists (j in 1..n_domains where i != j) (domain_link_selection[j,i] ==1 \/ domain_link_selection[i,j] ==1) then
      selected_domain[i] == 1
    else 
      selected_domain[i] == 0
    endif
  );

%   effective VNF service counter by domain
% -------------------------------------------------

constraint 
  forall(k in 1..n_services)(
    forall(i in 1..n_domains) (
      count_serivce[k,i] = 
      sum(j in 1..num_vnf_links where vnfs[vnf_links[j,2], VNF_DOMAIN_KEY] == i /\ vnfs[vnf_links[j,2], VNF_TYPE] == k /\ vnfs[vnf_links[j,2], VNF_STATE_KEY] == 1 ) 
        (link_selection[j])
    )
  );

% test if a vnf is relevant vnf
% 
test if_relevent_vnf(1..n_vnfs: aVNF) =
  if (vnfs[aVNF,VNF_TYPE] > 0 /\ vnfs[aVNF,VNF_TYPE] < 6 /\ service_request[vnfs[aVNF,VNF_TYPE]] == 1 )
     % general service
     \/ 
     vnfs[aVNF,VNF_TYPE] > 8 
     \/
     vnfs[aVNF,VNF_STATE_KEY] == 1 
     % endpoint, gateway 
  then
    true
  else 
    false
  endif;

% test if_relevent_vnf(1..n_vnfs: aVNF) =
%   if (vnfs[aVNF,VNF_TYPE] > 0 /\ vnfs[aVNF,VNF_TYPE] < 5 /\ service_request[vnfs[aVNF,VNF_TYPE]] == 1 /\ request_bound[vnfs[aVNF,VNF_TYPE]] == 0)
%      % general service
%      \/ 
%      (vnfs[aVNF,VNF_TYPE] > 0 /\ vnfs[aVNF,VNF_TYPE] < 5 /\ service_request[vnfs[aVNF,VNF_TYPE]] == 1 /\ request_bound[vnfs[aVNF,VNF_TYPE]] == 1 /\ (vnfs[aVNF,VNF_DOMAIN_KEY] = start_domain \/ vnfs[aVNF,VNF_DOMAIN_KEY] = target_domain) ) 
%      % endpoint domain service
%      \/ 
%      vnfs[aVNF,VNF_TYPE] > 8 
%      % endpoint, gateway 
%   then
%     true
%   else 
%     false
%   endif;

%   service distribution
% -------------------------------------------------

predicate service_distribution() =
  forall(i in 1..n_services) (
    if service_request[ i ] == 1 then
        accumulative_constraint(i) /\ distributive_constraint(i)
     else 
        true
     endif
  )
;

predicate accumulative_constraint(var int: service_id) =
  let { var 0..n_vnfs: acc = sum(i in 1..n_domains)(
    count_serivce[service_id,i]
    )} 
  in (
    acc_request[service_id,1] <= acc /\ acc <= acc_request[service_id,2]
  );

predicate distributive_constraint(var int: service_id) =
  forall(i in 1..n_domains)(
      (
        selected_domain[i] == 0
        /\
        count_serivce[service_id,i] == 0
      )
      \/
      (
        selected_domain[i] == 1
        /\
        dis_request[service_id,1] <= count_serivce[service_id,i] /\ count_serivce[service_id,i] <= dis_request[service_id,2]

      )
      % \/
      % (
      %   selected_domain[i] == 1
      %   /\
      %   (request_bound[service_id] = 0 \/ (request_bound[service_id] = 1 /\ (i == start_domain \/ i == target_domain) ) )
      %   /\
      %   dis_request[service_id,1] <= count_serivce[service_id,i] /\ count_serivce[service_id,i] <= dis_request[service_id,2]
      % )
      % \/
      % (
      %   selected_domain[i] == 1
      %   /\
      %   (request_bound[service_id] = 1 /\ (i != start_domain /\ i != target_domain) )
      %  )

  );

% -------------------------------------------------
%       Core 
% -------------------------------------------------

% no link connection in irrelevant domains domains
constraint 
  forall(i in 1..num_vnf_links) (
    (selected_domain[vnfs[vnf_links[i,1],VNF_DOMAIN_KEY]] = 0 /\link_selection[i] = 0)
     \/
     selected_domain[vnfs[vnf_links[i,1],VNF_DOMAIN_KEY]] = 1
  );

% only relevant VNFs are connectable in the same domain
constraint 
  forall(i in 1..num_vnf_links where vnfs[vnf_links[i,1],VNF_DOMAIN_KEY] ==  vnfs[vnf_links[i,2],VNF_DOMAIN_KEY]) (
    if not if_relevent_vnf(vnf_links[i,2]) then
      link_selection[i] = 0 
    else
      true
    endif
  );

% no link connection if no domain connection
constraint 
  forall(i in 1..num_vnf_links where 
    domain_link_selection[
      vnfs[vnf_links[i,1],VNF_DOMAIN_KEY],
      vnfs[vnf_links[i,2],VNF_DOMAIN_KEY] ] == 0) (
    link_selection[i] = 0
  );


% channel constraint : link connection mandatory if domain connection exists
% ------------------------------------------------------------------------

constraint 
  forall(i,j in 1..n_domains where i != j) (
    domain_link_selection[i,j] == 1 -> exists (m in 1..num_vnf_links where
      vnfs[vnf_links[m,1],VNF_DOMAIN_KEY] = i 
      /\ vnfs[vnf_links[m,2],VNF_DOMAIN_KEY] = j
      /\ vnfs[vnf_links[m,1],VNF_TYPE] = GATEWAY
      /\ vnfs[vnf_links[m,2],VNF_TYPE] = GATEWAY)
    (link_selection[m] = 1 )
  );

constraint 
   forall(m in 1..num_vnf_links where 
    vnfs[vnf_links[m,1],VNF_TYPE] = GATEWAY 
    /\ vnfs[vnf_links[m,2],VNF_TYPE] = GATEWAY
    /\ vnfs[vnf_links[m,1],VNF_DOMAIN_KEY] != vnfs[vnf_links[m,2],VNF_DOMAIN_KEY] ) (
      domain_link_selection[vnfs[vnf_links[m,1],VNF_DOMAIN_KEY],vnfs[vnf_links[m,2],VNF_DOMAIN_KEY]] = 1
      -> link_selection[m] = 1
   );

% conservative predicates
% --------------------------

% predicate start_target_properties(array[int] of var int: vnf_inFlow, array[int] of var int: vnf_outFlow) =
%   forall(idx in 1..n_vnfs where vnfs[idx,VNF_TYPE] == ENDPOINT)(
%     if vnfs[idx,VNF_DOMAIN_KEY] == start_domain then
%       vnf_inFlow[idx] = 0 /\ vnf_outFlow[idx] > 0
%     else 
%       true
%     endif
%   )
%   /\
%   forall(idx in 1..n_vnfs where vnfs[idx,VNF_TYPE] == ENDPOINT)(
%     if vnfs[idx,VNF_DOMAIN_KEY] == target_domain then
%       vnf_inFlow[idx] > 0 /\ vnf_outFlow[idx] = 0
%     else 
%       true
%     endif
%   );
predicate start_target_properties(array[int] of var int: vnf_inFlow, array[int] of var int: vnf_outFlow) =
  forall(idx in 1..n_vnfs where vnfs[idx,VNF_TYPE] == ENDPOINT)(
    (vnfs[idx,VNF_DOMAIN_KEY] == start_domain /\ vnf_inFlow[idx] = 0 /\ vnf_outFlow[idx] > 0)
    \/
    (vnfs[idx,VNF_DOMAIN_KEY] == target_domain /\  vnf_inFlow[idx] > 0 /\ vnf_outFlow[idx] = 0)
    \/
    (vnf_inFlow[idx] = 0 /\ vnf_outFlow[idx] = 0)
  )
  ;
% predicate start_target_properties(array[int] of var int: vnf_inFlow, array[int] of var int: vnf_outFlow) =

%       vnf_inFlow[113] = 0 /\ vnf_outFlow[113] > 0
% \/
%       vnf_inFlow[87] > 0 /\ vnf_outFlow[87] = 0

%   ;

      
predicate flow_control(array[int] of var int: vnf_inFlow, array[int] of var int: vnf_outFlow) =
    % vnf_outFlow definition
  forall(i in 1..n_vnfs) (
    vnf_outFlow[i] = sum(j in 1..num_vnf_links where vnf_links[j,1] == i) (link_selection[j])
  )
  /\ % vnf_inFlow definition
  forall(i in 1..n_vnfs) (
    vnf_inFlow[i] = sum(j in 1..num_vnf_links where vnf_links[j,2] == i) (link_selection[j])
  )
  /\ % generic VNF - flow through
  forall(i in 1..n_vnfs where vnfs[i,VNF_TYPE] != ENDPOINT /\ vnfs[i,VNF_TERMINATING] != 1) (
    (vnf_outFlow[i] > 0 /\ vnf_inFlow[i] > 0) \/ (vnf_outFlow[i] == 0 /\ vnf_inFlow[i] == 0)
  )
  /\ % DPI - flow terminates
  forall(i in 1..n_vnfs where vnfs[i,VNF_TERMINATING] == 1) (vnf_outFlow[i] == 0)
;

% main
% --------------------------

constraint
  start_target_properties(vnf_inFlow,vnf_outFlow)
  /\
  flow_control(vnf_inFlow,vnf_outFlow)
  /\
  service_distribution()
;

solve satisfy;

output[show(link_selection),show(selected_domain)];
output[ show(count_serivce)];
