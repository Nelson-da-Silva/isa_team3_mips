// reset from PC and IR ?
module datapath (input         PcEn, IorD,
                 input         IrWrite,
                 input         IrSel, RegDst,
                 input         MemToReg,
                 input         RegWrite, ALUSrcA,
                 input         Asel, Bsel,
                 input [1:0]   ALUSrcB,
                 input         ExtSel,
                 input [2:0]   ALUControl,
                 input         stall,
                 input         ALUsel,
                 input         PCSrc,
                 output        zero,
                 output [31:0] pc,
                 input  [31:0] instr,
                 output [31:0] aluoutnext, writedata);

    wire [4:0]  writereg;
    wire [31:0] memloc;
    wire [31:0] irin, irout;
    wire [31:0] wd3;
    wire [31:0] pcnext;
    wire [31:0] nextrd1, nextrd2;
    wire [31:0] rd1, rd2, rd1muxOut;
    wire [31:0] srca, srcb;
    wire [31:0] aluout;
    wire [31:0] signimm, signimmsh;
    wire [31:0] result;
    wire [31:0] SxOut, ZxOut;
    wire [31:0] branchnext;

    //next PC logic
    flopr #(32) Brreg(clk, reset, result, branchnext);
    mux2 #(32)  brmux(result, branchnext, PCSrc, pcnext);
    flopr #(32) Pcreg(clk, PcEn, pcnext, pc);
    mux2 #(32)  RegMem(pc, result, IorD, memloc);
    flopr #(32) Irreg(clk, IrWrite, irin, irout);
    //control for Brreg?

    // rigister file logic
    mux2 #(32)  muxIR(irin, irout, IrSel, instr);
    mux2 #(5)   muxA3(instr[20:16], instr[15:11], RegDst, writereg);
    mux2 #(32)  muxWD3(irin, result, MemToReg, wd3);
    regfile     rf(clk, RegWrite, instr[25:21], instr[20:16], writereg, result, nextrd1, nextrd2);
    flopr #(32) RegA(clk, reset, nextrd1, rd1);
    flopr #(32) RegB(clk, reset, nextrd2, rd2);
    mux2 #(32)  rd1mux(nextrd1, rd1, Asel, rd1muxOut);
    mux2 #(32)  rd2mux(nextrd2, rd2, Bsel, writedata);
    mux2 #(32)  alumux(nextaluout, aluout, ALUsel, result);
    signext     se(instr[15:0], SxOut);
    zeroext     ze(instr[15:0], ZxOut);
    mux2 #(32)  extmux(SxOut, ZxOut, ExtSel, signimm);
    sl2         immsh(signimm, signimmsh);

    // ALU logic
    mux4 #(32)  srcbmux(writedata, 32'b100, signimm, signimmsh ALUSrcB, srcb);
    mux2 #(32)  srcamux(pc, rd1muxOut, ALUSrcA, srca);
    alu         alu(srca, srcb, ALUControl, aluoutnext, zero);
    flopr #(32) RegALU(clk, reset, aluoutnext, aluout);
endmodule
)