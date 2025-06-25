//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: RF
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 寄存器堆 (Register File)。
//
// Dependencies: sccomp_top.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Added comments and clarification.
// Additional Comments:
// - 实现了异步读、同步写。
// - 寄存器 x0 (地址为0) 硬编码为0，符合RISC-V规范。
//------------------------------------------------------------------------------

module RF(
    input clk,                  // 时钟信号
    input rstn,                 // 复位信号 (低电平有效)
    input RFwr,                 // 寄存器写使能信号
    input [4:0] A1, A2, A3,     // 读地址A1, A2; 写地址A3
    input [31:0] WD,            // 待写入的数据
    output [31:0] RD1, RD2      // 读出的数据 RD1, RD2
);
    // 定义一个包含32个32位寄存器的寄存器堆
    reg [31:0] rf[31:0];
    integer i;

    // 同步写逻辑: 在时钟上升沿或复位下降沿触发
    always@(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 复位时，将rf[i]初始化为i，便于调试。
            // 综合警告: 此循环在综合时可能导致较长的初始化时间或资源占用。
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] = i;
            end
        end else begin
            // 当写使能有效且目标地址不为0时，执行写操作
            // (A3 != 0) 保证了 x0 寄存器不会被写入
            if (RFwr && (A3 != 5'b0)) begin
                rf[A3] <= WD;
            end
        end
    end

    // 异步读逻辑: 只要读地址变化，就立即更新输出
    // 如果读地址为0，则输出0；否则输出对应寄存器的值。
    assign RD1 = (A1 != 5'b0) ? rf[A1] : 32'b0;
    assign RD2 = (A2 != 5'b0) ? rf[A2] : 32'b0;

endmodule 