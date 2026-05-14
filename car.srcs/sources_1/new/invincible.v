`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 23:19:14
// Design Name: 
// Module Name: invincible
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


module invincible(
    input  wire clk,        // 100MHz 时钟
    input  wire rst,
    input  wire hit_event,  // 发生撞击（单周期脉冲）

    output reg  inv,        // invincible 无敌状态输出
    output wire flicker     // 闪烁信号 (给 renderer 模块用于视觉反馈)
);

    /////////////////////////////////////////////////////////
    // 配置参数
    /////////////////////////////////////////////////////////
    
    // 无敌持续时间：1 秒 (100MHz时钟下)
    localparam INV_TIME_MAX = 100_000_000;
    
    // 闪烁频率：约 10Hz (每100ms翻转一次状态)
    localparam FLICKER_MAX = 5_000_000;
    
    /////////////////////////////////////////////////////////
    // 无敌计时器逻辑
    /////////////////////////////////////////////////////////
    reg [31:0] inv_cnt;
    
    always @(posedge clk) begin
        if (rst) begin
            inv <= 0;
            inv_cnt <= 0;
        end
        else begin
            // 发生撞击 → 进入无敌状态并重置计时器
            if (hit_event) begin
                inv <= 1;
                inv_cnt <= 0;
            end
            else if (inv) begin
                // 计时超过设定时间 → 结束无敌状态
                if (inv_cnt >= INV_TIME_MAX) begin
                    inv <= 0;
                    inv_cnt <= 0;
                end else begin
                    inv_cnt <= inv_cnt + 1;
                end
            end
        end
    end
    
    /////////////////////////////////////////////////////////
    // 闪烁信号产生器 (10Hz)
    /////////////////////////////////////////////////////////
    reg [31:0] flk_cnt = 0;
    reg flk_state = 0;
    
    always @(posedge clk) begin
        flk_cnt <= flk_cnt + 1;
        if (flk_cnt >= FLICKER_MAX) begin
            flk_cnt <= 0;
            flk_state <= ~flk_state; // 翻转闪烁状态
        end
    end
    
    // 仅在无敌状态下输出闪烁信号
    assign flicker = flk_state & inv;

endmodule

