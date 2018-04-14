% 
% Based on domains connection, this script finalizes a concrete VNF function chain.
%
% Contact: t.liu@unibo.it 
%


include "in_params.mzn"; 

array[1..n_domains] of var 0..1: selected_domain;                     % effective domains re-computed from domain_link_selection
array[1..n_services,1..n_domains] of var 0..n_vnfs: count_serivce;    % number of services in domains
array[1..num_vnf_links] of var 0..1: link_selection;                  % resulting VNF connection links

array[1..n_domains,1..n_domains] of var 0..1: domain_cover; 

int: len_vnflist;
array[1..len_vnflist] of 1..10: vnflist; % 10 is the number of types
array[1..len_vnflist-1, 1..2] of 0..len_vnflist: intent_arcs;

array[1..len_vnflist] of var 1..n_vnfs: intent_match;

var int: total_cost;


% ===== domain cover constraint =====
% constraint 
%   forall(i in 1..n_domains where i != start_domain)(
%     domain_cover[start_domain,i] = 0
%   )/\
%   domain_cover[start_domain,start_domain] = 1;

constraint forall(i,j in 1..n_domains where i == j)(

      domain_cover[i,j] = 1
);


constraint 
  forall(i,j in 1..n_domains where i !=j)(
    (
      if(
        exists(s in 1..num_vnf_links where 
          vnfs[vnf_links[s,1], VNF_TYPE]=GATEWAY 
          /\
          vnfs[vnf_links[s,2], VNF_TYPE]=GATEWAY
          /\
          vnfs[vnf_links[s,2], VNF_DOMAIN_KEY]=i
          /\
          vnfs[vnf_links[s,1], VNF_DOMAIN_KEY]=j)
          (link_selection[s] = 1)
        \/
        exists(s in 1..num_vnf_links where 
          vnfs[vnf_links[s,1], VNF_TYPE]=GATEWAY 
          /\
          vnfs[vnf_links[s,2], VNF_TYPE]=GATEWAY
          /\
          vnfs[vnf_links[s,2], VNF_DOMAIN_KEY]=i
          /\
          vnfs[vnf_links[s,1], VNF_DOMAIN_KEY]!=j)
          (link_selection[s] = 1 /\ domain_cover[vnfs[vnf_links[s,1], VNF_DOMAIN_KEY],j] = 1)
      )
      then
      domain_cover[i,j] = 1
      else
      domain_cover[i,j] = 0
      endif

    )
  );

% =====

% first element in intent match
constraint forall(i in 1..n_vnfs 
    where vnfs[i, VNF_DOMAIN_KEY] = start_domain 
    /\ vnfs[i, VNF_TYPE] = ENDPOINT) (
    intent_match[1] = i
  );

constraint 
  forall(i in 1..len_vnflist)(
      vnfs[intent_match[i],VNF_TYPE] == vnflist[i]
  );

constraint 
  forall(i in 2..len_vnflist)(
     exists (j in 1..num_vnf_links)(
            link_selection[j] = 1
            /\
            vnf_links[j,2] = intent_match[i]
      )
  );

constraint link_selection[13] = 1;
constraint link_selection[14] = 1;
constraint link_selection[15] = 1;
constraint link_selection[16] = 1;
constraint link_selection[17] = 1;
constraint link_selection[18] = 1;



% constraint 
%   forall(i in 1..len_vnflist-1)(
%     ensure_path(intent_match[intent_arcs[i,1]],intent_match[intent_arcs[i,2]])
%   );

% constraint 
%   ensure_path(4,8);


% modo ricorsivo non funziona: segment fault !
% predicate ensure_path(var int: start,var int: target) = 
%   exists(k in 1..n_vnfs where vnfs[k,VNF_TYPE] == GATEWAY) (
%          (exists(i,j in 1..num_vnf_links where 
%            vnf_links[i,1] = start 
%           /\ vnf_links[i,2] = k
%           /\ vnf_links[j,1] = k
%           /\ vnf_links[j,2] = target)(link_selection[i] = 1 /\ link_selection[j] = 1))
%          % \/
%          % (forall(i in 1..num_vnf_links where 
%          %   vnf_links[i,1] = start 
%          %  /\ vnf_links[i,2] = k)(
%          %    link_selection[i] = 1
%          %   )
%          %  /\
%          %  ensure_path(k,target)
%          % )
%   )
%   \/
%   exists(k in 1..n_vnfs where vnfs[k,VNF_TYPE] == GATEWAY) (
%          ensure_path(k,target)
%   )
% ;

