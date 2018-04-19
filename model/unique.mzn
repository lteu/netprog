% 
% Service Function Chain 
%
% Contact: t.liu@unibo.it 
%

include "in_params.mzn"; 

int: vnflist_size; 
int: n_vnf_arcs = vnflist_size - 1;

array[1..vnflist_size] of 1..10: vnflist; % 10 is the number of types
array[1..n_vnf_arcs, 1..2] of 0..vnflist_size: vnf_arcs; % arcs extracted from vnflist considering dupList
array[1..vnflist_size] of var 1..n_nodes: vnf_match; % ground nodes for vnflist 
array[1..n_domains,1..n_domains] of var 0..1: domain_path; % domain_path[i,j]=1 means domain i is reachable from j (exists a path from j to i)
array[1..n_domains] of var 0..1: selected_domain;  % domains traversed by SFC
array[1..n_nodes] of var 0..1: selected_nodes; % all nodes belong to SFC
array[1..num_node_links] of var 0..1: link_selection; % resulting SFC
var int: n_fun_nodes; % number of functional nodes in SFC (excepting GATEWAY nodes)
var int: total_cost;


% objective function
% -- 
constraint 
  total_cost = sum(i in 1..num_node_links 
  where nodes[node_links[i,1], VNF_TYPE] = GATEWAY /\ nodes[node_links[i,2], VNF_TYPE] = GATEWAY ) 
  (domain_link_weights[nodes[node_links[i,1], VNF_DOMAIN_KEY], nodes[node_links[i,2],VNF_DOMAIN_KEY] ]*link_selection[i] );

% % -------------------------------------------------
% %      SFC Model
% % -------------------------------------------------

% % % domain constraints: 
% % % -------------------------------------------------
% % % 

% predicate ensure_domain_vnf(var int: domain_id,var int: type_id,var int: min,var int: max) =
%   let { var 0..n_vnf_arcs: acc = sum(i in 1..n_nodes where 
%     nodes[i,VNF_DOMAIN_KEY] = domain_id
%     /\
%     nodes[i,VNF_TYPE] = type_id
%     )(
%        selected_nodes[i]  
%    ) } in (
%     acc >= min
%     /\
%     acc <= max
%   )
% ;

% optimized
predicate ensure_domain_vnf(var int: domain_id,var int: type_id,var int: min,var int: max) =
  let { var 0..vnflist_size: acc = sum(i in 1..vnflist_size where 
    nodes[vnf_match[i],VNF_DOMAIN_KEY] = domain_id
    /\
    nodes[vnf_match[i],VNF_TYPE] = type_id
    )(
       1
   ) } in (
    acc >= min
    /\
    acc <= max
  )
;

% predicate ensure_domain_vnf(var int: domain_id,var int: type_id,var int: min,var int: max) =
%   exists (i in 1..n_nodes where 
%     nodes[i,VNF_DOMAIN_KEY] = domain_id
%     /\
%     nodes[i,VNF_TYPE] = type_id)(
%         selected_nodes[i] = 1
%     )
% ;

% optimized
constraint
  forall(i in 1..n_domain_constraints)(
        selected_domain[domain_constraints[i,1]] = 1 ->
        ensure_domain_vnf(domain_constraints[i,1], domain_constraints[i,2], domain_constraints[i,3], domain_constraints[i,4])
  );
% constraint
%   forall(i in 1..n_domains,j in 1..n_domain_constraints where domain_constraints[j,1] = i)(
%         selected_domain[i] = 1 ->
%         ensure_domain_vnf(i, domain_constraints[j,2], domain_constraints[j,3], domain_constraints[j,4])
%   );




% % domain path constraints:
% % -------------------------------------------------
% % domain has a path to itself
constraint 
  forall(i,j in 1..n_domains where i == j)(
      domain_path[i,j] = 1
  );

% propagate domain path 
constraint 
  forall(i,j in 1..n_domains where i <j)(
    if(
      exists(s in 1..num_node_links where 
        nodes[node_links[s,1], VNF_TYPE]=GATEWAY 
        /\
        nodes[node_links[s,2], VNF_TYPE]=GATEWAY
        /\
        nodes[node_links[s,2], VNF_DOMAIN_KEY]=i
        /\
        nodes[node_links[s,1], VNF_DOMAIN_KEY]=j)
        (link_selection[s] = 1)
      \/
      exists(s in 1..num_node_links where 
        nodes[node_links[s,1], VNF_TYPE]=GATEWAY 
        /\
        nodes[node_links[s,2], VNF_TYPE]=GATEWAY
        /\
        nodes[node_links[s,2], VNF_DOMAIN_KEY]=i
        /\
        nodes[node_links[s,1], VNF_DOMAIN_KEY]!=j)
        (link_selection[s] = 1 /\ domain_path[nodes[node_links[s,1], VNF_DOMAIN_KEY],j] = 1)
    )
    then
      domain_path[i,j] = 1
    else
      domain_path[i,j] = 0
    endif
  );

