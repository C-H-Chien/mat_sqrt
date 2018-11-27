module Mat_SQRT(
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

//set the number of iterations
parameter iter = 2;
parameter zoom = 6;
parameter func_of_inv = 0; //1 = adj , 0 = inv

//registry the input data
reg signed [32:0] A_t_A_00, A_t_A_01, A_t_A_02;
reg signed [32:0] A_t_A_10, A_t_A_11, A_t_A_12;
reg signed [32:0] A_t_A_20, A_t_A_21, A_t_A_22;

//identity matrix
reg signed [32:0] eye00, eye01, eye02;
reg signed [32:0] eye10, eye11, eye12;
reg signed [32:0] eye20, eye21, eye22;

//the matrix M_k
reg signed [32:0] M_k00, M_k01, M_k02;
reg signed [32:0] M_k10, M_k11, M_k12;
reg signed [32:0] M_k20, M_k21, M_k22;

//registry for M_k and N_k
reg signed [32:0] regM_k00, regM_k01, regM_k02;
reg signed [32:0] regM_k10, regM_k11, regM_k12;
reg signed [32:0] regM_k20, regM_k21, regM_k22;
reg signed [32:0] regN_k00, regN_k01, regN_k02;
reg signed [32:0] regN_k10, regN_k11, regN_k12;
reg signed [32:0] regN_k20, regN_k21, regN_k22;

//registry for N_k_h
reg signed [32:0] regN_k_h00, regN_k_h01, regN_k_h02;
reg signed [32:0] regN_k_h10, regN_k_h11, regN_k_h12;
reg signed [32:0] regN_k_h20, regN_k_h21, regN_k_h22;

wire signed [32:0] invM_k00, invM_k01, invM_k02;
wire signed [32:0] invM_k10, invM_k11, invM_k12;
wire signed [32:0] invM_k20, invM_k21, invM_k22;

wire signed [32:0] matmul00, matmul01, matmul02;
wire signed [32:0] matmul10, matmul11, matmul12;
wire signed [32:0] matmul20, matmul21, matmul22;

wire signed [32:0] N_k_h00, N_k_h01, N_k_h02;
wire signed [32:0] N_k_h10, N_k_h11, N_k_h12;
wire signed [32:0] N_k_h20, N_k_h21, N_k_h22;

//the matrix N_k
reg signed [32:0] N_k00, N_k01, N_k02;
reg signed [32:0] N_k10, N_k11, N_k12;
reg signed [32:0] N_k20, N_k21, N_k22;

//enable signal and data valid signals
reg en_MatMul, en_inv;
reg invMat_Dval, matmul_Dval, Nkh_Dval;
reg o_valid;

//state machine and number of iterations
reg [2:0] state;
reg [3:0] iter_num;

//data valid signal
reg regDval_matmul;
wire Dval_MatMul;
wire Dval_invMat;
wire Dval_Nkh;

reg signed [32:0] reg_mat_det;
wire signed [32:0] mat_det;

reg [2:0] clk_counter;

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
		en_MatMul <= 1'b0;
		en_inv <= 1'b0;
		invMat_Dval <= 1'b0; //obtain from InvMat inverse
		matmul_Dval <= 1'b0; //obtain from Mat_Mul matmul_1
		Nkh_Dval <= 1'b0;    //obtain from Mat_Mul matmul_2
	end
	else if (i_en) begin
		case (state)
			3'b000 : begin
							//initialize the M_k matrix
							M_k00 <= (eye00 + i_mat00)<<<1;
							M_k01 <= (eye01 + i_mat01)<<<1;
							M_k02 <= (eye02 + i_mat02)<<<1;
							M_k10 <= (eye10 + i_mat10)<<<1;
							M_k11 <= (eye11 + i_mat11)<<<1;
							M_k12 <= (eye12 + i_mat12)<<<1;
							M_k20 <= (eye20 + i_mat20)<<<1;
							M_k21 <= (eye21 + i_mat21)<<<1;
							M_k22 <= (eye22 + i_mat22)<<<1;
							
							//initialize the N_k matrix
							N_k00 <= eye00 - i_mat00;
							N_k01 <= eye01 - i_mat01;
							N_k02 <= eye02 - i_mat02;
							N_k10 <= eye10 - i_mat10;
							N_k11 <= eye11 - i_mat11;
							N_k12 <= eye12 - i_mat12;
							N_k20 <= eye20 - i_mat20;
							N_k21 <= eye21 - i_mat21;
							N_k22 <= eye22 - i_mat22;
							
							//wait for 3 clocks
							if(clk_counter < 4) begin
								clk_counter <= clk_counter + 1;
							end
							else begin
								clk_counter <= 3'b000;
								state <= 3'b001;
							end
						end
			3'b001 : begin
							en_inv <= 1'b1;
							invMat_Dval <= Dval_invMat;
							reg_mat_det <= mat_det;
							matmul_Dval <= Dval_MatMul;
							Nkh_Dval <= Dval_Nkh;
							
							if(Nkh_Dval) begin
								en_inv <= 1'b0;
								invMat_Dval <= 1'b0;
								matmul_Dval <= 1'b0;
								Nkh_Dval <= 1'b0;
								state <= 3'b010;
								iter_num <= iter_num + 1;
								//assign wire value to registers
								regN_k_h00 <= N_k_h00;
								regN_k_h01 <= N_k_h01;
								regN_k_h02 <= N_k_h02;
								regN_k_h10 <= N_k_h10;
								regN_k_h11 <= N_k_h11;
								regN_k_h12 <= N_k_h12;
								regN_k_h20 <= N_k_h20;
								regN_k_h21 <= N_k_h21;
								regN_k_h22 <= N_k_h22;
							 
							end
							if (Nkh_Dval && (iter_num > iter)) begin
								en_inv <= 1'b0;
								invMat_Dval <= 1'b0;
								matmul_Dval <= 1'b0;
								state <= 3'b101;
							end
					   end
			3'b010 : begin
							//add a negative sign to N_k_h
						   regN_k00 <= 16'h0 - regN_k_h00;
						   regN_k01 <= 16'h0 - regN_k_h01;
						   regN_k02 <= 16'h0 - regN_k_h02;
						   regN_k10 <= 16'h0 - regN_k_h10;
						   regN_k11 <= 16'h0 - regN_k_h11;
						   regN_k12 <= 16'h0 - regN_k_h12;
						   regN_k20 <= 16'h0 - regN_k_h20;
						   regN_k21 <= 16'h0 - regN_k_h21;
						   regN_k22 <= 16'h0 - regN_k_h22;
						   state <= 3'b011;
					   end
			3'b011 : begin
//						   regM_k00 <= (reg_mat_det * M_k00)>>>zoom + (regN_k00<<<1);
//						   regM_k01 <= (reg_mat_det * M_k01)>>>zoom + (regN_k01<<<1);
//						   regM_k02 <= (reg_mat_det * M_k02)>>>zoom + (regN_k02<<<1);
//						   regM_k10 <= (reg_mat_det * M_k10)>>>zoom + (regN_k10<<<1);
//						   regM_k11 <= (reg_mat_det * M_k11)>>>zoom + (regN_k11<<<1);
//						   regM_k12 <= (reg_mat_det * M_k12)>>>zoom + (regN_k12<<<1);
//						   regM_k20 <= (reg_mat_det * M_k20)>>>zoom + (regN_k20<<<1);
//						   regM_k21 <= (reg_mat_det * M_k21)>>>zoom + (regN_k21<<<1);
//						   regM_k22 <= (reg_mat_det * M_k22)>>>zoom + (regN_k22<<<1);
							
							regM_k00 <= M_k00 + (regN_k00<<<1);
						   regM_k01 <= M_k01 + (regN_k01<<<1);
						   regM_k02 <= M_k02 + (regN_k02<<<1);
						   regM_k10 <= M_k10 + (regN_k10<<<1);
						   regM_k11 <= M_k11 + (regN_k11<<<1);
						   regM_k12 <= M_k12 + (regN_k12<<<1);
						   regM_k20 <= M_k20 + (regN_k20<<<1);
						   regM_k21 <= M_k21 + (regN_k21<<<1);
						   regM_k22 <= M_k22 + (regN_k22<<<1);
							
							if(clk_counter < 4) begin
								clk_counter <= clk_counter + 1;
							end
							else begin
								clk_counter <= 3'b000;
								state <= 3'b100;
							end
					   end
			3'b100 : begin
							clk_counter <= 0;
//							M_k00 <= (regM_k00<<<zoom) / reg_mat_det;
//							M_k01 <= (regM_k01<<<zoom) / reg_mat_det;
//							M_k02 <= (regM_k02<<<zoom) / reg_mat_det;
//							M_k10 <= (regM_k10<<<zoom) / reg_mat_det;
//							M_k11 <= (regM_k11<<<zoom) / reg_mat_det;
//							M_k12 <= (regM_k12<<<zoom) / reg_mat_det;
//							M_k20 <= (regM_k20<<<zoom) / reg_mat_det;
//							M_k21 <= (regM_k21<<<zoom) / reg_mat_det;
//							M_k22 <= (regM_k22<<<zoom) / reg_mat_det;
//							
//							N_k00 <= (regN_k00<<<zoom) / reg_mat_det;
//							N_k01 <= (regN_k01<<<zoom) / reg_mat_det;
//							N_k02 <= (regN_k02<<<zoom) / reg_mat_det;
//							N_k10 <= (regN_k10<<<zoom) / reg_mat_det;
//							N_k11 <= (regN_k11<<<zoom) / reg_mat_det;
//							N_k12 <= (regN_k12<<<zoom) / reg_mat_det;
//							N_k20 <= (regN_k20<<<zoom) / reg_mat_det;
//							N_k21 <= (regN_k21<<<zoom) / reg_mat_det;
//							N_k22 <= (regN_k22<<<zoom) / reg_mat_det;
							
							M_k00 <= regM_k00;
							M_k01 <= regM_k01;
							M_k02 <= regM_k02;
							M_k10 <= regM_k10;
							M_k11 <= regM_k11;
							M_k12 <= regM_k12;
							M_k20 <= regM_k20;
							M_k21 <= regM_k21;
							M_k22 <= regM_k22;
							
							N_k00 <= regN_k00;
							N_k01 <= regN_k01;
							N_k02 <= regN_k02;
							N_k10 <= regN_k10;
							N_k11 <= regN_k11;
							N_k12 <= regN_k12;
							N_k20 <= regN_k20;
							N_k21 <= regN_k21;
							N_k22 <= regN_k22;
							
							if(clk_counter < 3) begin
								clk_counter <= clk_counter + 1;
							end
							else begin
								clk_counter <= 0;
								//state <= 3'b001;
								state <= 3'b101; //testing
							end
					   end
			3'b101 : begin
							o_valid <= 1'b1;
						end
		endcase
	end
end

InvMat inverse( .iclk(iclk), .irst_n(ireset), .i_en(en_inv), .adj_or_inv(func_of_inv),
					 .i_mat00(M_k00), .i_mat01(M_k01), .i_mat02(M_k02),
					 .i_mat10(M_k10), .i_mat11(M_k11), .i_mat12(M_k12),
					 .i_mat20(M_k20), .i_mat21(M_k21), .i_mat22(M_k22),
					 .invMat_11(invM_k00), .invMat_12(invM_k01), .invMat_13(invM_k02),
					 .invMat_21(invM_k10), .invMat_22(invM_k11), .invMat_23(invM_k12),
					 .invMat_31(invM_k20), .invMat_32(invM_k21), .invMat_33(invM_k22),
					 .o_det(mat_det),
					 .oDval(Dval_invMat)
);

Mat_Mul matmul_1( .iclk(iclk), .ireset(ireset), .ienable(invMat_Dval),
						.i_Mat_1_00(N_k00), .i_Mat_1_01(N_k01), .i_Mat_1_02(N_k02),
						.i_Mat_1_03(N_k10), .i_Mat_1_04(N_k11), .i_Mat_1_05(N_k12),
						.i_Mat_1_06(N_k20), .i_Mat_1_07(N_k21), .i_Mat_1_08(N_k22),
						.i_Mat_2_00(invM_k00), .i_Mat_2_01(invM_k01), .i_Mat_2_02(invM_k02),
						.i_Mat_2_03(invM_k10), .i_Mat_2_04(invM_k11), .i_Mat_2_05(invM_k12),
						.i_Mat_2_06(invM_k20), .i_Mat_2_07(invM_k21), .i_Mat_2_08(invM_k22),
						.o_Mat_00(matmul00), .o_Mat_01(matmul01), .o_Mat_02(matmul02),
						.o_Mat_10(matmul10), .o_Mat_11(matmul11), .o_Mat_12(matmul12),
						.o_Mat_20(matmul20), .o_Mat_21(matmul21), .o_Mat_22(matmul22),
						.MatMul_Dval(Dval_MatMul)
);

Mat_Mul matmul_2( .iclk(iclk), .ireset(ireset), .ienable(matmul_Dval),
						.i_Mat_1_00(matmul00), .i_Mat_1_01(matmul01), .i_Mat_1_02(matmul02),
						.i_Mat_1_03(matmul10), .i_Mat_1_04(matmul11), .i_Mat_1_05(matmul12),
						.i_Mat_1_06(matmul20), .i_Mat_1_07(matmul21), .i_Mat_1_08(matmul22),
						.i_Mat_2_00(N_k00), .i_Mat_2_01(N_k01), .i_Mat_2_02(N_k02),
						.i_Mat_2_03(N_k10), .i_Mat_2_04(N_k11), .i_Mat_2_05(N_k12),
						.i_Mat_2_06(N_k20), .i_Mat_2_07(N_k21), .i_Mat_2_08(N_k22),
						.o_Mat_00(N_k_h00), .o_Mat_01(N_k_h01), .o_Mat_02(N_k_h02),
						.o_Mat_10(N_k_h10), .o_Mat_11(N_k_h11), .o_Mat_12(N_k_h12),
						.o_Mat_20(N_k_h20), .o_Mat_21(N_k_h21), .o_Mat_22(N_k_h22),
						.MatMul_Dval(Dval_Nkh)
);

assign o_mat00 = invM_k00;
assign o_mat01 = invM_k01;
assign o_mat02 = invM_k02;
assign o_mat10 = invM_k10;
assign o_mat11 = invM_k11;
assign o_mat12 = invM_k12;
assign o_mat20 = invM_k20;
assign o_mat21 = invM_k21;
assign o_mat22 = mat_det;
assign o_Dval = o_valid;

endmodule