% predicate ensure_path(var int: start,var int: target) = 
%   forall(i in 1..n_vnfs) (
%          sum(k in 1..num_vnf_links where vnf_links[k,2] = i) (link_selection[k]) + (if i = start then 1 else 0 endif)
%     = 
%          sum(k in 1..num_vnf_links where vnf_links[k,1] = i) (link_selection[k]) + (if i = target then 1 else 0 endif)
%   )
% ;


% objective function
constraint 
  total_cost = sum(i in 1..num_vnf_links 
  where vnfs[vnf_links[i,1], VNF_TYPE] = GATEWAY /\ vnfs[vnf_links[i,2], VNF_TYPE] = GATEWAY ) 
  ( domain_link_weights[ vnfs[vnf_links[i,1], VNF_DOMAIN_KEY], vnfs[vnf_links[i,2],VNF_DOMAIN_KEY] ]* link_selection[i] );


% -------------------------------------------------
%      SFC Model
% -------------------------------------------------


% I will use proximity to source and target to replace it!
% todo:
%   numb(S,V,D)
% -------------------------------------------------
constraint 
  forall(k in 1..n_services)(
    forall(i in 1..n_domains) (
      count_serivce[k,i] = 
      sum(j in 1..num_vnf_links 
        where 
        (vnfs[vnf_links[j,2], VNF_DOMAIN_KEY] == i 
        /\ vnfs[vnf_links[j,2], VNF_TYPE] == k)
        \/ 
        (vnfs[vnf_links[j,1], VNF_DOMAIN_KEY] == i 
        /\ vnfs[vnf_links[j,1], VNF_TYPE] == k)
        ) 
        (link_selection[j])
    )
  );

% a node has incoming arc means node domain is selected
constraint 
  forall(i in 1..n_domains) (
    if exists (j in 1..num_vnf_links where
      vnfs[vnf_links[j,2], VNF_DOMAIN_KEY]  == i
    ) (link_selection[j] = 1) then
      selected_domain[i] == 1
    else 
      selected_domain[i] == 0
    endif
  );% includes both start and target D because endpoint connects to gateway%


% ENDPOINT constraint: 
% -------------------------------------------------
% ENDPOINT arcs must be selected in start target domains
constraint 
  forall(i in 1..num_vnf_links where 
    (vnfs[vnf_links[i,2], VNF_TYPE]  == GATEWAY /\ vnfs[vnf_links[i,1], VNF_TYPE]  == ENDPOINT /\ vnfs[vnf_links[i,1], VNF_DOMAIN_KEY]  == start_domain)
    \/
    (vnfs[vnf_links[i,1], VNF_TYPE]  == GATEWAY /\ vnfs[vnf_links[i,2], VNF_TYPE]  == ENDPOINT /\ vnfs[vnf_links[i,2], VNF_DOMAIN_KEY]  == target_domain)
  )(
      link_selection[i] = 1
  );

% no arcs to ENDPOINT if they are not start target domains
constraint 
  forall(i in 1..num_vnf_links where 
    (vnfs[vnf_links[i,1], VNF_TYPE]  == ENDPOINT /\ vnfs[vnf_links[i,1], VNF_DOMAIN_KEY]  != start_domain)
    \/
    (vnfs[vnf_links[i,2], VNF_TYPE]  == ENDPOINT /\ vnfs[vnf_links[i,2], VNF_DOMAIN_KEY]  != target_domain)
  )(
      link_selection[i] = 0
  );


% test if a vnf is relevant vnf
% todo: can be deleted after adding number constraint
test if_relevent_vnf(1..n_vnfs: aVNF) =
  if (vnfs[aVNF,VNF_TYPE] > 0 /\ vnfs[aVNF,VNF_TYPE] < 6 /\ service_request[vnfs[aVNF,VNF_TYPE]] == 1 )
     % general service
     \/ 
     vnfs[aVNF,VNF_TYPE] > 8 
     % endpoint, gateway 
  then
    true
  else 
    false
  endif;



% ---------------------
%   service constraints
% -------------------------------------------------

