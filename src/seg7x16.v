//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: seg7x16
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 8位7段数码管动态扫描驱动模块。
//
// Dependencies: sccomp_top.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed sensitivity lists, formatting, and potential latches.
// Additional Comments:
// - disp_mode=0: 将输入的4-bit数据译码为7段码显示。
// - disp_mode=1: 直接将输入的8-bit数据显示 (数据应为预编码的7段码)。
//------------------------------------------------------------------------------

module seg7x16(
    input clk,            // 主时钟
    input rstn,           // 复位信号 (低电平有效)
    input disp_mode,      // 显示模式选择
    input[63:0] i_data,   // 待显示的64位数据
    output [7:0] o_seg,   // 7段数码管段选信号 (共阴)
    output [7:0] o_sel    // 8位-数码管位选信号 (低电平有效)
);

    //================================================================
    // 1. 生成数码管扫描时钟 (seg7_clk)
    //================================================================
    reg [14:0] cnt;
    wire seg7_clk;

    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;
    end
    assign seg7_clk = cnt[14]; // 分频产生一个较慢的刷新时钟

    //================================================================
    // 2. 生成位选地址 (seg7_addr) 和位选信号 (o_sel_r)
    //================================================================
    reg [2:0] seg7_addr;

    always @(posedge seg7_clk or negedge rstn) begin
        if(!rstn)
            seg7_addr <= 0;
        else
            seg7_addr <= seg7_addr + 1'b1; // 3-bit地址，从0到7循环扫描
    end

    reg [7:0] o_sel_r;
    always @(*) begin
        case(seg7_addr)
            3'd0:    o_sel_r = 8'b11111110;
            3'd1:    o_sel_r = 8'b11111101;
            3'd2:    o_sel_r = 8'b11111011;
            3'd3:    o_sel_r = 8'b11110111;
            3'd4:    o_sel_r = 8'b11101111;
            3'd5:    o_sel_r = 8'b11011111;
            3'd6:    o_sel_r = 8'b10111111;
            3'd7:    o_sel_r = 8'b01111111;
            default: o_sel_r = 8'b11111111; // 默认全不选
        endcase
    end

    //================================================================
    // 3. 根据模式和地址选择要显示的数据 (seg_data_r)
    //================================================================
    reg [63:0] i_data_store;
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            i_data_store <= 0;
        else
            i_data_store <= i_data;
    end

    reg [7:0] seg_data_r;
    always @(*) begin
        seg_data_r = 8'h0; // 默认值
        if (disp_mode == 1'b0) begin // 模式0: 4-bit to 7-seg
            case(seg7_addr)
                3'd0:    seg_data_r = {4'b0, i_data_store[3:0]};
                3'd1:    seg_data_r = {4'b0, i_data_store[7:4]};
                3'd2:    seg_data_r = {4'b0, i_data_store[11:8]};
                3'd3:    seg_data_r = {4'b0, i_data_store[15:12]};
                3'd4:    seg_data_r = {4'b0, i_data_store[19:16]};
                3'd5:    seg_data_r = {4'b0, i_data_store[23:20]};
                3'd6:    seg_data_r = {4'b0, i_data_store[27:24]};
                3'd7:    seg_data_r = {4'b0, i_data_store[31:28]};
                default: seg_data_r = 8'h0;
            endcase
        end else begin // 模式1: 8-bit passthrough
            case(seg7_addr)
                3'd0:    seg_data_r = i_data_store[7:0];
                3'd1:    seg_data_r = i_data_store[15:8];
                3'd2:    seg_data_r = i_data_store[23:16];
                3'd3:    seg_data_r = i_data_store[31:24];
                3'd4:    seg_data_r = i_data_store[39:32];
                3'd5:    seg_data_r = i_data_store[47:40];
                3'd6:    seg_data_r = i_data_store[55:48];
                3'd7:    seg_data_r = i_data_store[63:56];
                default: seg_data_r = 8'h0;
            endcase
        end
    end

    //================================================================
    // 4. 将数据显示数据译码为7段码 (o_seg_r)
    //================================================================
    reg [7:0] o_seg_r;
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            o_seg_r <= 8'hff; // 复位时关闭所有段
        else if(disp_mode == 1'b0) begin // 模式0: 译码
            case(seg_data_r[3:0]) // 只关心低4位
                4'h0:    o_seg_r <= 8'hC0; // 0
                4'h1:    o_seg_r <= 8'hF9; // 1
                4'h2:    o_seg_r <= 8'hA4; // 2
                4'h3:    o_seg_r <= 8'hB0; // 3
                4'h4:    o_seg_r <= 8'h99; // 4
                4'h5:    o_seg_r <= 8'h92; // 5
                4'h6:    o_seg_r <= 8'h82; // 6
                4'h7:    o_seg_r <= 8'hF8; // 7
                4'h8:    o_seg_r <= 8'h80; // 8
                4'h9:    o_seg_r <= 8'h90; // 9
                4'hA:    o_seg_r <= 8'h88; // A
                4'hB:    o_seg_r <= 8'h83; // b
                4'hC:    o_seg_r <= 8'hC6; // C
                4'hD:    o_seg_r <= 8'hA1; // d
                4'hE:    o_seg_r <= 8'h86; // E
                4'hF:    o_seg_r <= 8'h8E; // F
                default: o_seg_r <= 8'hFF; // 默认关闭
            endcase
        end else begin // 模式1: 直通
            o_seg_r <= seg_data_r;
        end
    end

    //================================================================
    // 5. 输出赋值
    //================================================================
    assign o_sel = o_sel_r;
    assign o_seg = o_seg_r;

endmodule 