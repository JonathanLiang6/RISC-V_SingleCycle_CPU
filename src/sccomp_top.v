//------------------------------------------------------------------------------
// Author:Jonathan Liang
//
// Create Date:2025.03.21
// Design Name:SingleCycleCPU
// Module Name: sccomp
// Project Name:SingleCycleCPU
// Target Devices:
// Tool Versions:
// Description: 单周期CPU顶层模块，集成了CPU核心与外设接口。
//
// Dependencies: pc.v, npc.v, ctrl.v, rf.v, alu.v, ext.v, dm.v, seg7x16.v
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Corrected module instantiations and added full comments.
// Additional Comments:
//
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

module sccomp(
    input clk,                // 全局时钟输入
    input rstn,               // 全局复位输入 (低电平有效)
    input [15:0] sw_i,        // 开关输入信号，用于控制和调试
    output [7:0] disp_seg_o,  // 7段数码管段选输出
    output [7:0] disp_an_o    // 7段数码管位选输出
);

//================================================================
// 1. 时钟生成与选择
//================================================================
reg [31:0] clkdiv; // 时钟分频计数器
wire Clk_CPU;      // CPU核心工作时钟
wire Clk_instr;    // 指令存储器时钟

// 时钟分频逻辑
always @(posedge clk or negedge rstn) begin
    if (!rstn)
        clkdiv <= 0;
    else
        clkdiv <= clkdiv + 1'b1;
end

// CPU时钟选择逻辑: sw_i[15]用于选择快慢时钟
assign Clk_CPU = (sw_i[15]) ? clkdiv[27] : clkdiv[25];
assign Clk_instr = Clk_CPU & ~sw_i[1];

//================================================================
// 2. 调试与显示信号
//================================================================
reg [63:0] display_data;
reg [5:0] led_data_addr;
reg [63:0] led_disp_data;
reg [31:0] reg_data;
reg [31:0] reg_addr;
reg [31:0] alu_disp_data;
reg [2:0] alu_addr;
reg [31:0] dmem_data;
reg [7:0] dmem_addr;
parameter LED_DATA_NUM = 19;
parameter IM_CODE_NUM = 12;
parameter DM_DATA_NUM = 16;
reg [63:0] LED_DATA [18:0];

//================================================================
// 3. CPU核心信号线声明
//================================================================
wire [6:0] Op;
wire [6:0] Funct7;
wire [2:0] Funct3;
wire [19:0] uimm;
wire [11:0] iimm;
wire [11:0] simm;
wire [11:0] bimm;
wire [19:0] jimm;
wire [5:0] EXTOp;
wire [31:0] immout;
wire [4:0] rs1, rs2, rd;
reg [31:0] WD;
wire [1:0] WDSel;
wire RegWrite;
wire [31:0] RD1, RD2;
wire [31:0] A, B;
wire ALUSrc;
wire [4:0] ALUOp;
wire [31:0] aluout;
wire Zero;
wire MemWrite;
wire [2:0] DMType;
wire [31:0] dm_dout;
wire [2:0] NPCOp;
wire [31:0] PC;
wire [31:0] NPC;
wire [31:0] instr;
wire [31:0] PC_plus_4;


//================================================================
// 4. CPU数据通路
//================================================================
assign Op = instr[6:0];
assign Funct7 = instr[31:25];
assign Funct3 = instr[14:12];
assign rs1 = instr[19:15];
assign rs2 = instr[24:20];
assign rd = instr[11:7];
assign uimm = instr[31:12];
assign iimm = instr[31:20];
assign simm = {instr[31:25], instr[11:7]};
assign bimm = {instr[31], instr[7], instr[30:25], instr[11:8]};
assign jimm = {instr[31], instr[19:12], instr[20], instr[30:21]};

assign A = RD1;
assign B = (ALUSrc) ? immout : RD2;

assign PC_plus_4 = PC + 4;

//-- 寄存器写回数据选择 (采纳CPU.md中的always块风格)
always@(*) begin
    case(WDSel)
        2'b00: WD = aluout;  // 来源: ALU计算结果
        2'b01: WD = dm_dout; // 来源: 数据存储器
        2'b10: WD = PC + 4;  // 来源: PC+4 (用于JAL/JALR)
        default: WD = aluout; // 默认来源
    endcase
end

//================================================================
// 5. CPU模块实例化
//================================================================
ctrl U_ctrl(
    .Op(Op), .Funct7(Funct7), .Funct3(Funct3), .Zero(Zero),
    .RegWrite(RegWrite), .MemWrite(MemWrite), .EXTOp(EXTOp), .ALUOp(ALUOp),
    .ALUSrc(ALUSrc), .DMType(DMType), .WDSel(WDSel), .NPCOp(NPCOp)
);

EXT U_EXT(
    .uimm(uimm), .iimm(iimm), .simm(simm), .bimm(bimm), .jimm(jimm), .EXTOp(EXTOp),
    .immout(immout)
);

PC U_PC(
    .clk(Clk_CPU), .rstn(rstn), .sw_i(sw_i), .NPC(NPC),
    .PCout(PC)
);

