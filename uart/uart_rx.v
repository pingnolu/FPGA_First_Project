// ====================================================================
//                 第一版，两个状态机，没有二合一
//                      date：2026.10.9
//           2026.10.10,优化完善了串口接受，目前已是pro版
// ====================================================================
`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_rx
// Author   : 平の路
/* Function :
1.握手信号使能接收函数
2.参数化数据位，波特率，时钟频率
4.无校验位
5.使用状态机，分为:1.R_IDLE:空闲状态;2.R_START:接收起始位;3.R_DATA:接收数据信号;4.R_STOP:接收停止位;5.U_SEND:准备发送信号;
6.采用16倍过采样，bo3
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
    output reg [DATA_BITS-1:0]o_rx_data        // 用户输出端口
);

//====================================================================
//                          底层常数计算
//====================================================================
    localparam integer BAUD_CNT_MAX = CLK_FREQ/BAUD_RATE-1;
    localparam integer SAMPLE_CNT_MAX = CLK_FREQ/BAUD_RATE/16-1;    //16倍采样计时器最大值
    localparam integer SAMPLE_WIDTH = $clog2(SAMPLE_CNT_MAX+1);    //16倍采样计时器的位宽
    localparam integer BITS_WIDTH = $clog2(DATA_BITS);    //一共多少位比特位的位宽


//====================================================================
//                         下降沿检测
//====================================================================

    reg r_rx_d0,r_rx_d1,r_rx_d2;
    wire w_rx_fall;  //下降沿检测


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

    assign w_rx_fall = (~r_rx_d1 && r_rx_d2);     //下降沿来了

//====================================================================
//                 接收信号状态机+发送信号+16倍采样时钟
//====================================================================

//状态机一定义：rx接收数据
    localparam U_IDLE = 3'd0;       //空闲状态
    localparam U_START = 3'd1;      //接收起始位
    localparam U_DATA = 3'd2;       //接收数据信号
    localparam U_STOP = 3'd3;       //接收停止位
    // localparam U_SEND = 3'd4;       //接收停止位
    reg [2:0]r_uart_state;          //承载状态

//状态机二定义：16倍采样时钟
    localparam S_IDLE = 3'd0;       //空闲状态
    localparam S_SAMPLE_START = 3'd1;    //计时状态
    reg [2:0]r_sample_state;        //承载状态
    reg [SAMPLE_WIDTH-1:0]r_sample_cnt;         //16倍采样计时器
    wire w_sample_clk;              //16倍采样时钟
    reg [3:0]r_sample_div;          //16倍采样位置记录

    reg [DATA_BITS-1:0]r_rx_data;             //接收信号寄存器
    reg [BITS_WIDTH:0]r_bit_div;             //数据位,不减一是为了防止无限循环

// --- bo3 ---
    reg r_sample_a;
    reg r_sample_b;
    reg r_sample_c;
    wire w_voted;

//信号转存之后，16倍过采样计时器停止计时,1:正在发送，可以计时；0:停止计时
    reg r_rx_done;

    assign w_voted = {(r_sample_a&r_sample_b)|(r_sample_a&r_sample_c)|(r_sample_b&r_sample_c)};
    assign w_sample_clk = (r_sample_cnt == SAMPLE_CNT_MAX); //时钟实现

    //16倍采样计时器+分频点位记录
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_sample_state<=S_IDLE;
            r_sample_cnt<={(SAMPLE_WIDTH)*1'b0};
        end
        else begin
            case(r_sample_state)
            S_IDLE: begin
                if(w_rx_fall && i_rx_valid)begin       //握手信号+下降沿
                    r_sample_state<=S_SAMPLE_START;
                    r_sample_cnt<={(SAMPLE_WIDTH)*1'b0};
                    r_sample_div<=4'b0;
                end
                else
                    r_sample_state<=r_sample_state;
            end
            S_SAMPLE_START: begin
                if(r_rx_done)begin
                    if(w_sample_clk)begin
                        r_sample_cnt<=0;
                        if(r_sample_div==4'd15)
                            r_sample_div<=0;
                        else
                            r_sample_div<=r_sample_div+1;
                    end
                    else
                        r_sample_cnt<=r_sample_cnt+1;
                        r_sample_div<=r_sample_div;
                end
                else
                    r_sample_state<=S_IDLE;
            end
            default:begin
                r_sample_cnt<={(SAMPLE_WIDTH)*1'b0};
                r_sample_div<=4'b0;
                r_sample_state<=S_IDLE;
            end
            endcase
        end
    end

        //.  --- 接收信号状态机 ---
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_uart_state<=U_IDLE;
            r_rx_data<={(DATA_BITS){1'b0}};
            r_bit_div<={(BITS_WIDTH){1'b0}};
            r_rx_done<=1'b0;
            r_sample_a<=1;
            r_sample_b<=1;
            r_sample_c<=1;
        end
        else begin
            case (r_uart_state)
            U_IDLE:begin
                if(w_rx_fall&&i_rx_valid)begin       //握手信号+下降沿
                    r_rx_data<={(DATA_BITS){1'b0}};
                    r_bit_div<={(BITS_WIDTH){1'b0}};
                    r_uart_state<=U_START;
                    r_rx_done<=1'b1;
                end
                else
                    r_uart_state<=r_uart_state;
            end
            U_START:begin
                if(w_sample_clk)begin
                    case (r_sample_div)
                    7:begin
                        r_sample_a<=r_rx_d2;
                    end
                    8:begin
                        r_sample_b<=r_rx_d2;
                    end
                    9:begin
                        r_sample_c<=r_rx_d2;
                    end
                    15:begin
                        if(w_voted==0)begin
                            r_uart_state<=U_DATA;
                        end
                        else begin
                            r_uart_state<=U_IDLE;
                        end
                    end
                    endcase
                end
            end
            U_DATA:begin
                if(r_bit_div<=DATA_BITS-1)begin         ////
                    if(w_sample_clk)begin
                        case (r_sample_div)
                        7:begin
                            r_sample_a<=r_rx_d2;
                        end
                        8:begin
                            r_sample_b<=r_rx_d2;
                        end
                        9:begin
                            r_sample_c<=r_rx_d2;
                        end
                        15:begin
                            r_rx_data<={w_voted,r_rx_data[DATA_BITS-1:1]};
                            r_bit_div<=r_bit_div+1;
                        end
                        endcase
                    end
                end
                else
                    r_uart_state<=U_STOP;
            end
            U_STOP:begin
                if(w_sample_clk)begin
                    case (r_sample_div)
                    7:begin
                        r_sample_a<=r_rx_d2;
                    end
                    8:begin
                        r_sample_b<=r_rx_d2;
                    end
                    9:begin
                        r_sample_c<=r_rx_d2;
                    end
                    15:begin
                        if(w_voted==1)begin
                            r_bit_div<=0;
                            o_rx_data<=r_rx_data;
                            r_rx_done<=1'b0;
                        end
                        else begin
                            o_rx_data<={DATA_BITS{1'b0}};       //全员是零
                        end
                        r_uart_state<=U_IDLE;
                    end
                    endcase
                end
            end
            default:begin
                r_uart_state<=U_IDLE;
                r_rx_data<={(DATA_BITS){1'b0}};
                r_bit_div<={(BITS_WIDTH){1'b0}};
                r_rx_done<=1'b0;
                r_sample_a<=1;
                r_sample_b<=1;
                r_sample_c<=1;
            end
            endcase
        end
    end

endmodule



// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_rx (Industrial Oversampling Shift-Register Version)
// // Author   : 你的金牌导师 & 平の路
// // Function :
// // 1. 两级触发器同步消除亚稳态
// // 2. 16倍过采样，精准锁定数据中心
// // 3. 严格的 (A&B)|(B&C)|(A&C) 三选二表决逻辑过滤毛刺
// // 4. 纯硬件移位寄存器架构，消灭庞大 MUX
// // ----------------------------------------------------------------
// module uart_rx #(
//     parameter integer CLK_FREQ  = 50_000_000,
//     parameter integer BAUD_RATE = 9600,
//     parameter integer DATA_BITS = 8
// )(
//     input  wire                 i_clk,
//     input  wire                 i_rst_n,
//     input  wire                 i_rx,
//     input  wire                 i_rx_valid, // 接收使能信号
//     output reg  [DATA_BITS-1:0] o_rx_data,
//     output reg                  o_rx_done   // 接收完成标志一个脉冲
// );

//     // =================================================================
//     // 底层常数计算
//     // =================================================================
//     localparam integer SAMPLE_CNT_MAX = CLK_FREQ / (BAUD_RATE * 16) - 1;
//     localparam integer SAMPLE_WIDTH   = $clog2(SAMPLE_CNT_MAX + 1);

//     // =================================================================
//     // 跨时钟域 (CDC) 与亚稳态消除
//     // =================================================================
//     reg r_rx_d0, r_rx_d1, r_rx_d2;
//     wire w_rx_fall;

//     always @(posedge i_clk or negedge i_rst_n) begin
//         if (!i_rst_n) begin
//             r_rx_d0 <= 1'b1;
//             r_rx_d1 <= 1'b1;
//             r_rx_d2 <= 1'b1;
//         end else begin
//             r_rx_d0 <= i_rx;      // 第1拍：抓取外部野信号（可能亚稳态）
//             r_rx_d1 <= r_rx_d0;   // 第2拍：静置恢复，变成稳定信号
//             r_rx_d2 <= r_rx_d1;   // 第3拍：用来产生沿检测的老信号
//         end
//     end

//     // 下降沿检测（使用稳定后的信号！）
//     assign w_rx_fall = (~r_rx_d1 & r_rx_d2);

//     // =================================================================
//     // 状态机定义 (FSM)
//     // =================================================================
//     localparam [1:0] U_IDLE  = 2'd0;
//     localparam [1:0] U_START = 2'd1;
//     localparam [1:0] U_DATA  = 2'd2;
//     localparam [1:0] U_STOP  = 2'd3;

//     reg [1:0]              r_state;
//     reg [SAMPLE_WIDTH-1:0] r_clk_cnt;   // 用于生成 16 倍频节拍的计数器
//     reg [3:0]              r_sample_div;// 0-15 的切片计数器
//     reg [3:0]              r_bit_cnt;   // 当前接收到了第几个数据位

//     // 采样数据锁存
//     reg r_samp_7, r_samp_8, r_samp_9;
//     // 工业级三选二表决组合逻辑 (一簇逻辑门)
//     wire w_bit_val = (r_samp_7 & r_samp_8) | (r_samp_8 & r_samp_9) | (r_samp_7 & r_samp_9);

//     reg [DATA_BITS-1:0] r_shift_data; // 核心！移位寄存器抽屉

//     // =================================================================
//     // 核心大一统进程：控制与数据通路并进
//     // =================================================================
//     always @(posedge i_clk or negedge i_rst_n) begin
//         if (!i_rst_n) begin
//             r_state      <= U_IDLE;
//             r_clk_cnt    <= {SAMPLE_WIDTH{1'b0}};
//             r_sample_div <= 4'd0;
//             r_bit_cnt    <= 4'd0;
//             r_samp_7     <= 1'b0;
//             r_samp_8     <= 1'b0;
//             r_samp_9     <= 1'b0;
//             r_shift_data <= {DATA_BITS{1'b0}};
//             o_rx_data    <= {DATA_BITS{1'b0}};
//             o_rx_done    <= 1'b0;
//         end else begin
//             o_rx_done <= 1'b0; // 默认拉低，只在完成时产生一个周期的高脉冲

//             case (r_state)
//                 // --------------------------------------------------
//                 U_IDLE: begin
//                     r_sample_div <= 4'd0;
//                     r_clk_cnt    <= {SAMPLE_WIDTH{1'b0}};
//                     if (w_rx_fall && i_rx_valid) begin
//                         r_state <= U_START; // 侦测到起始位，直接发车
//                     end
//                 end

//                 // --------------------------------------------------
//                 // U_START, U_DATA, U_STOP 共用这套 16倍采样节拍逻辑
//                 default: begin
//                     if (r_clk_cnt == SAMPLE_CNT_MAX) begin // 一个 16 倍频节拍到达
//                         r_clk_cnt <= {SAMPLE_WIDTH{1'b0}};

//                         // 1. 记录切片位置
//                         r_sample_div <= r_sample_div + 1'b1; // 自动从 15 溢出回 0

//                         // 2. 硬件锁存 7,8,9 时刻的稳定信号
//                         if (r_sample_div == 4'd7) r_samp_7 <= r_rx_d1;
//                         if (r_sample_div == 4'd8) r_samp_8 <= r_rx_d1;
//                         if (r_sample_div == 4'd9) r_samp_9 <= r_rx_d1;

//                         // 3. 在切片周期的最后时刻 (15)，进行状态机结算！
//                         if (r_sample_div == 4'd15) begin
//                             case (r_state)
//                                 U_START: begin
//                                     // 检查起始位表决结果是否真为 0 (防假毛刺)
//                                     if (w_bit_val == 1'b0) begin
//                                         r_state   <= U_DATA;
//                                         r_bit_cnt <= 4'd0;
//                                     end else begin
//                                         r_state <= U_IDLE; // 是假干扰，滚回空闲
//                                     end
//                                 end

//                                 U_DATA: begin
//                                     // 【硬件移位美学】：新数据塞最高位，旧数据全右移！没有 DEMUX！
//                                     r_shift_data <= {w_bit_val, r_shift_data[DATA_BITS-1:1]};

//                                     if (r_bit_cnt == DATA_BITS - 1) begin
//                                         r_state <= U_STOP;
//                                     end else begin
//                                         r_bit_cnt <= r_bit_cnt + 1'b1;
//                                     end
//                                 end

//                                 U_STOP: begin
//                                     // 检查停止位是否真为 1
//                                     if (w_bit_val == 1'b1) begin
//                                         o_rx_data <= r_shift_data; // 抛出完整数据
//                                         o_rx_done <= 1'b1;         // 报告完成
//                                     end
//                                     r_state <= U_IDLE; // 无论成功与否，回到空闲
//                                 end
//                             endcase
//                         end
//                     end else begin
//                         r_clk_cnt <= r_clk_cnt + 1'b1; // 节拍器累加
//                     end
//                 end
//             endcase
//         end
//     end

// endmodule