% constraint 
%   forall(i in 1..n_services) (
%     count_serivce[i,start_domain] >= src_request[i,1]
%     /\ 
%     count_serivce[i,start_domain] <= src_request[i,2]
%     /\ 
%     count_serivce[i,target_domain] <= end_request[i,2]
%     /\ 
%     count_serivce[i,target_domain] >= end_request[i,1]
%   );


% -------------------------------------------------
%       Graph Core 
% -------------------------------------------------


% no loop between neighbor domains
constraint
  forall(i,j in 1..num_vnf_links where 
    i < j 
    /\
    vnfs[vnf_links[i,1], VNF_TYPE]  == GATEWAY
    /\
    vnfs[vnf_links[i,2], VNF_TYPE]  == GATEWAY
    /\
    vnf_links[i,1] == vnf_links[j,2] 
    /\ 
    vnf_links[i,2] == vnf_links[j,1]
  ) 
  (
    not (link_selection[i] = 1 /\ link_selection[j] = 1)
  );

% start domain has no incoming arc from other domain
constraint
  forall(i in 1..num_vnf_links where
    vnfs[vnf_links[i,2], VNF_TYPE]  == GATEWAY
    /\
    vnfs[vnf_links[i,1], VNF_TYPE]  == GATEWAY
    /\
    vnfs[vnf_links[i,2], VNF_DOMAIN_KEY] = start_domain
  ) 
  (
    link_selection[i] = 0
  );


% no domains allow 2 incoming arcs from different domains
% todo: can be improved based on domains
constraint 
  not exists(i,j in 1..num_vnf_links where 
      vnfs[vnf_links[i,2], VNF_TYPE]  == GATEWAY
      /\
      vnfs[vnf_links[i,1], VNF_TYPE]  == GATEWAY
      /\
      vnfs[vnf_links[j,2], VNF_TYPE]  == GATEWAY
      /\
      vnfs[vnf_links[j,1], VNF_TYPE]  == GATEWAY
      /\
      vnfs[vnf_links[i,2], VNF_DOMAIN_KEY]  == vnfs[vnf_links[j,2], VNF_DOMAIN_KEY]
      /\
      vnfs[vnf_links[i,1], VNF_DOMAIN_KEY]  != vnfs[vnf_links[j,1], VNF_DOMAIN_KEY]
  ) 
  (
    link_selection[i] = 1 /\ link_selection[j] = 1
  );

% each selected domain must have an incoming arc from other domain
constraint 
  forall(i in 1..n_domains where i != start_domain) (
    selected_domain[i] == 1 -> 
    exists (j in 1..num_vnf_links)(
      link_selection[j] = 1
      /\
      vnfs[vnf_links[j,2], VNF_DOMAIN_KEY]  == i
      /\
      vnfs[vnf_links[j,1], VNF_DOMAIN_KEY]  != i
      /\
      vnfs[vnf_links[j,2], VNF_TYPE]  == GATEWAY
      /\
      vnfs[vnf_links[j,1], VNF_TYPE]  == GATEWAY
    ));

% no outgoing arcs from unselected domains
constraint 
  forall(i in 1..num_vnf_links) (
    selected_domain[vnfs[vnf_links[i,1],VNF_DOMAIN_KEY]] = 0 -> link_selection[i] = 0
  );

% only relevant VNFs are connectable in the same domain
% todo: can be deleted after adding number constraint
constraint 
  forall(i in 1..num_vnf_links where vnfs[vnf_links[i,1],VNF_DOMAIN_KEY] ==  vnfs[vnf_links[i,2],VNF_DOMAIN_KEY]) (
    if not if_relevent_vnf(vnf_links[i,2]) \/ not if_relevent_vnf(vnf_links[i,1])then
      link_selection[i] = 0 
    else
      true
    endif
  );
      
% main
% --------------------------

% constraint
%   service_distribution()
% ;
% solve satisfy;
solve minimize total_cost;

output[show(link_selection),show(selected_domain)];
output[
"total_cost = ", show(total_cost), "\n"
];
output[ show(count_serivce)];

var int: serv3;
% test scope
constraint serv3 = sum(i in 1..n_domains)(
    count_serivce[5,i]
    );
output[ show(serv3)];
output[show(domain_cover)];
output[show(intent_match)];
