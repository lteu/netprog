%
% This script shows an example to regulate network traffic with CP.
% each node should handle inbound and outbound traffic,
% the difference btw in/out should satisfy the balance constraint,
% in the same time, it minimizes the overall edge cost.
%
% Tong
%
% Original version and explanation : 
% https://github.com/radsz/jacop/blob/master/src/main/java/org/jacop/examples/minizinc/transportation.mzn
% Original Author: Krzysztof Kuchcinski
% 



int: n = 10;   % number of nodes
int: m = 13;  % number of edges

array[1..m, 1..2] of int: edge =[| 1, 2 |
                              1, 3 |
                  1, 4 |
                  2, 5 |
                  2, 6 |
                  3, 5 |
                  3, 6 |
                  3, 7 |
                  4, 6 |
                  4, 7 |
                  5, 8 |
                  6, 9 |
                  7, 10
                             |];
array[1..m] of var 0..5 : flow;
array[1..m] of int: weight = [ 0, 0, 0, 3, 1, 4, 2, 4, 3, 3, 0, 0, 0];
array[1..n] of int: node_balance = [9, 0, 0, 0, 0, 0, 0, -3, -3, -3];

var int: cost;

/** @group globals
  Defines a network flow constraint with cost.
  
@param edge: a directed edge of the flow network. edge \p i connects node \a edge[\p i,1] to node \a edge[\p i,2].
@param balance: the difference between input and output flow for each node.
@param weight: the unit cost of the flow through the edge.
@param flow: the flow going through each edge.
@param cost: the overall cost of the flow.
ref. https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/network_flow.mzn
*/
predicate network_flow_cost(array[int,1..2] of int: edge, 
            array[int] of int: balance,
            array[int] of int: weight,
            array[int] of var int: flow, var int: cost) = 

    let { int: source_node = 1;
          int: sink_node = 2;
          set of int: edgeS = index_set_1of2(edge);
          set of int: NODES = index_set(balance);
    } in
    assert (
     edgeS == index_set(flow) /\
     edgeS == index_set(weight) /\
     lb_array(edge) >= min(NODES) /\ 
     ub_array(edge) <= max(NODES),
     "network_flow: wrong sizes of input array parameters",

     cost = sum(i in edgeS) (flow[i] * weight[i]) 
     /\
     forall (i in NODES) (
        sum (j in edgeS where i == edge[j,source_node]) (flow[j]) - 
        sum (j in edgeS where i == edge[j,sink_node]) (flow[j])
        = balance[i] 
     )
  );



constraint
    flow[2] <= 3 /\ flow[3] <= 3 /\
    flow[11] = 3 /\ flow[12] = 3 /\ flow[13] = 3 /\
    network_flow_cost(edge, node_balance, weight, flow, cost);

solve minimize cost;

output(["Flow on edges\n"]++
[show(flow)] ++
["cost = "++show(cost)++"\n"])