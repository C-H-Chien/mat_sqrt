# Hardware implementation of a matrix square root
square root of a matrix using verilog FPGA

***Note that this repository has been archived since 2018. Probably no change will be made in the futures***

MATLAB Files:

a. Software: MATLAB R2018a

Verilog Files:

a. Plateform  : Altera DE2i-150 FPGA board

b. Simulation : Altera Modelsim

c. Software   : Quartus 13.0sp1

This repository is responsible for implementing matrix square root in hardware platform using finite state machines.

To verify the results performed by the hardware, a MATLAB code is employed, as can be seen in `Matrix_Square_Root.m`

Two iterative methods are concerned including:
1. 【Mat_SQRT_Meini.v】: Meini's method, which is based on cyclic reduction algorithm (CR).
2. 【Mat_SQRT_DB.v】: Denman and Beavers (DB) method, which is based on matrix sign function iteration.

## References
`Chien, Chiang-Heng, Chiang-Ju Chien, and Chen-Chien Hsu. "HW/SW co-design and FPGA acceleration of a feature-based visual odometry." In 2019 4th International Conference on Robotics and Automation Engineering (ICRAE), pp. 148-152. IEEE, 2019.`

`B. Iannazzo, "A note on computing the matrix square root," Calcolo, Vol. 40, No. 4, pp. 273-283, 2003.`
