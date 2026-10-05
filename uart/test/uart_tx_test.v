// `timescale 1ns / 1ns

// // ----------------------------------------------------------------
// // Module   : uart_tx
// // Author   : 平の路
// // Function : uart_tx
// // ----------------------------------------------------------------
// module uart_tx (
//     input  wire clk,      // 系统时钟
//     input  wire rst_n,    // 低电平异步复位
//     input  wire [7:0]SW,       // 用户输入端口
//     output reg uart_tx_level=1,        // 用户输出端口
//     output reg LED        // 用户输出端口
// );

//     parameter ms =1_000_000;
//     parameter cnt_ms=50_000;
//     //记1s:25位[24:0],记2s:26位[25:0],记3~5s:27位[26:0],记6~10s:28位[27:0]
//     reg [25:0]counter0;
//     reg [2:0]counter1;

//     // 内部信号定义

//     //波特率：9600 1/9600*1000_000_000=104_166ns/20=5208
//     reg [13:0]baud_cnt;      //记波特周期
//     reg en_baud=1;       //使能波特计数器
//     wire baud_clk;      //波特晶振
//     wire baud_clk_start;      //波特晶振
//     reg [3:0]baud_div; //记录第几位波特（包括起始位和停止位），停止位结束时en_baud=0；
//     reg [7:0]tem_data;  //记录当前SW的各个值
//     reg [7:0]send_data;  //记录当前SW的各个值
//     reg en_tem_data=1;    //使能SW->tem_data的这个过程，保证时序一致


// /*************************物理时序逻辑电路设计区***********************/





//     //波特率周期
//     //en_baud为1时开始计时
//     always @(posedge clk or negedge rst_n)
//         begin
//             if (!rst_n)
//                 begin
//                     baud_cnt <= 1'b0;
//                     en_baud<=1;
//                 end
//             else if(en_baud==1)
//                 begin
//                     if(baud_cnt==5208-1)
//                         begin
//                             baud_cnt<=0;
//                         end
//                     else
//                         baud_cnt<=baud_cnt+1;
//                 end
//             else
//                 baud_cnt<=0;
//         end

//     //波特时钟
//     assign baud_clk =( baud_cnt==5208-1);
//     assign baud_clk_start =( baud_cnt==1);


//     //波特推进,第九位（停止位）结束后失能波特计时器
//     always @(posedge clk or negedge rst_n)
//         begin
//             if(!rst_n)
//                 baud_div<=0;
//             else if(baud_clk==1)
//                 begin
//                     if(baud_div==9)
//                         begin
//                             baud_div<=0;
//                             en_baud<=0;
//                             LED<=~LED;
//                         end
//                     else
//                         baud_div<=baud_div+1;
//                 end
//         end



//     //一秒钟计时器，记满en_baud=1,en_tem_data=1;
//     always @(posedge clk or negedge rst_n )
//         begin
//             if(!rst_n)
//                 counter0<=0;
//             else if(counter0==1000*cnt_ms)
//                 begin
//                     counter0<=0;
//                     en_baud<=1;
//                     en_tem_data<=1;
//                 end
//             else
//                 counter0<=counter0+1;
//         end


//     //获取SW的值
//     always @(posedge clk or negedge rst_n )
//         begin
//             if(!rst_n)
//                 en_tem_data<=1;
//             else if(en_tem_data==1)
//                 begin
//                     tem_data[0]<=SW[0];
//                     tem_data[1]<=SW[1];
//                     tem_data[2]<=SW[2];
//                     tem_data[3]<=SW[3];
//                     tem_data[4]<=SW[4];
//                     tem_data[5]<=SW[5];
//                     tem_data[6]<=SW[6];
//                     tem_data[7]<=SW[7];
//                     en_tem_data<=0;
//                 end
//         end



//     //串口发送设置电平
//     always @(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             uart_tx_level<=1;
//         else if((en_baud==1) && (baud_clk_start==1))
//             begin
//                 send_data<=tem_data;                    ////
//                 case(baud_div)
//                     0:uart_tx_level<=0;             //起始位必须是0
//                     1:uart_tx_level<=send_data[0];
//                     2:uart_tx_level<=send_data[1];
//                     3:uart_tx_level<=send_data[2];
//                     4:uart_tx_level<=send_data[3];
//                     5:uart_tx_level<=send_data[4];
//                     6:uart_tx_level<=send_data[5];
//                     7:uart_tx_level<=send_data[6];
//                     8:uart_tx_level<=send_data[7];
//                     9:uart_tx_level<=1;             //停止位必须是1
//                 endcase
//             end
//     end


// endmodule

















