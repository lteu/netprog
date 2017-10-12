% 
%
% CP for Intent-based network
% 
% 
%
% 
% command:
% mzn2fzn -I mznlib vnf.mzn -o xxx.fzn
% solve xxx.fzn
%
% ref: https://github.com/hakank/hakank/blob/master/minizinc/spp.mzn
%


int: num_domains;
int: num_vnfs;
int: num_domain_links;
int: num_vnf_links;
int: num_vnftypes;

array[1..num_domains, 1..3] of int: domains; 
array[1..num_domain_links, 1..4] of int: domain_links; 

array[1..num_vnftypes] of int: vnf_types;
array[1..num_vnf_links,1..2] of int: vnf_links;
array[1..num_vnf_links] of int: vnf_link_weight; 
array[1..num_vnfs, 1..8] of int: vnfs; % vnf nodes
array[1..num_domains] of 0..1: domain_activated; % domains where lie the source vnf and target vnf
array[1..3] of int: params; % conf params specifying which services are needed (WANA, SHAPER, DPI ...)

var int: path_length;
% source node 
1..num_vnfs: s;

% target node 
1..num_vnfs: t;

% vnf_links_selection[i,j] = 1 means that edge (i,j) belong to shortest path;
% vnf_links_selection[i,j] = 0 means that edge (i,j) does not belong to shortest path;
array[1..num_vnf_links] of var 0..1: vnf_links_selection;
array[1..num_domains] of var 0..1: domain_wana;

constraint path_length = sum(i in 1..num_vnf_links)( vnf_links_selection[i] );

constraint  path_length < 100;
% conservation conditions for unity flow from s to t; every feasible, solution is a path from s to t
constraint 
  forall(i in 1..num_vnfs) (
         sum(k in 1..num_vnf_links where vnf_links[k,2] = i) (vnf_links_selection[k]) + (if i = s then 1 else 0 endif)
    = 
         sum(k in 1..num_vnf_links where vnf_links[k,1] = i) (vnf_links_selection[k]) + (if i = t then 1 else 0 endif)
  );

% simmetry breaking
constraint 
  forall(i in 1..num_vnf_links) (
    forall(j in 1..num_vnf_links where i != j /\ vnf_links[i,2] = vnf_links[j,1] /\ vnf_links[i,1] = vnf_links[j,2]) (
       not (vnf_links_selection[i]=1 /\ vnf_links_selection[j]=1)
    )
  );


% capacity constraint , todo, missing attributes for capacity
% constraint 
%   forall(i in 1..num_vnf_links where vnf_links_selection[i] = 1)(vnfs[vnf_links[i,1],x] /\ /\);

% WANA check and 
constraint
  if sum(i in 1..num_domains where domain_activated[i] = 1) (
    if exists (j in 1..num_vnfs where vnfs[j,8] = i)( vnfs[j,5] = 1)then 
      1 
    else 
      0 
    endif
  ) = 2 /\ params[2] = 1 then
    forall(i in 1..num_domains where domain_activated[i] = 1 )(
      exists ( j in 1..num_vnfs where vnfs[j,8] = i /\ vnfs[j,5] = 1)
      (path_member(vnf_links_selection,vnf_links,j))
    )
  else 
      true
  endif;


% ensure that a VNF is presented in the path
predicate path_member(array [int] of var int: link_sel, array [int,int] of var int: vnf_links, int: y) =
  exists ( i in index_set(link_sel) ) (link_sel[i]==1 /\ (vnf_links[i,1]==y \/ vnf_links[i,2]==y) );

% DPI
constraint % todo: condition needed
  if params[1] = 1 then
    forall(j in 1..num_vnfs where domain_activated[vnfs[j,8]] = 1 /\ vnfs[j,3] = 1)(
      path_member(vnf_links_selection,vnf_links,j)
    )
  else
    true
  endif;

% WANA
% constraint % todo: condition needed 
%   forall(i in 1..num_domains where domain_activated[i] = 1)(
%     exists ( j in 1..num_vnfs where vnfs[j,8] = i /\ vnfs[j,5] = 1)
%     (path_member(vnf_links_selection,vnf_links,j))
%   );

% constraint % todo: condition needed 
%   forall(i in 1..num_domains where domain_activated[i] = 1)(
%     forall ( j in 1..num_vnfs where vnfs[j,8] = i)
%     (path_member(vnf_links_selection,vnf_links,j))
%   );


% Tong: example, an edge 2->4 must be included. 
% constraint edge_selection[4] = 1;


% objetive
var int: cost = sum(i in 1..num_vnf_links) (vnf_link_weight[i] * vnf_links_selection[i]);

solve minimize cost;

output
[
  "edge seletion: " ++ show(vnf_links_selection) ++ "\n" ++
  "cost: " ++ show(cost) ++ "\n" ++
  "domain: "++ show(params)  ++ "\n" 
];


% output ["Length: ", show(sum(e in vnf_links)(1 * vnf_links_selection[e])), "\n"] ++
%        ["Start : ", show(s), "\n"] ++
%        ["End   : ", show(t), "\n\n"] ++
%        ["Edges in shortest path:\n"] ++
%        [ if   fix(vnf_links_selection[e]) = 1
%          then show(vnf_links[e,1]) ++ " -> " ++ show(vnf_links[e,2]) ++ "\n" 
%          else "" 
%          endif | e in vnf_links
%        ];

% """""""""""""""""""""""""""""""""
% INSTANCE DATA
% """""""""""""""""""""""""""""""""

s = 1;
t = 10;


num_domains = 3;
% num_vnfs = 10;
num_vnfs = 10;
num_domain_links = 3;
num_vnf_links = 90;
num_vnftypes = 10;


