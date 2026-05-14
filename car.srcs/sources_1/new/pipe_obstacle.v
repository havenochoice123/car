`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/29 12:16:30
// Design Name: 
// Module Name: pipe_obstacle
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

module pipe_obstacle(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] state,
    input  wire [15:0] score,

    output reg signed [11:0] pipe_x, // 12位有符号数，允许屏幕外的负坐标
    output reg [9:0] pipe_y_upper,   // 上管道下边缘Y坐标
    output reg [9:0] pipe_y_lower    // 下管道上边缘Y坐标
);

    localparam SCREEN_W = 640;
    localparam PIPE_W = 40;
    localparam GAP_MIN = 100; 
    localparam GAP_MAX = 180; 
    localparam BASE_SPEED = 2; // 基础速度，较低以减少跳跃感

    // 移动更新频率控制 (~120 Hz)，使运动更平滑
    localparam MOVE_TICK_MAX = 833_333; // 100MHz / 120 ≈ 8.33e5

    // 随机数生成器 (LFSR)
    reg [15:0] lfsr = 16'hACE1;
    always @(posedge clk) lfsr <= {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
    wire [9:0] rand_h = lfsr[9:0];
    wire [9:0] rand_gap = lfsr[15:8];

    reg [9:0] speed;
    // 难度随分数增加：每40分速度+1
    always @(posedge clk) speed <= BASE_SPEED + (score / 40);

    // 移动时钟分频器
    reg [20:0] move_div;
    wire move_tick = (move_div == MOVE_TICK_MAX);

    integer gap, upper_h;

    // 产生低频移动脉冲
    always @(posedge clk) begin
        if (rst || state != 1)
            move_div <= 0;
        else if (move_tick)
            move_div <= 0;
        else
            move_div <= move_div + 1;
    end

    // 管道位置更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            pipe_x <= SCREEN_W + 60;
            pipe_y_upper <= 150;
            pipe_y_lower <= 290;
        end else begin
            case (state)
            0: begin // IDLE: 保持在屏幕外
                pipe_x <= SCREEN_W + 60; 
            end
            
            1: begin // RUN: 游戏进行中
                if (move_tick) begin
                    pipe_x <= pipe_x - speed; // 向左移动

                    // 当管道完全移出左边界 (-40) → 重生到右侧
                    if (pipe_x < -PIPE_W) begin 
                        pipe_x <= SCREEN_W + (rand_gap % 100); // 随机水平偏移
                        
                        // 随机生成上下管道的间隙和位置
                        gap = GAP_MIN + (rand_gap % (GAP_MAX - GAP_MIN));
                        upper_h = 50 + (rand_h % 250); 
                        
                        pipe_y_upper <= upper_h;
                        pipe_y_lower <= upper_h + gap;
                    end
                end
            end
            
            2: pipe_x <= pipe_x; // GAMEOVER: 停止移动
            endcase
        end
    end 
endmodule