`timescale 1ns / 1ps

module CPU #(
    parameter PRINT_OPCODE = 7'b0101011,
    parameter START_EXECUTION_OPCODE = 7'b0001011,
    parameter IMEM_SIZE = 400,
    parameter DMEM_SIZE = 400,
    parameter CLKS_PER_BIT = 10416,
    parameter BUFFER_SIZE = 200,
    parameter MAX_BITS_TO_SEND = 32,
    parameter NEXT_PC_PREDICTOR_BUFFER_SIZE = 64,
    parameter GLOBAL_HISTORY_REGISTER_SIZE = 6,
    parameter RETURN_ADDRESS_STACK_SIZE = 8,
    parameter REGISTER_COUNT = 32,
    parameter PROGRAM_START_ADDRESS = 256
) (
    input clk,
    input reset,
    input start_execution,
    input [31:0] instruction_from_IMem0,
    input [31:0] instruction_from_IMem1,

    output [31:0] instruction_address,
    output uart_output);

    localparam IDLE = 1'b0,
               EXECUTING = 1'b1;

    localparam MTIME_ADDRESS = DMEM_SIZE;
    localparam MTIMECMP_ADDRESS = DMEM_SIZE + 4;
    localparam INVALID_DATA_ADDRESS_START = DMEM_SIZE + 8;

    reg CPU_state;
    reg [31:0] pc;
    wire [31:0] next_pc_0; // from speculation_recover_unit_0
    wire [31:0] next_pc_1; // from speculation_recover_unit_1

    // Signals for forwarding
    wire [4:0] forwarding_rs10, forwarding_rs20; // from EX_unit_0
    wire [4:0] forwarding_rs11, forwarding_rs21; // from EX_unit_1
    wire [4:0] forwarding_EXBR0_rd; // from BR_unit
    wire [4:0] forwarding_EXBR1_rd; // from BR_unit
    wire forwarding_EXBR0_rw; // from BR_unit
    wire forwarding_EXBR1_rw; //from BR_unit
    wire [4:0] forwarding_BRMEM0_rd; // from MEM_unit
    wire [4:0] forwarding_BRMEM1_rd; // from MEM_unit
    wire forwarding_BRMEM0_rw; // from MEM_unit
    wire forwarding_BRMEM1_rw; // from MEM_unit
    wire [4:0] forwarding_MEMWB0_rd; // from WB_unit
    wire [4:0] forwarding_MEMWB1_rd; // from WB_unit
    wire forwarding_MEMWB0_rw; // from WB_unit
    wire forwarding_MEMWB1_rw; // from WB_unit
    // output
    wire [1:0] forwarding_forwardA0, forwarding_forwardB0, forwarding_forwardA1, forwarding_forwardB1;
    wire forwarding_forward_from_other_sideA0, forwarding_forward_from_other_sideB0, forwarding_forward_from_other_sideA1, forwarding_forward_from_other_sideB1;

    // Signals for hazard
    wire [4:0] hazard_rs10, hazard_rs20, hazard_rd0; // from ID_unit_0
    wire [4:0] hazard_rs11, hazard_rs21, hazard_rd1; // from ID_unit_1
    wire hazard_rw0, hazard_rw1; // from ID_units
    wire hazard_memuse0, hazard_memuse1; // from ID_units
    wire hazard_print0, hazard_print1; // from ID_units
    wire hazard_decoding_multiply; // from main ID unit
    wire hazard_decoding_atomic; // from main ID unit
    wire hazard_CSR_file_write_in_main_ID; // from main ID unit
    wire [2:0] hazard_CSR_to_write_in_main_ID; // from main ID unit
    wire hazard_multiply_in_sub_ID; // from sub ID unit
    wire hazard_atomic_in_sub_ID; // from sub ID unit
    wire [2:0] hazard_CSR_value_select_in_sub_ID; // from sub ID unit
    wire [4:0] hazard_IDEX0_rd; // from EX_unit_0
    wire [4:0] hazard_IDEX1_rd; // from EX_unit_1
    wire hazard_IDEX0_memread; // from EX_unit_0
    wire hazard_IDEX1_memread; // from EX_unit_1
    wire hazard_EX0_multiplying; // from EX_unit_0
    wire hazard_EX1_multiplying; // from EX_unit_1
    wire hazard_EXBR0_wrong_speculation; // from BR_unit_0
    wire hazard_EXBR1_wrong_speculation; // from BR_unit_1
    wire hazard_EXBR0_trap; // from BR_unit_0
    wire hazard_EXBR1_trap; // from BR_unit_1
    // output
    wire [1:0] hazard_pcwrite;
    wire hazard_IFID_bubble, hazard_IFID_stall, hazard_IFID_separate;
    wire hazard_IDEX0_bubble, hazard_EXBR0_bubble, hazard_BRMEM0_bubble;
    wire hazard_IDEX1_bubble, hazard_EXBR1_bubble, hazard_BRMEM1_bubble;
    wire hazard_invalidate_reserve;

    // Signals for CSR_forwarding
    wire [2:0] CSR_forwarding_ID0_CSR_value_select, CSR_forwarding_ID1_CSR_value_select;
    wire CSR_forwarding_forward_EX0_to_ID0, CSR_forwarding_forward_EX1_to_ID0;
    wire CSR_forwarding_forward_EX0_to_ID1, CSR_forwarding_forward_EX1_to_ID1; 
    // from EX to ID
    wire [31:0] CSR_forwarding_CSR_value_to_write_in_EX0, CSR_forwarding_CSR_value_to_write_in_EX1; 

    // Signals for CSR file
    wire CSR_file_write0, CSR_file_write1;
    wire [2:0] CSR_file_CSR_to_write0, CSR_file_CSR_to_write1;
    wire [31:0] CSR_file_value_to_write0, CSR_file_value_to_write1;
    wire CSR_file_write_mcause0, CSR_file_write_mcause1;
    wire [31:0] CSR_file_mcause_to_write0, CSR_file_mcause_to_write1;
    wire [31:0] CSR_file_mtval_to_write0, CSR_file_mtval_to_write1;
    wire CSR_file_mstatus_trap_shift0, CSR_file_mstatus_trap_shift1;
    wire CSR_file_mstatus_return_shift0, CSR_file_mstatus_return_shift1;
    // output
    wire [31:0] CSR_file_mtvec;
    wire [31:0] CSR_file_mstatus;
    wire [31:0] CSR_file_mepc;
    wire [31:0] CSR_file_mcause;
    wire [31:0] CSR_file_mscratch;
    wire [31:0] CSR_file_mtval;
    wire [31:0] CSR_file_mie;
    wire [31:0] CSR_file_mip;
    // timer
    wire timer_mtip;

    // Signals for next_pc_predictor
    reg [31:0] next_pc_predictor_read_pc0, next_pc_predictor_read_pc1;
    // output
    wire [31:0] next_pc_predictor_predicted_target0, next_pc_predictor_predicted_target1;
    wire next_pc_predictor_predicted_jump0, next_pc_predictor_predicted_jump1, next_pc_predictor_predicted_return0, next_pc_predictor_predicted_return1;
    wire [31:0] next_pc_predictor_return_address_to_push_from_predictor_candidate0, next_pc_predictor_return_address_to_push_from_predictor_candidate1;

    // from PC choose stage to next_pc_predictor
    wire next_pc_predictor_predicted_jump_used, next_pc_predictor_predicted_return_used;
    wire [31:0] next_pc_predictor_return_address_to_push_from_predictor;

    // from next_pc_predictor_writer
    wire [31:0] next_pc_predictor_write_pc;
    wire next_pc_predictor_targetwrite, next_pc_predictor_takenwrite, next_pc_predictor_jumpwrite, next_pc_predictor_raswrite;
    wire next_pc_predictor_taken, next_pc_predictor_is_jump, next_pc_predictor_is_return;
    wire [31:0] next_pc_predictor_target_to_write;
    wire [31:0] next_pc_predictor_return_address_to_push;

    // from BR_unit_0
    wire [31:0] next_pc_predictor_write_pc0;
    wire next_pc_predictor_targetwrite0, next_pc_predictor_takenwrite0, next_pc_predictor_jumpwrite0, next_pc_predictor_raswrite0;
    wire next_pc_predictor_taken0, next_pc_predictor_is_jump0, next_pc_predictor_is_return0;
    wire [31:0] next_pc_predictor_target_to_write0;
    wire [31:0] next_pc_predictor_return_address_to_push0;

    // from BR_unit_1
    wire [31:0] next_pc_predictor_write_pc1;
    wire next_pc_predictor_targetwrite1, next_pc_predictor_takenwrite1, next_pc_predictor_jumpwrite1, next_pc_predictor_raswrite1;
    wire next_pc_predictor_taken1, next_pc_predictor_is_jump1, next_pc_predictor_is_return1;
    wire [31:0] next_pc_predictor_target_to_write1;
    wire [31:0] next_pc_predictor_return_address_to_push1;

    // Signals for register file
    wire [$clog2(REGISTER_COUNT) - 1 : 0] register_file_register_to_read10, register_file_register_to_read20; // from ID_unit_0
    wire [$clog2(REGISTER_COUNT) - 1 : 0] register_file_register_to_read11, register_file_register_to_read21; // from ID_unit_1
    wire register_file_write_enable0, register_file_write_enable1; // from WB_unit
    wire [$clog2(REGISTER_COUNT) - 1 : 0] register_file_register_to_write0, register_file_register_to_write1; // from WB_unit
    wire [31:0] register_file_data_to_write0, register_file_data_to_write1; // from WB_unit

    // Signals for IF -> ID
    wire [31:0] IFID0_instruction, IFID0_pc;
    wire IFID0_flush_upon_wrong_speculation;
    wire [31:0] IFID0_speculated_next_pc;
    wire IFID0_instruction_access_fault, IFID0_instruction_misaligned;

    wire [31:0] IFID1_instruction, IFID1_pc;
    wire IFID1_flush_upon_wrong_speculation;
    wire [31:0] IFID1_speculated_next_pc;
    wire IFID1_instruction_access_fault, IFID1_instruction_misaligned;

    // Signals for ID -> EX - actions
    wire IDEX0_branch, IDEX0_memread, IDEX0_memwrite, IDEX0_regwrite, IDEX0_stop, IDEX0_print, IDEX0_flush_upon_wrong_speculation, IDEX0_multiply;
    wire [1:0] IDEX0_jump;
    wire IDEX0_reserve;
    wire IDEX0_trap, IDEX0_CSR_file_write, IDEX0_write_mcause;

    wire IDEX1_branch, IDEX1_memread, IDEX1_memwrite, IDEX1_regwrite, IDEX1_stop, IDEX1_print, IDEX1_flush_upon_wrong_speculation, IDEX1_multiply;
    wire [1:0] IDEX1_jump;
    wire IDEX1_reserve;
    wire IDEX1_trap, IDEX1_CSR_file_write, IDEX1_write_mcause;
    
    // Signals for ID -> EX - infos
    wire [31:0] IDEX0_instruction, IDEX0_pc, IDEX0_immediate_value;
    wire [31:0] IDEX0_readdata1, IDEX0_readdata2; // from register file
    wire IDEX0_immediate;
    wire [1:0] IDEX0_alusrc1, IDEX0_toreg;
    wire [31:0] IDEX0_speculated_next_pc;
    wire [3:0] IDEX0_ALU_operation;
    wire IDEX0_forward_for_rd;
    wire IDEX0_use_ALU_result_from_prev_inst;
    wire IDEX0_trap_is_return;
    wire [2:0] IDEX0_CSR_to_write;
    wire [31:0] IDEX0_CSR_value, IDEX0_mcause_to_write, IDEX0_mtval_to_write;

    wire [31:0] IDEX1_instruction, IDEX1_pc, IDEX1_immediate_value;
    wire [31:0] IDEX1_readdata1, IDEX1_readdata2; // from register file
    wire IDEX1_immediate;
    wire [1:0] IDEX1_alusrc1, IDEX1_toreg;
    wire [31:0] IDEX1_speculated_next_pc;
    wire [3:0] IDEX1_ALU_operation;
    wire IDEX1_trap_is_return;
    wire [2:0] IDEX1_CSR_to_write;
    wire [31:0] IDEX1_CSR_value, IDEX1_mcause_to_write, IDEX1_mtval_to_write;

    // Signals for EX -> BR - actions
    wire EXBR0_branch, EXBR0_memread, EXBR0_memwrite, EXBR0_regwrite, EXBR0_stop, EXBR0_print, EXBR0_flush_upon_wrong_speculation;
    wire [1:0] EXBR0_jump;
    wire EXBR0_reserve;
    wire EXBR0_trap, EXBR0_CSR_file_write, EXBR0_write_mcause;

    wire EXBR1_branch, EXBR1_memread, EXBR1_memwrite, EXBR1_regwrite, EXBR1_stop, EXBR1_print, EXBR1_flush_upon_wrong_speculation;
    wire [1:0] EXBR1_jump;
    wire EXBR1_reserve;
    wire EXBR1_trap, EXBR1_CSR_file_write, EXBR1_write_mcause;

    // Signals for EX -> BR - infos
    wire [31:0] EXBR0_instruction, EXBR0_pcplusfour, EXBR0_ALU_result, EXBR0_data_to_write;
    wire [1:0] EXBR0_toreg;
    wire [31:0] EXBR0_printdata;
    wire [31:0] EXBR0_pc;
    wire EXBR0_branch_control_taken;
    wire [31:0] EXBR0_speculated_next_pc;
    wire [31:0] EXBR0_pcplusimmediate;
    wire [31:0] EXBR0_tentative_register_file_data_to_write;
    wire EXBR0_trap_is_return;
    wire [31:0] EXBR0_CSR_value;
    wire [2:0] EXBR0_CSR_to_write;
    wire [31:0] EXBR0_CSR_value_to_write, EXBR0_mcause_to_write, EXBR0_mtval_to_write;

    wire [31:0] EXBR1_instruction, EXBR1_pcplusfour, EXBR1_ALU_result, EXBR1_data_to_write;
    wire [1:0] EXBR1_toreg;
    wire [31:0] EXBR1_printdata;
    wire [31:0] EXBR1_pc;
    wire EXBR1_branch_control_taken;
    wire [31:0] EXBR1_speculated_next_pc;
    wire [31:0] EXBR1_pcplusimmediate;
    wire [31:0] EXBR1_tentative_register_file_data_to_write;
    wire EXBR1_trap_is_return;
    wire [31:0] EXBR1_CSR_value;
    wire [2:0] EXBR1_CSR_to_write;
    wire [31:0] EXBR1_CSR_value_to_write, EXBR1_mcause_to_write, EXBR1_mtval_to_write;

    // Signals for BR -> MEM - actions
    wire BRMEM0_regwrite, BRMEM0_stop, BRMEM0_print;

    wire BRMEM1_regwrite, BRMEM1_stop, BRMEM1_print;

    // Signals for BR -> MEM - infos
    wire [31:0] BRMEM0_instruction, BRMEM0_pcplusfour, BRMEM0_ALU_result, BRMEM0_data_to_write;
    wire [1:0] BRMEM0_toreg;
    wire [31:0] BRMEM0_printdata;
    wire [31:0] BRMEM0_register_file_data_to_write; // from MEM_unit_0
    wire [31:0] BRMEM0_CSR_value;

    wire [31:0] BRMEM1_instruction, BRMEM1_pcplusfour, BRMEM1_ALU_result, BRMEM1_data_to_write;
    wire [1:0] BRMEM1_toreg;
    wire [31:0] BRMEM1_printdata;
    wire [31:0] BRMEM1_register_file_data_to_write; // from MEM_unit_1
    wire [31:0] BRMEM1_CSR_value;

    // Signals for forwarding reserve stores
    wire override_EXBR0_forwarding_for_reserve, override_EXBR1_forwarding_for_reserve; // from MEM_unit
    wire EXBR0_reserve_result, EXBR1_reserve_result; // from MEM_unit

    // Signals for MEM -> WB - actions
    wire MEMWB0_regwrite, MEMWB0_stop, MEMWB0_print;

    wire MEMWB1_regwrite, MEMWB1_stop, MEMWB1_print;

    // Signals for MEM -> WB - infos
    wire [31:0] MEMWB0_instruction, MEMWB0_pcplusfour, MEMWB0_ALU_result;
    wire [1:0] MEMWB0_toreg;
    wire [31:0] MEMWB0_printdata;
    wire [31:0] MEMWB0_DMem_readdata;
    wire [31:0] MEMWB0_CSR_value;

    wire [31:0] MEMWB1_instruction, MEMWB1_pcplusfour, MEMWB1_ALU_result;
    wire [1:0] MEMWB1_toreg;
    wire [31:0] MEMWB1_printdata;
    wire [31:0] MEMWB1_DMem_readdata;
    wire [31:0] MEMWB1_CSR_value;

    // Regs for stats
    reg [31:0] stat_valid_instruction_count;
    reg [31:0] stat_total_cycle_count;
    reg [31:0] stat_branch_count;
    reg [31:0] stat_misprediction_count;

    forwarding forwarding_inst (
        .rs10(forwarding_rs10),
        .rs20(forwarding_rs20),
        .rs11(forwarding_rs11),
        .rs21(forwarding_rs21),
        .EXBR0_rd(forwarding_EXBR0_rd),
        .EXBR1_rd(forwarding_EXBR1_rd),
        .BRMEM0_rd(forwarding_BRMEM0_rd),
        .BRMEM1_rd(forwarding_BRMEM1_rd),
        .MEMWB0_rd(forwarding_MEMWB0_rd),
        .MEMWB1_rd(forwarding_MEMWB1_rd),
        .EXBR0_rw(forwarding_EXBR0_rw),
        .EXBR1_rw(forwarding_EXBR1_rw),
        .BRMEM0_rw(forwarding_BRMEM0_rw),
        .BRMEM1_rw(forwarding_BRMEM1_rw),
        .MEMWB0_rw(forwarding_MEMWB0_rw),
        .MEMWB1_rw(forwarding_MEMWB1_rw),

        .forwardA0(forwarding_forwardA0),
        .forwardB0(forwarding_forwardB0),
        .forwardA1(forwarding_forwardA1),
        .forwardB1(forwarding_forwardB1),
        .forward_from_other_sideA0(forwarding_forward_from_other_sideA0),
        .forward_from_other_sideB0(forwarding_forward_from_other_sideB0),
        .forward_from_other_sideA1(forwarding_forward_from_other_sideA1),
        .forward_from_other_sideB1(forwarding_forward_from_other_sideB1)
    );

    hazard hazard_inst (
        .rs10(hazard_rs10),
        .rs20(hazard_rs20),
        .rs11(hazard_rs11),
        .rs21(hazard_rs21),
        .rd0(hazard_rd0),
        .rd1(hazard_rd1),
        .rw0(hazard_rw0),
        .rw1(hazard_rw1),
        .memuse0(hazard_memuse0),
        .memuse1(hazard_memuse1),
        .print0(hazard_print0),
        .print1(hazard_print1),
        .decoding_multiply(hazard_decoding_multiply),
        .decoding_atomic(hazard_decoding_atomic),
        .CSR_file_write_in_main_ID(hazard_CSR_file_write_in_main_ID),
        .CSR_to_write_in_main_ID(hazard_CSR_to_write_in_main_ID),
        .multiply_in_sub_ID(hazard_multiply_in_sub_ID),
        .atomic_in_sub_ID(hazard_atomic_in_sub_ID),
        .CSR_value_select_in_sub_ID(hazard_CSR_value_select_in_sub_ID),
        .IDEX0_rd(hazard_IDEX0_rd),
        .IDEX0_memread(hazard_IDEX0_memread),
        .IDEX1_rd(hazard_IDEX1_rd),
        .IDEX1_memread(hazard_IDEX1_memread),
        .EX0_multiplying(hazard_EX0_multiplying),
        .EX1_multiplying(hazard_EX1_multiplying),
        .EXBR0_wrong_speculation(hazard_EXBR0_wrong_speculation),
        .EXBR1_wrong_speculation(hazard_EXBR1_wrong_speculation),
        .EXBR0_trap(hazard_EXBR0_trap),
        .EXBR1_trap(hazard_EXBR1_trap),

        .pcwrite(hazard_pcwrite),
        .IFID_bubble(hazard_IFID_bubble),
        .IFID_stall(hazard_IFID_stall),
        .IFID_separate(hazard_IFID_separate),

        .IDEX0_bubble(hazard_IDEX0_bubble),
        .EXBR0_bubble(hazard_EXBR0_bubble),
        .BRMEM0_bubble(hazard_BRMEM0_bubble),
        .IDEX1_bubble(hazard_IDEX1_bubble),
        .EXBR1_bubble(hazard_EXBR1_bubble),
        .BRMEM1_bubble(hazard_BRMEM1_bubble),
        .invalidate_reserve(hazard_invalidate_reserve)
    );

    CSR_forwarding CSR_forwarding_inst (
        .IDEX0_CSR_file_write(IDEX0_CSR_file_write),
        .IDEX1_CSR_file_write(IDEX1_CSR_file_write),
        .IDEX0_CSR_to_write(IDEX0_CSR_to_write),
        .IDEX1_CSR_to_write(IDEX1_CSR_to_write),
        .ID0_CSR_value_select(CSR_forwarding_ID0_CSR_value_select),
        .ID1_CSR_value_select(CSR_forwarding_ID1_CSR_value_select),

        .forward_EX0_to_ID0(CSR_forwarding_forward_EX0_to_ID0),
        .forward_EX1_to_ID0(CSR_forwarding_forward_EX1_to_ID0),
        .forward_EX0_to_ID1(CSR_forwarding_forward_EX0_to_ID1),
        .forward_EX1_to_ID1(CSR_forwarding_forward_EX1_to_ID1)
    );

    CSR_file CSR_file_inst (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),

        .timer_mtip(timer_mtip),

        .write0(CSR_file_write0),
        .CSR_to_write0(CSR_file_CSR_to_write0),
        .value_to_write0(CSR_file_value_to_write0),

        .write1(CSR_file_write1),
        .CSR_to_write1(CSR_file_CSR_to_write1),
        .value_to_write1(CSR_file_value_to_write1),

        .write_mcause0(CSR_file_write_mcause0),
        .mcause_to_write0(CSR_file_mcause_to_write0),
        .mtval_to_write0(CSR_file_mtval_to_write0),
        .write_mcause1(CSR_file_write_mcause1),
        .mcause_to_write1(CSR_file_mcause_to_write1),
        .mtval_to_write1(CSR_file_mtval_to_write1),

        .mstatus_trap_shift0(CSR_file_mstatus_trap_shift0),
        .mstatus_trap_shift1(CSR_file_mstatus_trap_shift1),
        .mstatus_return_shift0(CSR_file_mstatus_return_shift0),
        .mstatus_return_shift1(CSR_file_mstatus_return_shift1),

        .mtvec(CSR_file_mtvec),
        .mstatus(CSR_file_mstatus),
        .mepc(CSR_file_mepc),
        .mcause(CSR_file_mcause),
        .mscratch(CSR_file_mscratch),
        .mtval(CSR_file_mtval),
        .mie(CSR_file_mie),
        .mip(CSR_file_mip)
    );
    
    next_pc_predictor #(
        .NEXT_PC_PREDICTOR_BUFFER_SIZE(NEXT_PC_PREDICTOR_BUFFER_SIZE),
        .GLOBAL_HISTORY_REGISTER_SIZE(GLOBAL_HISTORY_REGISTER_SIZE),
        .RETURN_ADDRESS_STACK_SIZE(RETURN_ADDRESS_STACK_SIZE)
    ) next_pc_predictor_inst0 (
        .clk(clk),
        .reset(reset),
        .read_pc(next_pc_predictor_read_pc0),
        
        .write_pc(next_pc_predictor_write_pc),
        .takenwrite(next_pc_predictor_takenwrite),
        .targetwrite(next_pc_predictor_targetwrite),
        .jumpwrite(next_pc_predictor_jumpwrite),
        .raswrite(next_pc_predictor_raswrite),
        .taken(next_pc_predictor_taken),
        .is_jump(next_pc_predictor_is_jump),
        .is_return(next_pc_predictor_is_return),
        .target_to_write(next_pc_predictor_target_to_write),
        .return_address_to_push(next_pc_predictor_return_address_to_push),
        .predicted_jump_used(next_pc_predictor_predicted_jump_used),
        .predicted_return_used(next_pc_predictor_predicted_return_used),
        .return_address_to_push_from_predictor(next_pc_predictor_return_address_to_push_from_predictor),

        .predicted_target(next_pc_predictor_predicted_target0),
        .predicted_jump(next_pc_predictor_predicted_jump0),
        .predicted_return(next_pc_predictor_predicted_return0),
        .return_address_to_push_from_predictor_candidate(next_pc_predictor_return_address_to_push_from_predictor_candidate0)
    );

    next_pc_predictor #(
        .NEXT_PC_PREDICTOR_BUFFER_SIZE(NEXT_PC_PREDICTOR_BUFFER_SIZE),
        .GLOBAL_HISTORY_REGISTER_SIZE(GLOBAL_HISTORY_REGISTER_SIZE),
        .RETURN_ADDRESS_STACK_SIZE(RETURN_ADDRESS_STACK_SIZE)
    ) next_pc_predictor_inst1 (
        .clk(clk),
        .reset(reset),
        .read_pc(next_pc_predictor_read_pc1),

        .write_pc(next_pc_predictor_write_pc),
        .takenwrite(next_pc_predictor_takenwrite),
        .targetwrite(next_pc_predictor_targetwrite),
        .jumpwrite(next_pc_predictor_jumpwrite),
        .raswrite(next_pc_predictor_raswrite),
        .taken(next_pc_predictor_taken),
        .is_jump(next_pc_predictor_is_jump),
        .is_return(next_pc_predictor_is_return),
        .target_to_write(next_pc_predictor_target_to_write),
        .return_address_to_push(next_pc_predictor_return_address_to_push),
        .predicted_jump_used(next_pc_predictor_predicted_jump_used),
        .predicted_return_used(next_pc_predictor_predicted_return_used),
        .return_address_to_push_from_predictor(next_pc_predictor_return_address_to_push_from_predictor),

        .predicted_target(next_pc_predictor_predicted_target1),
        .predicted_jump(next_pc_predictor_predicted_jump1),
        .predicted_return(next_pc_predictor_predicted_return1),
        .return_address_to_push_from_predictor_candidate(next_pc_predictor_return_address_to_push_from_predictor_candidate1)
    );

    register_file #(
        .REGISTER_COUNT(REGISTER_COUNT)
    ) register_file_inst (
        .clk(clk),
        .reset(reset),
        .register_to_read10(register_file_register_to_read10),
        .register_to_read20(register_file_register_to_read20),
        .register_to_read11(register_file_register_to_read11),
        .register_to_read21(register_file_register_to_read21),

        .write_enable0(register_file_write_enable0),
        .register_to_write0(register_file_register_to_write0),
        .data_to_write0(register_file_data_to_write0),

        .write_enable1(register_file_write_enable1),
        .register_to_write1(register_file_register_to_write1),
        .data_to_write1(register_file_data_to_write1),

        .IDEX0_readdata1(IDEX0_readdata1),
        .IDEX0_readdata2(IDEX0_readdata2),
        .IDEX1_readdata1(IDEX1_readdata1),
        .IDEX1_readdata2(IDEX1_readdata2)
    );

    IF_unit #(
        .IMEM_SIZE(IMEM_SIZE)
    ) IF_unit_inst (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_IFID_stall(hazard_IFID_stall),
        .hazard_IFID_bubble(hazard_IFID_bubble),
        .hazard_IFID_separate(hazard_IFID_separate),

        .pc(pc),
        .instruction_from_IMem0(instruction_from_IMem0),
        .instruction_from_IMem1(instruction_from_IMem1),
        .next_pc_predictor_predicted_target0(next_pc_predictor_predicted_target0),
        .next_pc_predictor_predicted_target1(next_pc_predictor_predicted_target1),

        .IFID0_pc(IFID0_pc),
        .IFID0_instruction(IFID0_instruction),
        .IFID0_flush_upon_wrong_speculation(IFID0_flush_upon_wrong_speculation),
        .IFID0_speculated_next_pc(IFID0_speculated_next_pc),
        .IFID0_instruction_access_fault(IFID0_instruction_access_fault),
        .IFID0_instruction_misaligned(IFID0_instruction_misaligned),

        .IFID1_pc(IFID1_pc),
        .IFID1_instruction(IFID1_instruction),
        .IFID1_flush_upon_wrong_speculation(IFID1_flush_upon_wrong_speculation),
        .IFID1_speculated_next_pc(IFID1_speculated_next_pc),
        .IFID1_instruction_access_fault(IFID1_instruction_access_fault),
        .IFID1_instruction_misaligned(IFID1_instruction_misaligned),

        .instruction_address(instruction_address)
    );

    ID_unit_main #(
        .PRINT_OPCODE(PRINT_OPCODE),
        .START_EXECUTION_OPCODE(START_EXECUTION_OPCODE),
        .REGISTER_COUNT(REGISTER_COUNT)
    ) ID_unit_inst0 (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_IDEX_bubble(hazard_IDEX0_bubble),

        .CSR_file_mtvec(CSR_file_mtvec),
        .CSR_file_mstatus(CSR_file_mstatus),
        .CSR_file_mepc(CSR_file_mepc),
        .CSR_file_mcause(CSR_file_mcause),
        .CSR_file_mscratch(CSR_file_mscratch),
        .CSR_file_mtval(CSR_file_mtval),
        .CSR_file_mie(CSR_file_mie),
        .CSR_file_mip(CSR_file_mip),

        .CSR_forwarding_forward_EX0_to_ID(CSR_forwarding_forward_EX0_to_ID0),
        .CSR_forwarding_forward_EX1_to_ID(CSR_forwarding_forward_EX1_to_ID0),
        .CSR_forwarding_CSR_value_to_write_in_EX0(CSR_forwarding_CSR_value_to_write_in_EX0),
        .CSR_forwarding_CSR_value_to_write_in_EX1(CSR_forwarding_CSR_value_to_write_in_EX1),

        .IFID_pc(IFID0_pc),
        .IFID_instruction(IFID0_instruction),
        .IFID_flush_upon_wrong_speculation(IFID0_flush_upon_wrong_speculation),
        .IFID_speculated_next_pc(IFID0_speculated_next_pc),
        .IFID_instruction_access_fault(IFID0_instruction_access_fault),
        .IFID_instruction_misaligned(IFID0_instruction_misaligned),

        .IDEX_branch(IDEX0_branch),
        .IDEX_memread(IDEX0_memread),
        .IDEX_memwrite(IDEX0_memwrite),
        .IDEX_regwrite(IDEX0_regwrite),
        .IDEX_stop(IDEX0_stop),
        .IDEX_print(IDEX0_print),
        .IDEX_flush_upon_wrong_speculation(IDEX0_flush_upon_wrong_speculation),
        .IDEX_multiply(IDEX0_multiply),
        .IDEX_jump(IDEX0_jump),
        .IDEX_reserve(IDEX0_reserve),
        .IDEX_trap(IDEX0_trap),
        .IDEX_CSR_file_write(IDEX0_CSR_file_write), 
        .IDEX_write_mcause(IDEX0_write_mcause),

        .IDEX_instruction(IDEX0_instruction),
        .IDEX_pc(IDEX0_pc),
        .IDEX_immediate_value(IDEX0_immediate_value),
        .IDEX_immediate(IDEX0_immediate),
        .IDEX_alusrc1(IDEX0_alusrc1),
        .IDEX_toreg(IDEX0_toreg),
        .IDEX_speculated_next_pc(IDEX0_speculated_next_pc),
        .IDEX_ALU_operation(IDEX0_ALU_operation),
        .IDEX_forward_for_rd(IDEX0_forward_for_rd),
        .IDEX_use_ALU_result_from_prev_inst(IDEX0_use_ALU_result_from_prev_inst),
        .IDEX_trap_is_return(IDEX0_trap_is_return),
        .IDEX_CSR_to_write(IDEX0_CSR_to_write),
        .IDEX_CSR_value(IDEX0_CSR_value),
        .IDEX_mcause_to_write(IDEX0_mcause_to_write),
        .IDEX_mtval_to_write(IDEX0_mtval_to_write),

        .hazard_rs1(hazard_rs10),
        .hazard_rs2(hazard_rs20),
        .hazard_rd(hazard_rd0),
        .hazard_rw(hazard_rw0),
        .hazard_memuse(hazard_memuse0),
        .hazard_print(hazard_print0),
        .hazard_decoding_multiply(hazard_decoding_multiply),
        .hazard_decoding_atomic(hazard_decoding_atomic),
        .hazard_CSR_file_write_in_main_ID(hazard_CSR_file_write_in_main_ID),
        .hazard_CSR_to_write_in_main_ID(hazard_CSR_to_write_in_main_ID), 
        .register_file_register_to_read1(register_file_register_to_read10),
        .register_file_register_to_read2(register_file_register_to_read20),
        .CSR_forwarding_ID_CSR_value_select(CSR_forwarding_ID0_CSR_value_select)
    );

    ID_unit #(
        .PRINT_OPCODE(PRINT_OPCODE),
        .START_EXECUTION_OPCODE(START_EXECUTION_OPCODE),
        .REGISTER_COUNT(REGISTER_COUNT)
    ) ID_unit_inst1 (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_IDEX_bubble(hazard_IDEX1_bubble),

        .CSR_file_mtvec(CSR_file_mtvec),
        .CSR_file_mstatus(CSR_file_mstatus),
        .CSR_file_mepc(CSR_file_mepc),
        .CSR_file_mcause(CSR_file_mcause),
        .CSR_file_mscratch(CSR_file_mscratch),
        .CSR_file_mtval(CSR_file_mtval),
        .CSR_file_mie(CSR_file_mie),
        .CSR_file_mip(CSR_file_mip),

        .CSR_forwarding_forward_EX0_to_ID(CSR_forwarding_forward_EX0_to_ID1),
        .CSR_forwarding_forward_EX1_to_ID(CSR_forwarding_forward_EX1_to_ID1),
        .CSR_forwarding_CSR_value_to_write_in_EX0(CSR_forwarding_CSR_value_to_write_in_EX0),
        .CSR_forwarding_CSR_value_to_write_in_EX1(CSR_forwarding_CSR_value_to_write_in_EX1), 

        .IFID_pc(IFID1_pc),
        .IFID_instruction(IFID1_instruction),
        .IFID_flush_upon_wrong_speculation(IFID1_flush_upon_wrong_speculation),
        .IFID_speculated_next_pc(IFID1_speculated_next_pc),
        .IFID_instruction_access_fault(IFID1_instruction_access_fault),
        .IFID_instruction_misaligned(IFID1_instruction_misaligned),

        .IDEX_branch(IDEX1_branch),
        .IDEX_memread(IDEX1_memread),
        .IDEX_memwrite(IDEX1_memwrite),
        .IDEX_regwrite(IDEX1_regwrite),
        .IDEX_stop(IDEX1_stop),
        .IDEX_print(IDEX1_print),
        .IDEX_flush_upon_wrong_speculation(IDEX1_flush_upon_wrong_speculation),
        .IDEX_multiply(IDEX1_multiply),
        .IDEX_jump(IDEX1_jump),
        .IDEX_reserve(IDEX1_reserve),
        .IDEX_trap(IDEX1_trap),
        .IDEX_CSR_file_write(IDEX1_CSR_file_write),
        .IDEX_write_mcause(IDEX1_write_mcause),

        .IDEX_instruction(IDEX1_instruction),
        .IDEX_pc(IDEX1_pc),
        .IDEX_immediate_value(IDEX1_immediate_value),
        .IDEX_immediate(IDEX1_immediate),
        .IDEX_alusrc1(IDEX1_alusrc1),
        .IDEX_toreg(IDEX1_toreg),
        .IDEX_speculated_next_pc(IDEX1_speculated_next_pc),
        .IDEX_ALU_operation(IDEX1_ALU_operation),
        .IDEX_trap_is_return(IDEX1_trap_is_return),
        .IDEX_CSR_to_write(IDEX1_CSR_to_write),
        .IDEX_CSR_value(IDEX1_CSR_value),
        .IDEX_mcause_to_write(IDEX1_mcause_to_write),
        .IDEX_mtval_to_write(IDEX1_mtval_to_write),

        .hazard_rs1(hazard_rs11),
        .hazard_rs2(hazard_rs21),
        .hazard_rd(hazard_rd1),
        .hazard_rw(hazard_rw1),
        .hazard_memuse(hazard_memuse1),
        .hazard_print(hazard_print1),
        .hazard_multiply_in_sub_ID(hazard_multiply_in_sub_ID),
        .hazard_atomic_in_sub_ID(hazard_atomic_in_sub_ID),
        .hazard_CSR_value_select_in_sub_ID(hazard_CSR_value_select_in_sub_ID),
        .register_file_register_to_read1(register_file_register_to_read11),
        .register_file_register_to_read2(register_file_register_to_read21),
        .CSR_forwarding_ID_CSR_value_select(CSR_forwarding_ID1_CSR_value_select)
    );

    EX_unit EX_unit_inst_0 (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_EXBR_bubble(hazard_EXBR0_bubble),

        .EXBR_tentative_data_to_write_from_other_side(EXBR1_tentative_register_file_data_to_write),
        .BRMEM_register_file_data_to_write(BRMEM0_register_file_data_to_write),
        .BRMEM_register_file_data_to_write_from_other_side(BRMEM1_register_file_data_to_write),
        .register_file_data_to_write(register_file_data_to_write0),
        .register_file_data_to_write_from_other_side(register_file_data_to_write1),
        .forwarding_forwardA(forwarding_forwardA0),
        .forwarding_forwardB(forwarding_forwardB0),
        .forwarding_forward_from_other_sideA(forwarding_forward_from_other_sideA0),
        .forwarding_forward_from_other_sideB(forwarding_forward_from_other_sideB0),
        .override_EXBR_forwarding_for_reserve(override_EXBR0_forwarding_for_reserve),
        .override_EXBR_forwarding_from_other_side_for_reserve(override_EXBR1_forwarding_for_reserve),
        .reserve_result(EXBR0_reserve_result),
        .reserve_result_from_other_side(EXBR1_reserve_result),

        .IDEX_branch(IDEX0_branch),
        .IDEX_memread(IDEX0_memread),
        .IDEX_memwrite(IDEX0_memwrite),
        .IDEX_regwrite(IDEX0_regwrite),
        .IDEX_stop(IDEX0_stop),
        .IDEX_print(IDEX0_print),
        .IDEX_flush_upon_wrong_speculation(IDEX0_flush_upon_wrong_speculation),
        .IDEX_multiply(IDEX0_multiply),
        .IDEX_jump(IDEX0_jump),
        .IDEX_reserve(IDEX0_reserve),
        .IDEX_trap(IDEX0_trap),
        .IDEX_CSR_file_write(IDEX0_CSR_file_write),
        .IDEX_write_mcause(IDEX0_write_mcause),

        .IDEX_instruction(IDEX0_instruction),
        .IDEX_pc(IDEX0_pc),
        .IDEX_immediate_value(IDEX0_immediate_value),
        .IDEX_readdata1(IDEX0_readdata1),
        .IDEX_readdata2(IDEX0_readdata2),
        .IDEX_immediate(IDEX0_immediate),
        .IDEX_alusrc1(IDEX0_alusrc1),
        .IDEX_toreg(IDEX0_toreg),
        .IDEX_speculated_next_pc(IDEX0_speculated_next_pc),
        .IDEX_ALU_operation(IDEX0_ALU_operation),
        .IDEX_forward_for_rd(IDEX0_forward_for_rd),
        .IDEX_use_ALU_result_from_prev_inst(IDEX0_use_ALU_result_from_prev_inst),
        .IDEX_trap_is_return(IDEX0_trap_is_return),
        .IDEX_CSR_to_write(IDEX0_CSR_to_write),
        .IDEX_CSR_value(IDEX0_CSR_value),
        .IDEX_mcause_to_write(IDEX0_mcause_to_write),
        .IDEX_mtval_to_write(IDEX0_mtval_to_write),

        .EXBR_branch(EXBR0_branch),
        .EXBR_memread(EXBR0_memread),
        .EXBR_memwrite(EXBR0_memwrite),
        .EXBR_regwrite(EXBR0_regwrite),
        .EXBR_stop(EXBR0_stop),
        .EXBR_print(EXBR0_print),
        .EXBR_flush_upon_wrong_speculation(EXBR0_flush_upon_wrong_speculation),
        .EXBR_jump(EXBR0_jump),
        .EXBR_reserve(EXBR0_reserve),
        .EXBR_trap(EXBR0_trap),
        .EXBR_CSR_file_write(EXBR0_CSR_file_write),
        .EXBR_write_mcause(EXBR0_write_mcause),

        .EXBR_instruction(EXBR0_instruction),
        .EXBR_pcplusfour(EXBR0_pcplusfour),
        .EXBR_ALU_result(EXBR0_ALU_result),
        .EXBR_data_to_write(EXBR0_data_to_write),
        .EXBR_toreg(EXBR0_toreg),
        .EXBR_printdata(EXBR0_printdata),
        .EXBR_pc(EXBR0_pc),
        .EXBR_branch_control_taken(EXBR0_branch_control_taken),
        .EXBR_speculated_next_pc(EXBR0_speculated_next_pc),
        .EXBR_pcplusimmediate(EXBR0_pcplusimmediate),
        .EXBR_tentative_register_file_data_to_write(EXBR0_tentative_register_file_data_to_write),
        .EXBR_trap_is_return(EXBR0_trap_is_return),
        .EXBR_CSR_value(EXBR0_CSR_value),
        .EXBR_CSR_to_write(EXBR0_CSR_to_write),
        .EXBR_CSR_value_to_write(EXBR0_CSR_value_to_write),
        .EXBR_mcause_to_write(EXBR0_mcause_to_write),
        .EXBR_mtval_to_write(EXBR0_mtval_to_write),

        .forwarding_rs1(forwarding_rs10),
        .forwarding_rs2(forwarding_rs20),
        .hazard_IDEX_memread(hazard_IDEX0_memread),
        .hazard_IDEX_rd(hazard_IDEX0_rd),
        .hazard_EX_multiplying(hazard_EX0_multiplying),
        .CSR_forwarding_CSR_value_to_write_in_EX(CSR_forwarding_CSR_value_to_write_in_EX0) 
    );

    EX_unit_sub EX_unit_inst_1 (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_EXBR_bubble(hazard_EXBR1_bubble),

        .EXBR_tentative_data_to_write_from_other_side(EXBR0_tentative_register_file_data_to_write),
        .BRMEM_register_file_data_to_write(BRMEM1_register_file_data_to_write),
        .BRMEM_register_file_data_to_write_from_other_side(BRMEM0_register_file_data_to_write),
        .register_file_data_to_write(register_file_data_to_write1),
        .register_file_data_to_write_from_other_side(register_file_data_to_write0),
        .forwarding_forwardA(forwarding_forwardA1),
        .forwarding_forwardB(forwarding_forwardB1),
        .forwarding_forward_from_other_sideA(forwarding_forward_from_other_sideA1),
        .forwarding_forward_from_other_sideB(forwarding_forward_from_other_sideB1),
        .override_EXBR_forwarding_for_reserve(override_EXBR1_forwarding_for_reserve),
        .override_EXBR_forwarding_from_other_side_for_reserve(override_EXBR0_forwarding_for_reserve),
        .reserve_result(EXBR1_reserve_result),
        .reserve_result_from_other_side(EXBR0_reserve_result),

        .IDEX_branch(IDEX1_branch),
        .IDEX_memread(IDEX1_memread),
        .IDEX_memwrite(IDEX1_memwrite),
        .IDEX_regwrite(IDEX1_regwrite),
        .IDEX_stop(IDEX1_stop),
        .IDEX_print(IDEX1_print),
        .IDEX_flush_upon_wrong_speculation(IDEX1_flush_upon_wrong_speculation),
        .IDEX_multiply(IDEX1_multiply),
        .IDEX_jump(IDEX1_jump),
        .IDEX_reserve(IDEX1_reserve),
        .IDEX_trap(IDEX1_trap),
        .IDEX_CSR_file_write(IDEX1_CSR_file_write),
        .IDEX_write_mcause(IDEX1_write_mcause),

        .IDEX_instruction(IDEX1_instruction),
        .IDEX_pc(IDEX1_pc),
        .IDEX_immediate_value(IDEX1_immediate_value),
        .IDEX_readdata1(IDEX1_readdata1),
        .IDEX_readdata2(IDEX1_readdata2),
        .IDEX_immediate(IDEX1_immediate),
        .IDEX_alusrc1(IDEX1_alusrc1),
        .IDEX_toreg(IDEX1_toreg),
        .IDEX_speculated_next_pc(IDEX1_speculated_next_pc),
        .IDEX_ALU_operation(IDEX1_ALU_operation),
        .IDEX_forward_for_rd(1'b0),
        .IDEX_use_ALU_result_from_prev_inst(1'b0),
        .IDEX_trap_is_return(IDEX1_trap_is_return),
        .IDEX_CSR_to_write(IDEX1_CSR_to_write),
        .IDEX_CSR_value(IDEX1_CSR_value),
        .IDEX_mcause_to_write(IDEX1_mcause_to_write),
        .IDEX_mtval_to_write(IDEX1_mtval_to_write),

        .EXBR_branch(EXBR1_branch),
        .EXBR_memread(EXBR1_memread),
        .EXBR_memwrite(EXBR1_memwrite),
        .EXBR_regwrite(EXBR1_regwrite),
        .EXBR_stop(EXBR1_stop),
        .EXBR_print(EXBR1_print),
        .EXBR_flush_upon_wrong_speculation(EXBR1_flush_upon_wrong_speculation),
        .EXBR_jump(EXBR1_jump),
        .EXBR_reserve(EXBR1_reserve),
        .EXBR_trap(EXBR1_trap),
        .EXBR_CSR_file_write(EXBR1_CSR_file_write),
        .EXBR_write_mcause(EXBR1_write_mcause),

        .EXBR_instruction(EXBR1_instruction),
        .EXBR_pcplusfour(EXBR1_pcplusfour),
        .EXBR_ALU_result(EXBR1_ALU_result),
        .EXBR_data_to_write(EXBR1_data_to_write),
        .EXBR_toreg(EXBR1_toreg),
        .EXBR_printdata(EXBR1_printdata),
        .EXBR_pc(EXBR1_pc),
        .EXBR_branch_control_taken(EXBR1_branch_control_taken),
        .EXBR_speculated_next_pc(EXBR1_speculated_next_pc),
        .EXBR_pcplusimmediate(EXBR1_pcplusimmediate),
        .EXBR_tentative_register_file_data_to_write(EXBR1_tentative_register_file_data_to_write),
        .EXBR_trap_is_return(EXBR1_trap_is_return),
        .EXBR_CSR_value(EXBR1_CSR_value),
        .EXBR_CSR_to_write(EXBR1_CSR_to_write),
        .EXBR_CSR_value_to_write(EXBR1_CSR_value_to_write),
        .EXBR_mcause_to_write(EXBR1_mcause_to_write),
        .EXBR_mtval_to_write(EXBR1_mtval_to_write),

        .forwarding_rs1(forwarding_rs11),
        .forwarding_rs2(forwarding_rs21),
        .hazard_IDEX_memread(hazard_IDEX1_memread),
        .hazard_IDEX_rd(hazard_IDEX1_rd),
        .hazard_EX_multiplying(hazard_EX1_multiplying),
        .CSR_forwarding_CSR_value_to_write_in_EX(CSR_forwarding_CSR_value_to_write_in_EX1)
    );

    BR_unit #(
        .INVALID_DATA_ADDRESS_START(INVALID_DATA_ADDRESS_START)
    ) BR_unit_inst_0 (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_BRMEM_bubble(hazard_BRMEM0_bubble),

        .EXBR_branch(EXBR0_branch),
        .EXBR_memread(EXBR0_memread),
        .EXBR_memwrite(EXBR0_memwrite),
        .EXBR_regwrite(EXBR0_regwrite),
        .EXBR_stop(EXBR0_stop),
        .EXBR_print(EXBR0_print),
        .EXBR_flush_upon_wrong_speculation(EXBR0_flush_upon_wrong_speculation),
        .EXBR_jump(EXBR0_jump),
        .EXBR_trap(EXBR0_trap),
        .EXBR_CSR_file_write(EXBR0_CSR_file_write),
        .EXBR_write_mcause(EXBR0_write_mcause),
        
        .EXBR_instruction(EXBR0_instruction),
        .EXBR_pcplusfour(EXBR0_pcplusfour),
        .EXBR_ALU_result(EXBR0_ALU_result),
        .EXBR_data_to_write(EXBR0_data_to_write),
        .EXBR_toreg(EXBR0_toreg),
        .EXBR_printdata(EXBR0_printdata),
        .EXBR_pc(EXBR0_pc),
        .EXBR_branch_control_taken(EXBR0_branch_control_taken),
        .EXBR_speculated_next_pc(EXBR0_speculated_next_pc),
        .EXBR_pcplusimmediate(EXBR0_pcplusimmediate),
        .EXBR_trap_is_return(EXBR0_trap_is_return),
        .EXBR_CSR_value(EXBR0_CSR_value),
        .EXBR_CSR_to_write(EXBR0_CSR_to_write),
        .EXBR_CSR_value_to_write(EXBR0_CSR_value_to_write),
        .EXBR_mcause_to_write(EXBR0_mcause_to_write),
        .EXBR_mtval_to_write(EXBR0_mtval_to_write),

        .BRMEM_regwrite(BRMEM0_regwrite),
        .BRMEM_stop(BRMEM0_stop),
        .BRMEM_print(BRMEM0_print),

        .BRMEM_instruction(BRMEM0_instruction),
        .BRMEM_pcplusfour(BRMEM0_pcplusfour),
        .BRMEM_ALU_result(BRMEM0_ALU_result),
        .BRMEM_data_to_write(BRMEM0_data_to_write),
        .BRMEM_toreg(BRMEM0_toreg),
        .BRMEM_printdata(BRMEM0_printdata),
        .BRMEM_CSR_value(BRMEM0_CSR_value),

        .next_pc_predictor_write_pc(next_pc_predictor_write_pc0),
        .next_pc_predictor_targetwrite(next_pc_predictor_targetwrite0),
        .next_pc_predictor_takenwrite(next_pc_predictor_takenwrite0),
        .next_pc_predictor_jumpwrite(next_pc_predictor_jumpwrite0),
        .next_pc_predictor_raswrite(next_pc_predictor_raswrite0),
        .next_pc_predictor_taken(next_pc_predictor_taken0),
        .next_pc_predictor_is_jump(next_pc_predictor_is_jump0),
        .next_pc_predictor_is_return(next_pc_predictor_is_return0),
        .next_pc_predictor_target_to_write(next_pc_predictor_target_to_write0),
        .next_pc_predictor_return_address_to_push(next_pc_predictor_return_address_to_push0),

        .next_pc(next_pc_0),
        .hazard_EXBR_wrong_speculation(hazard_EXBR0_wrong_speculation),
        .hazard_EXBR_trap(hazard_EXBR0_trap),

        .CSR_file_write(CSR_file_write0),
        .CSR_file_CSR_to_write(CSR_file_CSR_to_write0),
        .CSR_file_value_to_write(CSR_file_value_to_write0),
        .CSR_file_write_mcause(CSR_file_write_mcause0),
        .CSR_file_mcause_to_write(CSR_file_mcause_to_write0),
        .CSR_file_mtval_to_write(CSR_file_mtval_to_write0),
        .CSR_file_mstatus_trap_shift(CSR_file_mstatus_trap_shift0),
        .CSR_file_mstatus_return_shift(CSR_file_mstatus_return_shift0),

        .forwarding_EXBR_rd(forwarding_EXBR0_rd),
        .forwarding_EXBR_rw(forwarding_EXBR0_rw)
    );

    BR_unit #(
        .INVALID_DATA_ADDRESS_START(INVALID_DATA_ADDRESS_START)
    ) BR_unit_inst_1 (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        .hazard_BRMEM_bubble(hazard_BRMEM1_bubble),

        .EXBR_branch(EXBR1_branch),
        .EXBR_memread(EXBR1_memread),
        .EXBR_memwrite(EXBR1_memwrite),
        .EXBR_regwrite(EXBR1_regwrite),
        .EXBR_stop(EXBR1_stop),
        .EXBR_print(EXBR1_print),
        .EXBR_flush_upon_wrong_speculation(EXBR1_flush_upon_wrong_speculation),
        .EXBR_jump(EXBR1_jump),
        .EXBR_trap(EXBR1_trap),
        .EXBR_CSR_file_write(EXBR1_CSR_file_write),
        .EXBR_write_mcause(EXBR1_write_mcause),
        
        .EXBR_instruction(EXBR1_instruction),
        .EXBR_pcplusfour(EXBR1_pcplusfour),
        .EXBR_ALU_result(EXBR1_ALU_result),
        .EXBR_data_to_write(EXBR1_data_to_write),
        .EXBR_toreg(EXBR1_toreg),
        .EXBR_printdata(EXBR1_printdata),
        .EXBR_pc(EXBR1_pc),
        .EXBR_branch_control_taken(EXBR1_branch_control_taken),
        .EXBR_speculated_next_pc(EXBR1_speculated_next_pc),
        .EXBR_pcplusimmediate(EXBR1_pcplusimmediate),
        .EXBR_trap_is_return(EXBR1_trap_is_return),
        .EXBR_CSR_value(EXBR1_CSR_value),
        .EXBR_CSR_to_write(EXBR1_CSR_to_write),
        .EXBR_CSR_value_to_write(EXBR1_CSR_value_to_write),
        .EXBR_mcause_to_write(EXBR1_mcause_to_write),
        .EXBR_mtval_to_write(EXBR1_mtval_to_write),

        .BRMEM_regwrite(BRMEM1_regwrite),
        .BRMEM_stop(BRMEM1_stop),
        .BRMEM_print(BRMEM1_print),

        .BRMEM_instruction(BRMEM1_instruction),
        .BRMEM_pcplusfour(BRMEM1_pcplusfour),
        .BRMEM_ALU_result(BRMEM1_ALU_result),
        .BRMEM_data_to_write(BRMEM1_data_to_write),
        .BRMEM_toreg(BRMEM1_toreg),
        .BRMEM_printdata(BRMEM1_printdata),
        .BRMEM_CSR_value(BRMEM1_CSR_value),

        .next_pc_predictor_write_pc(next_pc_predictor_write_pc1),
        .next_pc_predictor_targetwrite(next_pc_predictor_targetwrite1),
        .next_pc_predictor_takenwrite(next_pc_predictor_takenwrite1),
        .next_pc_predictor_jumpwrite(next_pc_predictor_jumpwrite1),
        .next_pc_predictor_raswrite(next_pc_predictor_raswrite1),
        .next_pc_predictor_taken(next_pc_predictor_taken1),
        .next_pc_predictor_is_jump(next_pc_predictor_is_jump1),
        .next_pc_predictor_is_return(next_pc_predictor_is_return1),
        .next_pc_predictor_target_to_write(next_pc_predictor_target_to_write1),
        .next_pc_predictor_return_address_to_push(next_pc_predictor_return_address_to_push1),

        .next_pc(next_pc_1),
        .hazard_EXBR_wrong_speculation(hazard_EXBR1_wrong_speculation),
        .hazard_EXBR_trap(hazard_EXBR1_trap),

        .CSR_file_write(CSR_file_write1),
        .CSR_file_CSR_to_write(CSR_file_CSR_to_write1),
        .CSR_file_value_to_write(CSR_file_value_to_write1),
        .CSR_file_write_mcause(CSR_file_write_mcause1),
        .CSR_file_mcause_to_write(CSR_file_mcause_to_write1),
        .CSR_file_mtval_to_write(CSR_file_mtval_to_write1),
        .CSR_file_mstatus_trap_shift(CSR_file_mstatus_trap_shift1),
        .CSR_file_mstatus_return_shift(CSR_file_mstatus_return_shift1),

        .forwarding_EXBR_rd(forwarding_EXBR1_rd),
        .forwarding_EXBR_rw(forwarding_EXBR1_rw)
    );

    next_pc_predictor_writer next_pc_predictor_writer_inst (
        .next_pc_predictor_write_pc0(next_pc_predictor_write_pc0),
        .next_pc_predictor_targetwrite0(next_pc_predictor_targetwrite0),
        .next_pc_predictor_takenwrite0(next_pc_predictor_takenwrite0),
        .next_pc_predictor_jumpwrite0(next_pc_predictor_jumpwrite0),
        .next_pc_predictor_raswrite0(next_pc_predictor_raswrite0),
        .next_pc_predictor_taken0(next_pc_predictor_taken0),
        .next_pc_predictor_is_jump0(next_pc_predictor_is_jump0),
        .next_pc_predictor_is_return0(next_pc_predictor_is_return0),
        .next_pc_predictor_target_to_write0(next_pc_predictor_target_to_write0),
        .next_pc_predictor_return_address_to_push0(next_pc_predictor_return_address_to_push0),

        .next_pc_predictor_write_pc1(next_pc_predictor_write_pc1),
        .next_pc_predictor_targetwrite1(next_pc_predictor_targetwrite1),
        .next_pc_predictor_takenwrite1(next_pc_predictor_takenwrite1),
        .next_pc_predictor_jumpwrite1(next_pc_predictor_jumpwrite1),
        .next_pc_predictor_raswrite1(next_pc_predictor_raswrite1),
        .next_pc_predictor_taken1(next_pc_predictor_taken1),
        .next_pc_predictor_is_jump1(next_pc_predictor_is_jump1),
        .next_pc_predictor_is_return1(next_pc_predictor_is_return1),
        .next_pc_predictor_target_to_write1(next_pc_predictor_target_to_write1),
        .next_pc_predictor_return_address_to_push1(next_pc_predictor_return_address_to_push1),

        .next_pc_predictor_write_pc(next_pc_predictor_write_pc),
        .next_pc_predictor_targetwrite(next_pc_predictor_targetwrite),
        .next_pc_predictor_takenwrite(next_pc_predictor_takenwrite),
        .next_pc_predictor_jumpwrite(next_pc_predictor_jumpwrite),
        .next_pc_predictor_raswrite(next_pc_predictor_raswrite),
        .next_pc_predictor_taken(next_pc_predictor_taken),
        .next_pc_predictor_is_jump(next_pc_predictor_is_jump),
        .next_pc_predictor_is_return(next_pc_predictor_is_return),
        .next_pc_predictor_target_to_write(next_pc_predictor_target_to_write),
        .next_pc_predictor_return_address_to_push(next_pc_predictor_return_address_to_push)
    );

    MEM_unit #(
        .DMEM_SIZE(DMEM_SIZE),
        .MTIME_ADDRESS(MTIME_ADDRESS),
        .MTIMECMP_ADDRESS(MTIMECMP_ADDRESS)
    ) MEM_unit_inst (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),

        .hazard_invalidate_reserve(hazard_invalidate_reserve),

        .EXBR0_memread(EXBR0_memread),
        .EXBR0_memwrite(EXBR0_memwrite),
        .EXBR0_ALU_result(EXBR0_ALU_result),
        .EXBR0_data_to_write(EXBR0_data_to_write),
        .EXBR0_instruction(EXBR0_instruction),
        .EXBR0_reserve(EXBR0_reserve),
        
        .EXBR1_memread(EXBR1_memread),
        .EXBR1_memwrite(EXBR1_memwrite),
        .EXBR1_ALU_result(EXBR1_ALU_result),
        .EXBR1_data_to_write(EXBR1_data_to_write),
        .EXBR1_instruction(EXBR1_instruction),
        .EXBR1_reserve(EXBR1_reserve),
        .hazard_BRMEM1_bubble(hazard_BRMEM1_bubble),

        .BRMEM0_regwrite(BRMEM0_regwrite),
        .BRMEM0_stop(BRMEM0_stop),
        .BRMEM0_print(BRMEM0_print),

        .BRMEM1_regwrite(BRMEM1_regwrite),
        .BRMEM1_stop(BRMEM1_stop),
        .BRMEM1_print(BRMEM1_print),

        .BRMEM0_instruction(BRMEM0_instruction),
        .BRMEM0_pcplusfour(BRMEM0_pcplusfour),
        .BRMEM0_ALU_result(BRMEM0_ALU_result),
        .BRMEM0_data_to_write(BRMEM0_data_to_write),
        .BRMEM0_toreg(BRMEM0_toreg),
        .BRMEM0_printdata(BRMEM0_printdata),
        .BRMEM0_CSR_value(BRMEM0_CSR_value),

        .BRMEM1_instruction(BRMEM1_instruction),
        .BRMEM1_pcplusfour(BRMEM1_pcplusfour),
        .BRMEM1_ALU_result(BRMEM1_ALU_result),
        .BRMEM1_data_to_write(BRMEM1_data_to_write),
        .BRMEM1_toreg(BRMEM1_toreg),
        .BRMEM1_printdata(BRMEM1_printdata),
        .BRMEM1_CSR_value(BRMEM1_CSR_value),

        .MEMWB0_regwrite(MEMWB0_regwrite),
        .MEMWB0_stop(MEMWB0_stop),
        .MEMWB0_print(MEMWB0_print),

        .MEMWB1_regwrite(MEMWB1_regwrite),
        .MEMWB1_stop(MEMWB1_stop),
        .MEMWB1_print(MEMWB1_print),

        .MEMWB0_instruction(MEMWB0_instruction),
        .MEMWB0_pcplusfour(MEMWB0_pcplusfour),
        .MEMWB0_ALU_result(MEMWB0_ALU_result),
        .MEMWB0_toreg(MEMWB0_toreg),
        .MEMWB0_printdata(MEMWB0_printdata),
        .MEMWB0_DMem_readdata(MEMWB0_DMem_readdata),
        .MEMWB0_CSR_value(MEMWB0_CSR_value),

        .MEMWB1_instruction(MEMWB1_instruction),
        .MEMWB1_pcplusfour(MEMWB1_pcplusfour),
        .MEMWB1_ALU_result(MEMWB1_ALU_result),
        .MEMWB1_toreg(MEMWB1_toreg),
        .MEMWB1_printdata(MEMWB1_printdata),
        .MEMWB1_DMem_readdata(MEMWB1_DMem_readdata),
        .MEMWB1_CSR_value(MEMWB1_CSR_value),

        .forwarding_BRMEM0_rd(forwarding_BRMEM0_rd),
        .forwarding_BRMEM0_rw(forwarding_BRMEM0_rw),
        .forwarding_BRMEM1_rd(forwarding_BRMEM1_rd),
        .forwarding_BRMEM1_rw(forwarding_BRMEM1_rw),

        .override_EXBR0_forwarding_for_reserve(override_EXBR0_forwarding_for_reserve),
        .override_EXBR1_forwarding_for_reserve(override_EXBR1_forwarding_for_reserve),
        .EXBR0_reserve_result(EXBR0_reserve_result),
        .EXBR1_reserve_result(EXBR1_reserve_result),

        .BRMEM0_register_file_data_to_write(BRMEM0_register_file_data_to_write),
        .BRMEM1_register_file_data_to_write(BRMEM1_register_file_data_to_write),

        .timer_mtip(timer_mtip)
    );

    WB_unit #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .BUFFER_SIZE(BUFFER_SIZE),
        .MAX_BITS_TO_SEND(MAX_BITS_TO_SEND),
        .REGISTER_COUNT(REGISTER_COUNT)
    ) WB_unit_inst (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),

        .MEMWB0_regwrite(MEMWB0_regwrite),
        .MEMWB0_print(MEMWB0_print),

        .MEMWB1_regwrite(MEMWB1_regwrite),
        .MEMWB1_print(MEMWB1_print),

        .MEMWB0_instruction(MEMWB0_instruction),
        .MEMWB0_pcplusfour(MEMWB0_pcplusfour),
        .MEMWB0_ALU_result(MEMWB0_ALU_result),
        .MEMWB0_toreg(MEMWB0_toreg),
        .MEMWB0_printdata(MEMWB0_printdata),
        .MEMWB0_DMem_readdata(MEMWB0_DMem_readdata),
        .MEMWB0_CSR_value(MEMWB0_CSR_value),

        .MEMWB1_instruction(MEMWB1_instruction),
        .MEMWB1_pcplusfour(MEMWB1_pcplusfour),
        .MEMWB1_ALU_result(MEMWB1_ALU_result),
        .MEMWB1_toreg(MEMWB1_toreg),
        .MEMWB1_printdata(MEMWB1_printdata),
        .MEMWB1_DMem_readdata(MEMWB1_DMem_readdata),
        .MEMWB1_CSR_value(MEMWB1_CSR_value),
        
        .uart_output(uart_output),

        .register_file_write_enable0(register_file_write_enable0),
        .register_file_register_to_write0(register_file_register_to_write0),
        .register_file_data_to_write0(register_file_data_to_write0),

        .register_file_write_enable1(register_file_write_enable1),
        .register_file_register_to_write1(register_file_register_to_write1),
        .register_file_data_to_write1(register_file_data_to_write1),

        .forwarding_MEMWB0_rd(forwarding_MEMWB0_rd),
        .forwarding_MEMWB0_rw(forwarding_MEMWB0_rw),
        .forwarding_MEMWB1_rd(forwarding_MEMWB1_rd),
        .forwarding_MEMWB1_rw(forwarding_MEMWB1_rw)
    );

    always @(posedge clk) begin
        if (reset) begin
            CPU_state <= IDLE;
        end
        else if (CPU_state == IDLE) begin
            if (start_execution) begin
                CPU_state <= EXECUTING;
                pc <= PROGRAM_START_ADDRESS;
            end

            stat_valid_instruction_count <= 0;
            stat_total_cycle_count <= 0;
            stat_branch_count <= 0;
            stat_misprediction_count <= 0;
        end
        else begin
            stat_total_cycle_count <= stat_total_cycle_count + 1;

            // Updating pc
            if (hazard_pcwrite == 1) pc <= next_pc_0;
            else if (hazard_pcwrite == 2) pc <= next_pc_1;
            else if (hazard_pcwrite == 3) begin
                if (hazard_IFID_separate) pc <= next_pc_predictor_predicted_target0;
                else pc <= pc;
            end
            else begin
                if (next_pc_predictor_predicted_target0 != pc + 4) pc <= next_pc_predictor_predicted_target0;
                else pc <= next_pc_predictor_predicted_target1;
            end

            if (EXBR0_flush_upon_wrong_speculation && EXBR1_flush_upon_wrong_speculation && ~hazard_BRMEM1_bubble) stat_valid_instruction_count <= stat_valid_instruction_count + 2;
            else if (EXBR0_flush_upon_wrong_speculation || EXBR1_flush_upon_wrong_speculation) stat_valid_instruction_count <= stat_valid_instruction_count + 1;

            if (EXBR0_branch || EXBR0_jump == 2 || EXBR0_jump == 3 
                || (EXBR0_flush_upon_wrong_speculation && EXBR0_instruction[6:0] == 7'b1110011)) begin
                    stat_branch_count <= stat_branch_count + 1;
                    //$display("branch at %d", EXBR0_pc);
            end
            if ((EXBR1_branch || EXBR1_jump == 2 || EXBR1_jump == 3
                || (EXBR1_flush_upon_wrong_speculation && EXBR1_instruction[6:0] == 7'b1110011))
                && ~hazard_BRMEM1_bubble) begin
                    stat_branch_count <= stat_branch_count + 1;
                    //$display("branch at %d", EXBR1_pc);
            end
            if ((EXBR0_branch || EXBR0_jump == 2 || EXBR0_jump == 3 
                || (EXBR0_flush_upon_wrong_speculation && EXBR0_instruction[6:0] == 7'b1110011))
                &&
                ((EXBR1_branch || EXBR1_jump == 2 || EXBR1_jump == 3
                || (EXBR1_flush_upon_wrong_speculation && EXBR1_instruction[6:0] == 7'b1110011))
                && ~hazard_BRMEM1_bubble)) stat_branch_count <= stat_branch_count + 2;

            if (hazard_EXBR0_wrong_speculation || hazard_EXBR1_wrong_speculation) stat_misprediction_count <= stat_misprediction_count + 1;

            if (MEMWB0_stop || MEMWB1_stop) begin
                CPU_state <= IDLE;
                $display("%d cycles for %d valid instructions. IPC: %f", stat_total_cycle_count, stat_valid_instruction_count, $itor(stat_valid_instruction_count) / $itor(stat_total_cycle_count));
                $display("%d mispredictions for %d branches. Misprediction rate: %f%%", stat_misprediction_count, stat_branch_count, 100 * $itor(stat_misprediction_count) / $itor(stat_branch_count));
            end

            /*
            if (hazard_EXBR0_wrong_speculation) begin
                $display("Wrong speculation at %d. Predicted %d, actual %d. Instruction: %h.", EXBR0_pc, EXBR0_speculated_next_pc, next_pc_0, EXBR0_instruction);
            end
            else if (hazard_EXBR1_wrong_speculation) begin
                $display("Wrong speculation at %d. Predicted %d, actual %d. Instruction: %h.", EXBR1_pc, EXBR1_speculated_next_pc, next_pc_1, EXBR1_instruction);
            end
            */

            //$display("Current cycle: %d", stat_total_cycle_count);
            //$display("next_pc_predictor_read_pc: %d, %d", next_pc_predictor_read_pc0, next_pc_predictor_read_pc1);
            //$display("next_pc_predictor_predicted_target: %d, %d", next_pc_predictor_predicted_target0, next_pc_predictor_predicted_target1);
            //$display("PC: %d", pc);
            //$display("IFID_speculated_next_pc: %d, %d", IFID0_speculated_next_pc, IFID1_speculated_next_pc);
            //$display("IDEX_speculated_next_pc: %d, %d", IDEX0_speculated_next_pc, IDEX1_speculated_next_pc);
            //$display("IDEX_readdata1: %d, %d", IDEX0_readdata1, IDEX1_readdata1);
            //$display("ForwardA: %d, %d", forwarding_forwardA0, forwarding_forwardA1);
            //$display("EXBR_flush_upon_wrong_speculation: %d, %d", EXBR0_flush_upon_wrong_speculation, EXBR1_flush_upon_wrong_speculation);
            //$display("EXBR_jump: %d, %d", EXBR0_jump, EXBR1_jump);
            //$display("EXBR_speculated_next_pc: %d, %d", EXBR0_speculated_next_pc, EXBR1_speculated_next_pc);
            //$display("EXBR_actual_next_pc: %d, %d", next_pc_0, next_pc_1);
            //$display("EXBR_ALU_result: %d, %d", EXBR0_ALU_result, EXBR1_ALU_result);
            //$display("EXBR_data_to_write: %d, %d", EXBR0_data_to_write, EXBR1_data_to_write);
            //$display("MEMWB_regwrite: %d, %d", MEMWB0_regwrite, MEMWB1_regwrite);
            //$display("EXBR_pc: %d, %d", EXBR0_pc, EXBR1_pc);

            //if (EXBR0_flush_upon_wrong_speculation) $display("Instruction in cycle %d: %h", stat_total_cycle_count, EXBR0_instruction);
            //if (EXBR1_flush_upon_wrong_speculation) $display("Instruction in cycle %d: %h", stat_total_cycle_count, EXBR1_instruction);

            /*
            $display("PC: %d", pc);
            $display("IFID_instruction: %h, %h", IFID0_instruction, IFID1_instruction);
            $display("IDEX_instruction: %h, %h", IDEX0_instruction, IDEX1_instruction);
            $display("EXBR_instruction: %h, %h", EXBR0_instruction, EXBR1_instruction);
            $display("BRMEM_instruction: %h, %h", BRMEM0_instruction, BRMEM1_instruction);
            $display("MEMWB_instruction: %h, %h", MEMWB0_instruction, MEMWB1_instruction);

            $display("");
            */
        end
    end

    // Set next_pc_predictor_read_pc
    always @(*) begin
        if (hazard_pcwrite == 1) next_pc_predictor_read_pc0 = next_pc_0;
        else if (hazard_pcwrite == 2) next_pc_predictor_read_pc0 = next_pc_1;
        else if (hazard_pcwrite == 3) begin
            if (hazard_IFID_separate) next_pc_predictor_read_pc0 = next_pc_predictor_predicted_target0;
            else next_pc_predictor_read_pc0 = pc;
        end
        else begin
            if (next_pc_predictor_predicted_target0 != pc + 4) next_pc_predictor_read_pc0 = next_pc_predictor_predicted_target0;
            else next_pc_predictor_read_pc0 = next_pc_predictor_predicted_target1;
        end 

        if (CPU_state == IDLE) next_pc_predictor_read_pc0 = PROGRAM_START_ADDRESS;

        if (hazard_pcwrite == 1) next_pc_predictor_read_pc1 = next_pc_0 + 4;
        else if (hazard_pcwrite == 2) next_pc_predictor_read_pc1 = next_pc_1 + 4;
        else if (hazard_pcwrite == 3) begin
            if (hazard_IFID_separate) next_pc_predictor_read_pc1 = next_pc_predictor_predicted_target0 + 4;
            else next_pc_predictor_read_pc1 = pc + 4;
        end
        else begin
            if (next_pc_predictor_predicted_target0 != pc + 4) next_pc_predictor_read_pc1 = next_pc_predictor_predicted_target0 + 4;
            else next_pc_predictor_read_pc1 = next_pc_predictor_predicted_target1 + 4;
        end 

        if (CPU_state == IDLE) next_pc_predictor_read_pc1 = PROGRAM_START_ADDRESS + 4;
    end

    assign next_pc_predictor_predicted_jump_used = (hazard_pcwrite == 0) && (next_pc_predictor_predicted_jump0 || (~next_pc_predictor_predicted_return0 && next_pc_predictor_predicted_jump1));
    assign next_pc_predictor_predicted_return_used = (hazard_pcwrite == 0) && (next_pc_predictor_predicted_return0 || (~next_pc_predictor_predicted_jump0 && next_pc_predictor_predicted_return1));
    assign next_pc_predictor_return_address_to_push_from_predictor = (next_pc_predictor_predicted_jump0) ? next_pc_predictor_return_address_to_push_from_predictor_candidate0 : next_pc_predictor_return_address_to_push_from_predictor_candidate1;

endmodule