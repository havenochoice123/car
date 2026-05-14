`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 16:13:03
// Design Name: 
// Module Name: game_data
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


module game_data(
    input  wire clk,        // 100MHz 时钟
    input  wire rst,

    input  wire [2:0] state,      // 游戏状态: 0=IDLE, 1=RUN, 2=GAMEOVER
    input  wire hit,              // 碰撞信号 (来自 collision 模块的单周期脉冲)

    output reg [1:0] life,        // 剩余生命值
    output reg [15:0] score       // 当前得分
);

    /////////////////////////////////////////////////////
    // 参数定义
    /////////////////////////////////////////////////////
    localparam MAX_LIFE = 3;      // 最大生命值
    
    // 分数增加间隔：每 N 个时钟周期增加 1 分
    localparam SCORE_INC_MAX = 20_000_000; // 减慢得分速度，避免游戏过快结束
    
    reg [31:0] score_cnt;
    
    /////////////////////////////////////////////////////
    // 游戏数据逻辑
    /////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (rst) begin
            life <= MAX_LIFE;
            score <= 0;
            score_cnt <= 0;
        end
        else begin
            case (state)
    
            // ----------------------------------------
            // IDLE: 重置游戏数据
            // ----------------------------------------
            0: begin
                life <= MAX_LIFE;
                score <= 0;
                score_cnt <= 0;
            end
    
            // ----------------------------------------
            // RUN: 游戏主循环
            // ----------------------------------------
            1: begin
                // 1. 计分逻辑 (基于时间)
                score_cnt <= score_cnt + 1;
                if (score_cnt >= SCORE_INC_MAX) begin
                    score_cnt <= 0;
                    score <= score + 1;
                end
    
                // 2. 生命值逻辑 (基于碰撞事件)
                if (hit && life > 0) begin
                    life <= life - 1;
                end
            end
    
            // ----------------------------------------
            // GAMEOVER: 冻结数值
            // ----------------------------------------
            2: begin
                // 保持生命值和分数不变，供显示模块使用
            end
    
            endcase
        end
    end

endmodule

