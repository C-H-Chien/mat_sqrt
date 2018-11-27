/*
This module is responsible for deriving the square root of a matrix
using Denman and Beavers (DB) method based on matrix sign function iteration.
*/

module Mat_SQRT_DB(
	input						iclk,
	input						ireset,
	input 					i_en,
	input  signed [32:0] i_mat00, i_mat01, i_mat02,
	input  signed [32:0] i_mat10, i_mat11, i_mat12,
	input  signed [32:0] i_mat20, i_mat21, i_mat22,
	output signed [32:0] o_mat00, o_mat01, o_mat02,
	output signed [32:0] o_mat10, o_mat11, o_mat12,
	output signed [32:0] o_mat20, o_mat21, o_mat22,
	output o_Dval
);

//set parameters
parameter iter = 4;			//number of iterations
parameter func_of_inv = 0; //used for matrix inversion module : 1 = adj , 0 = inv

//state machine and number of iterations
reg [2:0] state;
reg [3:0] iter_num;

//register of a counter for counting number of clocks
reg [2:0] clk_counter;

//identity matrix
reg signed [32:0] eye00, eye01, eye02;
reg signed [32:0] eye10, eye11, eye12;
reg signed [32:0] eye20, eye21, eye22;

//registers of the matrix Y_k
reg signed [32:0] Y_k00, Y_k01, Y_k02;
reg signed [32:0] Y_k10, Y_k11, Y_k12;
reg signed [32:0] Y_k20, Y_k21, Y_k22;

//registers of the matrix Z_k
reg signed [32:0] Z_k00, Z_k01, Z_k02;
reg signed [32:0] Z_k10, Z_k11, Z_k12;
reg signed [32:0] Z_k20, Z_k21, Z_k22;

//registers of the matrix Y_k_hat
reg signed [32:0] Y_k_hat00, Y_k_hat01, Y_k_hat02;
reg signed [32:0] Y_k_hat10, Y_k_hat11, Y_k_hat12;
reg signed [32:0] Y_k_hat20, Y_k_hat21, Y_k_hat22;

//registers of the matrix Z_k_hat
reg signed [32:0] Z_k_hat00, Z_k_hat01, Z_k_hat02;
reg signed [32:0] Z_k_hat10, Z_k_hat11, Z_k_hat12;
reg signed [32:0] Z_k_hat20, Z_k_hat21, Z_k_hat22;

//registers for inverse matrix inv(Z_k)
reg signed [32:0] regInvZ_k_00, regInvZ_k_01, regInvZ_k_02;
reg signed [32:0] regInvZ_k_10, regInvZ_k_11, regInvZ_k_12;
reg signed [32:0] regInvZ_k_20, regInvZ_k_21, regInvZ_k_22;

//registers for inverse matrix inv(Y_k)
reg signed [32:0] regInvY_k_00, regInvY_k_01, regInvY_k_02;
reg signed [32:0] regInvY_k_10, regInvY_k_11, regInvY_k_12;
reg signed [32:0] regInvY_k_20, regInvY_k_21, regInvY_k_22;

//wires of inversion of matrix Y_k (outputs of module "InvMat inv_Y")
wire signed [32:0] invY_k00, invY_k01, invY_k02;
wire signed [32:0] invY_k10, invY_k11, invY_k12;
wire signed [32:0] invY_k20, invY_k21, invY_k22;

//wires of inversion of matrix Z_k (outputs of module "InvMat inv_Z")
wire signed [32:0] invZ_k00, invZ_k01, invZ_k02;
wire signed [32:0] invZ_k10, invZ_k11, invZ_k12;
wire signed [32:0] invZ_k20, invZ_k21, invZ_k22;

//registers of enable signals
reg en_inv_Zk;
reg en_inv_Yk;

//registers of data valid signals
reg invMat_Dval_Yk, invMat_Dval_Zk;
reg o_valid;

//wires of data valid signals
wire Dval_invMat_Yk;
wire Dval_invMat_Zk;

reg signed [32:0] reg_mat_det;
wire signed [32:0] mat_det;

