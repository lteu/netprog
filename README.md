Network Programming
====

Applying CP to Intent-Based Management and Orchestration


## launching scripts

```
netprog$: mzn2fzn -I mznlib vnf.mzn -o xxx.fzn

netprog$: ./fzn_chuffed.dms xxx.fzn
```

%
% # Intent-based network programming with Minizinc
% This script, derived from spanning tree model, deals with SDN routing problems.
% 
%
% References:
%
% Cerroni,et al. "Intent-based management and orchestration of heterogeneous openflow/IoT SDN domains." 
% Network Softwarization (NetSoft), 2017 IEEE Conference on. IEEE, 2017.
% 
% Credits: Hakank - shortest path model with adjacency matrix
% https://raw.githubusercontent.com/hakank/hakank/master/minizinc/shortest_path_model.mzn
%


## Tech References


- [Shortest_path](https://github.com/MiniZinc/minizinc-benchmarks/tree/master/shortest_path)

- [Shortest Path Problem](https://github.com/hakank/hakank/blob/master/minizinc/spp.mzn)

- [Netflow from std lib](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/network_flow.mzn)

- [Mzn Global Constraints](http://www.minizinc.org/doc-lib/doc-globals.html)


- [Transportation, flow balance control](https://github.com/radsz/jacop/blob/master/src/main/java/org/jacop/examples/minizinc/transportation.mzn)