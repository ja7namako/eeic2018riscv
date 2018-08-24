`include "execute"
module CPU(clk,rstd);
    input clk;
    input rstd;
    wire [31:0]ins;
    reg [31:0]pc;
    
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [12:0] imm_b;
    wire [19:0] imm_u;
    wire [19:0] imm_j;

    wire [31:0]r1;
    wire [31:0]r2;
    wire [31:0] alures;
    wire [31:0] memres;
    wire [31:0] CSRres;
    wire [31:0] lastres;
    wire [31:0] nextpc;

    wire [3:0]selectop;
    wire wren;
    wire npcren;
    wire csren;
    //fetch
    fetch fetch1(pc,ins);
    //endfetch
    
    //decode
    decode decode1(ins,selectop,wren,npcen,csren);//output=selectop wren npcen csren
    //immidiate
    assign imm_i = $signed(ins[31:20]);
    assign imm_s = $signed({ins[31:25], ins[11:7]});
    assign imm_b = {ins[31], ins[7], ins[30:25], ins[11:8]};
    assign imm_u = ins[31:12];
    assign imm_j = {ins[31], ins[19:12], ins[20], ins[30:21]};
    //end immidiate
    //end decode
    
    //execute
    alu alu1(r1,r2,ins[24:20],imm_i,alures,ins[14:12],ins[30],ins[5]);
    mem_access mem_access1(clk,r1,r2,imm_i,imm_s,memres,ins[14:12],ins[5]);
    CSR CSR1(r1,ins[19:15],ins[31:20],CSRres,ins[14:12],csren);
    select select1(alures,memres,CSRres,lastres,selectop);
    //end execute

    //writeback
    npc npc1(r1,r2,imm_b,pc,nextpc,ins[14:12],npcen);
    always @(negedge rstd or posedge clk)
     begin
	if (rstd == 0) pc <= 32'h00000000;
	  else if (clk == 1) pc <= nextpc;
     end
    reg_file reg_file1(clk, rstd, lastres, ins[19:15], ins[24:20], ins[11:7], wren, r1, r2);
    //end writeback

endmodule

module fetch (pc, ins); 
   input [31:0] pc;
   output [31:0] ins;
   reg [31:0] 	 ins_mem[0:255];
   assign ins = ins_mem[pc];
endmodule

module decode(ins,selectop,wren,npcen,csren);
    input [31:0]ins;
    output [3:0]selectop;
    output wren;
    output npcen;
    output csren;
    case (ins[6:0])
      7'b0000011:assign selectop = 4'b0010; //memres
      7'b0010011:assign selectop = 4'b0001; //alures
      7'b0110011:assign selectop = 4'b0001; //alures
      7'b1110011:assign selectop = 4'b0011; //CSRres
      default: assign selectop = 4'b0000; //none
    endcase
    case (ins[6:0])
      7'b0100011:assign wren = 1'b1;
      7'b0010011:assign wren = 1'b1;
      7'b0110011:assign wren = 1'b1;
      7'b1110011:assign wren = 1'b1;
      default: assign wren = 1'b0;
    endcase
    case (ins[6:0])
      7'b1100011:assign npcen = 1'b1;
      default: assign npcen = 1'b0;
    endcase
    case (ins[6:0])
      7'b1110011:assign csren = 1'b1;
      default: assign csren = 1'b0;
    endcase
    
endmodule;