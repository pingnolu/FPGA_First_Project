// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_rx
// // Author   : 平の路
// // Function :     //接收电脑端信号，电脑端发送多少数字（十进制是8位数字），每个相对应的LED亮）
//                   //时刻接受信号，接收到新信号之后，所有LED闪两下，频率同上（300ms亮，200ms灭），再开始新的闪烁


//波特率计数器逻辑
//UART 信号边沿检测逻辑
//波特率计数器使能逻辑
//位计数器逻辑
//位接收逻辑
//接收完成标志信号
// // ----------------------------------------------------------------
// module uart_rx (
//     input  wire clk,      // 系统时钟
//     input  wire rst_n,    // 低电平异步复位
//     input  wire uart_rx_leval,       // 用户输入端口
//     output reg [7:0]LED        // 用户输出端口
// );

//     parameter ms =1_000_000;
//     parameter cnt_ms=50_000;
//     //记1s:25位[24:0],记2s:26位[25:0],记3~5s:27位[26:0],记6~10s:28位[27:0]
//     reg [25:0]tim_cnt;

//     // 内部信号定义
//     reg first_leval;
//     reg second_leval;
//     reg third_leval;

//     reg en_receive;         //使能接受信号，0表示不能接受，1表示可接受
//     reg signal_com;         //信号来了

//     reg [13:0] baud_cnt;        // 波特率周期计数器（5208）
//     reg [12:0] mid_cnt;         //延时到中间
//     reg en_mid;
//     reg [3:0] bit_cnt;         // 位计数器 (0~9)

//     reg [7:0] com_signal;       //来的信号
//     reg [7:0] use_signal;       //使用的信号
//     reg baud_clk;
//     reg [1:0]en_LED;
//     reg [24:0]led_cnt;


//     //接收电脑端信号，电脑端发送多少数字（十进制是8位数字），每个相对应的LED灯闪几下（亮300ms，灭200ms，最多九下）
//     //时刻接受信号，接收到新信号之后，所有LED闪两下，频率同上，再开始新的闪烁

// /*************************物理时序逻辑电路设计区***********************/



// //-----------------------------------------------------------------------
// //判断信号来没来
// //-----------------------------------------------------------------------

//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 begin
//                     first_leval<=1;
//                     second_leval<=1;
//                     third_leval<=1;
//                     signal_com<=0;
//                 end
//             else if(en_receive==1)
//                 begin
//                     first_leval<=uart_rx_leval;
//                     second_leval<=first_leval;
//                     third_leval<=second_leval;      //打两拍消除亚稳态
//                     if(third_leval==1&&second_leval==0)     //说明开始位来了，暂停接受新信号
//                         begin
//                             en_receive<=0;
//                             signal_com<=1;
//                         end
//                 end
//         end


// //-----------------------------------------------------------------------
// //一倍采样
// //-----------------------------------------------------------------------

//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 begin
//                     mid_cnt<=0;
//                 end
//             else if(signal_com==1)
//                 begin
//                     if(mid_cnt==2604)
//                         begin
//                             mid_cnt<=0;
//                             en_mid<=1;
//                         end
//                     else
//                         mid_cnt<=mid_cnt+1;
//                 end
//         end



// //-----------------------------------------------------------------------
// //波特计时器
// //-----------------------------------------------------------------------

//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 begin
//                     baud_cnt<=0;
//                     bit_cnt<=0;
//                 end
//             else if(mid_cnt==1)
//                 begin
//                     if(baud_cnt==5208)
//                             baud_cnt<=0;
//                     else
//                             baud_cnt<=baud_cnt+1;
//                 end
//         end

// //-----------------------------------------------------------------------
// //接受信号
// //-----------------------------------------------------------------------
//     assign baud_clk = (baud_cnt==1);

//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 begin
//                     com_signal<=0;
//                 end
//             else if(baud_clk==1)
//                 begin
//                     if(bit_cnt==9)         //信号结束，start是第一位(bit_cnt==0)
//                         begin
//                             bit_cnt<=0;
//                             signal_com<=0;
//                             en_receive<=1;
//                             mid_cnt<=0;
//                             use_signal<=com_signal;             //信号中转
//                             en_LED<=1;
//                         end
//                     else
//                         com_signal[bit_cnt]<=uart_rx_leval;     //接收信号
//                         bit_cnt<=bit_cnt+1;
//                 end
//         end



