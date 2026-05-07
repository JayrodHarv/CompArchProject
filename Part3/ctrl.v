// ECE:3350 SISC computer project
// finite state machine

`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load, mm_sel, dm_we, rb_sel);

	input clk, rst_f;
	input [3:0] opcode, mm, stat;
	output reg rf_we, wb_sel;
	output reg [3:0] alu_op;
	output reg br_sel;
	output pc_rst;
	output reg pc_write;
	output reg pc_sel;
	output reg ir_load;
	output reg mm_sel;
	output reg dm_we;
	output reg rb_sel;

	assign pc_rst = ~rst_f; // pc_rst is the inverse of rst_f
  
	// state parameter declarations
	
	parameter start0 = 0, start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;
	
	// opcode parameter declarations
	
	parameter NOOP = 0, REG_OP = 1, REG_IM = 2, SWAP = 3, BRA = 4, BRR = 5, BNE = 6, BNR = 7;
	parameter JPA = 8, JPR = 9, LOD = 10, STR = 11, CALL = 12, RET = 13, HLT = 15;
		
	// addressing modes
	
	parameter AM_IMM = 8;

	// state register and next state signal
	
	reg [2:0]  present_state, next_state;

	// initial procedure to initialize the present state to 'start0'.

	initial
		present_state = start0;

	/* Procedure that progresses the fsm to the next state on the positive edge of 
		the clock, OR resets the state to 'start1' on the negative edge of rst_f. 
		Notice that the computer is reset when rst_f is low, not high. */

	always @(posedge clk, negedge rst_f)
	begin
		if (rst_f == 1'b0)
			present_state <= start1;
		else
			present_state <= next_state;
	end
	
	/* The following combinational procedure determines the next state of the fsm. */

	always @(present_state, rst_f)
	begin
		case(present_state)
			start0:     next_state = start1;
			start1:     if (rst_f == 1'b0) next_state = start1;
									else next_state = fetch;
			fetch:      next_state = decode;
			decode:     next_state = execute;
			execute:    next_state = mem;
			mem:        next_state = writeback;
			writeback:  next_state = fetch;
			default:    next_state = start1;
		endcase
	end

	always @(present_state, opcode)
	begin

		// Defaults (set everything to zero)
		ir_load  = 0;
		pc_write = 0;
		pc_sel   = 0;
		br_sel   = 0;
		rf_we    = 0;
		alu_op   = 4'b0000;
		wb_sel   = 0;
		mm_sel   = 0;
		dm_we    = 0;
		rb_sel   = 0;

		case (present_state)

			fetch:
			begin
				ir_load  = 1;
				pc_write = 1;
				pc_sel   = 0;
			end

			decode:
			begin
				case (opcode)
					// Branch Instructions
					BRA:
					if (|(mm & stat))
					begin
						pc_sel = 1;
						pc_write = 1;
						br_sel = 1;
					end

					BRR:
					if (|(mm & stat))
					begin
						pc_sel = 1;
						pc_write = 1;
						br_sel = 0;
					end

					BNE:
					if (!(|(mm & stat)))
					begin
						pc_sel = 1;
						pc_write = 1;
						br_sel = 1;
					end

					BNR:
					if (!(|(mm & stat)))
					begin
						pc_sel = 1;
						pc_write = 1;
						br_sel = 0;
					end
					
					default:
					begin
						pc_sel = 0;
						pc_write = 0;
						br_sel = 0;
					end
				endcase
			end

			mem:
			begin
				case (opcode)
					REG_OP:		alu_op = 4'b0000;
					REG_IM:		alu_op = 4'b0010;
					LOD:		mm_sel = mm[3];
					STR:
					begin
						dm_we = 1;
						mm_sel = mm[3];
						rb_sel = 1;
					end
					default:	alu_op = 4'b0000;
				endcase
			end

			execute:
			begin
				case (opcode)
					NOOP:     	alu_op = 4'b0000;
					REG_OP:   	alu_op = 4'b0001;
					REG_IM:   	alu_op = 4'b0011;
					LOD:		alu_op = 4'b0010;
					STR:		alu_op = 4'b0010;
					default:  	alu_op = 4'b0000;
				endcase
			end

			writeback:
			begin
				case (opcode)
					REG_OP,REG_IM:	rf_we = 1'b1;
					LOD:
					begin
						rf_we = 1;
						wb_sel = 1;
					end
					default:
					begin 
						rf_we = 1'b0;
						wb_sel = 1'b0;
						alu_op = 4'b0000;
					end
				endcase
			end
		endcase
	end

	// Halt on HLT instruction
	
	always @ (opcode)
	begin
		if (opcode == HLT)
		begin 
		#5 $display ("Halt."); //Delay 5 ns so $monitor will print the halt instruction
		$stop;
		end
	end
endmodule
