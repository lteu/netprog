## SOLVE

e.g.

1) ``` mzn2fzn -I mznlib model/unique.mzn example/map2.dzn example/request6.dzn -o xxx.fzn ```
2) ``` ./fzn_chuffed.dms xxx.fzn ```


## DRAW

copy the following to 'rlt.txt' separate items by ';'
1) result "link_selection = = array1d(1..796, [0, 0 ..."
2) "vnf_links = [|1..."
3) "vnfs = [|1,0, ..."

run ``` python draw_frag_network.py ```

## Issue

In case 'mzn2fzn not found', please do:

1) ``` echo "PATH=$HOME/[mzn_bin_path]" >> ~/.bashrc ```
2) ``` source ~/.bashrc ```
