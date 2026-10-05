// `include "and_gate.v"
`timescale 1ns / 1ps

module tb_and_gate();

    // 测试仪主动发出的信号必须能“记住”状态，所以用 reg（寄存器）
    reg  tb_a;
    reg  tb_b;
    // 只是用来观察芯片输出的探针，用 wire 即可
    wire tb_y;

    // 【核心动作：插上芯片】
    // 把我们刚才画好的 and_gate 芯片插到测试仪的底座上，并把引脚连好
    and_gate u_and_gate (
        .a(tb_a),
        .b(tb_b),
        .y(tb_y)
    );

    // initial 块是给仿真软件看的，它按时间顺序给电路加电压
    initial begin
        // 告诉 VS Code：把所有的电压变化录制成 wave.vcd 文件，方便一会看波形！
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_and_gate);

        // 0 纳秒时：开关全部断开 (0 代表低电平)
        tb_a = 1'b0;
        tb_b = 1'b0;

        #10; // 现实时间暂停 10 纳秒
        tb_a = 1'b0;
        tb_b = 1'b1; // 给 B 通电

        #10;
        tb_a = 1'b1; // 给 A 通电
        tb_b = 1'b0; // 给 B 断电

        #10;
        tb_a = 1'b1; // 给 A 通电
        tb_b = 1'b1; // 给 B 通电 (此时 A和B 都是高电平！)

        #10;
        $finish; // 测试结束，拔掉电源
    end

endmodule