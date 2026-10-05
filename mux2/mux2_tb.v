`timescale 1ns / 1ns

// ----------------------------------------------------------------
// Module   : mux2_tb
// Author   : 平の路
// Function : mux2_tb
// ----------------------------------------------------------------
module mux2_tb ();

    reg a1;
    reg b1;
    reg set1;
    wire out1;

mux2 mux2_inst0(
    .a(a1),       // 用户输入端口
    .b(b1),       // 用户输入端口
    .set(set1),       // 用户输入端口
    .out(out1)        // 用户输出端口
);
    // 内部信号定义

initial begin
    $dumpfile("wave.vcd");          //指定波形数据库的文件名
    $dumpvars(0, mux2_tb);          //测试的目标文件

    a1=0;b1=0;set1=0;
    #20;

    a1=0;b1=1;set1=0;
    #20;

    a1=1;b1=0;set1=0;
    #20;

    a1=1;b1=1;set1=0;
    #20;

    a1=0;b1=0;set1=1;
    #20;

    a1=0;b1=1;set1=1;
    #20;

    a1=1;b1=0;set1=1;
    #20;

    a1=1;b1=1;set1=1;
    #20;
    $finish;
end

    // 物理时序逻辑电路设计区
    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //          <= 1'b0;
    //     end else begin

    //     end
    // end

endmodule