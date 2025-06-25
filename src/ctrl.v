//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: ctrl
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 控制单元。解码指令并生成相应的控制信号。
//
// Dependencies: sccomp_top.v, alu.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Refactored for clarity and correctness.
// Additional Comments:
//
//------------------------------------------------------------------------------

module ctrl(
    input [6:0] Op,         // 指令的操作码 (opcode)
    input [6:0] Funct7,     // 指令的 funct7 字段
    input [2:0] Funct3,     // 指令的 funct3 字段
    input Zero,         // 来自ALU的Zero标志位，用于分支指令
    output reg RegWrite,    // 寄存器文件写使能
    output reg MemWrite,    // 数据存储器写使能
    output reg [5:0] EXTOp,     // 立即数扩展单元操作码
    output reg [4:0] ALUOp,     // ALU操作码
    output reg ALUSrc,      // ALU操作数B来源选择 (RD2或立即数)
    output reg [2:0] DMType,    // 数据存储器操作类型 (byte, half-word, word)
    output reg [1:0] WDSel,     // 写回寄存器的数据来源选择
    output reg [2:0] NPCOp      // Next PC 操作码
);

    // ALU 操作码定义 (应与alu.v保持一致)
    localparam ALUOP_NOP   = 5'b00000;
    localparam ALUOP_LUI   = 5'b00001;
    localparam ALUOP_AUIPC = 5'b00010;
    localparam ALUOP_ADD   = 5'b00011;
    localparam ALUOP_SUB   = 5'b00100;
    // localparam ALUOP_SLT = ... // 可扩展

    // RISC-V 指令操作码 (Opcode)
    localparam OP_LUI    = 7'b0110111; // U-type
    localparam OP_AUIPC  = 7'b0010111; // U-type
    localparam OP_JAL    = 7'b1101111; // J-type
    localparam OP_JALR   = 7'b1100111; // I-type
    localparam OP_BRANCH = 7'b1100011; // B-type
    localparam OP_LOAD   = 7'b0000011; // I-type
    localparam OP_STORE  = 7'b0100011; // S-type
    localparam OP_IMM    = 7'b0010011; // I-type (ADDI, SLTI, etc.)
    localparam OP_RTYPE  = 7'b0110011; // R-type

    // Funct3/Funct7 定义 (部分)
    // R-Type
    localparam F3_ADD_SUB = 3'b000;
    localparam F7_ADD     = 7'b0000000;
    localparam F7_SUB     = 7'b0100000;
    // I-Type (IMM)
    localparam F3_ADDI    = 3'b000;
    // Load
    localparam F3_LB      = 3'b000;
    localparam F3_LH      = 3'b001;
    localparam F3_LW      = 3'b010;
    // Store
    localparam F3_SB      = 3'b000;
    localparam F3_SH      = 3'b001;
    localparam F3_SW      = 3'b010;
    // Branch
    localparam F3_BEQ     = 3'b000;

    // EXTOp 定义 (bit-mask)
    localparam EXT_J = 6'b000001; // J-type
    localparam EXT_U = 6'b000010; // U-type
    localparam EXT_B = 6'b000100; // B-type
    localparam EXT_S = 6'b001000; // S-type
    localparam EXT_I = 6'b010000; // I-type

    // WDSel 定义
    localparam WD_ALU = 2'b00; // ALU result
    localparam WD_MEM = 2'b01; // Memory read data
    localparam WD_PC4 = 2'b10; // PC + 4

    // NPCOp 定义
    localparam NPC_PC4   = 3'b000; // PC + 4
    localparam NPC_BR    = 3'b001; // Branch
    localparam NPC_JAL   = 3'b010; // JAL
    localparam NPC_JALR  = 3'b100; // JALR

    always @(*) begin
        // 1. 设置所有控制信号的默认值
        RegWrite = 1'b0;
        MemWrite = 1'b0;
        EXTOp    = 6'b0;
        ALUOp    = ALUOP_NOP;
        ALUSrc   = 1'b0;
        DMType   = 3'b0;
        WDSel    = WD_ALU;
        NPCOp    = NPC_PC4;

        // 2. 根据指令Opcode生成控制信号
        case (Op)
            OP_RTYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0; // B from Regs[rs2]
                if (Funct3 == F3_ADD_SUB) begin
                    if (Funct7 == F7_ADD)
                        ALUOp = ALUOP_ADD;
                    else if (Funct7 == F7_SUB)
                        ALUOp = ALUOP_SUB;
                end
                // ... 在此添加其他R-Type指令
            end

            OP_IMM: begin // ADDI
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // B from immediate
                EXTOp    = EXT_I;
                if (Funct3 == F3_ADDI) begin
                    ALUOp = ALUOP_ADD;
                end
                // ... 在此添加其他I-Type指令
            end

            OP_LOAD: begin // LB, LH, LW
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                ALUSrc   = 1'b1; // B from immediate
                EXTOp    = EXT_I;
                ALUOp    = ALUOP_ADD; // Addr = rs1 + imm
                WDSel    = WD_MEM;
                DMType   = Funct3; // Pass Funct3 to select load type
            end

            OP_STORE: begin // SB, SH, SW
                RegWrite = 1'b0;
                MemWrite = 1'b1;
                ALUSrc   = 1'b1; // B from immediate
                EXTOp    = EXT_S;
                ALUOp    = ALUOP_ADD; // Addr = rs1 + imm
                DMType   = Funct3; // Pass Funct3 to select store type
            end

            OP_BRANCH: begin // BEQ
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                ALUSrc   = 1'b0; // B from Regs[rs2]
                EXTOp    = EXT_B;
                if (Funct3 == F3_BEQ && Zero) begin // BEQ and Z=1
                    NPCOp = NPC_BR;
                end
                ALUOp = ALUOP_SUB; // For comparison
            end

            OP_LUI: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // B from immediate
                EXTOp    = EXT_U;
                ALUOp    = ALUOP_LUI;
            end

            OP_AUIPC: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // B from immediate
                EXTOp    = EXT_U;
                ALUOp    = ALUOP_AUIPC;
            end

            OP_JAL: begin
                RegWrite = 1'b1;
                EXTOp    = EXT_J;
                WDSel    = WD_PC4;
                NPCOp    = NPC_JAL;
            end

            OP_JALR: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // B from immediate
                EXTOp    = EXT_I;
                WDSel    = WD_PC4;
                NPCOp    = NPC_JALR;
                ALUOp    = ALUOP_ADD; // for target address calculation
            end
        endcase
    end
endmodule
