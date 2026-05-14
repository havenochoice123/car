`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 23:04:15
// Design Name: 
// Module Name: sevenseg
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


module sevenseg(
    input  wire clk,        // 100MHz 时钟
    input  wire [15:0] score,      // 分数输入 (来自 game_data)

    output reg  [7:0]  an,         // 数码管位选信号 (Anode)
    output reg  [6:0]  seg,        // 数码管段选信号 (Segments)
    output reg dp                  // 小数点
);

    /////////////////////////////////////////////////////////////
    // 扫描时钟分频器 (每位约1kHz刷新率)
    /////////////////////////////////////////////////////////////
    reg [15:0] clkdiv;
    always @(posedge clk) clkdiv <= clkdiv + 1;
    
    wire [2:0] scan_sel = clkdiv[15:13]; // 取高位用于8位扫描选择
    
    /////////////////////////////////////////////////////////////
    // 分数拆分逻辑 (0-9999)
    /////////////////////////////////////////////////////////////
    reg [3:0] d[7:0]; // 8个数字位，目前只使用低4位 d0-d3
    integer i;
    
    always @(*) begin
        for (i=0; i<8; i=i+1) d[i] = 4'hF; // 默认关闭 (F)
        d[0] = (score      ) % 10; // 个位
        d[1] = (score / 10 ) % 10; // 十位
        d[2] = (score / 100) % 10; // 百位
        d[3] = (score / 1000) % 10; // 千位
    end
    
    /////////////////////////////////////////////////////////////
    // 7段数码管译码器 (共阳极)
    /////////////////////////////////////////////////////////////
    reg [3:0] digit;
    
    always @(*) begin
        case (digit)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // 全灭
        endcase
    end
    
    /////////////////////////////////////////////////////////////
    // 动态扫描逻辑
    /////////////////////////////////////////////////////////////
    always @(*) begin
        dp = 1'b1; // 始终关闭小数点 (共阳极低电平有效，这里置1关闭)
    
        case(scan_sel)
            3'd0: begin an = 8'b1111_1110; digit = d[0]; end // 最右侧位
            3'd1: begin an = 8'b1111_1101; digit = d[1]; end
            3'd2: begin an = 8'b1111_1011; digit = d[2]; end
            3'd3: begin an = 8'b1111_0111; digit = d[3]; end
            default: begin an = 8'b1111_1111; digit = 4'hF; end // 其他位关闭
        endcase
    end

endmodule

