`timescale 1ns / 1ps

module BR_unit #(
    parameter INVALID_DATA_ADDRESS_START = 400
) (
    input clk,
    input reset,
    input CPU_state,
    input hazard_BRMEM_bubble,

    // EXBR - actions
    input EXBR_branch, EXBR_memread, EXBR_memwrite, EXBR_regwrite, EXBR_stop, EXBR_print, EXBR_flush_upon_wrong_speculation,
    input [1:0] EXBR_jump,
    input EXBR_trap, EXBR_CSR_file_write, EXBR_write_mcause,

    // EXBR - infos
    input [31:0] EXBR_instruction, EXBR_pcplusfour, EXBR_ALU_result, EXBR_data_to_write,
    input [1:0] EXBR_toreg,
    input [31:0] EXBR_printdata,
    input [31:0] EXBR_pc,
    input EXBR_branch_control_taken,
    input [31:0] EXBR_speculated_next_pc,
    input [31:0] EXBR_pcplusimmediate,
    input EXBR_trap_is_return,
    input [31:0] EXBR_CSR_value,
    input [2:0] EXBR_CSR_to_write,
    input [31:0] EXBR_CSR_value_to_write,
    input [31:0] EXBR_mcause_to_write, EXBR_mtval_to_write,

    // BRMEM - actions
    output reg BRMEM_regwrite, BRMEM_stop, BRMEM_print,

    // BRMEM - infos
    output reg [31:0] BRMEM_instruction, BRMEM_pcplusfour, BRMEM_ALU_result, BRMEM_data_to_write,
    output reg [1:0] BRMEM_toreg,
    output reg [31:0] BRMEM_printdata,
    output reg [31:0] BRMEM_CSR_value,

    // wires to next_pc_predictor
    output [31:0] next_pc_predictor_write_pc,
    output next_pc_predictor_targetwrite, next_pc_predictor_takenwrite, next_pc_predictor_jumpwrite, next_pc_predictor_raswrite,
    output next_pc_predictor_taken, next_pc_predictor_is_jump, next_pc_predictor_is_return,
    output [31:0] next_pc_predictor_target_to_write,
    output [31:0] next_pc_predictor_return_address_to_push,

    // wires
    output [31:0] next_pc,
    output hazard_EXBR_wrong_speculation,
    output hazard_EXBR_trap,

    // wires to CSR file
    output CSR_file_write,
    output [2:0] CSR_file_CSR_to_write,
    output [31:0] CSR_file_value_to_write, 
    output CSR_file_write_mcause,
    output [31:0] CSR_file_mcause_to_write, CSR_file_mtval_to_write,
    output CSR_file_mstatus_trap_shift, CSR_file_mstatus_return_shift,
    
    // wires to forwarding
    output [4:0] forwarding_EXBR_rd,
    output forwarding_EXBR_rw
);

    wire load_access_fault, store_access_fault;

    always @(posedge clk) begin
        if (reset || CPU_state == 0 || hazard_BRMEM_bubble) begin
            BRMEM_regwrite <= 0;
            BRMEM_stop <= 0;
            BRMEM_print <= 0;
        end
        else begin
            BRMEM_regwrite <= EXBR_regwrite;
            BRMEM_stop <= EXBR_stop;
            BRMEM_print <= EXBR_print;

            BRMEM_instruction <= EXBR_instruction;
            BRMEM_pcplusfour <= EXBR_pcplusfour;
            BRMEM_ALU_result <= EXBR_ALU_result;
            BRMEM_data_to_write <= EXBR_data_to_write;
            BRMEM_toreg <= EXBR_toreg;
            BRMEM_printdata <= EXBR_printdata;
            BRMEM_CSR_value <= EXBR_CSR_value;
        end
    end

    assign load_access_fault = (EXBR_memread && (EXBR_ALU_result >= INVALID_DATA_ADDRESS_START));
    assign store_access_fault = (EXBR_memwrite && (EXBR_ALU_result >= INVALID_DATA_ADDRESS_START));

    assign next_pc = (EXBR_trap || load_access_fault || store_access_fault) ? EXBR_CSR_value 
                                                                            : (EXBR_branch_control_taken || EXBR_jump == 2) ? EXBR_pcplusimmediate : ((EXBR_jump == 3) ? EXBR_ALU_result : EXBR_pcplusfour);
    
    assign hazard_EXBR_wrong_speculation = (EXBR_flush_upon_wrong_speculation && EXBR_speculated_next_pc != next_pc) ? 1 : 0;
    assign hazard_EXBR_trap = (EXBR_trap || load_access_fault || store_access_fault);

    assign CSR_file_write = ((EXBR_CSR_file_write || load_access_fault || store_access_fault) && ~hazard_BRMEM_bubble);
    assign CSR_file_CSR_to_write = EXBR_CSR_to_write;
    assign CSR_file_value_to_write = (load_access_fault || store_access_fault) ? EXBR_pc : EXBR_CSR_value_to_write;
    assign CSR_file_write_mcause = ((EXBR_write_mcause || load_access_fault || store_access_fault) && ~hazard_BRMEM_bubble);
    assign CSR_file_mcause_to_write = (EXBR_write_mcause) ? EXBR_mcause_to_write : (load_access_fault ? 5 : 7);
    assign CSR_file_mtval_to_write = (load_access_fault || store_access_fault) ? EXBR_ALU_result : EXBR_mtval_to_write;
    assign CSR_file_mstatus_trap_shift = ((EXBR_trap || load_access_fault || store_access_fault) && ~hazard_BRMEM_bubble && ~EXBR_trap_is_return);
    assign CSR_file_mstatus_return_shift = (EXBR_trap && ~hazard_BRMEM_bubble && EXBR_trap_is_return);

    assign next_pc_predictor_write_pc = EXBR_pc;
    assign next_pc_predictor_takenwrite = (EXBR_flush_upon_wrong_speculation && EXBR_branch) ? 1 : 0;
    assign next_pc_predictor_targetwrite = (EXBR_flush_upon_wrong_speculation && ((EXBR_branch && EXBR_branch_control_taken) || EXBR_jump == 2 || EXBR_jump == 3)) ? 1 : 0;
    assign next_pc_predictor_jumpwrite = (EXBR_flush_upon_wrong_speculation && (EXBR_branch || EXBR_jump == 2 || EXBR_jump == 3)) ? 1 : 0;
    assign next_pc_predictor_raswrite = (EXBR_flush_upon_wrong_speculation && (EXBR_speculated_next_pc != next_pc) && (EXBR_jump == 2 || EXBR_jump == 3)) ? 1 : 0;
    assign next_pc_predictor_taken = (EXBR_branch_control_taken) ? 1 : 0;
    assign next_pc_predictor_is_jump = (EXBR_jump == 2) ? 1 : 0;
    assign next_pc_predictor_is_return = (EXBR_jump == 3) ? 1 : 0;
    assign next_pc_predictor_target_to_write = next_pc;
    assign next_pc_predictor_return_address_to_push = EXBR_pcplusfour;

    assign forwarding_EXBR_rd = EXBR_instruction[11:7];
    assign forwarding_EXBR_rw = EXBR_regwrite;

endmodule