% bad modelling, why ???
% constraint 
%   forall(i in 1..num_node_links where  
%     nodes[node_links[i,1], VNF_TYPE]=GATEWAY 
%     /\
%     nodes[node_links[i,2], VNF_TYPE]=GATEWAY)(
%     link_selection[i] = 1 ->(
%       domain_path[nodes[node_links[i,2],VNF_DOMAIN_KEY],nodes[node_links[i,1],VNF_DOMAIN_KEY]] = 1
%       /\
%       forall(j in 1..n_domains)(
%         domain_path[nodes[node_links[i,1], VNF_DOMAIN_KEY],j] = 1
%         ->
%         domain_path[nodes[node_links[i,2], VNF_DOMAIN_KEY],j] = 1
%       )
%     )
%   );

% vnflist match constraint: 
% -------------------------------------------------
% first element in vnf_match (start ENDPOINT)
constraint 
  forall(i in 1..n_nodes where 
    nodes[i, VNF_DOMAIN_KEY] = start_domain 
    /\ 
    nodes[i, VNF_TYPE] = ENDPOINT)(
    vnf_match[1] = i
  );

% final element in vnf_match (target ENDPOINT)
constraint 
  forall(i in 1..n_nodes where 
    nodes[i, VNF_DOMAIN_KEY] = target_domain 
    /\ 
    nodes[i, VNF_TYPE] = ENDPOINT)(
    vnf_match[vnflist_size] = i
  );

% node type in vnf_match observes vnflist
constraint 
  forall(i in 2..vnflist_size)(
    exists(j in 1..n_nodes where nodes[j,VNF_TYPE] == vnflist[i])(
        vnf_match[i] = j 
    )
  );


% bound vnf_match to selected nodes (arcs)
constraint 
  forall(i in 2..vnflist_size)(
     exists (j in 1..num_node_links)(
            link_selection[j] = 1
            /\
            vnf_match[i] = node_links[j,2] 
      )
  );
% % % bound vnf_match to domain_path
constraint 
  forall(i in 1..n_vnf_arcs)(
    domain_path[nodes[vnf_match[vnf_arcs[i,1]], VNF_DOMAIN_KEY],nodes[vnf_match[vnf_arcs[i,2]], VNF_DOMAIN_KEY]] = 1
  );


% % % %   proximity constraints
% % % -------------------------------------------------

constraint 
  forall(i in 1..vnflist_size)(
    proximity_to_destination[i] = 1 -> 
    exists(j in 1..n_nodes where nodes[j,VNF_DOMAIN_KEY] = target_domain)(
        selected_nodes[j] = 1 /\ vnf_match[i] = j
    )
  );
constraint 
  forall(i in 1..vnflist_size)(
    proximity_to_source[i] = 1 -> 
    exists(j in 1..n_nodes where nodes[j,VNF_DOMAIN_KEY] = start_domain)(
        selected_nodes[j] = 1 /\ vnf_match[i] = j
    )
  );

% % % channel constraints: 
% % % -------------------------------------------------
% % % node with incoming arc means node domain is selected
% constraint 
%   forall(i in 1..n_domains) (
%     if exists (j in 1..num_node_links where
%       nodes[node_links[j,2], VNF_DOMAIN_KEY]  == i
%     ) (link_selection[j] = 1) then
%       selected_domain[i] == 1
%     else 
%       selected_domain[i] == 0
%     endif
%   );% includes both start and target D because ENDPOINT connects to gateway%

constraint 
    forall(i in 1..num_node_links)(
      link_selection[i] = 1 -> 
      selected_domain[nodes[node_links[i,1], VNF_DOMAIN_KEY] ] == 1
      /\
      selected_domain[nodes[node_links[i,2], VNF_DOMAIN_KEY] ] == 1
      /\
      selected_nodes[node_links[i,1]] == 1
      /\
      selected_nodes[node_links[i,2]] == 1
    )
  ;% includes both start and target D because ENDPOINT connects to gateway%


% % node with incoming arc means node is selected
% constraint 
%   forall(i in 1..n_nodes where nodes[i,VNF_TYPE] != ENDPOINT)(
%     if exists (j in 1..num_node_links where
%        node_links[j,2] == i \/ node_links[j,1] == i
%     ) (link_selection[j] = 1) then
%       selected_nodes[i] == 1
%     else 
%       selected_nodes[i] == 0
%     endif
%   );



% constraint approach 1
% % % get number of fun nodes by filtering selected_nodes
constraint 
    n_fun_nodes = sum(i in 1..n_nodes where 
      nodes[i,VNF_TYPE] != GATEWAY)(
      selected_nodes[i]
    );
% tightly bound the number of selected fun node to vnflist, 
constraint n_fun_nodes = vnflist_size;

% constraint approach 2
%   forall(i in 1..n_nodes where nodes[i,VNF_TYPE] != GATEWAY)(
%     selected_nodes[i] = 1 ->
%     exists(j in 1..vnflist_size)(vnf_match[j] = i)
%   );


