include "globals.mzn"; 
int: m = 3;
int: n = 5;
array[1..m,1..n] of int: diffs = [|14,18,24,30,13
                                  |10,12,18,24,7
                                  | 8,7,12,18,6|];

% decision variables
array[1..m] of var 1..n: x; % which row to select
var int: z; % difference between the selected and smallest values

solve minimize z;
% solve satisfy;

% constraint 1: at_most 2 of the same column can be selected
constraint
  % at most two rows can have the same column
  forall(j in 1..n) (
    at_most(2,x,j)
  )
; 

% constraint 2: calculate the least difference
constraint
  % get smallest difference to the smallest value
  z = sum(i in 1..m) (
       % value of selected column - the smallest value of the row
       diffs[i,x[i]]-min([diffs[i,j] | j in 1..n]) 
  )
  % /\ % for solve satisfy
  % z = 1
  ;

  output [
    "z: \(z)\n",
    "x: \(x)  values:\([diffs[i,x[i]] | i in 1..m])\n"
  ];