`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : uart_tx
// Author   : 平の路 & 金牌导师
// Function : 工业级 UART 发送端 (带 1 秒定时自动触发)
// ----------------------------------------------------------------
module uart_tx #(
    parameter CLK_FREQ  = 50_000_000, // 系统时钟 50MHz
    parameter BAUD_RATE = 9600        // 波特率 9600
)(
    input  wire       clk,            // 系统时钟
    input  wire       rst_n,          // 低电平异步复位
    input  wire [7:0] SW,             // 用户拨码开关输入
    output reg        uart_tx_level,  // 串口发送线 TX
    output reg        LED             // 发送指示灯
);

    // ------------------------------------------------------------
    // 参数自动计算 (避免硬编码 magic number)
    // ------------------------------------------------------------
    localparam BPS_CNT_MAX = CLK_FREQ / BAUD_RATE; // 9600波特率对应 5208 个周期
    localparam ONE_SEC_MAX = CLK_FREQ - 1;          // 1秒对应的时钟计数器最大值 (50MHz -> 49_999_999)

    // ------------------------------------------------------------
    // 内部寄存器与导线定义
    // ------------------------------------------------------------
    reg [25:0] sec_cnt;         // 1秒定时计数器
    reg [12:0] baud_cnt;        // 波特率周期计数器 (足够存 5208)
    reg [3:0]  bit_cnt;         // 发送位计数器 (0~9)
    reg        tx_busy;         // 发送忙状态标志 (1: 正在发送, 0: 空闲)
    reg [7:0]  send_data_reg;   // 发送数据锁存寄存器

    // ------------------------------------------------------------
    // 1. 1秒定时计数器逻辑 (产生周期性发送触发脉冲)
    // ------------------------------------------------------------
    reg start_pulse;            // 1秒触发脉冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_cnt     <= 26'd0;
            start_pulse <= 1'b0;
        end else if (sec_cnt == ONE_SEC_MAX) begin
            sec_cnt     <= 26'd0;
            start_pulse <= 1; // 触发一次发送
        end else begin
            sec_cnt     <= sec_cnt + 1'b1;
            start_pulse <= 1'b0;
        end
    end

    // ------------------------------------------------------------
    // 2. 发送忙标志自锁与数据采样锁存
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy       <= 1'b0;
            send_data_reg <= 8'd0;
            LED           <= 1'b0;
        end else if (start_pulse && !tx_busy) begin
            tx_busy       <= 1'b1;  // 拉高忙标志，锁定发送
            send_data_reg <= SW;    // 锁存当前的 SW 输入，防止发送途中 SW 改变导致乱码
        end else if (bit_cnt == 4'd9 && (baud_cnt == BPS_CNT_MAX - 1)) begin
            tx_busy       <= 1'b0;  // 10个 bit 发送完毕，释放总线
            LED           <= ~LED;  // 每次发送完毕翻转一次 LED
        end
    end

    // ------------------------------------------------------------
    // 3. 波特率分频计数器
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= 13'd0;
        end else if (tx_busy) begin
            if (baud_cnt == BPS_CNT_MAX - 1)
                baud_cnt <= 13'd0;
            else
                baud_cnt <= baud_cnt + 1'b1;
        end else begin
            baud_cnt <= 13'd0;
        end
    end

    // 产生的波特率采样/切换脉冲 (维持 1 个时钟周期)
    wire baud_pulse = (baud_cnt == BPS_CNT_MAX - 1);

    // ------------------------------------------------------------
    // 4. 发送位计数器 (bit_cnt)
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 4'd0;
        end else if (tx_busy && baud_pulse) begin
            if (bit_cnt == 4'd9)
                bit_cnt <= 4'd0;
            else
                bit_cnt <= bit_cnt + 1'b1;
        end else if (!tx_busy) begin
            bit_cnt <= 4'd0;
        end
    end

    // ------------------------------------------------------------
    // 5. 串口发送波形切换 (并转串输出)
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx_level <= 1'b1; // 复位时 UART 线路默认维持高电平 (空闲态)
        end else if (tx_busy) begin
            case (bit_cnt)
                4'd0: uart_tx_level <= 1'b0;             // 起始位 (Start Bit)
                4'd1: uart_tx_level <= send_data_reg[0]; // LSB 数据位 0
                4'd2: uart_tx_level <= send_data_reg[1]; // 数据位 1
                4'd3: uart_tx_level <= send_data_reg[2]; // 数据位 2
                4'd4: uart_tx_level <= send_data_reg[3]; // 数据位 3
                4'd5: uart_tx_level <= send_data_reg[4]; // 数据位 4
                4'd6: uart_tx_level <= send_data_reg[5]; // 数据位 5
                4'd7: uart_tx_level <= send_data_reg[6]; // 数据位 6
                4'd8: uart_tx_level <= send_data_reg[7]; // MSB 数据位 7
                4'd9: uart_tx_level <= 1'b1;             // 停止位 (Stop Bit)
                default: uart_tx_level <= 1'b1;
            endcase
        end else begin
            uart_tx_level <= 1'b1; // 空闲保持高电平
        end
    end

endmodule