`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/18 17:06:50
// Design Name: 
// Module Name: debouncer
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


// 简单的按键消抖模块
module debouncer #(parameter CNT_MAX = 500_000)(
    input  wire clk,
    input  wire rst,
    input  wire din,
    output reg  dout
);
    reg din_sync1, din_sync2;
    reg [$clog2(CNT_MAX):0] cnt;

    // 双触发器同步，防止亚稳态
    always @(posedge clk) begin
        if (rst) begin
            din_sync1 <= 0;
            din_sync2 <= 0;
        end else begin
            din_sync1 <= din;
            din_sync2 <= din_sync1;
        end
    end

    // 计数消抖逻辑
    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0;
            dout <= 0;
        end else if (din_sync2 != dout) begin
            if (cnt == CNT_MAX) begin
                dout <= din_sync2;
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end else begin
            cnt <= 0;
        end
    end
endmodule
