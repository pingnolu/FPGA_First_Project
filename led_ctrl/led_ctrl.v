`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : led_ctrl
// Author   : 平の路
// Function : ...
// ----------------------------------------------------------------
module led_ctrl (
    input  wire clk,      // 系统时钟
    input  wire rst_n,    // 低电平异步复位
    input  wire [7:0]A,       // 用户输入端口
    output reg LED         // 用户输出端口
);

    parameter ms = 1_000_000;
    parameter cnt_ms=50_000;

    // 内部信号定义
    reg [25:0]counter0;
    reg [2:0]counter1;

    // 物理时序逻辑电路设计区
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            begin
            counter0  <= 0;
            counter1  <= 0;
            end
        else if(counter0==250*cnt_ms-1)
            begin
            counter1<=counter1+1;
            counter0<=0;
            end
        else
            begin
            counter0<=counter0+1;
            end
    end
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            begin
            LED  <= 1'b0;
            end
        // else if(counter1==A)                     ////
        //     begin
        //     LED<=1;
        //     end
        else
            begin
            LED<=A[counter1];
            end

endmodule

