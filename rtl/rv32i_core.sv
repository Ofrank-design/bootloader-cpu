module rv32i_core import alu_pkg::*; import ctrl_pkg::*; #(
    parameter logic [31:0] RESET_ADDR = 32'h0
) (
    input  logic        clk, rst_n,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    output logic [31:0] dmem_addr, dmem_wdata,
    output logic        dmem_we, dmem_re,
    input  logic [31:0] dmem_rdata
);
    logic [31:0] pc_q, pc_next, pc_plus4;
    assign imem_addr = pc_q;
    assign pc_plus4  = pc_q + 32'd4;
    pc #(.RESET_ADDR(RESET_ADDR)) u_pc (.clk, .rst_n, .pc_next, .pc_q);

    logic [6:0] opcode, funct7; logic [2:0] funct3; logic [4:0] rs1, rs2, rd;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    instr_decoder u_dec (.instr(imem_rdata), .opcode, .funct3, .funct7, .rs1, .rs2, .rd,
                         .imm_i, .imm_s, .imm_b, .imm_u, .imm_j);

    logic reg_write, alu_src, mem_read, mem_write, branch, branch_ne, jump;
    alu_op_e alu_op; imm_sel_e imm_sel; wb_sel_e wb_sel;
    control u_ctrl (.opcode, .funct3, .funct7, .reg_write, .alu_src, .alu_op, .imm_sel,
                    .wb_sel, .mem_read, .mem_write, .branch, .branch_ne, .jump);

    logic [31:0] imm;
    always_comb begin
        unique case (imm_sel)
            IMM_I: imm = imm_i;  IMM_S: imm = imm_s;  IMM_B: imm = imm_b;
            IMM_U: imm = imm_u;  IMM_J: imm = imm_j;  default: imm = 32'b0;
        endcase
    end

    logic [31:0] rs1_data, rs2_data, wb_data;
    regfile u_rf (.clk, .we(reg_write), .rs1_addr(rs1), .rs2_addr(rs2), .rd_addr(rd),
                  .rd_data(wb_data), .rs1_data, .rs2_data);

    logic [31:0] alu_b, alu_result; logic alu_zero;
    assign alu_b = alu_src ? imm : rs2_data;
    alu u_alu (.op(alu_op), .a(rs1_data), .b(alu_b), .result(alu_result), .zero(alu_zero));

    assign dmem_addr = alu_result;  assign dmem_wdata = rs2_data;
    assign dmem_we = mem_write;     assign dmem_re = mem_read;

    always_comb begin
        unique case (wb_sel)
            WB_ALU: wb_data = alu_result;  WB_MEM: wb_data = dmem_rdata;
            WB_PC4: wb_data = pc_plus4;    WB_IMMU: wb_data = imm_u;
            default: wb_data = alu_result;
        endcase
    end

    logic branch_taken;
    assign branch_taken = branch & (alu_zero ^ branch_ne);
    always_comb begin
        if (jump)              pc_next = pc_q + imm_j;
        else if (branch_taken) pc_next = pc_q + imm_b;
        else                   pc_next = pc_plus4;
    end
endmodule
