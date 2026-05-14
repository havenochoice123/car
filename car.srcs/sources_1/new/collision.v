`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 15:48:37
// Design Name: 
// Module Name: collision
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


module collision(
    input  wire clk,
    input  wire rst,

    input  wire [9:0] car_x,
    input  wire [9:0] car_y,

    input  wire signed [11:0] obs_x,
    input  wire [9:0] obs_y,
    input  wire [9:0] obs_h,
    input  wire obs_active,

    output reg hit,           // 碰撞脉冲信号 (单周期)
    output reg invincible     // 无敌状态信号
);

    // ---------------------------------------------------
    // 碰撞箱参数定义
    // ---------------------------------------------------
    localparam CAR_W = 16;    // 赛车宽度
    localparam CAR_H = 16;    // 赛车高度
    
    localparam OBS_W = 40;    // 障碍物(管道)宽度
    
    localparam HITBOX_PAD = 2;   // 碰撞箱内缩边距，用于优化手感，避免边缘轻微接触即判定碰撞
    
    // ---------------------------------------------------
    // 冷却/无敌时间计时器
    // ---------------------------------------------------
    localparam COOLDOWN_MAX = 30_000_000; // 碰撞后无敌时间: 0.3秒 @ 100MHz
    
    reg [31:0] cooldown_cnt = 0;
    
    // ---------------------------------------------------
    // 原始碰撞检测 (AABB - 轴对齐包围盒算法)
    // ---------------------------------------------------
    wire signed [11:0] cx0 = {2'b00, car_x};
    wire signed [11:0] cx1 = {2'b00, car_x} + CAR_W;

    // X轴重叠检测：使用有符号比较，防止屏幕外(负坐标)的障碍物错误触发碰撞
    wire collide_x =
        (cx0 + HITBOX_PAD < obs_x + OBS_W - HITBOX_PAD) &&
        (cx1 - HITBOX_PAD > obs_x + HITBOX_PAD);
    
    // Y轴重叠检测
    wire collide_y =
        (car_y + HITBOX_PAD < obs_y + obs_h - HITBOX_PAD) &&
        (car_y + CAR_H - HITBOX_PAD > obs_y + HITBOX_PAD);
    
    // 综合判定：障碍物激活且X、Y轴均重叠
    wire raw_hit = obs_active && collide_x && collide_y;
    
    // ---------------------------------------------------
    // 碰撞处理与冷却逻辑
    // ---------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            hit <= 0;
            invincible <= 0;
            cooldown_cnt <= 0;
        end
        else begin
            hit <= 0; // 默认无碰撞脉冲
    
            if (invincible) begin
                // 处于无敌/冷却状态
                if (cooldown_cnt >= COOLDOWN_MAX) begin
                    invincible <= 0; // 冷却结束
                    cooldown_cnt <= 0;
                end
                else begin
                    cooldown_cnt <= cooldown_cnt + 1;
                end
            end
            else begin
                // 非无敌状态 -> 允许检测新的碰撞
                if (raw_hit) begin
                    hit <= 1;           // 产生碰撞脉冲
                    invincible <= 1;    // 进入无敌状态
                    cooldown_cnt <= 0;
                end
            end
        end
    end

endmodule


