`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 23:13:12
// Design Name: 
// Module Name: ui_text
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


module ui_text(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [2:0] state,

    output wire ready,
    output wire gameover
);

    ////////////////////////////////////////////
    // READY 文本区域 (简单的矩形条)
    ////////////////////////////////////////////
    localparam RX0 = 200;
    localparam RY0 = 150;
    
    // 判断当前像素是否在 READY 文本区域内
    wire in_ready_region =
        (pixel_x >= RX0) && (pixel_x < RX0 + 160) &&
        (pixel_y >= RY0) && (pixel_y < RY0 + 32);
    
    // 仅在状态 0 (IDLE) 显示
    assign ready = (state == 0) && in_ready_region;
    
    ////////////////////////////////////////////
    // GAME OVER 文本区域 (简单的矩形条)
    ////////////////////////////////////////////
    localparam GX0 = 180;
    localparam GY0 = 200;
    
    // 判断当前像素是否在 GAME OVER 文本区域内
    wire in_go_region =
        (pixel_x >= GX0) && (pixel_x < GX0 + 240) &&
        (pixel_y >= GY0) && (pixel_y < GY0 + 32);
    
    // 仅在状态 2 (GAMEOVER) 显示
    assign gameover = (state == 2) && in_go_region;
    
endmodule

