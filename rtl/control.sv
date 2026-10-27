package ctrl_pkg;
    typedef enum logic [2:0] {IMM_I, IMM_S, IMM_B, IMM_U, IMM_J} imm_sel_e;
    typedef enum logic [1:0] {WB_ALU, WB_MEM, WB_PC4, WB_IMMU}  wb_sel_e;
endpackage

module control import alu_pkg::*; import ctrl_pkg::*; (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic       reg_write, alu_src,
    output alu_op_e    alu_op,
    output imm_sel_e   imm_sel,
    output wb_sel_e    wb_sel,
    output logic       mem_read, mem_write, branch, branch_ne, jump
);
    localparam logic [6:0] OP_LUI=7'h37, OP_JAL=7'h6F, OP_BRANCH=7'h63,
                           OP_LOAD=7'h03, OP_STORE=7'h23, OP_IMM=7'h13, OP_REG=7'h33;

    alu_op_e arith_op;
    always_comb begin
        unique case (funct3)
            3'b000:  arith_op = (opcode == OP_REG && funct7[5]) ? ALU_SUB : ALU_ADD;
            3'b001:  arith_op = ALU_SLL;
            3'b010:  arith_op = ALU_SLT;
            3'b011:  arith_op = ALU_SLTU;
            3'b100:  arith_op = ALU_XOR;
            3'b101:  arith_op = funct7[5] ? ALU_SRA : ALU_SRL;
            3'b110:  arith_op = ALU_OR;
            3'b111:  arith_op = ALU_AND;
            default: arith_op = ALU_ADD;
        endcase
    end

    always_comb begin
        reg_write=0; alu_src=0; alu_op=ALU_ADD; imm_sel=IMM_I; wb_sel=WB_ALU;
        mem_read=0; mem_write=0; branch=0; branch_ne=0; jump=0;
        unique case (opcode)
            OP_LUI:    begin reg_write=1; imm_sel=IMM_U; wb_sel=WB_IMMU; end
            OP_IMM:    begin reg_write=1; alu_src=1; alu_op=arith_op; imm_sel=IMM_I; end
            OP_REG:    begin reg_write=1; alu_op=arith_op; end
            OP_LOAD:   begin reg_write=1; alu_src=1; imm_sel=IMM_I; wb_sel=WB_MEM; mem_read=1; end
            OP_STORE:  begin alu_src=1; imm_sel=IMM_S; mem_write=1; end
            OP_BRANCH: begin alu_op=ALU_SUB; imm_sel=IMM_B; branch=1; branch_ne=funct3[0]; end
            OP_JAL:    begin reg_write=1; imm_sel=IMM_J; wb_sel=WB_PC4; jump=1; end
            default: ;
        endcase
    end
endmodule
