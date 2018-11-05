module resisterfile(
  clk,
  rstd,
  wr,
  ra1,
  ra2,
  wa,
  wren,
  rr1,
  rr2
);
input clk,rstd,wren;
input [31:0] wr;
input [4:0] ra1,ra2,wa;
output [31:0] rr1,rr2;
reg [31:0] rf [0:31];
assign rr1 = rf[ra1];
assign rr2 = rf[ra2];
always @(negedge rstd or posedge clk)
    if (rstd == 0) rf [0] <= 32'h00000000;
    else if(wren == 0) rf [wa] <= wr;
endmodule // resisterfile

module writeback(clk,rstd,nextpc,pc);
input clk,rstd;
input [31:0] nextpc;
output [31:0] pc;
reg [31:0] pc;

always @(negedge rstd or posedge clk)
    begin
      if(rstd == 0) pc <= 32'h00000000;
      else if(clk == 1) pc <= nextpc;
    end
endmodule
