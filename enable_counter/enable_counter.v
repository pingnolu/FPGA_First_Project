`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : enable_counter
// Author   : 平の路
// Function : enable_counter
// ----------------------------------------------------------------
module enable_counter (
    input  wire clk,      // 系统时钟
    input  wire rst_n,    // 低电平异步复位
    input  wire SW,       // 用户输入端口
    output reg [7:0]LED        // 用户输出端口
);

    parameter ms =1_000_000;
    parameter cnt_ms=50_000;

    reg [25:0]counter0;    //记1s:25位[24:0],记2s:26位[25:0],记3~5s:27位[26:0],记6~10s:28位[27:0]
    reg [2:0]counter1;
    reg [25:0] counter2;

    // 内部信号定义
    reg [1:0]en_counter0;
    reg [1:0]en_counter2=1;


/*************************物理时序逻辑电路设计区***********************/

    //counter0:控制LED切换
    //空闲状态计时结束后开始计时，动态变化时间里：每250ms，LED切换下一个
    always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
                begin
                counter0 <= 1'b0;
                end
            else if(en_counter0)
                begin
                    if(counter0==250*cnt_ms)
                        begin
                            counter0<=0;
                            LED<={LED[6:0],LED[7]};
                        end
                    else
                        counter0<=counter0+1;
                end
            else
                counter0<=0;
        end



    //counter1:计数第几个LED
    //空闲状态结束后开始计时，记录第几个LED灯闪烁（从零开始），当第七个LED灯闪烁完成之后，使能counter2，LED归零，失能counter0；
    always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
                begin
                    counter1 <= 1'b0;
                end
            else if(en_counter0)
                begin
                    if(counter0==250*cnt_ms)
                        begin
                            counter0<=0;
                                if(counter1==7)
                                    begin
                                        counter1<=0;
                                        LED<=0;
                                        en_counter2<=1;
                                        en_counter0<=0;
                                    end
                                else
                                    counter1<=counter1+1;
                        end
                    else
                        counter0<=counter0+1;
                end
            else
                counter1<=counter1;
        end


    //counter2:空闲状态计时
    //第7个LED闪烁结束后开始计时，空闲持续1s，空闲状态结束后，使能counter0，使能LED，失能counter2；
    always @(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
                begin
                    counter2 <= 1'b0;
                end
            else if(en_counter2)
                begin
                    if(counter2==1000*cnt_ms)
                        begin
                            counter2<=0;
                            en_counter0<=1;
                            en_counter2<=0;
                            LED<=1;
                        end
                    else
                        counter2<=counter2+1;
                end
            else
                counter2<=0;
        end

endmodule