`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_rx_tb
// Author   : 平の路
// Function :2026.10.10，大功告成
// ----------------------------------------------------------------
module uart_rx_tb ();
    parameter integer CLK_FREQ = 50_000_000; // 系统时钟频率 (默认 50MHz)
    parameter integer BAUD_RATE = 9600;
    parameter integer DATA_BITS = 8;
   //测试信号定义
    reg i_clk;     //虚拟时钟定义
    reg i_rst_n;   //虚拟复位定义
    reg i_rx;
    reg i_rx_valid;
    wire [DATA_BITS-1:0]o_rx_data;

   //模块引用+例化
uart_rx#(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .DATA_BITS(DATA_BITS)
)
uart_rx_inst0(        //这里报错不用管
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_rx(i_rx),
    .i_rx_valid(i_rx_valid),
    .o_rx_data(o_rx_data)
);

   //时钟初始化
    initial i_clk=0;
    always #10 i_clk=~i_clk;     //时钟频率为50MHZ(20ns翻转一次)

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, uart_rx_tb);
        i_rst_n=0;
        #201;
        i_rst_n=1;
        i_rx=1;
        #1_000_000;
        i_rx_valid=1;
        i_rx=0;
        #(5208*20)
        i_rx=1;
        #(5208*20)
        i_rx=1;
        #(5208*20)
        i_rx=0;
        #(5208*20)
        i_rx=0;
        #(5208*20)
        i_rx=1;
        #(5208*20)
        i_rx=0;
        #(5208*20)
        i_rx=1;
        #(5208*20)
        i_rx=0;
        #(5208*20)
        i_rx=1;
        #1_000_000;
        $finish;
    end
endmodule
//终端运行指令:iverilog -o wave.out uart_tx.v uart_tx_tb.v
//终端运行指令:vvp wave.out


// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_rx_tb
// // Function : UART 接收模块的专业仿真测试台 (Testbench)
// // ----------------------------------------------------------------
// module uart_rx_tb();

//     // 1. 参数定义
//     parameter integer CLK_FREQ  = 50_000_000; // 50MHz 系统时钟
//     parameter integer BAUD_RATE = 9600;       // 9600 波特率
//     parameter integer DATA_BITS = 8;          // 8位数据位

//     // 2. 测试台驱动信号声明 (用 reg 驱动输入，用 wire 接收输出)
//     reg                   i_clk;
//     reg                   i_rst_n;
//     reg                   i_rx;
//     reg                   i_rx_valid;
//     wire [DATA_BITS-1:0]  o_rx_data;

//     // 3. 实例化待测模块 (DUT - Device Under Test)
//     uart_rx #(
//         .CLK_FREQ  (CLK_FREQ),
//         .BAUD_RATE (BAUD_RATE),
//         .DATA_BITS (DATA_BITS)
//     ) dut (
//         .i_clk      (i_clk),
//         .i_rst_n    (i_rst_n),
//         .i_rx       (i_rx),
//         .i_rx_valid (i_rx_valid),
//         .o_rx_data  (o_rx_data)
//     );

//     // 4. 时钟生成器：50MHz，周期 20ns
//     initial begin
//         i_clk = 1'b0;
//         forever #(10) i_clk = ~i_clk; // 每 10ns 翻转一次，时钟周期 = 20ns
//     end

//     // 5. 模拟发送一个字节的 UART 任务 (Task)
//     // 9600波特率下，1个比特位持续的时间约等于 104167 ns (约 104.17 us)
//     localparam real BIT_TIME_NS = 1000_000_000.0 / BAUD_RATE;

//     task send_uart_byte(input [7:0] data);
//         integer i;
//         begin
//             // --- 1. 发送起始位 (Start Bit: 低电平 0) ---
//             i_rx = 1'b0;
//             #BIT_TIME_NS;

//             // --- 2. 发送 8位数据 (Data Bits: LSB 先行) ---
//             for (i = 0; i < DATA_BITS; i = i + 1) begin
//                 i_rx = data[i];
//                 #BIT_TIME_NS;
//             end

//             // --- 3. 发送停止位 (Stop Bit: 高电平 1) ---
//             i_rx = 1'b1;
//             #BIT_TIME_NS;
//         end
//     endtask

//     // 6. 测试激励施放主流程
//     initial begin
//         // 初始化信号
//         i_rst_n    = 1'b0;
//         i_rx       = 1'b1; // 空闲时串口线必须保持高电平
//         i_rx_valid = 1'b0;

//         // 复位释放
//         #200;
//         i_rst_n    = 1'b1;
//         i_rx_valid = 1'b1; // 开启接收使能握手
//         #500;

//         // 模拟电脑串口向 FPGA 发送字符 'A' (ASCII: 0x41 = 8'b0100_0001)
//         $display("[%t] 开始向 FPGA 发送字符 'A' (0x41)...", $time);
//         send_uart_byte(8'h41);

//         // 等待一段时间再发送第二个字符 'B' (ASCII: 0x42 = 8'b0100_0010)
//         #200_000; // 间隔 200us
//         $display("[%t] 开始向 FPGA 发送字符 'B' (0x42)...", $time);
//         send_uart_byte(8'h42);

//         // 仿真运行一段时间后结束
//         #500_000;
//         $display("[%t] 仿真顺利结束！", $time);
//         $finish;
//     end

// endmodule