% 
% Addressing Intent with Service Function Chain 
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

% % node type in vnf_match observes vnflist
constraint 
  forall(i in 2..vnflist_size)(
      nodes[vnf_match[i],VNF_TYPE] == vnflist[i]
  );

% % bound vnf_match to selected nodes (arcs)
constraint 
  forall(i in 2..vnflist_size)(
     exists (j in 1..num_node_links)(
            link_selection[j] = 1
            /\
            node_links[j,2] = vnf_match[i]
      )
  );

% % bound vnf_match to domain_path
constraint 
  forall(i in 1..n_vnf_arcs)(
    domain_path[nodes[vnf_match[vnf_arcs[i,2]], VNF_DOMAIN_KEY],nodes[vnf_match[vnf_arcs[i,1]], VNF_DOMAIN_KEY]] = 1
  );


% %   proximity constraints
% % -------------------------------------------------
constraint 
  forall(i in 1..vnflist_size)(
    proximity_to_source[i] = 1 -> nodes[vnf_match[i],VNF_DOMAIN_KEY] = start_domain 
    /\
    proximity_to_destination[i] = 1 -> nodes[vnf_match[i],VNF_DOMAIN_KEY] = target_domain
  );
  

% % channel constraints: 
% % -------------------------------------------------
% % node with incoming arc means node domain is selected
constraint 
  forall(i in 1..n_domains) (
    if exists (j in 1..num_node_links where
      nodes[node_links[j,2], VNF_DOMAIN_KEY]  == i
    ) (link_selection[j] = 1) then
      selected_domain[i] == 1
    else 
      selected_domain[i] == 0
    endif
  );% includes both start and target D because ENDPOINT connects to gateway%


% % node with incoming arc means node is selected
constraint 
  forall(i in 1..n_nodes where nodes[i,VNF_TYPE] != ENDPOINT)(
    if exists (j in 1..num_node_links where
       node_links[j,2] == i \/ node_links[j,1] == i
    ) (link_selection[j] = 1) then
      selected_nodes[i] == 1
    else 
      selected_nodes[i] == 0
    endif
  );

% % get number of fun nodes by filtering selected_nodes
constraint 
    n_fun_nodes = sum(i in 1..n_nodes where 
    nodes[i,VNF_TYPE] != GATEWAY)(
    selected_nodes[i]
    );

% % tightly bound the number of selected fun node to vnflist, 
% constraint n_fun_nodes = vnflist_size;

% % ENDPOINT constraint: 
% % -------------------------------------------------
% % ENDPOINT arcs must be selected in start and target domains
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
