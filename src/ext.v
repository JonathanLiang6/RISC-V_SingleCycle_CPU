//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: EXT
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 立即数扩展单元。根据指令类型对不同格式的立即数进行符号位扩展或拼接。
//
// Dependencies: sccomp_top.v, ctrl.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Added U-Type immediate support.
// Additional Comments:
//
//------------------------------------------------------------------------------

module EXT(
    input [19:0] uimm,    // U-Type 立即数 (高20位)
    input [11:0] iimm,    // I-Type 立即数
    input [11:0] simm,    // S-Type 立即数
    input [11:0] bimm,    // B-Type 立即数
    input [19:0] jimm,    // J-Type 立即数
    input [5:0] EXTOp,    // 扩展操作码
    output reg [31:0] immout // 扩展后的32位立即数
);

    // 扩展操作码定义 (与ctrl.v保持一致)
    localparam EXT_CTRL_JTYPE = 6'b000001;
    localparam EXT_CTRL_UTYPE = 6'b000010;
    localparam EXT_CTRL_BTYPE = 6'b000100;
    localparam EXT_CTRL_STYPE = 6'b001000;
    localparam EXT_CTRL_ITYPE = 6'b010000;

    // 组合逻辑，根据EXTOp选择不同的扩展方式
    always@(*) begin
        // 默认输出为0, 避免生成锁存器
        immout = 32'h0;
        case(EXTOp)
            EXT_CTRL_ITYPE: immout = {{20{iimm[11]}}, iimm};                   // I-Type: 符号扩展
            EXT_CTRL_STYPE: immout = {{20{simm[11]}}, simm};                   // S-Type: 符号扩展
            EXT_CTRL_BTYPE: immout = {{19{bimm[11]}}, bimm, 1'b0};             // B-Type: 符号扩展并左移1位
            EXT_CTRL_JTYPE: immout = {{11{jimm[19]}}, jimm, 1'b0};             // J-Type: 符号扩展并左移1位
            EXT_CTRL_UTYPE: immout = {uimm, 12'h000};                          // U-Type: 拼接高20位，低12位置0
            default:        immout = 32'h0;
        endcase
    end

endmodule 