module dmem #(parameter int DEPTH_WORDS = 256) (
    input  logic        clk, we,
    input  logic [31:0] addr, wdata,
    output logic [31:0] rdata
);
    logic [31:0] mem [0:DEPTH_WORDS-1];
    initial for (int i = 0; i < DEPTH_WORDS; i++) mem[i] = 32'b0;
    always_ff @(posedge clk) if (we) mem[addr[$clog2(DEPTH_WORDS)+1:2]] <= wdata;
    assign rdata = mem[addr[$clog2(DEPTH_WORDS)+1:2]];
endmodule
