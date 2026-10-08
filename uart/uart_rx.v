`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_rx
// Author   : 平の路
/* Function :
1.握手信号使能接收函数
2.参数化波特率，数据位，时钟频率（在整体逻辑写完之后再进行优化）
3.信号转码时间内，接收到的信号无效（这个也放下）
4.在停止位结束之后，将数据发出
5.使用状态机，分为:1.R_IDLE:空闲状态;2.R_START:接收起始位;3.R_DATA:接收数据信号;4.R_STOP:接收停止位;
6.采用16倍采样，多数表决决定最终数据(少数服从多数先放下)
7.打两拍消抖
*/

// ----------------------------------------------------------------
module uart_rx #(
    parameter integer CLK_FREQ = 50_000_000, // 系统时钟频率 (默认 50MHz)
    parameter integer BAUD_RATE = 9600,
    parameter integer DATA_BITS = 8
)(

    input  wire i_clk,      // 系统时钟
    input  wire i_rst_n,    // 低电平异步复位
    input  wire i_rx,       // rx
    input  wire i_rx_valid, //握手信号
    output reg [9:0]o_rx_data        // 用户输出端口
);

    //记1s:25位[24:0],记2s:26位[25:0],记3~5s:27位[26:0],记6~10s:28位[27:0]
    reg [25:0]i_tim_cnt;

    // 内部信号定义

//====================================================================
//                          底层常数计算
//====================================================================
    localparam integer BAUD_CNT_MAX = CLK_FREQ/BAUD_RATE-1;
    localparam integer SAMPLE_CNT_MAX = CLK_FREQ/BAUD_RATE/16-1;

//====================================================================
//                         下降沿检测
//====================================================================

    reg r_rx_d0,r_rx_d1,r_rx_d2;
    wire w_rx_fall;  //下降沿检测

    assign w_rx_fall = (~r_rx_d1 && r_rx_d2);     //下降沿来了

        //打两拍，下降沿检测
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_rx_d0<=1;
            r_rx_d1<=1;
            r_rx_d2<=1;
        end
        else begin
            r_rx_d0<=i_rx;
            r_rx_d1<=r_rx_d0;   //打的那一拍，d0是亚稳态无所谓，经过这一拍误差会小很多，如果误差还是很大，再打一两拍即可
            r_rx_d2<=r_rx_d1;   //d2为较老信号，d1为较新信号
        end
    end


//====================================================================
//                 接收信号状态机+发送信号+16倍采样时钟
//====================================================================

//状态机一定义：rx接收数据
    localparam U_IDLE = 3'd0;       //空闲状态
    localparam U_START = 3'd1;      //接收起始位
    localparam U_DATA = 3'd2;       //接收数据信号
    localparam U_STOP = 3'd3;       //接收停止位
    reg [2:0]r_uart_state;          //承载状态

//状态机二定义：16倍采样时钟
    localparam S_IDLE = 3'd0;       //空闲状态
    localparam S_SAMPLE_START = 3'd1;    //计时状态
    reg [2:0]r_sample_state;        //承载状态
    reg [10:0]r_sample_cnt;         //16倍采样计时器
    wire w_sample_clk;              //16倍采样时钟
    assign w_sample_clk = (r_sample_cnt == SAMPLE_CNT_MAX); //时钟实现
    reg [3:0]r_sample_div;          //16倍采样位置记录

    reg [9:0]r_rx_data;             //接收信号寄存器
    reg [3:0]r_bit_div;             //数据位

    //16倍采样计时器
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_sample_state<=S_IDLE;
            r_sample_cnt<=0;
        end
        else begin
            case(r_sample_state)
            S_IDLE: begin
                if(w_rx_fall&&i_rx_valid)       //握手信号+下降沿
                    r_sample_state<=S_SAMPLE_START;
                else
                    r_sample_state<=r_sample_state;
            end
            S_SAMPLE_START: begin
                if(w_sample_clk)
                    r_sample_cnt<=0;
                else
                    r_sample_cnt<=r_sample_cnt+1;
            end
            endcase
        end
    end

    //16倍分频点位记录
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n)
            r_sample_div<=4'b0;
        else if(w_sample_clk)
            if(r_sample_div==4'd15)
                r_sample_div<=0;
            else
                r_sample_div<=r_sample_div+1;
        else
            r_sample_div<=r_sample_div;
    end


        //.  --- 接收信号状态机 ---
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_uart_state<=U_IDLE;
            r_rx_data<=10'b0;
            r_bit_div<=3'b0;
        end
        else begin
            case (r_uart_state)
            U_IDLE:begin
                if(w_rx_fall&&i_rx_valid)       //握手信号+下降沿
                    r_uart_state<=U_START;
                else
                    r_uart_state<=r_uart_state;
            end
            U_START:begin
                if(r_sample_div==7)begin
                    if(i_rx==0)begin        //说明不是毛刺,少数服从多数先放下
                        r_rx_data[r_bit_div]<=i_rx;
                        r_bit_div<=r_bit_div+1;
                        r_uart_state<=U_DATA;
                    end
                    else
                        r_uart_state<=U_IDLE;
                end
            end
            U_DATA:begin
                if(r_bit_div<=9)begin
                    if(r_sample_div==8)begin
                        r_rx_data[r_bit_div]<=i_rx;
                        r_bit_div<=r_bit_div+1;
                    end
                end
                else
                    r_uart_state<=U_STOP;
            end
            U_STOP:begin
                if(r_sample_div==8) begin
                    r_rx_data[r_bit_div]<=i_rx;
                    r_bit_div<=0;
                    r_uart_state<=U_IDLE;
                end
                else
                    r_rx_data<=r_rx_data;
            end
            endcase
        end
    end

endmodule