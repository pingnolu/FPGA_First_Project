// // ====================================================================
// //                 第一版，伟大尝试，出错很多，不建议使用
// // ====================================================================


// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_tx
// // Author   : 平の路
// // Function :第一版
// // ----------------------------------------------------------------

// module uart_tx #(
//     parameter integer CLK_FREQ   = 50_000_000, // 系统时钟频率 (默认 50MHz)
//     parameter integer BAUD_RATE   = 9600, // 波特率
//     parameter [7:0] UART_TX_DATA   = 0000_0000, // 数据
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
//     localparam integer SEND_FREQ_CNT = CLK_FREQ/SEND_FREQ-1;//波特率->波特计数最大值(时钟频率/发送频率)

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
//                     tx_data_r<=UART_TX_DATA;
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















//====================================================================
//                 第二版，兼容性优化，参数化了时钟频率+波特率+数据位
//====================================================================

`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_tx
// Author   : 平の路
// Function : 只负责发送，默认空闲，通过握手接口激活后进入忙碌阶段，最后一位数据发送完成之后进入空闲状态
// ----------------------------------------------------------------
module uart_tx #(
    parameter integer CLK_FREQ = 50_000_000, // 系统时钟频率 (默认 50MHz)
    parameter integer BAUD_RATE = 9600,      //波特率
    parameter integer DATA_BITS = 8          //数据位

)(

    input  wire i_clk,      // 系统时钟
    input  wire i_rst_n,    // 低电平异步复位
    input  wire i_tx_valid,       // 握手信号
    input wire [DATA_BITS-1:0]i_tx_data,    //要发送的数据
    output reg o_tx,        // 串口输出值,8位数据
    output reg o_tx_ready        //状态信号
);

    // 内部信号定义
//====================================================================
//                          底层常数计算
//====================================================================
    localparam integer BAUD_CNT_MAX = CLK_FREQ/BAUD_RATE-1;


//====================================================================
//                           寄存器声明
//====================================================================
    reg [14:0]r_baud_cnt;       //位宽放大一点，兼容不同波特率
    reg [3:0] r_bit_cnt;        //数据计数器
    reg [DATA_BITS-1:0] r_tx_data;        //数据寄存器（防止中途更改数据）


    wire w_tx_busy = ~o_tx_ready;

    wire w_baud_pulse = (r_baud_cnt==BAUD_CNT_MAX);         //波特脉冲
//====================================================================
//进程1:波特率计数器控制 (LSM 基础驱动)
//====================================================================
    always @(posedge i_clk or negedge i_rst_n)
        begin
            if(!i_rst_n)
                begin
                    r_baud_cnt<=0;
                end
            else if(w_tx_busy) begin
                if(w_baud_pulse)
                    r_baud_cnt<=0;
                else
                    r_baud_cnt<=r_baud_cnt+1;
            end
            else
                r_baud_cnt<=0;

        end

//====================================================================
//进程 2：状态流转与数据锁存
//====================================================================

    always @(posedge i_clk or negedge i_rst_n)
        begin
            if (!i_rst_n)
                begin
                    o_tx_ready<=1;      //默认拉高
                    r_bit_cnt<= 0;
                    r_tx_data<={DATA_BITS{1'b0}};           //{N{A}} 的意思就是：把 A 这个信号，原封不动地复制 N 遍，拼在一起。
                end
            else
                begin
                    if(o_tx_ready)
                        begin
                            if(i_tx_valid)
                                begin
                                    r_bit_cnt<=0;
                                    o_tx_ready<=0;  //进入忙碌状态
                                    r_tx_data<=i_tx_data;//数据锁存
                                end
                        end
                    else
                        begin
                            if(w_baud_pulse)
                                begin
                                    if(r_bit_cnt==DATA_BITS+1)
                                        begin
                                            r_bit_cnt<=0;
                                            o_tx_ready<=1;
                                        end
                                    else
                                        r_bit_cnt<=r_bit_cnt+1;
                                end
                        end
                end
        end




//====================================================================
//进程 3：物理引脚电平映射 (多路选择器 MUX)
//====================================================================


    always @(posedge i_clk or negedge i_rst_n)
        begin
            if (!i_rst_n)
                begin
                    o_tx <= 1;
                end
            else if(w_tx_busy)
                begin
                    if(r_bit_cnt==0)
                        o_tx<=0;
                    else if(r_bit_cnt==DATA_BITS+1)
                        o_tx<=1;
                    else
                        o_tx<=r_tx_data[r_bit_cnt-1];
                end
            else
                o_tx<=1;
        end

endmodule
//大功告成






// //====================================================================
// //      AI完美版，加了$clog2，加了放弃了多路选择器，使用了移位寄存器
// //      优势：兼容性更强，消耗资源减少
// //====================================================================



// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_tx (Ultimate Shift-Register Version)
// // Author   : 你的金牌导师 & 平の路
// // Function : 采用 $clog2 自动位宽计算与全硬件移位寄存器架构
// // ----------------------------------------------------------------
// module uart_tx #(
//     parameter integer CLK_FREQ  = 50_000_000,
//     parameter integer BAUD_RATE = 9600,
//     parameter integer DATA_BITS = 8
// )(
//     input  wire                 i_clk,
//     input  wire                 i_rst_n,
//     input  wire                 i_tx_valid,
//     input  wire [DATA_BITS-1:0] i_tx_data,
//     output reg                  o_tx,
//     output reg                  o_tx_ready
// );

//     // =================================================================
//     // 底层常数与自动位宽推导 (高级参数化)
//     // =================================================================
//     localparam integer BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE - 1;
//     // 魔法指令：自动推导需要的触发器数量！
//     localparam integer BAUD_WIDTH   = $clog2(BAUD_CNT_MAX + 1);

//     // =================================================================
//     // 物理寄存器声明
//     // =================================================================
//     reg [BAUD_WIDTH-1:0] r_baud_cnt; // 无论频率多少，位宽永远刚好够用，不浪费一个DFF
//     reg [3:0]            r_bit_cnt;

//     // 【架构巨变】：不再只存数据，而是存一整个“物理发送帧” (Start + Data + Stop)
//     // 位宽为：1(起始) + DATA_BITS(数据) + 1(停止)
//     reg [DATA_BITS+1:0]  r_tx_frame;

//     wire w_tx_busy    = ~o_tx_ready;
//     wire w_baud_pulse = (r_baud_cnt == BAUD_CNT_MAX);

//     // =================================================================
//     // 进程 1: 波特率基础节拍器 (不变)
//     // =================================================================
//     always @(posedge i_clk or negedge i_rst_n) begin
//         if (!i_rst_n) begin
//             r_baud_cnt <= {BAUD_WIDTH{1'b0}}; // 严格位宽清零
//         end else if (w_tx_busy) begin
//             if (w_baud_pulse)
//                 r_baud_cnt <= {BAUD_WIDTH{1'b0}};
//             else
//                 r_baud_cnt <= r_baud_cnt + 1'b1;
//         end else begin
//             r_baud_cnt <= {BAUD_WIDTH{1'b0}};
//         end
//     end

//     // =================================================================
//     // 进程 2 & 3 合体：状态机与流水线移位 (消灭 MUX)
//     // =================================================================
//     always @(posedge i_clk or negedge i_rst_n) begin
//         if (!i_rst_n) begin
//             o_tx_ready <= 1'b1;
//             r_bit_cnt  <= 4'd0;
//             o_tx       <= 1'b1; // 复位时，串口线必须为高电平
//             r_tx_frame <= {(DATA_BITS+2){1'b1}};
//         end else begin
//             if (o_tx_ready) begin
//                 if (i_tx_valid) begin
//                     o_tx_ready <= 1'b0;
//                     r_bit_cnt  <= 4'd0;
//                     // 【硬件思维】：咔哒！把 起始位(0) + 数据 + 停止位(1) 瞬间焊装进流水线！
//                     r_tx_frame <= {1'b1, i_tx_data, 1'b0};
//                 end
//             end else begin
//                 if (w_baud_pulse) begin
//                     if (r_bit_cnt == DATA_BITS + 1) begin
//                         o_tx_ready <= 1'b1; // 发送结束
//                         r_bit_cnt  <= 4'd0;
//                     end else begin
//                         r_bit_cnt  <= r_bit_cnt + 1'b1;
//                         // 【硬件思维】：物理移位！向右挤压，最高位补 1 (空闲电平)
//                         r_tx_frame <= {1'b1, r_tx_frame[DATA_BITS+1 : 1]};
//                     end
//                 end
//             end

//             // 【极致硬件美学】：物理引脚 o_tx 永远死死地连在流水线的出口（最低位）上！
//             // 不需要任何复杂的 if-else 或 case 选择！
//             if (w_tx_busy)
//                 o_tx <= r_tx_frame[0];
//             else
//                 o_tx <= 1'b1;
//         end
//     end

// endmodule