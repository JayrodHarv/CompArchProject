// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns / 100ps

module sisc (
    clk,
    rst_f,
    ir
);

  input clk, rst_f;
  input [31:0] ir;

  // ---------------------------------
  // declare all internal wires here
  // ---------------------------------
  wire [3:0] alu_op;  // ALU operation code from control unit to ALU
  wire       wb_sel;  // writeback select from control unit to writeback mux
  wire       rf_we;  // register file write enable from control unit to register file
  wire [3:0] stat_en;  // status register enable from control unit to status register
  wire [3:0] stat;  // Wire connecting the status register to the control circuit
  wire [3:0] mm;  // Something with memory that we don't care about right now

  wire [31:0] rsa, rsb;  // outputs from register file
  wire [3:0] cc;  // condition code from alu to status register
  wire [31:0] alu_out;  // output from alu to writeback mux and status register
  wire [31:0] wb_data;  // output from writeback mux to register file

  // ---------------------------------
  // decode instruction fields
  // ---------------------------------
  wire [3:0] opcode = ir[31:28];  // opcode is the top 4 bits of the instruction
  wire [3:0]  write_reg = ir[27:24]; // rd is the next 4 bits of the instruction, used for writeback register id
  wire [3:0]  rsa_id    = ir[23:20]; // rsa_id is the next 4 bits of the instruction, used for register file read port A
  wire [3:0]  rsb_id    = ir[19:16]; // rsb_id is the next 4 bits of the instruction, used for register file read port B
  wire [15:0] imm       = ir[15:0];  // imm is the last 16 bits of the instruction, used for immediate values
  wire [3:0]  funct     = ir[3:0];   // funct is the last 4 bits of the instruction, used for ALU function code

  // ---------------------------------
  // component instantiation goes here
  // ---------------------------------

  // ALU
  alu alu0 (
      clk,
      rsa,
      rsb,
      imm,
      cc[3],  // carry in from status register
      alu_op,
      funct,
      alu_out,
      cc,
      stat_en
  );

  // status register
  statreg statreg0 (
      clk,
      cc,
      stat_en,
      stat
  );

  // control unit
  ctrl ctrl0 (
      clk,
      rst_f,
      opcode,
      mm,  // ignore for now
      stat,
      rf_we,
      alu_op,
      wb_sel
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
      rsa_id,
      rsb_id,
      write_reg,
      wb_data,
      rf_we,
      rsa,
      rsb
  );

  initial begin
    $monitor(
        "Time= %0d, IR= %h, R1= %h, R2= %h, R3= %h, R4= %h, R5= %h, ALU_OP= %h, WB_SEL= %b, RF_WE= %b, wb_data= %h",
        $time, ir, rsa, rsb, rf0.ram_array[1], rf0.ram_array[2], rf0.ram_array[3],
        rf0.ram_array[4], rf0.ram_array[5], alu_op, wb_sel, rf_we, wb_data);
  end


endmodule
