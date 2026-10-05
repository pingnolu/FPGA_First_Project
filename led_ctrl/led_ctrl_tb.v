// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : led_ctrl_tb
// // Author   : 平の路
// // Function : led_ctrl_tb
// // ----------------------------------------------------------------
// module led_ctrl_tb ();

//     // defparam led_ctrl_inst0.ms=1_000;
//     // defparam led_ctrl_inst0.cnt_ms=50;
//    //测试信号定义
//     reg clk1;     //虚拟时钟定义
//     reg rst_n1;   //虚拟复位定义
//     reg [7:0]A1;
//     wire LED1;

//    //模块引用+例化
// led_ctrl#(
//     .ms(1000),
//     .cnt_ms(50)
// ) led_ctrl_inst0(
//     .A(A1),
//     .LED(LED1),
//     .clk(clk1),
//     .rst_n(rst_n1)
// );

//    //时钟初始化
//     initial clk1=0;
//     always #20 clk1=~clk1;     //时钟频率为50MHZ(20ns翻转一次)

//     initial begin
//         $dumpfile("wave.vcd");
//         $dumpvars(0, led_ctrl_tb);

//         rst_n1=0;
//         A1=8'b0000_0000;
//         #201;
//         rst_n1=1;
//         A1=8'b1010_1010;
//         #1_000_000;
//         // A1=8'b0000_0011;
//         // #300_000;
//         // A1=8'b0000_1111;
//         // #300_000;
//         // A1=8'b1111_1111;
//         // #300_000;
//         $finish;
//     end
// endmodule

`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : led_ctrl_tb
// Author   : 平の路
// Function : led_ctrl_tb
// ----------------------------------------------------------------
module led_ctrl_tb ();

   //测试信号定义
    reg clk;     //虚拟时钟定义
    reg rst_n;   //虚拟复位定义
    reg [7:0]A;
    wire LED;

   //模块引用+例化
led_ctrl#(
    .ms(1000),
    .cnt_ms(50)
)
led_ctrl_inst0(
    .clk(clk),
    .rst_n(rst_n),
    .A(A),
    .LED(LED)
);

   //时钟初始化
    initial clk=0;
    always #20 clk=~clk;     //时钟频率为50MHZ(20ns翻转一次)

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, led_ctrl_tb);

        rst_n=0;
        #201;
        rst_n=1;
        #1_000_000_0;
        $finish;
    end
endmodule
