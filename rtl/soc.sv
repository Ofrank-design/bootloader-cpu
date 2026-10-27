// Core + ROM + RAM + GPIO. Data bus decode: addr[31:28]==4'h4 -> GPIO, else RAM.
module soc #(parameter string FW_FILE = "firmware.hex") (
    input  logic        clk, rst_n,
    input  logic [31:0] gpio_in,
    output logic [31:0] gpio_out
);
    logic [31:0] imem_addr, imem_rdata;
    logic [31:0] d_addr, d_wdata, d_rdata, ram_rdata, gpio_rdata;
    logic        d_we, d_re;

    rv32i_core u_core (.clk, .rst_n, .imem_addr, .imem_rdata,
                       .dmem_addr(d_addr), .dmem_wdata(d_wdata),
                       .dmem_we(d_we), .dmem_re(d_re), .dmem_rdata(d_rdata));

    imem #(.INIT_FILE(FW_FILE)) u_imem (.addr(imem_addr), .rdata(imem_rdata));

    logic gpio_sel;
    assign gpio_sel = (d_addr[31:28] == 4'h4);

    dmem u_dmem (.clk, .we(d_we & ~gpio_sel), .addr(d_addr), .wdata(d_wdata), .rdata(ram_rdata));

    gpio u_gpio (.clk, .rst_n, .sel(gpio_sel), .we(d_we), .offset(d_addr[3:0]),
                 .wdata(d_wdata), .rdata(gpio_rdata), .pins_in(gpio_in), .pins_out(gpio_out));

    assign d_rdata = gpio_sel ? gpio_rdata : ram_rdata;
endmodule
