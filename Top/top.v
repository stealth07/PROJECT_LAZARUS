`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2016 12:14:44 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(Clk, Rst);

    input Clk, Rst;
    // Data Signals
    wire [31:0] IM_Out,         // Ouput of IM
        SL_Out,
        JIMux_Out,
        RF_RD1,         // Ouptut #1 of RF
        RF_RD2,         // Output #2 of RF
        RegDst_Out,     // Output of RegDstMux
        ALUSrc_Out,     // Output of ALUSrcMux
        PC_Out,         // Output of ProgramCounter
        SE_Out,         // Output of SE
        ALU_Out,        // Output of ALU
        DM_Out,         // Output of DM
        PCI_Out,        // Output of PCI (PC Incrementer)
        JA_Out,         // Output of JA (Jump Adder)
        MemToReg_Out;   // Output
        
    wire ALU_Zero;      // Output of ALU Zero Flag
    
    // Control Signals
    wire RegDst,            // RegDst Mux Control
        ALUSrc,             // ALUSrc Mux Contorl
        MemWrite,           // Data Memory Write Control
        MemRead,            // Data Memory Read Control
        MemToReg,           // MemToReg Mux Control
        RegWrite,           // Register File Write Control
        Branch,             // Branch Control
        SignExt,            // Sign Extend Control
        JIMuxControl;       // PC Jump/Increment Mux Control
    
    wire [4:0] ALUControl;  // ALU Controller to ALU Data
    wire [3:0] ALUOp;       // Controller to ALU Controller Data
    
    
    // Controller(s)
    ALU_Controller ALUController(
        .Rst(Rst),
        .AluOp(ALUOp),
        .Funct(IM_Out[5:0]),
        .ALUControl(ALUControl));
    DatapathController Controller(
        .Rst(Rst),
        .OpCode(IM_Out[31:26]),
        .AluOp(ALUOp),
        .RegDst(RegDst),
        .RegWrite(RegWrite),
        .AluSrc(ALUSrc),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Branch(Branch),
        .MemToReg(MemToReg),
        .SignExt(SignExt));
    
    // Data Path Components
    ProgramCounter PC(
        .Address(JIMux_Out),
        .PC(PC_Out),
        .Reset(Rst),
        .Clk(Clk));
    InstructionMemory IM(
        .Address(PC_Out),
        .Instruction(IM_Out));
//    Mux32Bit2To1 RegDestMux(
//        .Out(RegDst_Out[4:0]),
//        .In0(IM_Out[15:11]),
//        .In1(IM_Out[20:16]),
//        .sel(RegDst));
        Mux5bit_2to1 RegDstMux(
                 .A(IM_Out[15:11]),
                 .B(IM_Out[20:16]), 
                 .sel(RegDst), 
                 .Out(RegDst_Out[4:0]));
        
        
    RegisterFile RF(
        .ReadRegister1(IM_Out[25:21]),
        .ReadRegister2(IM_Out[20:16]),
        .WriteRegister(RegDst_Out[4:0]),
        .WriteData(MemToReg_Out),
        .RegWrite(RegWrite),
        .Clk(Clk),
        .ReadData1(RF_RD1),
        .ReadData2(RF_RD2));
    SignExtension SE(
        .In(IM_Out[15:0]),
        .Out(SE_Out));
    Mux32Bit2To1 ALUSrcMux(
        .Out(ALUSrc_Out),
        .In0(RF_RD2),
        .In1(SE_Out),
        .sel(ALUSrc));
    ALU32Bit ALU(
        .ALUControl(ALUControl),
        .A(RF_RD1),
        .B(ALUSrc_Out),
        .Shamt(IM_Out[10:6]),
        .ALUResult(ALU_Out),
        .Zero(ALU_Zero)
        );
    DataMemory DM(
        .Address(ALU_Out),
        .WriteData(RF_RD2),
        .Clk(Clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ReadData(DM_Out));
    Mux32Bit2To1 MemToRegMux(
        .Out(MemToReg_Out),
        .In0(ALU_Out),
        .In1(DM_Out),
        .sel(MemToReg));

    // Program Counter Data Path
    Adder PCI(
        .InA(PC_Out),
        .InB(32'd4),
        .Out(PCI_Out));
    ShiftLeft SL(
        .In(SE_Out),
        .Out(SL_Out),
        .Shift(32'd2));
    Adder JA(
        .InA(PCI_Out),
        .InB(SL_Out),
        .Out(JA_Out));
    AND JumpAnd(
        .InA(ALU_Zero),
        .InB(Branch),
        .Out(JIMuxControl));
    Mux32Bit2To1 JIMux(
        .Out(JIMux_Out),
        .In0(PCI_Out),
        .In1(JA_Out),
        .sel(JIMuxControl));
        
endmodule