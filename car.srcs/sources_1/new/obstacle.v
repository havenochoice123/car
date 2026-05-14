`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 15:45:14
// Design Name: 
// Module Name: obstacle
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


module obstacles(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] state,
    input  wire [15:0] score,

    output reg [9:0] obs0_x, obs0_y,
    output reg [9:0] obs1_x, obs1_y,
    output reg [9:0] obs2_x, obs2_y
);

    /////////////////////////////////////////////////////
    // 参数定义
    /////////////////////////////////////////////////////
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;
    
    localparam OBS_W = 20;
    localparam OBS_H = 80;
    
    localparam BASE_SPEED = 3; // 基础移动速度
    
    /////////////////////////////////////////////////////
    // LFSR 伪随机数生成器
    /////////////////////////////////////////////////////
    reg [15:0] lfsr = 16'hACE1;
    
    always @(posedge clk) begin
        // 简单的线性反馈移位寄存器，用于生成随机位置
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end
    
    wire [7:0] r0 = lfsr[7:0];
    wire [7:0] r1 = lfsr[15:8];
    
    /////////////////////////////////////////////////////
    // 速度控制：随分数增加而加快
    /////////////////////////////////////////////////////
    reg [7:0] speed;
    
    always @(posedge clk) begin
        speed <= BASE_SPEED + (score / 10);
    end
    
    /////////////////////////////////////////////////////
    // 障碍物位置更新任务 (Task)
    /////////////////////////////////////////////////////
    task update_obstacle;
        inout reg [9:0] x;
        inout reg [9:0] y;
        input  [7:0] rand_y;
        input  [7:0] rand_gap;
    
        // 如果障碍物还在屏幕内或左侧边缘，继续向左移动
        if (x >= -OBS_W)
            x = x - speed;
        else begin
            // 移出屏幕后，重置到右侧，并随机生成新的Y坐标
            x = SCREEN_W + (rand_gap % 200);
            y = (rand_y % (SCREEN_H - OBS_H));
        end
    endtask
    
    /////////////////////////////////////////////////////
    // 主逻辑
    /////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (rst) begin
            // 复位位置
            obs0_x <= 700; obs0_y <= 100;
            obs1_x <= 500; obs1_y <= 200;
            obs2_x <= 900; obs2_y <= 150;
        end else begin
            case (state)
    
            0: begin  // IDLE: 保持初始位置
                obs0_x <= 700; obs0_y <= 100;
                obs1_x <= 500; obs1_y <= 200;
                obs2_x <= 900; obs2_y <= 150;
            end
    
            1: begin  // RUN: 更新障碍物位置
                // 这里应该调用 update_obstacle，但在 always 块中直接写逻辑可能更清晰或需要适配 Verilog 版本
                // 注意：原代码似乎截断了，这里假设是完整逻辑的意图
                // 由于 task 在 always 块中调用有局限性，通常直接展开写
                
                // 障碍物 0
                if (obs0_x >= -OBS_W) obs0_x <= obs0_x - speed;
                else begin
                    obs0_x <= SCREEN_W + (r0 % 200);
                    obs0_y <= (r1 % (SCREEN_H - OBS_H));
                end

                // 障碍物 1 (使用 lfsr 的不同部分或下一周期的值，这里简化处理)
                if (obs1_x >= -OBS_W) obs1_x <= obs1_x - speed;
                else begin
                    obs1_x <= SCREEN_W + (r1 % 200);
                    obs1_y <= (r0 % (SCREEN_H - OBS_H));
                end
                
                // 障碍物 2
                if (obs2_x >= -OBS_W) obs2_x <= obs2_x - speed;
                else begin
                    obs2_x <= SCREEN_W + ((r0+r1) % 200);
                    obs2_y <= ((r1+30) % (SCREEN_H - OBS_H));
                end
            end
            
            2: begin // GAMEOVER: 停止移动
                // 保持当前值
            end
            
            endcase
        end
    end

endmodule
                update_obstacle(obs0_x, obs0_y, r0, r1);
                update_obstacle(obs1_x, obs1_y, r1, r0);
                update_obstacle(obs2_x, obs2_y, r0 ^ r1, r0 + r1);
            end
    
            2: begin  // GAMEOVER
                // keep still
            end
    
            endcase
        end
    end

endmodule



