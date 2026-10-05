// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_tx
// // Author   : 平の路
// // Function :
// // ----------------------------------------------------------------

// module uart_tx #(
//     parameter integer CLK_FREQ   = 50_000_000, // 系统时钟频率 (默认 50MHz)
//     parameter integer BAUD_RATE   = 9600, // 波特率
//     parameter [7:0] UART_TX_DATA   = 0000_0000, // 波特率
//     parameter integer SEND_FREQ = 1     //发送频率
// )(

//     input  wire clk,      // 系统时钟
//     input  wire rst_n,    // 低电平异步复位
//     output reg tx        // 用户输出端口
// );
// //=================================================================
// //线形序列机，串口发送，1起始位，8数据位，1结束位
// //=================================================================

//     localparam integer BAUD_CNT_MAX = CLK_FREQ/BAUD_RATE-1;//波特率->波特计数最大值(时钟频率/波特率)
//     localparam integer SEND_FREQ_CNT = CLK_FREQ/SEND_FREQ-1;//波特率->波特计数最大值(时钟频率/波特率)

//     reg [3:0]bit_cnt;       //数据位计数器（0～9）
//     reg [15:0]baud_cnt;     //波特率计数器（记到BAUD_CNT_MAX）（9600波特率记到5208）
//     reg [25:0]tim_cnt;      //发送频率计数器，记满开始发送
//     wire baud_clk;          //波特时钟，每过一个波特时间翻转
//     reg tx_state;           //tx状态标志，0为等待发送，1为正在发送
//     reg [7:0]tx_data_r;          //数据寄存器，防止在发送过程中修改数据

//     always @(posedge clk or negedge rst_n)      //SEND_FREQ计时器，记满开始发送
//         begin
//             if (!rst_n)
//                 begin
//                     tim_cnt <= 0;
//                     tx_data_r<=0;
//                     tx_state<=0;
//                 end
//             else if(tim_cnt==SEND_FREQ_CNT)
//                 begin
//                     tim_cnt<=0;
//                     tx_data_r<=UART_TX_DATA
//                     tx_state<=1;
//                 end
//             else
//                 tim_cnt<=tim_cnt+1;
//         end

//     always @(posedge clk or negedge rst_n)      //波特计数器，记满清零
//         begin
//             if (!rst_n)
//                 begin
//                     baud_cnt<=0;
//                 end
//             else if(tx_state==1)
//                 begin
//                     if(baud_cnt==BAUD_CNT_MAX)
//                         begin
//                             baud_cnt<=0;
//                             if(bit_cnt==9)
//                                 bit_cnt<=0;
//                             else
//                                 bit_cnt<=bit_cnt+1;     //数据位计数器，波特计数器记满+1；
//                         end
//                     else
//                         baud_cnt<=baud_cnt+1;
//                 end
//             else
//                 baud_cnt<=0;
//         end

//     assign baud_clk=(baud_cnt==0 && tx_state==1);   //波特晶振，波特计数器记满翻转=1，清零再反转=0；

//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 tx<=1;
//             else if(tx_state==1 && baud_clk==1)
//                 begin
//                     case(bit_cnt)
//                         0:tx<=0;
//                         1:tx<=tx_data_r[0];
//                         2:tx<=tx_data_r[1];
//                         3:tx<=tx_data_r[2];
//                         4:tx<=tx_data_r[3];
//                         5:tx<=tx_data_r[4];
//                         6:tx<=tx_data_r[5];
//                         7:tx<=tx_data_r[6];
//                         8:tx<=tx_data_r[7];
//                         9:tx<=1;
//                         default:tx<=1;
//                     endcase
//                 end
//         end
// endmodule

