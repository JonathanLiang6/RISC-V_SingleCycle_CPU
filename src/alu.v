//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: alu
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 算术逻辑单元 (ALU), 负责执行算术和逻辑运算。
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//------------------------------------------------------------------------------

// ALU 操作码定义
`define ALUOp_nop 5'b00000   // 空操作 (no operation)
`define ALUOp_lui 5'b00001   // LUI 指令 (load upper immediate)
`define ALUOp_auipc 5'b00010 // AUIPC 指令 (add upper immediate to pc)
`define ALUOp_add 5'b00011   // 加法 (add)
`define ALUOp_sub 5'b00100   // 减法 (subtract)
// 注意：当前ALU实现的操作有限，可以根据需要扩展更多操作，例如AND, OR, XOR, SLT等

// ALU 模块，负责执行算术和逻辑运算
module alu(
    input signed [31:0] A, B,  // ALU 的两个32位有符号输入操作数 A 和 B
    input [4:0] ALUOp,         // ALU 5位操作码，用于选择执行的操作
    output reg signed [31:0] C, // ALU 32位有符号输出结果
    output Zero            // Zero 标志位, 当结果C为0时，该信号为1
);

    // 组合逻辑，根据ALUOp计算结果C
    // 使用 always@(*) 表示这是一个组合逻辑块，输出随输入变化而立即变化
    always @(*) begin
        // case 语句根据不同的 ALUOp 执行不同的操作
        case (ALUOp)
            `ALUOp_add:   C = A + B;    // 加法
            `ALUOp_sub:   C = A - B;    // 减法
            `ALUOp_lui:   C = B;        // LUI指令，将立即数B(高20位)直接输出
            `ALUOp_auipc: C = A + B;    // AUIPC指令，A为PC，B为立即数，相加
            // 其他RISC-V指令如 AND, OR, XOR, SLT, SLL, SRL, SRA 等可在此处添加
            default:      C = 32'b0;    // 对于未定义的操作码(如nop)，默认输出为0，避免生成锁存器
        endcase
    end

    // 当输出结果C为0时，Zero标志位为1，否则为0
    assign Zero = (C == 32'b0);

endmodule 