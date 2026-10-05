`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_send_learn
// Author   : 平の路
// Function : uart_send_learn
// ----------------------------------------------------------------
module uart_send_learn (
    input  wire clk,      // 系统时钟
    input  wire rst_n,    // 低电平异步复位
    input  wire [7:0]SW,       // 用户输入端口
    output reg uart_tx,        // 用户输出端口
    output reg LED        // 用户输出端口
);

    parameter ms =1_000_000;
    parameter cnt_ms=50_000;
    parameter MCNT_BAUD=5207;

    reg [25:0]counter0;    //记1s:25位[24:0],记2s:26位[25:0],记3~5s:27位[26:0],记6~10s:28位[27:0]
    reg [2:0]counter1;

    // 内部信号定义


/*************************物理时序逻辑电路设计区***********************/

    reg [12:0]baud_div_cnt;
    reg [0:0]en_baud_cnt;
//波特率计数器      1/9600*1000000000/20  -1
    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            baud_div_cnt<=0;
        else if(en_baud_cnt==1)
            begin
                if(baud_div_cnt==MCNT_BAUD)
                    baud_div_cnt<=0;
                else
                    baud_div_cnt<=baud_div_cnt+1;
            end
    end


// 位计数器





//延时计数器



//位发送逻辑




//LED翻转逻辑





    always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
                begin
                   counter0 <= 1'b0;
                end
            else
                begin

                end
        end

endmodule