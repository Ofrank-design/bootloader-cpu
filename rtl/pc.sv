module pc #(parameter logic [31:0] RESET_ADDR = 32'h0) (
    input  logic clk, rst_n,
    input  logic [31:0] pc_next,
    output logic [31:0] pc_q
);
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) pc_q <= RESET_ADDR; else pc_q <= pc_next;
endmodule
