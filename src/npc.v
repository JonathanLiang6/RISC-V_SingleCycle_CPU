//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: NPC
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 下一条指令地址 (Next Program Counter) 计算单元。
//
// Dependencies: sccomp_top.v, ctrl.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Improved style and added default case.
// Additional Comments:
//
//------------------------------------------------------------------------------

module NPC(
    input [31:0] PC,      // 当前程序计数器 (PC)
    input [2:0] NPCOp,    // NPC 计算操作码
    input [31:0] immout,  // 来自立即数扩展单元的结果
    input [31:0] aluout,  // 来自ALU的计算结果 (用于JALR)
    output reg [31:0] NPC // 计算出的下一条指令地址
);

    // NPC 操作码定义 (与ctrl.v保持一致)
    localparam NPC_PLUS4  = 3'b000; // 顺序执行 (PC + 4)
    localparam NPC_BRANCH = 3'b001; // 分支跳转 (PC + imm)
    localparam NPC_JAL    = 3'b010; // JAL 跳转 (PC + imm)
    localparam NPC_JALR   = 3'b100; // JALR 跳转 (rs1 + imm)

    // 组合逻辑，根据NPCOp计算NPC的值
    always@(*) begin
        // case 语句根据不同的 NPCOp 执行不同的地址计算
        case(NPCOp)
            NPC_PLUS4:  NPC = PC + 4;
            NPC_BRANCH: NPC = PC + immout;
            NPC_JAL:    NPC = PC + immout;
            // JALR 的目标地址是 (rs1 + imm)。RISC-V规范要求将结果的最低位清零，
            // 即 (rs1 + imm) & ~1。此处为简化设计，直接使用ALU的计算结果。
            NPC_JALR:   NPC = aluout;
            // 默认情况下，NPC指向下一条顺序指令，这可以防止生成锁存器。
            default:    NPC = PC + 4;
        endcase
    end

endmodule 