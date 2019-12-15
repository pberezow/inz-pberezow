$offDigit
Sets
    d    demand    / d1, d2, d3, d4, d5, d6, d7 /
    s    supply    / s1, s2, s3, s4, s5, s6, s7 / ;
Parameters
    demand(d)    demand in point d    / d1  20.0, d2  20.0, d3  20.0, d4  23.0, d5  26.0, d6  25.0, d7  26.0 /
    supply(s)    supply in point s    / s1  27.0, s2  28.0, s3  25.0, s4  20.0, s5  20.0, s6  20.0, s7  20.0 /
    setupCostMatrix(d, s)    / d1 .s1  15.0, d1 .s2  41.0, d1 .s3  130.0, d1 .s4  60.0, d1 .s5  13.0, d1 .s6  87.0, d1 .s7  0.0, d2 .s1  201.0, d2 .s2  10.0, d2 .s3  127.0, d2 .s4  54.0, d2 .s5  671.0, d2 .s6  100.0, d2 .s7  48.0, d3 .s1  505.0, d3 .s2  1.0, d3 .s3  0.0, d3 .s4  610.0, d3 .s5  9.0, d3 .s6  17.0, d3 .s7  55.0, d4 .s1  12.0, d4 .s2  154.0, d4 .s3  6.0, d4 .s4  100.0, d4 .s5  17.0, d4 .s6  1000.0, d4 .s7  1.0, d5 .s1  9.0, d5 .s2  62.0, d5 .s3  8.0, d5 .s4  17.0, d5 .s5  120.0, d5 .s6  4.0, d5 .s7  42.0, d6 .s1  17.0, d6 .s2  0.0, d6 .s3  167.0, d6 .s4  1000.0, d6 .s5  57.0, d6 .s6  10.0, d6 .s7  5.0, d7 .s1  10.0, d7 .s2  18.0, d7 .s3  205.0, d7 .s4  38.0, d7 .s5  4.0, d7 .s6  305.0, d7 .s7  100.0 /
    costMatrix(d, s)    / d1 .s1  0.0, d1 .s2  21.0, d1 .s3  50.0, d1 .s4  62.0, d1 .s5  93.0, d1 .s6  77.0, d1 .s7  1000.0, d2 .s1  21.0, d2 .s2  0.0, d2 .s3  17.0, d2 .s4  54.0, d2 .s5  67.0, d2 .s6  1000.0, d2 .s7  48.0, d3 .s1  50.0, d3 .s2  17.0, d3 .s3  0.0, d3 .s4  60.0, d3 .s5  98.0, d3 .s6  67.0, d3 .s7  25.0, d4 .s1  62.0, d4 .s2  54.0, d4 .s3  60.0, d4 .s4  0.0, d4 .s5  27.0, d4 .s6  1000.0, d4 .s7  38.0, d5 .s1  93.0, d5 .s2  67.0, d5 .s3  98.0, d5 .s4  27.0, d5 .s5  0.0, d5 .s6  47.0, d5 .s7  42.0, d6 .s1  77.0, d6 .s2  1000.0, d6 .s3  67.0, d6 .s4  1000.0, d6 .s5  47.0, d6 .s6  0.0, d6 .s7  35.0, d7 .s1  1000.0, d7 .s2  48.0, d7 .s3  25.0, d7 .s4  38.0, d7 .s5  42.0, d7 .s6  35.0, d7 .s7  0.0 / ;
Scalar M ; 
M = sum(d, demand(d)) + sum(s, supply(s));
Variables
    x(d, s)    resultMatrix
    y(d, s)    values for setupCost
    result    objective value ;
Positive variables x ;
Binary variables y ;
Equations
    demEq(d)    demand limit for point d
    supEq(s)    supply limit for point s
    setC(d,s)    setup cost eq
    cost    objective function ;
demEq(d) ..    sum(s, x(d,s)) =e= demand(d) ;
supEq(s) ..    sum(d, x(d,s)) =e= supply(s) ;
setC(d,s) ..    x(d,s) =l= y(d,s) * M ;
cost ..    result  =e=  sum((d,s), costMatrix(d,s)*x(d,s)) + sum((d,s), setupCostMatrix(d,s)*y(d,s)) ;
Model transport /all/ ;
Solve transport using MIP minimizing result ;