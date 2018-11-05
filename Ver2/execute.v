module execute(
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
  storeselector
);
input [3:0]alu_op;
input [1:0]calcselect_op;
input [3:0]mem_op;
input [6:0]ins_op;
input [2:0]ins_subop;
input [31:0]rd1;
input [31:0]rd2;
input [31:0]pc;
input immI;
input immB;
input immJ;
input immU;
input immS;
input clk;
input rstd;
output [31:0]npc;
output [31:0]rdresult;

wire [31:0]data2;
wire BranchFlag;
wire [31:0]aluresult;
wire [31:0]pctordresult;
wire [31:0]memresult;
//
assign data2 = calcselector(rd2,immI,immS,calcselect_op);
assign aluresult = alu(rd1,data2,alu_op);
assign BranchFlag = compare(rd1,rd2,ins_subop);
assign npc = nextpc(immB,immJ,ins_op,BranchFlag,pc,aluresult);
assign pctordresult = pctord(immU,pc,ins_op);
memaccess g_memaccess(aluresult,rd1,memresult,ins_op,ins_subop,clk);
assign rdresult = storeselector(aluresult,memresult,pctordresult,ins_op);
//
function [31:0] alu;
  input [31:0] data1;
  input [31:0] data2;
  input [2:0] op;
  case (op)
      0_000:  alu = data1 + data2;
      1_000:  alu = data1 - data2;
      0_001:  alu = data1 << data2[4:0];
      0_010:  alu = $signed(data1) < $signed(data2);
      0_011:  alu = data1 < data2;
      0_100:  alu = data1 ^ data2;
      0_101:  alu = data1 >> data2[4:0];
      1_101:  alu = data1 >>> data2[4:0];
      0_110:  alu = data1 | data2;
      0_111:  alu = data1 & data2;
      default:alu = 32'bx; 
  endcase
endfunction

function [31:0] calcselector;
  input [31:0] rd2;
  input [11:0] immI;
  input [11:0] immS;
  input [1:0]op;
  case (op)
      10:  calcselector = $signed(immS);
      00:  calcselector = $signed(immI);
      default:calcselector = rd2; 
  endcase
endfunction

function compare;
input [31:0]data1;
input [31:0]data2;
input [2:0] op;
case (op)
  3'b000:compare = ($signed(data1) == $signed(data2));
  3'b001:compare = (data1 != data2);
  3'b100:compare = ($signed(data1) < $signed(data2));
  3'b101:compare = ($signed(data1) >= $signed(data2));
  3'b010:compare = (data1 == data2);
  3'b110:compare = (data1 < data2);
  default:compare = 1'b0;
endcase
endfunction

function [31:0] nextpc;
input [11:0]immB;
input [19:0]immJ;
input [6:0]op;
input BranchFlag;
input [31:0]pc;
input [31:0]alu_input;
casex ({op[6] & op[5] & ~op[4] & op[1] & op[0],op[3],op[2],BranchFlag})
  4'b111x:nextpc = $signed({immJ,1'b0}) +pc;
  4'b1001:nextpc = $signed({immB,1'b0}) +pc;
  4'b101x:nextpc = alu_input;
  default:nextpc = 4 + pc;
endcase
endfunction // nextpc

function [31:0] pctord;
input [19:0]immU;
input [31:0]pc;
input [7:0]op;
case (op)
  7'b0110111:pctord = {immU,{12{1'b0}}};
  7'b0010111:pctord = {immU,{12{1'b0}}}+pc;
  default: pctord = 4+pc;
endcase
endfunction

function [31:0] storeselector;
input [31:0]alu_input;
input [31:0]mem_input;
input [31:0]pctord_input;
input [6:0]op;
casex (op)
  7'b0x10011:storeselector = alu_input;
  7'b0000011:storeselector = mem_input; 
  default: storeselector = pctord_input;
endcase
endfunction // storeselector

endmodule // execute

module data_mem(address, clk, write_data, wren, read_data);
   input [15:0] address;
   input       clk, wren;
   input [7:0] write_data;
   output [7:0] read_data;
   reg [7:0] 	d_mem [0:255] ;

   always @(posedge clk)
     if (wren == 0) d_mem[address] <= write_data;
   assign read_data = d_mem[address];
endmodule

module memaccess(
  address,
  reg_data,
  mem_result,
  mainop,
  subop,
  clk
);
input [31:0] address;
input [31:0] reg_data;
input [2:0] mainop;
input subop;
input clk;
output [31:0] mem_result;
wire [3:0] dren;
wire [31:0] dm_r_data;
wire [31:0] dm_w_data;
    function [3:0]create_op;
        input [3:0]op;//subop_mainop
        case (op)
          4'b1_000:create_op = 4'b0111;
          4'b1_001:create_op = 4'b0011;
          4'b1_010:create_op = 4'b0000;
          default: create_op = 4'b1111;
        endcase
    endfunction//create_op;

    function [31:0]endian_w;
        input [31:0]source;
        input [2:0]op;
		  case (op)
          3'b000:endian_w = source[31:0];
          3'b001:endian_w = {source[31:16],source[7:0],source[15:8]}; 
          3'b010:endian_w = {source[7:0],source[15:8],source[23:16],source[31:24]};
          default:endian_w = source[31:0];
        endcase
    endfunction//endian_w

    function [31:0]endian_r;
        input [31:0]source;
        input [2:0]op;
        case (op)
          3'b000:endian_r = $signed(source[7:0]);
          3'b001:endian_r = {{16{source[7]}},source[7:0],source[15:8]}; 
          3'b010:endian_r = {source[7:0],source[15:8],source[23:16],source[31:24]};
          3'b000:endian_r = {{24{1'b0}},source[7:0]};
          3'b001:endian_r = {{16{source[7]}},source[7:0],source[15:8]}; 
          default:endian_r = source;
        endcase
    endfunction//endian_r


    assign dren = create_op({subop,mainop[2:0]});
    assign dm_w_data = endian_w(reg_data,mainop);
    data_mem data_mem_body0(address[17:2], clk, dm_w_data[7:0], dren[0], dm_r_data [7:0]);
    data_mem data_mem_body1(address[17:2], clk, dm_w_data[15:8], dren[1], dm_r_data[15:8]);
    data_mem data_mem_body2(address[17:2], clk, dm_w_data[23:16], dren[2], dm_r_data[23:16]);
    data_mem data_mem_body3(address[17:2], clk, dm_w_data[31:24], dren[3], dm_r_data[31:24]);
    assign mem_result = endian_r(dm_r_data,mainop);
endmodule // memaccess