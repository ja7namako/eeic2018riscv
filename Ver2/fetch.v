module fetch(
  pc,
  ins
);
input [31:0] pc;
output [31:0] ins;
reg [31:0] ins_mem [0:255];
assign ins = ins_mem[pc]; 
endmodule // fetch