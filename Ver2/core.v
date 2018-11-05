//動作保証外につき要検証
module core(
  clk,
  rstd
);
input clk;
input rstd;

wire [31:0]pc;
wire [31:0]ins;
wire [3:0]alu_op;
wire [3:0]mem_op;
wire [1:0]calcselect_op;
wire [6:0]ins_op;
wire [2:0]ins_subop;
wire [4:0]ra1;
wire [4:0]ra2;
wire [4:0]rad;
wire immI;
wire immB;
wire immJ;
wire immU;
wire immS;
wire [31:0]npc;
wire [31:0]rdresult;
wire [31:0]rd1;
wire [31:0]rd2;
module fetch Fetch(pc,ins);
module decode Decode(
  ins,
  alu_op,
  mem_op,
  calcselect_op,
  ins_op,
  ins_subop,
  ra1,
  ra2,
  rad,
  immI,
  immB,
  immJ,
  immU,
  immS);
module execute Execute(
  alu_op,
  mem_op,
  calcselect_op,
  ins_op,
  ins_subop,
  rd1,
  rd2,
  pc,
  immI,
  immB,
  immJ,
  immU,
  immS,
  clk,
  rstd,
  npc,
  rdresult);
module writeback Writeback(clk,rstd,npc,pc);
module resisterfile Resisterfile(
  clk,
  rstd,
  rdresult,
  ra1,
  ra2,
  rad,
  1'b0,
  rd1,
  rd2);
endmodule // core