`timescale 1ns / 1ps

module EX_unit_sub (
    input clk,
    input reset,
    input CPU_state,
    input hazard_EXBR_bubble,

    input [31:0] EXBR_tentative_data_to_write_from_other_side,
    input [31:0] BRMEM_register_file_data_to_write,
    input [31:0] BRMEM_register_file_data_to_write_from_other_side,
    input [31:0] register_file_data_to_write,
    input [31:0] register_file_data_to_write_from_other_side,
    input [1:0] forwarding_forwardA, forwarding_forwardB,
    input forwarding_forward_from_other_sideA,
    input forwarding_forward_from_other_sideB,
    input override_EXBR_forwarding_for_reserve, override_EXBR_forwarding_from_other_side_for_reserve,
    input reserve_result, reserve_result_from_other_side,

    // IDEX - actions
    input IDEX_branch, IDEX_memread, IDEX_memwrite, IDEX_regwrite, IDEX_stop, IDEX_print, IDEX_flush_upon_wrong_speculation, IDEX_multiply,
    input [1:0] IDEX_jump,
    input IDEX_reserve,
    input IDEX_trap, IDEX_CSR_file_write, IDEX_write_mcause,

    // IDEX - infos
    input [31:0] IDEX_instruction, IDEX_pc, IDEX_immediate_value, IDEX_readdata1, IDEX_readdata2,
    input IDEX_immediate,
    input [1:0] IDEX_alusrc1, IDEX_toreg,
    input [31:0] IDEX_speculated_next_pc,
    input [3:0] IDEX_ALU_operation,
    input IDEX_forward_for_rd,
    input IDEX_use_ALU_result_from_prev_inst,
    input IDEX_trap_is_return,
    input [2:0] IDEX_CSR_to_write,
    input [31:0] IDEX_CSR_value,
    input [31:0] IDEX_mcause_to_write, IDEX_mtval_to_write,

    // EXBR - actions
    output reg EXBR_branch, EXBR_memread, EXBR_memwrite, EXBR_regwrite, EXBR_stop, EXBR_print, EXBR_flush_upon_wrong_speculation,
    output reg [1:0] EXBR_jump,
    output reg EXBR_reserve,
    output reg EXBR_trap, EXBR_CSR_file_write, EXBR_write_mcause,

    // EXBR - infos
    output reg [31:0] EXBR_instruction, EXBR_pcplusfour, EXBR_ALU_result, EXBR_data_to_write,
    output reg [1:0] EXBR_toreg,
    output reg [31:0] EXBR_printdata,
    output reg [31:0] EXBR_pc,
    output reg EXBR_branch_control_taken,
    output reg [31:0] EXBR_speculated_next_pc,
    output reg [31:0] EXBR_pcplusimmediate,
    output reg [31:0] EXBR_tentative_register_file_data_to_write,
    output reg EXBR_trap_is_return,
    output reg [31:0] EXBR_CSR_value,
    output reg [2:0] EXBR_CSR_to_write,
    output reg [31:0] EXBR_CSR_value_to_write,
    output reg [31:0] EXBR_mcause_to_write, EXBR_mtval_to_write,

    // wires
    output [4:0] forwarding_rs1, forwarding_rs2,
    output hazard_IDEX_memread,
    output hazard_EX_multiplying,
    output [4:0] hazard_IDEX_rd,
    output [31:0] CSR_forwarding_CSR_value_to_write_in_EX 
);

    // Signals for ALU
    wire [3:0] ALU_operation;
    wire [31:0] ALU_inputx, ALU_inputy;
    wire [31:0] ALU_result;

    // Signals for CSR_ALU
    wire [31:0] CSR_ALU_CSR_value, CSR_ALU_rs1_value, CSR_ALU_rs1;
    wire [2:0] CSR_ALU_funct3;
    wire CSR_ALU_trap;
    wire [31:0] CSR_ALU_pc;
    wire [31:0] CSR_ALU_result;

    // Signals for branch_control
    wire branch_control_branch;
    wire [2:0] branch_control_funct3;
    wire [31:0] branch_control_inputx, branch_control_inputy;
    wire branch_control_taken;

    wire [31:0] new_readdata1, new_readdata2;

    ALU ALU_inst (
        .operation(ALU_operation),
        .inputx(ALU_inputx),
        .inputy(ALU_inputy),
        
        .result(ALU_result)
    );

    CSR_ALU CSR_ALU_inst (
        .CSR_value(CSR_ALU_CSR_value),
        .rs1_value(CSR_ALU_rs1_value),
        .rs1(CSR_ALU_rs1),
        .funct3(CSR_ALU_funct3),
        .trap(CSR_ALU_trap),
        .pc(CSR_ALU_pc),

        .result(CSR_ALU_result)
    );

    branch_control branch_control_inst (
        .branch(branch_control_branch),
        .funct3(branch_control_funct3),
        .inputx(branch_control_inputx),
        .inputy(branch_control_inputy),

        .taken(branch_control_taken)
    );

    always @(posedge clk) begin
        if (reset || CPU_state == 0 || hazard_EXBR_bubble) begin
            EXBR_branch <= 0;
            EXBR_jump <= 0;
            EXBR_memread <= 0;
            EXBR_memwrite <= 0;
            EXBR_regwrite <= 0; 
            EXBR_stop <= 0;
            EXBR_print <= 0;
            EXBR_flush_upon_wrong_speculation <= 0;
            EXBR_reserve <= 0;
            EXBR_trap <= 0;
            EXBR_CSR_file_write <= 0; 
            EXBR_write_mcause <= 0;
        end
        else begin
            EXBR_pcplusfour <= IDEX_pc + 4;
            EXBR_instruction <= IDEX_instruction;
            EXBR_ALU_result <= ALU_result;
            EXBR_data_to_write <= (IDEX_use_ALU_result_from_prev_inst) ? EXBR_ALU_result : new_readdata2;
            EXBR_memread <= IDEX_memread;
            EXBR_memwrite <= IDEX_memwrite;
            EXBR_toreg <= IDEX_toreg;
            EXBR_regwrite <= IDEX_regwrite;
            EXBR_stop <= IDEX_stop;
            EXBR_print <= IDEX_print;
            EXBR_printdata <= new_readdata1;
            EXBR_pc <= IDEX_pc;
            EXBR_jump <= IDEX_jump;
            EXBR_branch <= IDEX_branch;
            EXBR_branch_control_taken <= branch_control_taken;
            EXBR_flush_upon_wrong_speculation <= IDEX_flush_upon_wrong_speculation;
            EXBR_speculated_next_pc <= IDEX_speculated_next_pc;
            EXBR_pcplusimmediate <= IDEX_pc + IDEX_immediate_value;
            EXBR_tentative_register_file_data_to_write <= (IDEX_toreg[0] == 1) ? IDEX_CSR_value : ((IDEX_toreg[1] == 1) ? IDEX_pc + 4 : ALU_result); 
            EXBR_reserve <= IDEX_reserve;
            EXBR_trap <= IDEX_trap;
            EXBR_trap_is_return <= IDEX_trap_is_return;
            EXBR_CSR_file_write <= IDEX_CSR_file_write;
            EXBR_CSR_value <= IDEX_CSR_value;
            EXBR_CSR_to_write <= IDEX_CSR_to_write;
            EXBR_CSR_value_to_write <= CSR_forwarding_CSR_value_to_write_in_EX;
            EXBR_write_mcause <= IDEX_write_mcause;
            EXBR_mcause_to_write <= IDEX_mcause_to_write;
            EXBR_mtval_to_write <= IDEX_mtval_to_write;
        end
        
        //if (IDEX_forward_for_rd) $display("input x: %d, input y: %d, result: %d", ALU_inputx, ALU_inputy, ALU_result);
    end

    assign forwarding_rs1 = (IDEX_forward_for_rd == 1) ? IDEX_instruction[11:7] : IDEX_instruction[19:15];
    assign forwarding_rs2 = IDEX_instruction[24:20];

    assign new_readdata1 = (forwarding_forward_from_other_sideA == 1) ? (forwarding_forwardA > 1) ? ((forwarding_forwardA == 3) ? register_file_data_to_write_from_other_side : BRMEM_register_file_data_to_write_from_other_side)
                                                                                                  : ((forwarding_forwardA == 1) ? (override_EXBR_forwarding_from_other_side_for_reserve ? reserve_result_from_other_side : EXBR_tentative_data_to_write_from_other_side) : IDEX_readdata1)
                                                                      : (forwarding_forwardA > 1) ? ((forwarding_forwardA == 3) ? register_file_data_to_write : BRMEM_register_file_data_to_write)
                                                                                                  : ((forwarding_forwardA == 1) ? (override_EXBR_forwarding_for_reserve ? reserve_result : EXBR_tentative_register_file_data_to_write) : IDEX_readdata1); 
    assign new_readdata2 = (forwarding_forward_from_other_sideB == 1) ? (forwarding_forwardB > 1) ? ((forwarding_forwardB == 3) ? register_file_data_to_write_from_other_side : BRMEM_register_file_data_to_write_from_other_side)
                                                                                                  : ((forwarding_forwardB == 1) ? (override_EXBR_forwarding_from_other_side_for_reserve ? reserve_result_from_other_side : EXBR_tentative_data_to_write_from_other_side) : IDEX_readdata2) 
                                                                      : (forwarding_forwardB > 1) ? ((forwarding_forwardB == 3) ? register_file_data_to_write : BRMEM_register_file_data_to_write)
                                                                                                  : ((forwarding_forwardB == 1) ? (override_EXBR_forwarding_for_reserve ? reserve_result : EXBR_tentative_register_file_data_to_write) : IDEX_readdata2); 

    assign ALU_operation = IDEX_ALU_operation;
    assign ALU_inputx = (IDEX_alusrc1 == 0) ? new_readdata1 : ((IDEX_alusrc1 == 1) ? 0 : IDEX_pc);
    assign ALU_inputy = (IDEX_immediate == 1) ? IDEX_immediate_value : new_readdata2;

    assign CSR_ALU_CSR_value = IDEX_CSR_value;
    assign CSR_ALU_rs1_value = new_readdata1;
    assign CSR_ALU_rs1 = {27'b0, IDEX_instruction[19:15]};
    assign CSR_ALU_funct3 = IDEX_instruction[14:12];
    assign CSR_ALU_trap = IDEX_trap;
    assign CSR_ALU_pc = IDEX_pc;

    assign branch_control_branch = IDEX_branch;
    assign branch_control_funct3 = IDEX_instruction[14:12];
    assign branch_control_inputx = new_readdata1;
    assign branch_control_inputy = new_readdata2;

    assign hazard_IDEX_memread = IDEX_memread;
    assign hazard_IDEX_rd = IDEX_instruction[11:7];
    assign hazard_EX_multiplying = 0;

    assign CSR_forwarding_CSR_value_to_write_in_EX = CSR_ALU_result; 

endmodule