`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : enable_counter_tb
// Author   : 平の路
// Function : enable_counter_tb
// ----------------------------------------------------------------
module enable_counter_tb ();

   //测试信号定义
    reg clk;     //虚拟时钟定义
    reg rst_n;   //虚拟复位定义
    reg SW;
    wire [7:0]LED;

   //模块引用+例化
enable_counter#(
    .ms(100),       //时间缩短一万倍
    .cnt_ms(5)
)
enable_counter_inst0(
    .clk(clk),
    .rst_n(rst_n),
    .SW(SW),
    .LED(LED)
);

   //时钟初始化
    initial clk=0;
    always #10 clk=~clk;     //时钟频率为50MHZ(20ns翻转一次)

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, enable_counter_tb);

        rst_n=0;
        #201;
        rst_n=1;
        #1_000_000;
        $finish;
    end
endmodule