// //-----------------------------------------------------------------------
// //信号处理
// //-----------------------------------------------------------------------
//     //led计时器
//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 begin
//                     led_cnt<=0;
//                 end
//             else if(en_LED==1)
//                 begin
//                     if(led_cnt<=800*cnt_ms)
//                         begin
//                             led_cnt<=0;
//                             en_LED<=2;
//                         end
//                     else
//                         led_cnt<=led_cnt+1;
//                 end
//         end

//     //所有led闪烁两次
//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 begin
//                     en_LED<=0;
//                 end
//             else if(en_LED==1)
//                 begin
//                     if(led_cnt==1)
//                         LED<=8'b1111_1111;
//                     else if(led_cnt==300*cnt_ms)
//                         LED<=0;
//                     else if(led_cnt==500*cnt_ms)
//                         LED<=8'b1111_1111;
//                     else if(led_cnt==800*cnt_ms)
//                         LED<=0;

//                 end
//         end


//     //对应的led亮
//     always @(posedge clk or negedge rst_n)
//         begin
//             if (!rst_n)
//                 begin
//                     use_signal <= 1'b0;
//                 end
//             else if(en_LED==2)
//                 begin
//                     LED<=use_signal;
//                 end
//         end

// endmodule

// *******************************************************************************************************************************
`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module  : uart_rx_led_ctrl
// Author  : 顶级 FPGA 导师
// Function:
//   1. 接收电脑端发送的 8bit 串口数据 (9600 波特率)
//   2. 接收到新数据后，所有 LED 闪烁两次 (亮300ms, 灭200ms)
//   3. 闪烁结束后，LED 常亮显示刚才接收到的 8bit 数据
// ----------------------------------------------------------------

module uart_rx_led_ctrl #(
    // --- 参数化设计 (Parameterization) ---
    // 导师提示：优秀的硬件工程师永远不会在代码里写死数字。用参数方便后期修改和复用。
    parameter SYS_CLK_FREQ = 50_000_000,       // 系统时钟 50MHz
    parameter BAUD_RATE    = 9600              // 串口波特率
)(
    input  wire       clk,       // 系统时钟 (50MHz)
    input  wire       rst_n,     // 异步复位，低电平有效
    input  wire       rx,        // 串口接收引脚 (对应你的 uart_rx_leval)
    output reg  [7:0] led        // 8位 LED 输出，高电平亮
);

    // =========================================================================
    // 第一部分：UART 接收端 (UART Receiver)
    // =========================================================================

    // 计算波特率周期所需的时钟数：50,000,000 / 9600 ≈ 5208
    localparam BPS_CNT_MAX = SYS_CLK_FREQ / BAUD_RATE;

    // 跨时钟域 (CDC) 与 边沿检测：打两拍消除亚稳态 (Metastability)
    // 导师比喻：把外界传来的信件让两个保安核对一下，防止信件送到一半时内部系统出错。
    reg rx_d0, rx_d1, rx_d2;
    wire rx_fall; // 下降沿脉冲

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0 <= 1'b1; // UART 默认是高电平
            rx_d1 <= 1'b1;
            rx_d2 <= 1'b1;
        end else begin
            rx_d0 <= rx;      // 第一拍：采样
            rx_d1 <= rx_d0;   // 第二拍：同步（消除亚稳态）
            rx_d2 <= rx_d1;   // 第三拍：用于边沿检测
        end
    end

    // 当上一拍是高电平，这一拍是低电平时，说明抓到了下降沿（起始位来了！）
    assign rx_fall = (~rx_d1) & rx_d2;

    // --- UART 接收状态机定义 ---
    localparam U_IDLE  = 3'd0; // 空闲状态
    localparam U_START = 3'd1; // 接收起始位
    localparam U_DATA  = 3'd2; // 接收数据位
    localparam U_STOP  = 3'd3; // 接收停止位

    reg [2:0]  uart_state;
    reg [12:0] baud_cnt;       // 波特率计数器 (最大需计 5208)
    reg [2:0]  bit_cnt;        // 数据位计数器 (0-7, 共8位)
    reg [7:0]  rx_data_shift;  // 移位寄存器，用于拼凑8位数据

    // 模块交互信号
    reg [7:0]  rx_data;        // 最终接收到的有效数据
    reg        rx_done;        // 接收完成一个字节的单脉冲标志 (给LED模块用的信使)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_state <= U_IDLE;
            baud_cnt   <= 13'd0;
            bit_cnt    <= 3'd0;
            rx_data_shift <= 8'd0;
            rx_data    <= 8'd0;
            rx_done    <= 1'b0;
        end else begin
            rx_done <= 1'b0; // 默认拉低，只在接收完成瞬间拉高一个时钟周期 (单脉冲)

            case (uart_state)
                U_IDLE: begin
                    baud_cnt <= 13'd0;
                    bit_cnt  <= 3'd0;
                    if (rx_fall) // 抓到起始位的下降沿
                        uart_state <= U_START;
                end

                U_START: begin
                    // 导师提示：不要在边缘采样，要在每一位的正中间采样最稳定！(5208/2 = 2604)
                    if (baud_cnt == BPS_CNT_MAX/2 - 1) begin
                        baud_cnt <= 13'd0;
                        uart_state <= U_DATA; // 走到中间后，进入数据接收状态
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                U_DATA: begin
                    if (baud_cnt == BPS_CNT_MAX - 1) begin
                        baud_cnt <= 13'd0;
                        // 硬件思维：将外部串行数据一位位“挤”进移位寄存器
                        rx_data_shift <= {rx_d1, rx_data_shift[7:1]};
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 3'd0;
                            uart_state <= U_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                U_STOP: begin
                    if (baud_cnt == BPS_CNT_MAX - 1) begin
                        baud_cnt <= 13'd0;
                        uart_state <= U_IDLE; // 接收结束，回到空闲
                        rx_data  <= rx_data_shift; // 将拼好的8位数据锁存
                        rx_done  <= 1'b1;          // 告诉外界：我收到新数据啦！
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: uart_state <= U_IDLE;
            endcase
        end
    end

    // =========================================================================
    // 第二部分：LED 闪烁与显示控制 (LED Controller)
    // =========================================================================

    // LED 时序参数 (基于 50MHz)
    localparam TIME_300MS = 32'd15_000_000;
    localparam TIME_200MS = 32'd10_000_000;

    // --- LED 状态机定义 ---
    localparam L_IDLE   = 3'd0; // 常态：显示数据
    localparam L_FLASH1 = 3'd1; // 第一次亮 300ms
    localparam L_DARK1  = 3'd2; // 第一次灭 200ms
    localparam L_FLASH2 = 3'd3; // 第二次亮 300ms
    localparam L_DARK2  = 3'd4; // 第二次灭 200ms

    reg [2:0]  led_state;
    reg [31:0] timer_cnt;   // 时间计数器，必须给够位宽！（防止你之前1位宽溢出的惨剧）
    reg [7:0]  led_data_r;  // 专门用于暂存准备显示的 8位数据

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_state <= L_IDLE;
            timer_cnt <= 32'd0;
            led_data_r<= 8'd0;
            led       <= 8'd0; // 导师提示：整个代码中，led 变量只在这个 always 块里被赋值！杜绝多驱动！
        end else begin
            // 收到新数据的最高优先级抢占！
            if (rx_done) begin
                led_data_r <= rx_data; // 锁存刚刚收到的新数据
                led_state  <= L_FLASH1; // 强行切入闪烁流程
                timer_cnt  <= 32'd0;
            end else begin
                case (led_state)
                    L_IDLE: begin
                        led <= led_data_r; // 空闲时，LED 显示锁存的数据
                    end

                    L_FLASH1: begin
                        led <= 8'b1111_1111; // 全亮
                        if (timer_cnt == TIME_300MS - 1) begin
                            timer_cnt <= 32'd0;
                            led_state <= L_DARK1;
                        end else begin
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end

                    L_DARK1: begin
                        led <= 8'b0000_0000; // 全灭
                        if (timer_cnt == TIME_200MS - 1) begin
                            timer_cnt <= 32'd0;
                            led_state <= L_FLASH2;
                        end else begin
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end

                    L_FLASH2: begin
                        led <= 8'b1111_1111; // 全亮
                        if (timer_cnt == TIME_300MS - 1) begin
                            timer_cnt <= 32'd0;
                            led_state <= L_DARK2;
                        end else begin
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end

                    L_DARK2: begin
                        led <= 8'b0000_0000; // 全灭
                        if (timer_cnt == TIME_200MS - 1) begin
                            timer_cnt <= 32'd0;
                            led_state <= L_IDLE; // 闪烁完毕，回空闲状态展示数据
                        end else begin
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end

                    default: led_state <= L_IDLE;
                endcase
            end
        end
    end

endmodule