% % % ENDPOINT constraint: 
% % % -------------------------------------------------
% % % ENDPOINT arcs must be selected in start and target domains
constraint 
  forall(i in 1..num_node_links where 
    (nodes[node_links[i,2], VNF_TYPE]  == GATEWAY /\ nodes[node_links[i,1], VNF_TYPE]  == ENDPOINT /\ nodes[node_links[i,1], VNF_DOMAIN_KEY]  == start_domain)
    \/
    (nodes[node_links[i,1], VNF_TYPE]  == GATEWAY /\ nodes[node_links[i,2], VNF_TYPE]  == ENDPOINT /\ nodes[node_links[i,2], VNF_DOMAIN_KEY]  == target_domain)
  )(
      link_selection[i] = 1
  );

% % no arcs to ENDPOINT if they are not start target domains
constraint 
  forall(i in 1..num_node_links where 
    (nodes[node_links[i,1], VNF_TYPE]  == ENDPOINT /\ nodes[node_links[i,1], VNF_DOMAIN_KEY]  != start_domain)
    \/
    (nodes[node_links[i,2], VNF_TYPE]  == ENDPOINT /\ nodes[node_links[i,2], VNF_DOMAIN_KEY]  != target_domain)
  )(
      link_selection[i] = 0
  );

% ENDPOINT in start and target domains are selected, others no
constraint 
  forall(i in 1..n_nodes where nodes[i,VNF_TYPE] == ENDPOINT)(
    if nodes[i,VNF_DOMAIN_KEY] = start_domain 
       \/ 
       nodes[i,VNF_DOMAIN_KEY] = target_domain  
    then
      selected_nodes[i] == 1
    else 
      selected_nodes[i] == 0
    endif
  );


% -------------------------------------------------
%      Core Graph
% -------------------------------------------------

% ??? todo
% no loop between neighbor domains
constraint
  forall(i,j in 1..num_node_links where 
    i < j 
    /\
    nodes[node_links[i,1], VNF_TYPE]  == GATEWAY
    /\
    nodes[node_links[i,2], VNF_TYPE]  == GATEWAY
    /\
    node_links[i,1] == node_links[j,2] 
    /\ 
    node_links[i,2] == node_links[j,1]
  ) 
  (
    not (link_selection[i] = 1 /\ link_selection[j] = 1)
    % link_selection[i] = 1 -> link_selection[j] = 1
  );

% start domain has no incoming arc from other domain
constraint
  forall(i in 1..num_node_links where
    nodes[node_links[i,2], VNF_TYPE]  == GATEWAY
    /\
    nodes[node_links[i,1], VNF_TYPE]  == GATEWAY
    /\
    nodes[node_links[i,2], VNF_DOMAIN_KEY] = start_domain
  ) 
  (
    link_selection[i] = 0
  );


% no domains allow 2 incoming arcs from different domains
% todo: can be improved based on domains ?
constraint 
  not exists(i,j in 1..num_node_links where 
      i < j
      /\
      nodes[node_links[i,2], VNF_TYPE]  == GATEWAY
      /\
      nodes[node_links[i,1], VNF_TYPE]  == GATEWAY
      /\
      nodes[node_links[j,2], VNF_TYPE]  == GATEWAY
      /\
      nodes[node_links[j,1], VNF_TYPE]  == GATEWAY
      /\
      nodes[node_links[i,2], VNF_DOMAIN_KEY]  == nodes[node_links[j,2], VNF_DOMAIN_KEY]
      /\
      nodes[node_links[i,1], VNF_DOMAIN_KEY]  != nodes[node_links[j,1], VNF_DOMAIN_KEY]
  ) 
  (
    link_selection[i] = 1 /\ link_selection[j] = 1
  );

% each selected domain must have an incoming arc from other domain
constraint 
  forall(i in 1..n_domains where i != start_domain) (
    selected_domain[i] == 1 -> 
    exists (j in 1..num_node_links)(
      link_selection[j] = 1
      /\
      nodes[node_links[j,2], VNF_DOMAIN_KEY]  == i
      /\
      nodes[node_links[j,1], VNF_DOMAIN_KEY]  != i
      /\
      nodes[node_links[j,2], VNF_TYPE]  == GATEWAY
      /\
      nodes[node_links[j,1], VNF_TYPE]  == GATEWAY
    ));

% no outgoing arcs from unselected domains
constraint 
  forall(i in 1..num_node_links) (
    selected_domain[nodes[node_links[i,1],VNF_DOMAIN_KEY]] = 0 -> link_selection[i] = 0
  );


% solve satisfy;
solve minimize total_cost;
      
% outputs
% --------------------------

output[show(link_selection),show(selected_domain)];
output[
"total_cost = ", show(total_cost), "\n"
];
output[show(domain_path)];
output[show(vnf_match)];
output[show(n_fun_nodes)];
output[show(selected_nodes)];
