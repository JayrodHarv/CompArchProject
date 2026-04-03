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
	// instruction decoding
	// ---------------------------------
	wire [3:0]	opcode      = instr[31:28];    	// opcode
	wire [3:0] 	mff			= instr[27:24];		// Mode / Flag Field (Multi-purpose field)
	wire [3:0] 	rd			= instr[23:20];		// Write Register
	wire [3:0] 	rs			= instr[19:16];		// Source Register A
	wire [3:0]	rt			= instr[15:12];		// Source Register B

	wire [11:0] funct		= instr[11:0];		// ALU function code
	wire [3:0]	alu_op		= funct[3:0];		// ALU operation code

	wire [15:0]	imm			= instr[15:0];		// Immediate Value
	wire [15:0] target		= instr[15:0];		// Memory Address 	  	

	// ---------------------------------
	// component instantiation goes here
	// ---------------------------------

	// Program Counter (PC)
	pc pc0 (
		clk,
		br_addr,
		pc_sel,
		pc_write,
		pc_rst,
		pc_out
	);

	// Branch Address Calculator (BR)
	br br0 (
		pc_out,
		target,
		br_sel,
		br_addr
	);

	// Instruction Memory (IM)
	im im0 (
		pc_out,
		instr_out
	);

	// Instruction Register (IR)
	ir ir0 (
		clk,
		ir_load,
		instr_out,
		instr
	);

	// Arithmetic Logic Unit (ALU)
	alu alu0 (
		clk,
		rsa,
		rsb,
		imm,
		cc[3],  // carry in from status register
		alu_op,
		alu_op, // give alu_op inplace of funct for now
		alu_out,
		cc,
		stat_en
	  );

	// status register (STATREG)
	statreg statreg0 (
		clk,
		cc,
		stat_en,
		stat
	  );

	// control unit (CTRL)
	ctrl ctrl0 (
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
		ir_load
	);

	// writeback mux
	mux32 mux0 (
		alu_out,
		0,
		wb_sel,
		wb_data
	);

	// register file
	rf rf0 (
		clk,
		rs,
		rt,
		rd,
		wb_data,
		rf_we,
		rsa,
		rsb
	);

	initial begin
		$monitor(
			"Time=%0d, IR=%h, R1=%h, R2=%h, R3=%h, R4=%h, R5=%h, ALU_OP=%h, BR_SEL=%h, PC_WRITE=%b, PC_SEL=%b STAT_REG=%b",
			$time, instr, rf0.ram_array[1], rf0.ram_array[2], rf0.ram_array[3], rf0.ram_array[4], rf0.ram_array[5], 
			alu_op, br_sel, pc_write, pc_sel, stat);
	end
endmodule
