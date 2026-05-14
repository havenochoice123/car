`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 16:29:52
// Design Name: 
// Module Name: game_fsm
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


module game_fsm(
    input  wire clk,
    input  wire rst,
    input  wire start_btn,      // 开始/重置按钮

    input  wire [1:0] life,     // 剩余生命值 (来自 game_data)
    output reg  [2:0] state     // 状态输出: 0=IDLE, 1=RUN, 2=GAMEOVER
);

    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    // 状态机状态定义
    //////////////////////////////////////////////////////////
    localparam IDLE     = 3'd0; // 待机/准备状态
    localparam RUN      = 3'd1; // 游戏进行中
    localparam GAMEOVER = 3'd2; // 游戏结束
    
    //////////////////////////////////////////////////////////
    // 状态机逻辑
    //////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
    
            //----------------------------------------------------
            // 0. IDLE (菜单 / 准备界面)
            //----------------------------------------------------
            IDLE: begin
                // 按下开始键进入游戏
                if (start_btn)
                    state <= RUN;
            end
    
            //----------------------------------------------------
            // 1. RUN (游戏主循环)
            //----------------------------------------------------
            RUN: begin
                // 生命值归零，游戏结束
                if (life == 0)
                    state <= GAMEOVER;
            end
    
            //----------------------------------------------------
            // 2. GAMEOVER (结束界面)
            //----------------------------------------------------
            GAMEOVER: begin
                // 按下开始键返回待机界面 (或直接重新开始，取决于设计)
                if (start_btn)
                    state <= IDLE;
            end
    
            endcase
        end
    end

endmodule

