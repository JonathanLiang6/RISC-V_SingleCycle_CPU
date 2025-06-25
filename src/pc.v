//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: PC
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 程序计数器 (Program Counter) 单元。
//
// Dependencies: sccomp_top.v, npc.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Refactored logic and removed redundant input.
// Additional Comments:
// - sw_i[1] 用于单步执行控制，为0时PC正常更新，为1时PC保持不变。
// - 包含一个硬编码的地址 0x48，当NPC等于该值时PC将回绕到0，这可能是为特定程序设计的。
//------------------------------------------------------------------------------

module PC(
    input clk,          // 时钟信号
    input rstn,         // 复位信号 (低电平有效)
    input [15:0] sw_i,  // 开关输入，用于控制
    input [31:0] NPC,   // 下一指令地址
    output reg [31:0] PCout // 当前PC输出
);

    // 时序逻辑，在时钟上升沿或复位下降沿更新PC
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            // 复位时，PC清零
            PCout <= 32'h00000000;
        end else begin
            // sw_i[1]为0时，CPU正常运行
            if(sw_i[1] == 1'b0) begin
                // 特殊逻辑: 如果下一条指令地址是0x48，则回绕到0
                if (NPC == 32'h00000048) begin
                    PCout <= 32'h00000000;
                // 否则，正常更新PC
                end else begin
                    PCout <= NPC;
                end
            // sw_i[1]为1时，CPU暂停，PC保持当前值
            end else begin
                PCout <= PCout;
            end
        end
    end

endmodule 