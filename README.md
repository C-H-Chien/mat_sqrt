# hardware implementation of a matrix square root
square root of a matrix using verilog FPGA

Author     : Chiang-Heng Chien

Dates      : Sep. 25th, 2018

Version    : 2.0

MATLAB Files:

a. Software: MATLAB R2018a

Verilog Files:

a. Plateform  : Altera DE2i-150 FPGA board

b. Simulation : Altera Modelsim

c. Software   : Quartus 13.0sp1

This repository is responsible for implementing matrix square root in hardware platform
using finite state machines.


To verify the results performed by the hardware, a MATLAB code is employed, as can be seen in 【Matrix_Square_Root.m】


Two iterative methods are concerned including:
1. 【Mat_SQRT_Meini.v】: Meini's method, which is based on cyclic reduction algorithm (CR).
2. 【Mat_SQRT_DB.v】: Denman and Beavers (DB) method, which is based on matrix sign function iteration.

reference can be referred to: B. Iannazzo, "A note on computing the matrix square root," Calcolo, Vol. 40, No. 4, pp. 273-283, 2003.
