// Illustrative GPIO peripheral matching the Project 7 register map.
// 0x0 DATA (R: inputs/output latch, W: output latch)  0x4 DIR (1=output)
// 0x8 SET (W: set bits)                               0xC CLR (W: clear bits)
module gpio (
    input  logic        clk, rst_n,
    input  logic        sel, we,
    input  logic [3:0]  offset,       // addr[3:0], word aligned
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic [31:0] pins_in,
    output logic [31:0] pins_out
);
    logic [31:0] dir_q, out_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dir_q <= 32'b0;
            out_q <= 32'b0;
        end else if (sel && we) begin
            unique case (offset[3:2])
                2'd0: out_q <= wdata;
                2'd1: dir_q <= wdata;
                2'd2: out_q <= out_q |  wdata;
                2'd3: out_q <= out_q & ~wdata;
            endcase
        end
    end

    always_comb begin
        unique case (offset[3:2])
            2'd0:    rdata = (pins_in & ~dir_q) | (out_q & dir_q);
            2'd1:    rdata = dir_q;
            default: rdata = 32'b0;
        endcase
    end

    assign pins_out = out_q & dir_q;
endmodule
