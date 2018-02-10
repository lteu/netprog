command to launch the script



SOLVE
===

e.g.

1) ``` mzn2fzn -I mznlib model/fg-domain.mzn data/test.dzn -o xxx.fzn ```
2) ``` ./fzn_chuffed.dms xxx.fzn ```

3) copy test.dzn to test-dom.dzn
4) append result 'domain_link_selection = array2d(1..15, 1..15, [1, 0 ...'
to test-dom.dzn

5) ``` mzn2fzn -I mznlib model/fg-vnf.mzn data/test-dom.dzn -o xxx.fzn ```

6) ``` ./fzn_chuffed.dms xxx.fzn ```


DRAW
===

copy 
1) result "link_selection = = array1d(1..796, [0, 0 ..."
2) "vnf_links = [|1..."
3) "vnfs = [|1,0, ..."
to the file rlt.txt, use ';' to separate items

run ``` python draw_frag_network.py ```

Issue
===
In case 'mzn2fzn not found', please do:

1) ``` echo "PATH=$HOME/[mzn_bin_path]" >> ~/.bashrc ```
2) ``` source ~/.bashrc ```