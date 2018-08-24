module reg_file(clk, rstd, wr, ra1, ra2, wa, wren, rr1, rr2);
   input clk, rstd, wren;
   input [31:0] wr;
   input [4:0] 	ra1, ra2, wa;
   output [31:0] rr1, rr2;
   reg [31:0] 	 rf [0:31];
   assign rr1 = rf[ra1];
   assign rr2 = rf[ra2];
   always @(negedge rstd or posedge clk) begin
     if (rstd == 0) rf [0] <= 32'h00000000;
     else if (wren == 0) rf[wa] <= wr;
   end
endmodule

`define ALU_ADD  4'o00
`define ALU_SUB  4'o10
`define ALU_SLL  4'o01
`define ALU_SLT  4'o02
`define ALU_SLTU 4'o03
`define ALU_XOR  4'o04
`define ALU_SRL  4'o05
`define ALU_SRA  4'o15
`define ALU_OR   4'o06
`define ALU_AND  4'o07

module alu (r1,r2,shamt,imm,rd,mainop,subop,riselect);
    input [31:0]r1;
    input [31:0]r2;
    input [4:0]shamt;
    input [31:0]imm;

    input [2:0]mainop;
    input subop;
    input riselect;

    output rd;

    wire [3:0]aluop;
    wire [31:0]op1;
    wire [31:0]op2;

    assign aluop = {subop,mainop[2:0]};
    assign op1 = r1;
    assign op2 = (riselect)?r2:imm;
    case (op)
      ALU_ADD:  assign rd = op1 + op2;
      ALU_SUB:  assign rd = op1 - op2;
      ALU_SL:   assign rd = op1 << op2[4:0];
      ALU_SLT:  assign rd = $signed(op1) < $signed(op2);
      ALU_SLTU: assign rd = op1 < op2;
      ALU_XOR:  assign rd = op1 ^ op2;
      ALU_SRL:  assign rd = op1 >> op2[4:0];
      ALU_SRA:  assign rd = op1 >>> op2[4:0];
      ALU_OR:   assign rd = op1 | op2;
      ALU_AND:  assign rd = op1 & op2;
      default:  assign rd = 32'bx; 
    endcase
endmodule

module data_mem(address, clk, write_data, wren, read_data);
   input [31:0] address;
   input       clk, wren;
   input [7:0] write_data;
   output [7:0] read_data;
   reg [7:0] 	d_mem [0:255] ;

   always @(posedge clk)
     if (wren == 0) d_mem[address] <= write_data;
   assign read_data = d_mem[address];
endmodule

module mem_access(clk,r1,r2,immi,imms,res,mainop,subop);//0書き込み1読み込み
    input clk;
    input [31:0]r1;//base
    input [31:0]r2;//source
    input [31:0]immi;
    input [31:0]imms;

    input [2:0]mainop;
    input subop;//LOAD0orSTORE1

    output [31:0]res;
    wire [31:0]mem_address;
    wire [31:0]reg2;
    wire [31:0]dm_r_data;
    wire [4:0]selector;
    wire [3:0]dren;
    wire [3:0]storedren;
    assign mem_address = subop ? r1 + immi: r1 + imms;
    assign selector = {mem_address[1:0],mainop};
    case (selector)
      5'b00_000: assign reg2 = {24'd0,r2[7:0]};
      5'b01_000: assign reg2 = {16'd0,r2[7:0],8'd0};
      5'b10_000: assign reg2 = {8'd0,r2[7:0],16'd0};
      5'b11_000: assign reg2 = {r2[7:0],24'd0};
      5'b00_001: assign reg2 = {16'd0,r2[7:0],r2[15:8]};
      5'b01_001: assign reg2 = {8'd0,r2[7:0],r2[15:8].8'd0};
      5'b10_001: assign reg2 = {r2[7:0],r2[15:8],16'd0};
      default: assign reg2 = {r2[7:0],r2[15:8],r2[23:16],r2[31:24]};
    endcase
    case (selector)
      5'b00_000: assign storedren = 4'b1110;
      5'b01_000: assign storedren = 4'b1101;
      5'b10_000: assign storedren = 4'b1011;
      5'b11_000: assign storedren = 4'b0111;
      5'b00_001: assign storedren = 4'b1100;
      5'b01_001: assign storedren = 4'b1001;
      5'b10_001: assign storedren = 4'b0011;
      5'b00_010: assign storedren = 4'b0000;
      default: assign storedren = 4'b1111;
    endcase
    assign dren = subop?storecode:4'b1111;
    data_mem data_mem_body0(mem_address[31:2], clk, reg2[7:0], dren[0], dm_r_data [7:0]);
    data_mem data_mem_body1(mem_address[31:2], clk, reg2[15:8], dren[1], dm_r_data[15:8]);
    data_mem data_mem_body2(mem_address[31:2], clk, reg2[23:16], dren[2], dm_r_data[23:16]);
    data_mem data_mem_body3(mem_address[31:2], clk, reg2[31:24], dren[3], dm_r_data[31:24]);
    case (selector)
      5'b00_000: assign res = {24{dm_r_data [7]},dm_r_data [7:0]};
      5'b01_000: assign res = {24{dm_r_data [15]},dm_r_data [15:8]};
      5'b10_000: assign res = {24{dm_r_data [23]},dm_r_data [23:16]};
      5'b11_000: assign res = {24{dm_r_data [31]},dm_r_data [31:24]};
      5'b00_100: assign res = {24'd0,dm_r_data [7:0]};
      5'b01_100: assign res = {24'd0,dm_r_data [15:8]};
      5'b10_100: assign res = {24'd0,dm_r_data [23:16]};
      5'b11_100: assign res = {24'd0,dm_r_data [31:24]};
      5'b00_001: assign res = {16{dm_r_data [7]},dm_r_data [7:0],dm_r_data [15:8]};
      5'b01_001: assign res = {16{dm_r_data [15]},dm_r_data [15:8],dm_r_data [23:16]};
      5'b10_001: assign res = {16{dm_r_data [23]},dm_r_data [23:16],dm_r_data [31:24]};
      5'b00_101: assign res = {16'd0,dm_r_data [7:0],dm_r_data [15:8]};
      5'b01_101: assign res = {16'd0,dm_r_data [15:8],dm_r_data [23:16]};
      5'b10_101: assign res = {16'd0,dm_r_data [23:16],dm_r_data [31:24]};
      5'b00_010: assign res = {dm_r_data [7:0],dm_r_data [15:8],dm_r_data [23:16],dm_r_data [31:24]};
      default: assign res = 32'd0;
    endcase
endmodule

module CSR(r1,zimm,csr,rd,mainop,csren);
endmodule

module npc(r1,r2,imm,pc,mainop,npcen);
endmodule

module (alures,memres,CSRres,lastres,selectop);
  input [31:0]alures;
  input [31:0]memres;
  input [31:0]CSRres;
  input [4:0]selectop;
  output [31:0]lastres;
  case (selectop)
      4'b0010:assign lastres = memres; //memres
      4'b0001:assign lastres = alures; //alures
      4'b0001:assign lastres = alures; //alures
      4'b0011:assign lastres = CSRres; //CSRres
      default: assign lastres = 32'd0; //none
    endcase
endmodule
