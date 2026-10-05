`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_tx_tb
// Author   : 平の路
// Function : uart_tx_tb
// ----------------------------------------------------------------
module uart_tx_tb ();

   //测试信号定义
    reg clk;     //虚拟时钟定义
    reg rst_n;   //虚拟复位定义
    reg [7:0]SW;
    wire LED;
    wire uart_tx_level;

   //模块引用+例化
uart_tx#(
    .ms(100),    //时间缩短一万倍(少了4个0)
    .cnt_ms(5)
)
uart_tx_inst0(
    .clk(clk),
    .rst_n(rst_n),
    .SW(SW),
    .LED(LED),
    .uart_tx_level(uart_tx_level)
);

   //时钟初始化
    initial clk=0;
    always #10 clk=~clk;     //时钟频率为50MHZ(20ns翻转一次)

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, uart_tx_tb);

        rst_n=0;
        #201;
        rst_n=1;
        SW=8'b1010_1010;
        #2000_00;
        SW=8'b1100_0011;
        #2000_00;
        $finish;
    end
endmodule