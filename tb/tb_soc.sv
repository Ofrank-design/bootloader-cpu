`timescale 1ns/1ps
module tb_soc;
    logic clk = 0, rst_n = 0;
    logic [31:0] gpio_in = 0, gpio_out;
    int errors = 0;

    soc #(.FW_FILE("fw/firmware.hex")) dut (.clk, .rst_n, .gpio_in, .gpio_out);

    always #5 clk = ~clk;

    task automatic expect_led(string msg, logic exp);
        if (gpio_out[1] !== exp) begin
            $display("FAIL %s: LED=%b expected %b (t=%0t)", msg, gpio_out[1], exp, $time);
            errors++;
        end else $display("ok   %s: LED=%b", msg, gpio_out[1]);
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1;

        repeat (50) @(posedge clk);
        expect_led("idle after reset", 1'b0);

        // Press and HOLD for a long time: must toggle exactly once
        gpio_in[0] = 1;
        repeat (20)   @(posedge clk);
        expect_led("after press (toggle 1)", 1'b1);
        repeat (1000) @(posedge clk);
        expect_led("still held (no re-toggle)", 1'b1);

        // Release
        gpio_in[0] = 0;
        repeat (50) @(posedge clk);
        expect_led("after release", 1'b1);

        // Second press: toggles back off
        gpio_in[0] = 1;
        repeat (20)   @(posedge clk);
        expect_led("second press (toggle 2)", 1'b0);
        repeat (500)  @(posedge clk);
        gpio_in[0] = 0;
        repeat (50) @(posedge clk);
        expect_led("after second release", 1'b0);

        if (errors == 0) $display("PASS: SoC runs button/LED firmware correctly");
        else             $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule
