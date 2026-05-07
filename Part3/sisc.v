// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns / 100ps

module sisc (
	clk,
	rst_f
);

	input clk, rst_f;

	// ---------------------------------
	// declare all internal wires here
	// ---------------------------------
	wire [3:0] 	alu_op;     // ALU operation code from control unit to ALU
	wire        wb_sel;     // writeback select from control unit to writeback mux
	wire        rf_we;      // register file write enable from control unit to register file
	wire [3:0]  stat_en;	// status register enable from control unit to status register
	wire [3:0]  stat;       // Wire connecting the status register to the control circuit

	wire [31:0] rsa, rsb;   // outputs from register file
	wire [3:0]  cc;         // condition code from alu to status register
	wire [31:0] alu_out;    // output from alu to writeback mux and status register
	wire [31:0] wb_data;    // output from writeback mux to register file

	// ---------------------------------
	// PART 2 WIRES
	// ---------------------------------
	wire [15:0] br_addr;
	wire [15:0] pc_out;
	wire [31:0]	instr_out;
	wire [31:0]	instr;

	// control signals
	wire 		br_sel;
	wire 		pc_rst;
	wire 		pc_write;
	wire 		pc_sel;
	wire		ir_load;

	// ---------------------------------
	// PART 3 WIRES
	// ---------------------------------
	wire [15:0] mux16_out;
	wire 		dm_we;
	wire 		mm_sel;
	wire		rb_sel;
	wire [3:0]  rb;
	wire [31:0] read_data;

	// ---------------------------------
	// instruction decoding
	// ---------------------------------
	wire [3:0]	opcode      = instr[31:28];    	// opcode
	wire [3:0] 	mff			= instr[27:24];		// Mode / Flag Field (Multi-purpose field)
	wire [3:0] 	rd			= instr[23:20];		// Write Register
	wire [3:0] 	rs			= instr[19:16];		// Source Register A
	wire [3:0]	rt			= instr[15:12];		// Source Register B

	wire [3:0] funct		= instr[3:0];		// ALU function code

	wire [15:0]	imm			= instr[15:0];		// Immediate Value
	wire [15:0] target		= instr[15:0];		// Memory Address 	  	

	// ---------------------------------
	// component instantiation goes here
	// ---------------------------------

	// control unit (CTRL)
	ctrl u1 (
		clk,
		rst_f,
		opcode,
		mff,
		stat,
		rf_we,
		alu_op,
		wb_sel,
		br_sel,
		pc_rst,
		pc_write,
		pc_sel,
		ir_load,
		mm_sel,
		dm_we,
		rb_sel
	);

	// register file
	rf u2 (
		clk,
		rs,
		rb,
		rd,
		wb_data,
		rf_we,
		rsa,
		rsb
	);

	// Arithmetic Logic Unit (ALU)
	alu u3 (
		clk,
		rsa,
		rsb,
		imm,
		cc[3],  // carry in from status register
		alu_op,
		mff,
		alu_out,
		cc,
		stat_en
	);

	// writeback mux
	mux32 u5 (
		alu_out,
		read_data,
		wb_sel,
		wb_data
	);

	// status register (STATREG)
	statreg u6 (
		clk,
		cc,
		stat_en,
		stat
	);

	// Branch Address Calculator (BR)
	br u7 (
		pc_out,
		target,
		br_sel,
		br_addr
	);

	// Instruction Memory (IM)
	im u8 (
		pc_out,
		instr_out
	);

	// Instruction Register (IR)
	ir u9 (
		clk,
		ir_load,
		instr_out,
		instr
	);

	// Program Counter (PC)
	pc u10 (
		clk,
		br_addr,
		pc_sel,
		pc_write,
		pc_rst,
		pc_out
	);

	dm u11 (
		mux16_out,
		mux16_out,
		rsb,
		dm_we,
		read_data
	);

	mux4 u12 (
		rt,
		rd,
		rb_sel,
		rb
	);

	mux16 u13 (
		alu_out[15:0], // Might need to be 16 instead of 32 bits
		imm,
		mm_sel,
		mux16_out
	);

	initial begin
		$monitor("Time = %0d IR = %h PC = %h R1 = %h R2 = %h R3 = %h R4 = %h R5 = %h ALU_OP = %h BR_SEL = %b PC_WRITE = %b PC_SEL = %b",
			$time, instr, pc_out, u2.ram_array[1], u2.ram_array[2], u2.ram_array[3], u2.ram_array[4], u2.ram_array[5], alu_op, br_sel, pc_write, pc_sel
		);
//     $monitor(
//         "| Time=%0d | \n\
// | PC=%h | PC_SEL=%b | PC_WRITE=%b | STAT=%b | BR_SEL=%b | BR_ADDR=%h | \n\
// | IR=%h | IR_LOAD=%b | RS=%h | RT=%h | RD=%h | MFF=%b | OPCODE=%b | \n\
// | R1=%h | R2=%h | R3=%h | R4=%h | R5=%h | RF_WE=%b | \n\
// | ALU_OP=%b | \n",
//           $time, pc_out, pc_sel, pc_write, stat, br_sel, br_addr,
//           instr, ir_load, rsa, rsb, rd, mff, opcode,
//           rf0.ram_array[1], rf0.ram_array[2], rf0.ram_array[3], rf0.ram_array[4], rf0.ram_array[5], rf_we,
//           alu_op
//     );
end
endmodule