% % 1:dpi, 2:wanna, 3:shaper
params =  [1,1,0];

% % 1:id, 2:sdn enabled, 3:capacity
domains =  array2d(1..num_domains, 1..3, [
       1, 1, 6,
       2, 1, 8, 
       3, 1, 10
]);

domain_activated = [
              1,
              0,
              1
              ];

% % 1: start, 2: target, 3: weight, 4:availability
domain_links =  array2d(1..num_domain_links, 1..4, [
       1, 2, 2, 1,
       1, 3, 3, 1, 
       2, 3, 2, 1
]);


% % 1 ID(nat), 2 Type(nat), 3 Terminating(bool, DPI), 4 Path Sense(bool), 
% % 5 Mirrored(bool, WANA), 6 Weight(Nat), 7 Active(bool), 8 domain_id
vnfs =  array2d(1..num_vnfs, 1..8, [
       1, 3, 0, 0, 0, 0, 1, 1,
       2, 7, 0, 1, 1, 1, 1, 1,
       3, 6, 0, 0, 0, 2, 1, 1,
       4, 7, 0, 1, 1, 1, 1, 2,
       5, 5, 1, 0, 0, 1, 1, 2,
       6, 5, 1, 0, 0, 2, 1, 2,
       7, 7, 0, 1, 1, 1, 1, 3,
       8, 5, 1, 0, 0, 2, 1, 3,
       9, 6, 0, 0, 0, 1, 1, 3,
      10, 3, 0, 0, 0, 0, 1, 3
]);

vnf_types =  [
              1, % black
              2, % brown
              3, % red
              4, % orange
              5, % yellow
              6, % green
              7, % blue
              8, % purple
              9, % gray
              10 % white
              ];

% %
vnf_links = array2d(1..num_vnf_links, 1..2, [
       1, 2, % 1 
       1, 3, % 2
       1, 4, % 3  
       1, 5, % 4
       1, 6, % 5
       1, 7, % 6
       1, 8, % 7
       1, 9, % 8
       1, 10, % 9
       2, 1, % 1 
       2, 3, % 2
       2, 4, % 3 
       2, 5, % 4
       2, 6, % 5
       2, 7, % 6
       2, 8, % 7
       2, 9, % 8
       2, 10, % 9
       3, 1, % 1 
       3, 2, % 2
       3, 4, % 3 
       3, 5, % 4
       3, 6, % 5
       3, 7, % 6
       3, 8, % 7
       3, 9, % 8
       3, 10, % 9
       4, 1, % 1 
       4, 2, % 2
       4, 3, % 3 
       4, 5, % 4
       4, 6, % 5
       4, 7, % 6
       4, 8, % 7
       4, 9, % 8
       4, 10, % 9
       5, 1, % 1 
       5, 2, % 2
       5, 3,
       5, 4, % 3 
       5, 6, % 5
       5, 7, % 6
       5, 8, % 7
       5, 9, % 8
       5, 10, % 9
       6, 1, % 1
       6, 2, 
       6, 3, % 2
       6, 4, % 3 
       6, 5, % 4
       6, 7, % 6
       6, 8, % 7
       6, 9, % 8
       6, 10, % 9
       7, 1, % 1 
       7, 2,
       7, 3, % 2
       7, 4, % 3 
       7, 5, % 4
       7, 6, % 5
       7, 8, % 7
       7, 9, % 8
       7, 10, % 9
       8, 1, % 1 
       8, 2, % 2
       8, 3, % 3 
       8, 4,
       8, 5, % 4
       8, 6, % 5
       8, 7, % 6
       8, 9, % 8
       8, 10, % 9
       9, 1, % 1
       9, 2, 
       9, 3, % 2
       9, 4, % 3 
       9, 5, % 4
       9, 6, % 5
       9, 7, % 6
       9, 8, % 7
       9, 10, % 9
      10, 1, % 1 
      10, 2,
      10, 3, % 2
      10, 4, % 3 
      10, 5, % 4
      10, 6, % 5
      10, 7, % 6
      10, 8, % 7
      10, 9
]);
% % vnf_link_weight = [0, 0, 2, 2, 2, 3, 3, 3, 3, % 1
% %           0, 0, 2, 2, 2, 3, 3, 3, 3, % 2
% %           0, 0, 2, 2, 2, 3, 3, 3, 3, % 3
% %           2, 2, 2, 0, 0, 2, 2, 2, 2, % 4
% %           2, 2, 2, 0, 0, 2, 2, 2, 2, % 5
% %           2, 2, 2, 0, 0, 2, 2, 2, 2, % 6
% %           3, 3, 3, 2, 2, 2, 0, 0, 0, % 7
% %           3, 3, 3, 2, 2, 2, 0, 0, 0, % 8
% %           3, 3, 3, 2, 2, 2, 0, 0, 0, % 9
% %           3, 3, 3, 2, 2, 2, 0, 0, 0  % 10
% %           ];

vnf_link_weight = [1, 1, 3, 3, 3, 4, 4, 4, 4, % 1
          1, 1, 3, 3, 3, 4, 4, 4, 4, % 2
          1, 1, 3, 3, 3, 4, 4, 4, 4, % 3
          3, 3, 3, 1, 1, 3, 3, 3, 3, % 4
          3, 3, 3, 1, 1, 3, 3, 3, 3, % 5
          3, 3, 3, 1, 1, 3, 3, 3, 3, % 6
          4, 4, 4, 3, 3, 3, 1, 1, 1, % 7
          4, 4, 4, 3, 3, 3, 1, 1, 1, % 8
          4, 4, 4, 3, 3, 3, 1, 1, 1, % 9
          4, 4, 4, 3, 3, 3, 1, 1, 1  % 10
          ];


