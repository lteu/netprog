Service Function Chain with Constraint Programming
====

Given a set of VNF with their related domains, the aim of
our system is to find a Function Chain that starts from the 
source domain and ends in the target domain including requested VNFs,
while respecting VNF properties.

## Requirements
- [MiniZinc](http://www.minizinc.org/software.html)
- Efficient Solver, e.g. [Chuffed](https://github.com/geoffchu/chuffed)

N.B. the binary ./fzn_chuffed.dms is compatible only with Mac OS, please substitute it if needed, check [Chuffed](https://github.com/geoffchu/chuffed/tree/master/binary) for your suitable one.

## Instance Generation

```
netprog/gen$: python crt-map.py

netprog/gen$: python crt-reqs.py

```
This will create VNF network topology and simulated requests respectively.
The created files are located in netprog/data-exp/test.dzn, netprog/data-exp/requests/request1.dzn ... 

## Run on test instances
```
netprog$: python main.py
```

## More
check [cmd.md](https://github.com/lteu/netprog/blob/master/cmd.md) for basic usage and graphic visualization 


Tongs-Air:netprog hear7st$ mzn2fzn model/unique.mzn data-exp/d16n200/map3.dzn data-exp/d16n200/req/request5.dzn -o xxx.fzn
Tongs-Air:netprog hear7st$ ./fzn_chuffed.dms xxx.fzn
Assertion failed: (false), function addClause, file core/sat.c, line 165.
Abort trap: 6
Tongs-Air:netprog hear7st$



## Tech References


- [Shortest_path](https://github.com/MiniZinc/minizinc-benchmarks/tree/master/shortest_path)

- [Shortest_path Matrix](https://raw.githubusercontent.com/hakank/hakank/master/minizinc/shortest_path_model.mzn)


- [Shortest Path Problem](https://github.com/hakank/hakank/blob/master/minizinc/spp.mzn)

- [Netflow from std lib](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/network_flow.mzn)

- [Mzn Global Constraints](http://www.minizinc.org/doc-lib/doc-globals.html)

- [Transportation, flow balance control](https://github.com/radsz/jacop/blob/master/src/main/java/org/jacop/examples/minizinc/transportation.mzn)