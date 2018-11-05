module decode(
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
  immS
);
input [31:0]ins;

output [3:0]alu_op;
output [3:0]mem_op;
output [1:0]calcselect_op;
output [6:0]ins_op;
output [2:0]ins_subop;
output [4:0]ra1;
output [4:0]ra2;
output [4:0]rad;
output immI;
output immB;
output immJ;
output immU;
output immS;

wire [6:0]op;
wire [2:0]subop;
wire [6:0]exop;


assign alu_op = aluop(op,subop,exop);
assign mem_op = memop(op,subop);
assign calcselect_op = calcselectop(op);
assign ins_op = ins[6:0]; 
assign ins_subop = ins[14:12];
assign [4:0]ra1 = ins[24:20];
assign [4:0]ra2 = ins[19:15];
assign [4:0]rad = ins[11:7];
assign op = ins[6:0]; 
assign subop = ins[14:12];
assign exop = ins[31:25];


function [31:0] aluop;
	input [6:0] op;
	input [2:0] subop;
	input [6:0] exop;
	if (op == 7'b0010111) 
      begin
        assign aluop = 4'b0000;
      end
      else
      begin
        assign aluop = {exop[5],subop};
      end
endfunction
      
function [1:0] calcselectop;
	input [6:0] op;
	case (op)
		7'b0100011: calcselectop = 2'b10;//immS
      7'b0110011: calcselectop = 2'b00;//r2data  
      default: calcselectop = 2'b01;//immI
   endcase
endfunction

function memop;
	input [6:0] op;
	input [2:0] subop;
	case (op)
		7'b0000011: memop = {0,subop};
		7'b0100011: memop = {1,subop}; 
      default: memop = 4'b0000;
	endcase
endfunction
endmodule // decode