`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_tx_tb
// Author   : 平の路
// Function : 串口发送仿真
// ----------------------------------------------------------------
module uart_tx_tb ();

   //测试信号定义
    reg i_clk;     //虚拟时钟定义
    reg i_rst_n;   //虚拟复位定义
    reg [7:0]i_tx_data;
    reg i_tx_valid;
    wire o_tx;
    wire o_tx_ready;

   //模块引用+例化
uart_tx#(
    .CLK_FREQ(50_000),    //时间缩短一千倍(少了3个0)
    .BAUD_RATE(960),
    .BIT_COUNT(8)
)
uart_tx_inst0(        //这里报错不用管
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_tx_data(i_tx_data),
    .i_tx_valid(i_tx_valid),
    .o_tx(o_tx),
    .o_tx_ready(o_tx_ready)
);

   //时钟初始化
    initial i_clk=0;
    always #10 i_clk=~i_clk;     //时钟频率为50MHZ(20ns翻转一次)

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, uart_tx_tb);

        i_rst_n=0;
        #201;
        i_rst_n=1;
        i_tx_data=8'b1100_1100;
        i_tx_valid=1;
        #1_000_00;
        i_tx_data=8'b1100_1100;
        i_tx_valid=0;
        #1_000_00;
        i_tx_data=8'b1100_1100;
        i_tx_valid=1;
        #1_000_00;
        $finish;
    end
endmodule