Service Function Chain with Constraint Programming
====

Given a set of VNF with their related domains, the aim of
our system is to find a Function Chain that starts from the 
source domain and ends in the target domain including requested VNFs,
while respecting VNF properties.

## Requirements
- [MiniZinc](http://www.minizinc.org/software.html)
- Efficient Solver, e.g., [Chuffed](https://github.com/geoffchu/chuffed)

N.B. the binary ./fzn_chuffed.dms is compatible only with Mac OS, please substitute it if needed, check [Chuffed](https://github.com/geoffchu/chuffed/tree/master/binary) for your suitable one.

## Instance Generation

### Generate an example

```
netprog/gen$: python crt_map.py

netprog/gen$: python crt_reqs.py

```
This will create VNF network topology and simulated requests respectively.
The created files are located at netprog/data-exp/test.dzn, netprog/data-exp/requests/request1.dzn ... 


### Automatically generate a testbed

You can personalize main.py or main2.py, which use the previous two scripts, to generate sets of experiments.
```
netprog/gen$: python main.py
```


## Run

### run the example
```
netprog$: python test.py
```

### run experiments with instances in the testbed
```
netprog/run$: python chuffed.py
```


## More
check [cmd.md](https://github.com/lteu/netprog/blob/master/cmd.md) for basic usage and graphic visualization 


## Tech References


- [Shortest_path](https://github.com/MiniZinc/minizinc-benchmarks/tree/master/shortest_path)

- [Shortest_path Matrix](https://raw.githubusercontent.com/hakank/hakank/master/minizinc/shortest_path_model.mzn)


- [Shortest Path Problem](https://github.com/hakank/hakank/blob/master/minizinc/spp.mzn)

- [Netflow from std lib](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/network_flow.mzn)

- [Mzn Global Constraints](http://www.minizinc.org/doc-lib/doc-globals.html)

- [Transportation, flow balance control](https://github.com/radsz/jacop/blob/master/src/main/java/org/jacop/examples/minizinc/transportation.mzn)