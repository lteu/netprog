% params

int: n_services = 3;

% int: DPI_KEY = 1;
% int: WANA_KEY = 2;
% int: SHAPER_KEY = 3;

% 1 ID(nat), 2 Type(nat), 3 Terminating(bool, DPI), 4 Path Sense(bool), 
% 5 Mirrored(bool, WANA), 6 Weight(Nat), 7 Active(bool), 8 domain_id

int: VNF_DOMAIN_KEY = 8;
int: VNF_TYPE = 2;
int: VNF_TERMINATING = 3;
int: VNF_MIRRORED = 5;

int: ENDPOINT = 10;
int: GATEWAY = 9;
int: WANA = 2;
int: DPI = 1;
int: SHAPER = 3;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functional Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%


int: n_vnfs;      % number of nodes in the matrix
int: start;       % start node
int: target;      % end node
int: M;           % edge cost's upper bound
int: n_domains;   % num of domains
int: num_vnf_links;


array[1..n_vnfs, 1..8] of int: vnfs; 
array[1..num_vnf_links, 1..2] of 1..n_vnfs: vnf_links;   

array[1..n_domains, 1..n_domains] of 0..M: domain_link_weights;        % distance matrix
array[1..n_domains] of 0..1: domain_activated;            % domains where lie the start and target vnf

array[1..n_services] of 0..1: service_request;                               % service parameters
array[1..n_services, 1..2] of 0..n_vnfs: acc_request;    
array[1..n_services, 1..2] of 0..n_vnfs: dis_request; 