NPC U_NPC(
    .PC(PC), .NPCOp(NPCOp), .immout(immout), .aluout(aluout),
    .NPC(NPC)
);

RF U_RF(
    .clk(Clk_CPU), .rstn(rstn), .RFwr(RegWrite),
    .A1(rs1), .A2(rs2), .A3(rd), .WD(WD),
    .RD1(RD1), .RD2(RD2)
);

alu U_alu(
    .A(A), .B(B), .ALUOp(ALUOp),
    .C(aluout), .Zero(Zero)
);

dm U_DM(
    .clk(Clk_CPU), .rstn(rstn), .DMWr(MemWrite),
    .addr(aluout[6:0]), .din(RD2), .DMType(DMType),
    .dout(dm_dout)
);

//================================================================
// 6. 指令与数据存储器
//================================================================
// 实例化指令ROM IP核 (dist_mem_gen_0), 替换原有的Verilog实现
dist_mem_gen_0 U_IM (
  .a(PC[8:2]),   // 地址输入 (PC是字节地址, 右移两位变为字地址)
  .spo(instr)    // 32位指令数据输出
);

//================================================================
// 7. 调试与显示逻辑
//================================================================
// ... (保留原有的调试和显示逻辑，仅修正注释和格式)
always @(posedge Clk_CPU or negedge rstn) begin
    if (!rstn) begin
        led_data_addr <= 6'd0;
        led_disp_data <= 64'b1;
    end else if (sw_i[0] == 1'b1) begin
        if (led_data_addr == LED_DATA_NUM) begin
            led_data_addr <= 6'd0;
            led_disp_data <= 64'b1;
        end else begin
            led_disp_data <= LED_DATA[led_data_addr];
            led_data_addr <= led_data_addr + 1'b1;
        end
    end else begin
        led_data_addr <= led_data_addr;
    end
end

always @(posedge Clk_CPU or negedge rstn) begin
    if (!rstn)
        reg_addr <= 0;
    else if (sw_i[13] == 1'b1) begin
        if (reg_addr == 31)
            reg_addr <= 0;
        else
            reg_addr <= reg_addr + 1;
        reg_data = U_RF.rf[reg_addr];
    end
end

always @(posedge Clk_CPU) begin
    alu_addr = alu_addr + 1'b1;
    case (alu_addr)
        3'b001: alu_disp_data = U_alu.A;
        3'b010: alu_disp_data = U_alu.B;
        3'b011: alu_disp_data = U_alu.C;
        3'b100: alu_disp_data = {31'b0, U_alu.Zero};
        default: alu_disp_data = 32'hffffffff;
    endcase
end

always @(posedge Clk_CPU or negedge rstn) begin
    if (!rstn) begin
        dmem_addr <= 0;
        dmem_data <= 32'hFFFFFFFF;
    end else if (sw_i[11] == 1'b1) begin
        if (dmem_addr == 16)
            dmem_addr <= 4'b0;
        else begin
            dmem_data <= U_DM.dmem[dmem_addr];
            dmem_addr <= dmem_addr + 1'b1;
        end
    end
end

initial begin
    LED_DATA[0] = 64'hC6F6F6F0C6F6F6F0;
    LED_DATA[1] = 64'hF9F6F6CFF9F6F6CF;
    LED_DATA[2] = 64'hFFC6F0FFFFC6F0FF;
    LED_DATA[3] = 64'hFFC0FFFFFFC0FFFF;
    LED_DATA[4] = 64'hFFA3FFFFFFA3FFFF;
    LED_DATA[5] = 64'hFFFFA3FFFFFFA3FF;
    LED_DATA[6] = 64'hFFFF9CFFFFFF9CFF;
    LED_DATA[7] = 64'hFF9EBCFFFF9EBCFF;
    LED_DATA[8] = 64'hFF9CFFFFFF9CFFFF;
    LED_DATA[9] = 64'hFFC0FFFFFFC0FFFF;
    LED_DATA[10] = 64'hFFA3FFFFFFA3FFFF;
    LED_DATA[11] = 64'hFFA7B3FFFFA7B3FF;
    LED_DATA[12] = 64'hFFC6F0FFFFC6F0FF;
    LED_DATA[13] = 64'hF9F6F6CFF9F6F6CF;
    LED_DATA[14] = 64'h9EBEBEBC9EBEBEBC;
    LED_DATA[15] = 64'h2737373327373733;
    LED_DATA[16] = 64'h505454EC505454EC;
    LED_DATA[17] = 64'h744454F8744454F8;
    LED_DATA[18] = 64'h0062080000620800;
end

always @(sw_i) begin
    if (sw_i[0] == 1'b0) begin
        case (sw_i[14:11])
            4'b1000: display_data = instr;
            4'b0100: display_data = reg_data;
            4'b0010: display_data = alu_disp_data;
            4'b0001: display_data = dmem_data;
            default: display_data = instr;
        endcase
    end else begin
        display_data = led_disp_data;
    end
end

seg7x16 U_seg7x16(
    .clk(clk), .rstn(rstn),
    .disp_mode(1'b0),
    .i_data(display_data),
    .o_seg(disp_seg_o),
    .o_sel(disp_an_o)
);

endmodule 