`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/10 23:26:16
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
input clk,                    // 时钟信号
input rst,                    // 复位信号

input page0_btn,              // 1: 自清洁，开关机，菜单
input page1_btn,              // 1: 切换到一二三档按键
input page2_btn,              // 1: 切换到时间调整相关按键
input page4_btn,              // 1: 切换到手势按键

output machine_state,          // 开机状态
output menu_btn_state,          // 开机状态

input up_btn,                 // 上按钮
input left_btn,               // 左按钮
input middle_btn,             // 中按钮
input right_btn,              // 右按钮
input down_btn,               // 下按钮

output [7:0] digit1,          // 数码管显示的数字1
output [7:0] digit2,          // 数码管显示的数字2
output [7:0] tube_sel,        // 数码管选择信号
output [4:0] led              // LED信号
    );
    wire clk_1hz;             // 1Hz 时钟信号

    wire on_off_btn;
    assign on_off_btn = middle_btn;

    wire menu_btn;
    assign menu_btn = (page1_btn|page0_btn) & up_btn;
    wire mode1_btn;
    assign mode1_btn = page1_btn & left_btn;
    wire mode2_btn;
    assign mode2_btn = page1_btn & right_btn;

    wire mode3_btn;
    assign mode3_btn = page1_btn & down_btn;
    
    wire mode_self_clean_btn;
    assign mode_self_clean_btn = page0_btn & down_btn;


    wire gesture_left;
    assign gesture_left = page4_btn & left_btn;
    wire gesture_right;
    assign gesture_right = page4_btn & right_btn;
    
    wire [3:0] time_adjust_btn;
    assign time_adjust_btn = {page2_btn & down_btn,page2_btn & right_btn,page2_btn & left_btn,page2_btn & up_btn};

    reg [7:0] digit1_out_top;         // 数码管显示的数字1
    reg [7:0] digit2_out_top;         // 数码管显示的数字1
    reg [7:0] tube_sel_out_top;         // 数码管显示的数字1

    wire [7:0] digit1_out_smoker;         // 数码管显示的数字1
    wire [7:0] digit2_out_smoker;         // 数码管显示的数字1
    wire [7:0] tube_sel_out_smoker;         // 数码管显示的数字1

    wire [7:0] digit1_out_selfClean;         // 数码管显示的数字1
    wire [7:0] digit2_out_selfClean;         // 数码管显示的数字1
    wire [7:0] tube_sel_out_selfClean;         // 数码管显示的数字1

    wire [7:0] digit1_out_time;         // 数码管显示的数字1
    wire [7:0] digit2_out_time;         // 数码管显示的数字1
    wire [7:0] tube_sel_out_time;         // 数码管显示的数字1

    

    //实例化1Hz分频器
    ClockDivider1Hz clock1hzzzz(.clk(clk),.rst(rst),.clk_out(clk_1hz));
    
    //实例化开关机模块
    onOffControl on_off_control(
    .clk(clk),
    .rst(rst),
    .left_btn(gesture_left),
    .right_btn(gesture_right),
    .on_off_btn(on_off_btn),
    .gesture_btn_state(page4_btn),
    .machine_state(machine_state));

    wire [2:0] mode_state;      // 模式状态 000待机 001一档 010二档 011三档（飓风） 100自清洁
    wire return_state;
    wire hurricane_mode_enabled;
    
    // 状态定义
    parameter STANDBY        = 3'b000;
    parameter MODE1          = 3'b001;
    parameter MODE2          = 3'b010;
    parameter MODE3          = 3'b011;
    parameter SELF_CLEAN     = 3'b100;


    //实例化油烟机模块
    smoker smoker_inst (
        .clk(clk),
        .rst(rst),
        .mode_state(mode_state),                    // 传递模式状态
        .menu_btn(menu_btn),
        .digit1(digit1_out_smoker),                // 数码管显示的数字1
        .digit2(digit2_out_smoker),                // 数码管显示的数字2
        .tube_sel(tube_sel_out_smoker),
        .return_state(return_state),
        .hurricane_mode_enabled(hurricane_mode_enabled)
    );
    

    //实例化模式选择模块
    mode_fsm mode_fsm_inst (
        .clk(clk),
        .rst(rst),
        .menu_btn(menu_btn),
        .mode1_btn(mode1_btn),
        .mode2_btn(mode2_btn),
        .mode3_btn(mode3_btn),
        .mode_self_clean_btn(mode_self_clean_btn),
        .machine_state(machine_state),
        .mode_state(mode_state),
        .menu_btn_state(menu_btn_state),
        .led(led),
        .return_state(return_state),
        .hurricane_mode_enabled(hurricane_mode_enabled)
    );

    wire [5:0] location_led;
    wire time_adjust_led;


    //当前时间显示模块
    currentTime u_currentTime (
    .clk(clk),                     // 连接系统时钟
    .rst(rst),                     // 连接复位信号
    .btn(time_adjust_btn),                     // 连接按钮输入
    .digit1(digit1_out_time),               // 连接数字管显示 1
    .digit2(digit2_out_time),               // 连接数字管显示 2
    .tube_sel(tube_sel_out_time),           // 连接显示管选择
    .time_adjust_led(time_adjust_led),  // 连接时间调整 LED 指示
    .location_led(location_led),    // 连接位置 LED

    .middle_btn(middle_btn),
    .machine_state(machine_state)
    );
    
    //自清洁模块
    selfcleaner selfcleaner (
    .clk(clk),                     // 连接系统时钟
    .rst(rst),                     // 连接复位信号
    .digit1(digit1_out_selfClean),               // 连接数字管显示 1
    .digit2(digit1_out_selfClean),               // 连接数字管显示 2
    .tube_sel(tube_sel_out_selfClean)           // 连接显示管选择
    );

    
    always @(posedge clk) begin
        if (machine_state)begin
            case(mode_state)
                STANDBY:begin digit1_out_top = digit1_out_time;
                              digit2_out_top = digit2_out_time;
                              tube_sel_out_top = tube_sel_out_time;  
                        end
                
                SELF_CLEAN:begin digit1_out_top = digit1_out_selfClean;
                                 digit2_out_top = digit2_out_selfClean;
                                tube_sel_out_top = tube_sel_out_selfClean;  
                            end
                
                
                default:begin digit1_out_top = digit1_out_smoker;
                              digit2_out_top =digit1_out_smoker;
                              tube_sel_out_top = tube_sel_out_smoker;  
                        end
            endcase
        end else begin
            digit1_out_top = 8'b00000000;
            digit2_out_top = 8'b00000000;
            tube_sel_out_top = 8'b00000000;
        end
    end
    assign digit1 = digit1_out_top;
    assign digit2 = digit2_out_top;
    assign tube_sel = tube_sel_out_top;    
endmodule