always @ (posedge iclk or negedge ireset) begin
	if (!ireset) begin
		//initialize state and number of iterations
		state <= 3'b000;
		iter_num <= 4'b0000;
		
		o_valid <= 1'b0;
		clk_counter <= 0;
		
		//initialize the identity matrix
		eye00 <= 16'h40; //dec = 1 * 64
		eye11 <= 16'h40; //dec = 1 * 64
		eye22 <= 16'h40; //dec = 1 * 64
		eye01 <= 16'h0;
		eye02 <= 16'h0;
		eye10 <= 16'h0;
		eye12 <= 16'h0;
		eye20 <= 16'h0;
		eye21 <= 16'h0;
		
		//initialize enable signals
		en_inv_Zk <= 1'b0;
		en_inv_Yk <= 1'b0;
		invMat_Dval_Yk <= 1'b0; //data valid signal from "InvMat inv_Y"
		invMat_Dval_Zk <= 1'b0; //data valid signal from "InvMat inv_Z"
	end
	else if (i_en) begin
		case (state)
			3'b000 : begin
							//initialize the Y_k matrix
							Y_k00 <= i_mat00;
							Y_k01 <= i_mat01;
							Y_k02 <= i_mat02;
							Y_k10 <= i_mat10;
							Y_k11 <= i_mat11;
							Y_k12 <= i_mat12;
							Y_k20 <= i_mat20;
							Y_k21 <= i_mat21;
							Y_k22 <= i_mat22;
							
							//initialize the Z_k matrix
							Z_k00 <= eye00;
							Z_k01 <= eye01;
							Z_k02 <= eye02;
							Z_k10 <= eye10;
							Z_k11 <= eye11;
							Z_k12 <= eye12;
							Z_k20 <= eye20;
							Z_k21 <= eye21;
							Z_k22 <= eye22;
							
							state <= 3'b001;
						end
			3'b001 : begin
							if (iter_num < iter) begin
								//enable inverses of Y_k and Z_k matrices (both can be derived independently)
								en_inv_Yk <= 1'b1;
								en_inv_Zk <= 1'b1;
								
								invMat_Dval_Yk <= Dval_invMat_Yk;
								invMat_Dval_Zk <= Dval_invMat_Zk;

								if(invMat_Dval_Yk && invMat_Dval_Zk) begin
									//inactivate modules of matrix inversion
									en_inv_Yk <= 1'b0;
									en_inv_Zk <= 1'b0;
									invMat_Dval_Yk <= 1'b0;
									invMat_Dval_Zk <= 1'b0;
									
									//change to the next state
									state <= 3'b010;
									
									//assign Z_k matrix inversion wire value to registers
									regInvZ_k_00 <= invZ_k00;
									regInvZ_k_01 <= invZ_k01;
									regInvZ_k_02 <= invZ_k02;
									regInvZ_k_10 <= invZ_k10;
									regInvZ_k_11 <= invZ_k11;
									regInvZ_k_12 <= invZ_k12;
									regInvZ_k_20 <= invZ_k20;
									regInvZ_k_21 <= invZ_k21;
									regInvZ_k_22 <= invZ_k22;
								 
									//assign Y_k matrix inversion wire value to registers
									regInvY_k_00 <= invY_k00;
									regInvY_k_01 <= invY_k01;
									regInvY_k_02 <= invY_k02;
									regInvY_k_10 <= invY_k10;
									regInvY_k_11 <= invY_k11;
									regInvY_k_12 <= invY_k12;
									regInvY_k_20 <= invY_k20;
									regInvY_k_21 <= invY_k21;
									regInvY_k_22 <= invY_k22;
								end
							end
							else begin
								state <= 3'b101;
							end
					   end
			3'b010 : begin
							//compute Y_k_hat and Z_k_hat
							Y_k_hat00 <= (Y_k00 + regInvZ_k_00)>>>1;
							Y_k_hat01 <= (Y_k01 + regInvZ_k_01)>>>1;
							Y_k_hat02 <= (Y_k02 + regInvZ_k_02)>>>1;
							Y_k_hat10 <= (Y_k10 + regInvZ_k_10)>>>1;
							Y_k_hat11 <= (Y_k11 + regInvZ_k_11)>>>1;
							Y_k_hat12 <= (Y_k12 + regInvZ_k_12)>>>1;
							Y_k_hat20 <= (Y_k20 + regInvZ_k_20)>>>1;
							Y_k_hat21 <= (Y_k21 + regInvZ_k_21)>>>1;
							Y_k_hat22 <= (Y_k22 + regInvZ_k_22)>>>1;
						   
							Z_k_hat00 <= (Z_k00 + regInvY_k_00)>>>1;
							Z_k_hat01 <= (Z_k01 + regInvY_k_01)>>>1;
							Z_k_hat02 <= (Z_k02 + regInvY_k_02)>>>1;
							Z_k_hat10 <= (Z_k10 + regInvY_k_10)>>>1;
							Z_k_hat11 <= (Z_k11 + regInvY_k_11)>>>1;
							Z_k_hat12 <= (Z_k12 + regInvY_k_12)>>>1;
							Z_k_hat20 <= (Z_k20 + regInvY_k_20)>>>1;
							Z_k_hat21 <= (Z_k21 + regInvY_k_21)>>>1;
							Z_k_hat22 <= (Z_k22 + regInvY_k_22)>>>1;
						   
							//wait for 2 clocks
							if(clk_counter < 2) begin
								clk_counter <= clk_counter + 1;
							end
							else begin
								clk_counter <= 3'b000;
								//change to the next state
								state <= 3'b011;
							end
					   end
			3'b011 : begin
							//assign Y_k with Y_k_hat and Z_k with Z_k_hat, respectively
							Y_k00 <= Y_k_hat00;
						   Y_k01 <= Y_k_hat01;
							Y_k02 <= Y_k_hat02;
							Y_k10 <= Y_k_hat10;
							Y_k11 <= Y_k_hat11;
							Y_k12 <= Y_k_hat12;
							Y_k20 <= Y_k_hat20;
							Y_k21 <= Y_k_hat21;
							Y_k22 <= Y_k_hat22;
							
							Z_k00 <= Z_k_hat00;
						   Z_k01 <= Z_k_hat01;
							Z_k02 <= Z_k_hat02;
							Z_k10 <= Z_k_hat10;
							Z_k11 <= Z_k_hat11;
							Z_k12 <= Z_k_hat12;
							Z_k20 <= Z_k_hat20;
							Z_k21 <= Z_k_hat21;
							Z_k22 <= Z_k_hat22;

							state <= 3'b100;
					   end
			3'b100 : begin
							iter_num <= iter_num + 1;
							state <= 3'b001;
					   end
			3'b101 : begin
							iter_num <= 0;
							o_valid <= 1'b1;
						end
		endcase
	end
