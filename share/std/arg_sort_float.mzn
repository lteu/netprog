include "alldifferent.mzn";

predicate arg_sort_float(array[int] of var float:x,
                         array[int] of var int:p) =
   assert(index_set(p) = 1..length(x),
     "arg_sort_float: second argument must have index 1..length(first argument)",
     alldifferent(p) /\
     forall(j in 1..length(x)-1)
       (x[p[j]] <= x[p[j+1]] /\ (x[p[j]] == x[p[j+1]] -> p[j] < p[j+1]))
   );
