`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 15:26:38
// Design Name: 
// Module Name: jstk2_spi
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
module jstk2_spi(
    input  wire clk,       // 100 MHz System Clock
    input  wire rst,

    input  wire miso,      // Master In Slave Out (JSTK2 -> FPGA)
    output reg  mosi,      // Master Out Slave In (FPGA -> JSTK2) (可用于设置LED)
    output reg  sclk,      // Serial Clock
    output reg  cs,        // Chip Select (Active Low)

    output reg [9:0] x,
    output reg [9:0] y,
    output reg [7:0] buttons
);

    // 1. SCLK 生成逻辑 (1MHz)
    localparam CLK_DIV = 49; 
    reg [6:0] cnt;

    // 为了防止时钟毛刺，SCLK 的生成逻辑保持不变，但要确保复位逻辑清晰
    always @(posedge clk) begin
        if (rst || state != ST_RECV) begin
            cnt <= 0;
            sclk <= 0; // 空闲时 SCLK 为低 (Mode 0)
        end else begin
            if (cnt == CLK_DIV) begin
                cnt <= 0;
                sclk <= ~sclk;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    // 检测 SCLK 上升沿用于采样数据
    reg sclk_d;
    always @(posedge clk) sclk_d <= sclk;
    wire sclk_rising = (sclk && !sclk_d);

    // 2. 状态机与数据接收
    reg [39:0] data_reg;   // 5 Bytes = 40 bits
    reg [23:0] wait_cnt;   // 【修改】增加位宽以支持更长的延时
    reg [5:0]  bit_cnt;
    reg [2:0]  state;

    localparam ST_INIT   = 0;
    localparam ST_START  = 1;
    localparam ST_RECV   = 2;
    localparam ST_PAUSE  = 3;
    localparam ST_LATCH  = 4;

    // 时间常量 (基于 100MHz 时钟)
    localparam T_100MS = 24'd10_000_000;
    localparam T_20US  = 24'd2_000;      

    always @(posedge clk) begin
        if (rst) begin
            cs <= 1;
            mosi <= 0; // 暂时不发命令，保持为0
            state <= ST_INIT;
            wait_cnt <= 0;
            x <= 10'd512;       // 中位值
            y <= 10'd512;       // 中位值
            buttons <= 0;
            data_reg <= 0;
        end
        else begin
            case(state)

            ST_INIT: begin 
                cs <= 1;
                wait_cnt <= wait_cnt + 1;
                // 【修改】真正的 100ms 延时，等待 Pmod 启动
                if (wait_cnt >= T_100MS) begin
                    wait_cnt <= 0;
                    state <= ST_START;
                end
            end

            ST_START: begin 
                cs <= 0; // 拉低片选，开始传输
                wait_cnt <= wait_cnt + 1;
                // 【修改】延时 20us，确保 CS 建立时间充足
                if (wait_cnt >= T_20US) begin 
                    wait_cnt <= 0;
                    bit_cnt <= 0;
                    state <= ST_RECV;
                end
            end

            ST_RECV: begin 
                // JSTK2 (SPI Mode 0) 在 SCLK 上升沿采样数据
                if (sclk_rising) begin
                    // 左移存入数据：先收到的位在高位 (如果你想用 data_reg[0] 存最新位)
                    // 但为了方便解析，我们采用：{data_reg[38:0], miso} 
                    // 这样 data_reg[39] 将是第一个接收到的位
                    data_reg <= {data_reg[38:0], miso};
                    
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 39) begin // 接收完 40 位 (0-39)
                        state <= ST_LATCH;
                    end
                end
            end

            ST_LATCH: begin
                cs <= 1; // 传输结束
                
                // 【核心修改】数据解析映射
                // JSTK2 发送顺序: X_Low -> X_High -> Y_Low -> Y_High -> Buttons
                // 因为我们是左移入 data_reg，最早收到的数据在最高位 [39:32]
                
                // X 轴解析: High 2 bits + Low 8 bits
                // Byte 1 (First In)  = data_reg[39:32] (X Low)
                // Byte 2 (Second In) = data_reg[31:24] (X High)
                x <= {data_reg[25:24], data_reg[39:32]}; 

                // Y 轴解析
                // Byte 3 (Third In)  = data_reg[23:16] (Y Low)
                // Byte 4 (Fourth In) = data_reg[15:8]  (Y High)
                y <= {data_reg[9:8], data_reg[23:16]};

                // 按钮解析
                // Byte 5 (Last In)   = data_reg[7:0]
                buttons <= data_reg[7:0];

                wait_cnt <= 0;
                state <= ST_PAUSE;
            end

            ST_PAUSE: begin 
                // 两次读取之间的间隔，避免读太快
                wait_cnt <= wait_cnt + 1;
                if (wait_cnt >= T_20US) begin
                    wait_cnt <= 0;
                    state <= ST_START;
                end
            end

            endcase
        end
    end

endmodule