end

InvMat inv_Z( .iclk(iclk), .irst_n(ireset), .i_en(en_inv_Yk), .adj_or_inv(func_of_inv),
				  .i_mat00(Z_k00), .i_mat01(Z_k01), .i_mat02(Z_k02),
				  .i_mat10(Z_k10), .i_mat11(Z_k11), .i_mat12(Z_k12),
				  .i_mat20(Z_k20), .i_mat21(Z_k21), .i_mat22(Z_k22),
				  .invMat_11(invZ_k00), .invMat_12(invZ_k01), .invMat_13(invZ_k02),
				  .invMat_21(invZ_k10), .invMat_22(invZ_k11), .invMat_23(invZ_k12),
				  .invMat_31(invZ_k20), .invMat_32(invZ_k21), .invMat_33(invZ_k22),
				  .o_det(mat_det), .oDval(Dval_invMat_Zk)
);

InvMat inv_Y( .iclk(iclk), .irst_n(ireset), .i_en(en_inv_Zk), .adj_or_inv(func_of_inv),
				  .i_mat00(Y_k00), .i_mat01(Y_k01), .i_mat02(Y_k02),
				  .i_mat10(Y_k10), .i_mat11(Y_k11), .i_mat12(Y_k12),
				  .i_mat20(Y_k20), .i_mat21(Y_k21), .i_mat22(Y_k22),
				  .invMat_11(invY_k00), .invMat_12(invY_k01), .invMat_13(invY_k02),
				  .invMat_21(invY_k10), .invMat_22(invY_k11), .invMat_23(invY_k12),
				  .invMat_31(invY_k20), .invMat_32(invY_k21), .invMat_33(invY_k22),
				  .o_det(mat_det), .oDval(Dval_invMat_Yk)
);

assign o_mat00 = Y_k00;
assign o_mat01 = Y_k01;
assign o_mat02 = Y_k02;
assign o_mat10 = Y_k10;
assign o_mat11 = Y_k11;
assign o_mat12 = Y_k12;
assign o_mat20 = Y_k20;
assign o_mat21 = Y_k21;
assign o_mat22 = Y_k22;
assign o_Dval = o_valid;

endmodule