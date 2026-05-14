`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 15:40:57
// Design Name: 
// Module Name: renderer
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


module renderer(
    input  wire       clk,
    input  wire [2:0] state,

    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire       valid,       // 视频有效信号 (video_on)

    input wire signed [11:0] pipe_x,
    input wire [9:0] pipe_y_upper,
    input wire [9:0] pipe_y_lower,

    input wire [9:0] car_x,
    input wire [9:0] car_y,

    input wire inv,               // 无敌状态
    input wire flicker,           // 闪烁信号

    output reg [11:0] rgb         // 12位 RGB 输出 (4-4-4)
);


    ////////////////////////////////////////////////////
    // 尺寸参数定义
    ////////////////////////////////////////////////////
    localparam CAR_W = 16;
    localparam CAR_H = 16;
    
    localparam OBS_W = 20;
    localparam OBS_H = 80;
    
    localparam PIPE_W = 40;
    
    ////////////////////////////////////////////////////
    // 上管道区域判定
    ////////////////////////////////////////////////////
    // 使用有符号数比较，确保负坐标管道正确显示（部分在屏幕外）
    wire signed [11:0] px = {2'b00, pixel_x};
    wire pipe_on = (pipe_x > -PIPE_W) && (pipe_x < 640);
    
    wire pipe_upper_area = pipe_on &&
    (px >= pipe_x) &&
    (px < pipe_x + PIPE_W) &&
    (pixel_y < pipe_y_upper);
    
    ////////////////////////////////////////////////////
    // 下管道区域判定
    ////////////////////////////////////////////////////
    wire pipe_lower_area = pipe_on &&
    (px >= pipe_x) &&
    (px < pipe_x + PIPE_W) &&
    (pixel_y >= pipe_y_lower);

    ////////////////////////////////////////////////////
    // 赛车区域判定
    ////////////////////////////////////////////////////
    wire car_area =
        (pixel_x >= car_x) &&
        (pixel_x <  car_x + CAR_W) &&
        (pixel_y >= car_y) &&
        (pixel_y <  car_y + CAR_H);
    
    ////////////////////////////////////////////////////
    // UI 文本区域判定 (READY / GAME OVER)
    ////////////////////////////////////////////////////
    wire ready_text;
    wire gameover_text;
    
    ui_text utext(
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .state(state),
        .ready(ready_text),
        .gameover(gameover_text)
    );
    
    ////////////////////////////////////////////////////
    // 主 RGB 颜色选择逻辑
    ////////////////////////////////////////////////////
    always @(*) begin
        if (!valid) begin
            rgb = 12'h000; // 消隐区输出黑色
        end else begin
            case (state)
    
            // ----------------------------------------
            // IDLE: 显示 READY 文本
            // ----------------------------------------
            0: begin
                if (ready_text)
                    rgb = 12'h0F0; // 绿色文本
                else
                    rgb = 12'h111; // 暗灰色背景
            end
    
            // ----------------------------------------
            // RUN: 游戏画面
            // ----------------------------------------
            1: begin
                if (car_area) begin
                    if (inv && flicker)
                        rgb = 12'h222;   // 无敌闪烁时"隐身"（显示背景色）
                    else
                        rgb = 12'h0FF;   // 正常显示赛车 (青色)
                end 
                else if (pipe_upper_area)
                    rgb = 12'h0A0; // 管道颜色 (绿色)
                else if (pipe_lower_area)
                    rgb = 12'h0A0;
                else
                    rgb = 12'h222; // 游戏背景色 (深灰)
            end
    
            // ----------------------------------------
            // GAMEOVER: 显示 GAME OVER 文本
            // ----------------------------------------
            2: begin
                if (gameover_text)
                    rgb = 12'hF00; // 红色文本
                else
                    rgb = 12'h111; // 暗灰色背景
            end
    
            endcase
        end
    end

endmodule


