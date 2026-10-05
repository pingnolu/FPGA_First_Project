`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : mux2
// Author   : 平の路
// Function : mux2
// ----------------------------------------------------------------
module mux2 (
    // input  wire clk,      // 系统时钟
    // input  wire rst_n,    // 低电平异步复位
    input  wire a,       // 用户输入端口
    input  wire b,       // 用户输入端口
    input  wire set,       // 用户输入端口
    output  out        // 用户输出端口
);

    // 内部信号定义
    assign out =(set==0)?a:b;

    // 物理时序逻辑电路设计区
    // always @(posedge clk or negedge rst_n)
    // begin
    //     if (!rst_n)
    //         begin
    //             out <= 1'b0;
    //         end
    //     else
    //         begin

    //         end
    // end

endmodule