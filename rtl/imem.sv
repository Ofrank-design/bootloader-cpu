module imem #(parameter int DEPTH_WORDS = 256, parameter string INIT_FILE = "firmware.hex") (
    input  logic [31:0] addr,
    output logic [31:0] rdata
);
    logic [31:0] mem [0:DEPTH_WORDS-1];
    initial begin
        for (int i = 0; i < DEPTH_WORDS; i++) mem[i] = 32'h0000_0013; // NOP (addi x0,x0,0)
        $readmemh(INIT_FILE, mem);
    end
    assign rdata = mem[addr[$clog2(DEPTH_WORDS)+1:2]];
endmodule
