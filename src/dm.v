//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: dm
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 数据存储器 (Data Memory)。支持字节、半字、字的读写操作。
//
// Dependencies: ctrl.v, sccomp_top.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Corrected DMType to match RISC-V Funct3, improved style.
// Additional Comments:
// - 本模块实现了异步读和同步写。
// - 未对地址进行对齐检查，例如 LW/SW 指令的地址应为4的倍数。
//------------------------------------------------------------------------------

module dm (
    input clk,                   // 时钟信号
    input rstn,                  // 复位信号 (低电平有效)
    input DMWr,                  // 数据存储器写使能信号
    input [6:0] addr,            // 存储器字节地址 (128 bytes total)
    input [31:0] din,            // 待写入的数据
    input [2:0] DMType,          // 数据操作类型，来自指令Funct3字段
    output reg [31:0] dout       // 读出的数据
);

    // 数据操作类型定义, 与RISC-V指令的Funct3字段保持一致
    // 读取操作
    localparam OP_LB  = 3'b000; // Load Byte (signed)
    localparam OP_LH  = 3'b001; // Load Half-word (signed)
    localparam OP_LW  = 3'b010; // Load Word
    localparam OP_LBU = 3'b100; // Load Byte (unsigned)
    localparam OP_LHU = 3'b101; // Load Half-word (unsigned)
    // 写入操作
    localparam OP_SB  = 3'b000; // Store Byte
    localparam OP_SH  = 3'b001; // Store Half-word
    localparam OP_SW  = 3'b010; // Store Word

    // 定义一个128字节的存储器阵列
    reg [7:0] dmem[127:0];
    integer i;

    // 同步写逻辑: 在时钟上升沿或复位信号下降沿触发
    always@(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 复位时，将存储器内容全部清零
            // 综合警告: 此循环在综合时可能导致较长的初始化时间或资源占用。
            // 对于FPGA，建议使用存储器初始化文件(.mem)来完成。
            for (i = 0; i < 128; i = i + 1) begin
                dmem[i] <= 8'b0;
            end
        end else begin
            // 如果写使能有效
            if (DMWr == 1'b1) begin
                // 根据操作类型，将数据写入存储器
                case (DMType)
                    OP_SW: begin
                        dmem[addr]   <= din[7:0];
                        dmem[addr+1] <= din[15:8];
                        dmem[addr+2] <= din[23:16];
                        dmem[addr+3] <= din[31:24];
                    end
                    OP_SH: begin
                        dmem[addr]   <= din[7:0];
                        dmem[addr+1] <= din[15:8];
                    end
                    OP_SB: dmem[addr] <= din[7:0];
                endcase
            end
        end
    end

    // 异步读逻辑: 只要输入地址或类型变化，就立即更新输出
    always @(*) begin
        // 默认为0，以防在非读取指令时生成锁存器
        dout = 32'b0;
        // 根据操作类型，从存储器读取数据并进行相应的扩展
        case (DMType)
            OP_LW:  dout = {dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr]};
            OP_LH:  dout = {{16{dmem[addr+1][7]}}, dmem[addr+1], dmem[addr]}; // 符号位扩展
            OP_LHU: dout = {16'h0000, dmem[addr+1], dmem[addr]};             // 零扩展
            OP_LB:  dout = {{24{dmem[addr][7]}}, dmem[addr]};                // 符号位扩展
            OP_LBU: dout = {24'h000000, dmem[addr]};                         // 零扩展
        endcase
    end
endmodule 