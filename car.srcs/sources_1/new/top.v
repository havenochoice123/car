`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 14:41:22
// Design Name: 
// Module Name: top
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


module top(
    input  wire       clk,       // 100MHz 板载时钟
    input  wire       rst,       // 复位信号 (来自 SW0)

    // 按钮输入 (上, 下, 左, 右)
    input  wire [3:0] btn,
    input  wire       start_btn, // 中间按钮 (开始/重置)



    // VGA 输出接口
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hs,
    output wire       vga_vs,

    // LED 指示灯
    output wire [1:0] led,

    // 7段数码管接口
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire       dp
);
    // =====================================================
    // 1. 时钟分频: 100MHz → 25MHz (供VGA 640x480 @ 60Hz 使用)
    // =====================================================
    reg [1:0] clk_div_cnt = 0;
    always @(posedge clk) begin
        clk_div_cnt <= clk_div_cnt + 1;
    end
    
    wire clk_25 = clk_div_cnt[1];   // 100MHz / 4 = 25MHz
    
    
    // =====================================================
    // 2. 公共信号定义
    // =====================================================
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_on;
    wire [1:0]  life;
    wire [15:0] score;
    
    // VGA 驱动模块实例化
    vga_driver vga_inst (
        .clk(clk_25),
        .rst(rst),
        .hsync(vga_hs),
        .vsync(vga_vs),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on)
    );
    
    
    // =====================================================
    // 4. 游戏状态机 (主控逻辑)
    // =====================================================
    wire [2:0] game_state;
    
    game_fsm fsm_inst (
        .clk(clk),
        .rst(rst),
        .start_btn(start_btn),
        .life(life),
        .state(game_state)
    );
    
    
    // =====================================================
    // 5. 赛车物理运动 (由板载按钮控制)
    // =====================================================
    wire [9:0] car_x;
    wire [9:0] car_y;
    // 按钮消抖处理，提高可靠性
    wire [3:0] btn_db;
    debouncer #(.CNT_MAX(500_000)) db_up   (.clk(clk), .rst(rst), .din(btn[0]), .dout(btn_db[0]));
    debouncer #(.CNT_MAX(500_000)) db_down (.clk(clk), .rst(rst), .din(btn[1]), .dout(btn_db[1]));
    debouncer #(.CNT_MAX(500_000)) db_left (.clk(clk), .rst(rst), .din(btn[2]), .dout(btn_db[2]));
    debouncer #(.CNT_MAX(500_000)) db_right(.clk(clk), .rst(rst), .din(btn[3]), .dout(btn_db[3]));

    car_motion car_inst (
        .clk(clk),
        .rst(rst),
        .state(game_state),
        .btn_up(btn_db[0]),
        .btn_down(btn_db[1]),
        .btn_left(btn_db[2]),
        .btn_right(btn_db[3]),
        .pixel_x(car_x),
        .pixel_y(car_y)
    );
    
    
    // =====================================
    // 6. 管道障碍物 (上下双管道)
    // =====================================
    wire signed [11:0] pipe_x;
    wire [9:0] pipe_y_upper; // 上管道下边缘Y坐标
    wire [9:0] pipe_y_lower; // 下管道上边缘Y坐标
    pipe_obstacle pipe_inst (
        .clk(clk),
        .rst(rst),
        .state(game_state),
        .score(score),
    
        .pipe_x(pipe_x),
        .pipe_y_upper(pipe_y_upper),
        .pipe_y_lower(pipe_y_lower)
    );
    
    
    // =====================================================
    // 7. 碰撞检测 (分别检测上下管道)
    // =====================================================
    
    // 管道激活标志：仅当管道在屏幕可视范围内时才进行碰撞检测
    wire pipe_active = (pipe_x >= -40) && (pipe_x < 640);

    // 上管道碰撞检测 (上管道占据 Y 区间 [0, pipe_y_upper) )
    wire hit_up;
    wire inv_up_unused;
    // 上管道
    collision col_up(
        .clk(clk),
        .rst(rst),
    
        .car_x(car_x),
        .car_y(car_y),
    
        .obs_x(pipe_x),
        .obs_y(0),
        .obs_h(pipe_y_upper),
        .obs_active(pipe_active),
    
        .hit(hit_up),
        .invincible(inv_up_unused)
    );

    
    // 下管道碰撞检测
    wire hit_low;
    wire inv_low_unused;
    
    collision col_low(
        .clk(clk),
        .rst(rst),
    
        .car_x(car_x),
        .car_y(car_y),
    
        .obs_x(pipe_x),
        .obs_y(pipe_y_lower),
        .obs_h(10'd480 - pipe_y_lower),
        .obs_active(pipe_active),
    
        .hit(hit_low),
        .invincible(inv_low_unused)
    );

    
    // 最终碰撞事件 (任意一个管道发生碰撞)
    wire hit_event;
    assign hit_event = hit_up | hit_low;
    
    
    // =====================================================
    // 8. 游戏数据管理 (生命值, 分数)
    // =====================================================
    game_data data_inst (
        .clk(clk),
        .rst(rst),
        .state(game_state),
        .hit(hit_event),
        .life(life),
        .score(score)
    );
    
    
    // =====================================================
    // 9. 无敌状态与闪烁控制
    // =====================================================
    wire inv;
    wire flicker;
    
    invincible u_invincible(
        .clk(clk),
        .rst(rst),
        .hit_event(hit_event),
        .inv(inv),
        .flicker(flicker)
    );
    
    
    // =====================================================
    // 10. 图像渲染 (赛车 + 管道 + 背景 + UI)
    // =====================================================
    wire [11:0] pixel_rgb;
    
    renderer render_inst (
    .clk(clk_25),
    .state(game_state),

    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .valid(video_on),

    .pipe_x(pipe_x),
    .pipe_y_upper(pipe_y_upper),
    .pipe_y_lower(pipe_y_lower),

    .car_x(car_x),
    .car_y(car_y),

    .inv(inv),
    .flicker(flicker),

    .rgb(pixel_rgb)
);

    
    // 将 12位 RGB 拆分为 VGA 4位通道
    assign vga_r = pixel_rgb[11:8];
    assign vga_g = pixel_rgb[7:4];
    assign vga_b = pixel_rgb[3:0];
    
    
    // =====================================================
    // 11. LED & 数码管输出
    // =====================================================
    assign led = life;  // LED 显示剩余生命值 (最大值3，仅需2位显示)

    
    // 数码管驱动 (只使用低4位)
    wire [7:0] an_full;
    sevenseg seg_inst (
        .clk(clk),
        .score(score),
        .seg(seg),
        .an(an_full),
        .dp(dp)
    );
    assign an = an_full[3:0];

endmodule