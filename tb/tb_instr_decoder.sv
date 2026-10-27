`timescale 1ns/1ps
module tb_instr_decoder;
    logic [31:0] instr;
    logic [6:0] opcode, funct7; logic [2:0] funct3; logic [4:0] rs1, rs2, rd;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    int errors = 0;
    instr_decoder dut (.*);

    task automatic check(string name, logic [31:0] got, logic [31:0] exp);
        if (got !== exp) begin
            $display("FAIL %-12s got=0x%08h exp=0x%08h", name, got, exp);
            errors++;
        end
    endtask

    initial begin
        instr = 32'h400002B7; #1; check("lui op", opcode, 7'h37); check("lui rd", rd, 5); check("lui imm_u", imm_u, 32'h4000_0000);
        instr = 32'h0042A303; #1; check("lw op", opcode, 7'h03); check("lw f3", funct3, 2); check("lw rs1", rs1, 5); check("lw rd", rd, 6); check("lw imm", imm_i, 4);
        instr = 32'h00236313; #1; check("ori f3", funct3, 6); check("ori imm", imm_i, 2);
        instr = 32'h0062A223; #1; check("sw op", opcode, 7'h23); check("sw rs2", rs2, 6); check("sw imm", imm_s, 4);
        instr = 32'hFE038CE3; #1; check("beq op", opcode, 7'h63); check("beq imm", imm_b, 32'hFFFF_FFF8);
        instr = 32'h00137393; #1; check("andi rs1", rs1, 6); check("andi rd", rd, 7); check("andi imm", imm_i, 1);
        instr = 32'hFE0E1EE3; #1; check("bne imm", imm_b, 32'hFFFF_FFFC);
        instr = 32'hFDDFF06F; #1; check("jal imm", imm_j, 32'hFFFF_FFDC);
        instr = 32'hFD1FF06F; #1; check("jal imm2", imm_j, 32'hFFFF_FFD0);
        if (errors == 0) $display("PASS: decoder"); else $display("FAIL: %0d", errors);
        $finish;
    end
endmodule
