package alu_pkg;
    typedef enum logic [3:0] {
        ALU_ADD=4'd0, ALU_SUB=4'd1, ALU_AND=4'd2, ALU_OR=4'd3, ALU_XOR=4'd4,
        ALU_SLT=4'd5, ALU_SLTU=4'd6, ALU_SLL=4'd7, ALU_SRL=4'd8, ALU_SRA=4'd9
    } alu_op_e;
endpackage

module alu import alu_pkg::*; (
    input  alu_op_e     op,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        zero
);
    always_comb begin
        unique case (op)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_XOR:  result = a ^ b;
            ALU_SLT:  result = {31'b0, $signed(a) < $signed(b)};
            ALU_SLTU: result = {31'b0, a < b};
            ALU_SLL:  result = a << b[4:0];
            ALU_SRL:  result = a >> b[4:0];
            ALU_SRA:  result = $unsigned($signed(a) >>> b[4:0]);
            default:  result = 32'b0;
        endcase
    end
    assign zero = (result == 32'b0);
endmodule
