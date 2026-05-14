module car_motion(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] state,
    input  wire btn_up,
    input  wire btn_down,
    input  wire btn_left,
    input  wire btn_right,
    output reg [9:0] pixel_x,
    output reg [9:0] pixel_y
);
    // 赛车尺寸与屏幕尺寸定义
    localparam CAR_SIZE = 16;
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    // 移动速度与步进控制参数
    localparam SPEED = 2;          // 每次移动的像素数
    localparam STEP_DIV = 400_000; // 步进分频计数器阈值 (100MHz下约4ms移动一次)
    localparam STEP_CNT_W = 19;    // 计数器位宽 (2^19 = 524288 > 400000)

    // 移动增量 (使用有符号数以便处理负向移动)
    reg signed [7:0] dx, dy;

    // 步进计数器：用于降低移动频率，避免赛车移动过快
    reg [STEP_CNT_W-1:0] step_cnt = 0;
    wire step_en = (step_cnt == STEP_DIV-1); // 步进使能信号

    // 步进计数器逻辑
    always @(posedge clk) begin
        if (rst || state != 1) begin
            step_cnt <= 0;
        end else if (step_en) begin
            step_cnt <= 0;
        end else begin
            step_cnt <= step_cnt + 1;
        end
    end

    // 根据按键输入计算移动方向
    always @(*) begin
        dx = 0;
        dy = 0;

        if (btn_left)  dx = -SPEED;
        else if (btn_right) dx = SPEED;

        if (btn_up)    dy = -SPEED;
        else if (btn_down)  dy = SPEED;
    end

    // 计算下一时刻的坐标 (扩展位宽以防止计算溢出)
    wire signed [10:0] cur_x = {1'b0, pixel_x};
    wire signed [10:0] cur_y = {1'b0, pixel_y};
    wire signed [10:0] next_x = cur_x + dx;
    wire signed [10:0] next_y = cur_y + dy;

    // 坐标更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            // 复位时赛车置于屏幕中心
            pixel_x <= SCREEN_W/2 - CAR_SIZE/2;
            pixel_y <= SCREEN_H/2 - CAR_SIZE/2;
        end 
        else if (state != 1) begin  // 非游戏进行状态 (如IDLE或GAMEOVER)
            pixel_x <= SCREEN_W/2 - CAR_SIZE/2;
            pixel_y <= SCREEN_H/2 - CAR_SIZE/2;
        end
        else if (step_en) begin // 仅在步进使能时更新坐标
            // X轴移动与边界限制
            if (next_x < 0)
                pixel_x <= 0;
            else if (next_x > SCREEN_W - CAR_SIZE)
                pixel_x <= SCREEN_W - CAR_SIZE;
            else
                pixel_x <= next_x[9:0];

            // Y轴移动与边界限制
            if (next_y < 0)
                pixel_y <= 0;
            else if (next_y > SCREEN_H - CAR_SIZE)
                pixel_y <= SCREEN_H - CAR_SIZE;
            else
                pixel_y <= next_y[9:0];
        end
    end
endmodule