`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_tx
// Author   : 你的金牌导师
// Function : 纯粹的 UART 发送器（剥离外部控制，采用握手接口）
// ----------------------------------------------------------------
module uart_tx #(
    parameter integer CLK_FREQ  = 50_000_000, // 系统时钟频率
    parameter integer BAUD_RATE = 115200      // 默认波特率
)(
    input  wire       i_clk,      // 系统时钟
    input  wire       i_rst_n,    // 异步复位 (低电平有效)

    // 用户端接口 (握手协议)
    input  wire [7:0] i_tx_data,  // 准备发送的数据
    input  wire       i_tx_valid, // 脉冲：拉高1周期表示请求发送
    output reg        o_tx_ready, // 状态：1=空闲可发送，0=正在发送中忙碌

    // 物理层接口
    output reg        o_tx        // UART 发送引脚
);

    // =================================================================
    // 底层常数计算
    // =================================================================
    localparam integer BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE - 1;

    // =================================================================
    // 寄存器声明 (对应硬件的 DFF 触发器)
    // =================================================================
    reg [15:0] r_baud_cnt; // 波特率计数器
    reg [3:0]  r_bit_cnt;  // 位计数器 (0~9，共10位: 1起始 + 8数据 + 1停止)
    reg [7:0]  r_tx_data;  // 数据锁存器 (防止发送中途外部数据突变)

    // 状态标志，用 o_tx_ready 的反相即可表示是否正在发送，无需额外声明 tx_state
    wire w_tx_busy = ~o_tx_ready;

    // 波特率脉冲标志 (组合逻辑，对应硬件的一根线和一个比较器)
    wire w_baud_pulse = (r_baud_cnt == BAUD_CNT_MAX);

    // =================================================================
    // 核心进程 1：波特率计数器控制 (LSM 基础驱动)
    // =================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_baud_cnt <= 16'd0;
        end else if (w_tx_busy) begin // 只有在忙碌(发送)状态才计数
            if (w_baud_pulse)
                r_baud_cnt <= 16'd0;
            else
                r_baud_cnt <= r_baud_cnt + 1'b1;
        end else begin
            r_baud_cnt <= 16'd0;
        end
    end

    // =================================================================
    // 核心进程 2：状态流转与数据锁存
    // =================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_tx_ready <= 1'b1;     // 复位时空闲
            r_bit_cnt  <= 4'd0;
            r_tx_data  <= 8'd0;
        end else begin
            // 状态 1：空闲态，等待握手信号 i_tx_valid
            if (o_tx_ready) begin
                if (i_tx_valid) begin
                    o_tx_ready <= 1'b0;        // 进入忙碌状态
                    r_tx_data  <= i_tx_data;   // 咔哒！关上抽屉，把数据锁存进来
                    r_bit_cnt  <= 4'd0;        // 清零位计数器，准备发送
                end
            end
            // 状态 2：发送态，受波特率脉冲驱动
            else begin
                if (w_baud_pulse) begin
                    if (r_bit_cnt == 4'd9) begin // 9 表示最后一位停止位已发送完毕
                        o_tx_ready <= 1'b1;      // 恢复空闲状态
                        r_bit_cnt  <= 4'd0;
                    end else begin
                        r_bit_cnt  <= r_bit_cnt + 1'b1;
                    end
                end
            end
        end
    end

    // =================================================================
    // 核心进程 3：物理引脚电平映射 (多路选择器 MUX)
    // =================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_tx <= 1'b1; // UART 规范：复位/空闲时必须拉高！
        end else if (w_tx_busy) begin
            // 这里的 case 在综合后，就是一个纯粹的 10选1 多路选择器 (MUX)
            case (r_bit_cnt)
                4'd0 : o_tx <= 1'b0;         // 起始位 (Start Bit)
                4'd1 : o_tx <= r_tx_data[0]; // LSB First
                4'd2 : o_tx <= r_tx_data[1];
                4'd3 : o_tx <= r_tx_data[2];
                4'd4 : o_tx <= r_tx_data[3];
                4'd5 : o_tx <= r_tx_data[4];
                4'd6 : o_tx <= r_tx_data[5];
                4'd7 : o_tx <= r_tx_data[6];
                4'd8 : o_tx <= r_tx_data[7]; // MSB
                4'd9 : o_tx <= 1'b1;         // 停止位 (Stop Bit)
                default: o_tx <= 1'b1;
            endcase
        end else begin
            o_tx <= 1'b1; // 空闲期间保持高电平
        end
    end

endmodule