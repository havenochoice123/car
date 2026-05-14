`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 15:31:24
// Design Name: 
// Module Name: vga_driver
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


module vga_driver(
    input wire clk,    // 25MHz 像素时钟
    input wire rst,

    output reg hsync,          // 行同步信号
    output reg vsync,          // 场同步信号
    output reg [9:0] pixel_x,  // 当前像素 X 坐标
    output reg [9:0] pixel_y,  // 当前像素 Y 坐标
    output wire video_on       // 视频有效区域标志
);

    ///////////////////////////////////////////////////
    // VGA 时序参数 (640×480 @ 60Hz)
    ///////////////////////////////////////////////////
    
    // 水平扫描参数 (单位: 像素时钟周期)
    localparam H_VISIBLE = 640; // 可视区域宽度
    localparam H_FRONT   = 16;  // 前肩
    localparam H_SYNC    = 96;  // 同步脉冲宽度
    localparam H_BACK    = 48;  // 后肩
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 总周期 800
    
    // 垂直扫描参数 (单位: 行)
    localparam V_VISIBLE = 480; // 可视区域高度
    localparam V_FRONT   = 10;  // 前肩
    localparam V_SYNC    = 2;   // 同步脉冲宽度
    localparam V_BACK    = 33;  // 后肩
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 总行数 525
    
    ///////////////////////////////////////////////////
    // 扫描计数器
    ///////////////////////////////////////////////////
    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;
    
    always @(posedge clk) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            // 水平计数器
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
    
                // 垂直计数器 (每完成一行扫描增加一次)
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
    
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end
    
    ///////////////////////////////////////////////////
    // 生成同步信号 (低电平有效)
    ///////////////////////////////////////////////////
    always @(posedge clk) begin
        // 行同步信号生成
        if (h_cnt >= H_VISIBLE + H_FRONT &&
            h_cnt <  H_VISIBLE + H_FRONT + H_SYNC)
            hsync <= 0;
        else
            hsync <= 1;
    
        // 场同步信号生成
        if (v_cnt >= V_VISIBLE + V_FRONT &&
            v_cnt <  V_VISIBLE + V_FRONT + V_SYNC)
            vsync <= 0;
        else
            vsync <= 1;
    end
    
    ///////////////////////////////////////////////////
    // 像素坐标输出
    ///////////////////////////////////////////////////
    always @(posedge clk) begin
        pixel_x <= (h_cnt < H_VISIBLE) ? h_cnt : 10'd0;
        pixel_y <= (v_cnt < V_VISIBLE) ? v_cnt : 10'd0;
    end
    
    ///////////////////////////////////////////////////
    // 视频有效信号：当扫描点处于可视区域内时为高
    ///////////////////////////////////////////////////
    assign video_on = (h_cnt < H_VISIBLE && v_cnt < V_VISIBLE);
    
endmodule

