`timescale 1ns / 1ps

module ID_unit_main # (
    parameter PRINT_OPCODE = 7'b0101011,
    parameter START_EXECUTION_OPCODE = 7'b0001011,
    parameter REGISTER_COUNT = 32
) (
    input clk,
    input reset,
    input CPU_state,
    input hazard_IDEX_bubble,

    // input from CSR_file_unit
    input [31:0] CSR_file_mtvec,
    input [31:0] CSR_file_mstatus,
    input [31:0] CSR_file_mepc,
    input [31:0] CSR_file_mcause,
    input [31:0] CSR_file_mscratch,
    input [31:0] CSR_file_mtval,
    input [31:0] CSR_file_mie,
    input [31:0] CSR_file_mip,

    // input for CSR_forwarding
    input CSR_forwarding_forward_EX0_to_ID, CSR_forwarding_forward_EX1_to_ID,
    input [31:0] CSR_forwarding_CSR_value_to_write_in_EX0, CSR_forwarding_CSR_value_to_write_in_EX1,

    // IFID
    input [31:0] IFID_pc,
    input [31:0] IFID_instruction,
    input IFID_flush_upon_wrong_speculation,
    input [31:0] IFID_speculated_next_pc,
    input IFID_instruction_access_fault, IFID_instruction_misaligned,

    // IDEX - actions
    output reg IDEX_branch, IDEX_memread, IDEX_memwrite, IDEX_regwrite, IDEX_stop, IDEX_print, IDEX_flush_upon_wrong_speculation, IDEX_multiply,
    output reg [1:0] IDEX_jump,
    output reg IDEX_reserve,
    output reg IDEX_trap,
    output reg IDEX_CSR_file_write,
    output reg IDEX_write_mcause,

    // IDEX - infos
    output reg [31:0] IDEX_instruction, IDEX_pc, IDEX_immediate_value,
    output reg IDEX_immediate,
    output reg [1:0] IDEX_alusrc1, IDEX_toreg,
    output reg [31:0] IDEX_speculated_next_pc,
    output reg [3:0] IDEX_ALU_operation,
    output reg IDEX_forward_for_rd,
    output reg IDEX_use_ALU_result_from_prev_inst,
    output reg IDEX_trap_is_return,
    output reg [2:0] IDEX_CSR_to_write,
    output reg [31:0] IDEX_CSR_value,
    output reg [31:0] IDEX_mcause_to_write, IDEX_mtval_to_write,

    // wires
    output [4:0] hazard_rs1, hazard_rs2, hazard_rd,
    output hazard_rw,
    output hazard_memuse,
    output hazard_print,
    output hazard_decoding_multiply,
    output hazard_decoding_atomic,
    output hazard_CSR_file_write_in_main_ID,
    output [2:0] hazard_CSR_to_write_in_main_ID,
    output [$clog2(REGISTER_COUNT) - 1 : 0] register_file_register_to_read1, register_file_register_to_read2,
    output [2:0] CSR_forwarding_ID_CSR_value_select
);

    localparam MTVEC = 3'b000,
               MSTATUS = 3'b001,
               MEPC = 3'b010,
               MCAUSE = 3'b011,
               MSCRATCH = 3'b100,
               MTVAL = 3'b101,
               MIE = 3'b110,
               MIP = 3'b111;

    // Signals for ImmediateGenerator
    wire [31:0] ImmediateGenerator_instruction;
    wire [31:0] ImmediateGenerator_immediate_value;

    // Signals for control
    wire [6:0] control_opcode;
    wire [4:0] control_funct5;
    wire [2:0] control_funct3;
    wire [11:0] control_funct12;
    wire control_instruction_access_fault, control_instruction_misaligned;
    wire control_mie, control_mtip, control_mtie;
    wire control_valid_instruction;
    // outputs
    wire control_add, control_immediate, control_branch, control_memread, control_memwrite, control_regwrite, control_print;
    wire [1:0] control_alusrc1, control_jump, control_toreg;
    wire control_reserve, control_atomic;
    wire control_trap;
    wire control_trap_is_return;
    wire control_CSR_file_write;
    wire [2:0] control_CSR_to_write;
    wire [2:0] control_CSR_value_select;
    wire control_write_mcause;
    wire [31:0] control_mcause_to_write;

    // Signals for ALU control
    wire ALU_control_add, ALU_control_immediate;
    wire [2:0] ALU_control_funct3;
    wire [6:0] ALU_control_funct7;
    wire [3:0] ALU_control_operation;

    // Signals for atomic decode
    reg [1:0] atomic_decode_phase;

    ImmediateGenerator ImmediateGenerator_inst (
        .instruction(ImmediateGenerator_instruction),
        .immediate_value(ImmediateGenerator_immediate_value)
    );

    control #(
        .PRINT_OPCODE(PRINT_OPCODE)
    ) control_inst (
        .opcode(control_opcode),
        .funct5(control_funct5),
        .funct3(control_funct3),
        .funct12(control_funct12),
        .instruction_access_fault(control_instruction_access_fault),
        .instruction_misaligned(control_instruction_misaligned),
        .mie(control_mie),
        .mtip(control_mtip),
        .mtie(control_mtie),
        .atomic_decode_phase(atomic_decode_phase),
        .valid_instruction(control_valid_instruction),

        .add(control_add),
        .immediate(control_immediate),
        .alusrc1(control_alusrc1),
        .branch(control_branch),
        .jump(control_jump),
        .memread(control_memread),
        .memwrite(control_memwrite),
        .toreg(control_toreg),
        .regwrite(control_regwrite),
        .reserve(control_reserve),
        .atomic(control_atomic),
        .trap(control_trap),
        .trap_is_return(control_trap_is_return),
        .CSR_file_write(control_CSR_file_write),
        .CSR_to_write(control_CSR_to_write),
        .CSR_value_select(control_CSR_value_select),
        .write_mcause(control_write_mcause),
        .mcause_to_write(control_mcause_to_write),
        .print(control_print)
    );

    ALU_control ALU_control_inst (
        .add(ALU_control_add),
        .immediate(ALU_control_immediate),
        .atomic(control_atomic),
        .funct3(ALU_control_funct3),
        .funct7(ALU_control_funct7),

        .operation(ALU_control_operation)
    );

    assign control_opcode = IFID_instruction[6:0];
    assign control_funct5 = IFID_instruction[31:27];
    assign control_funct3 = IFID_instruction[14:12];
    assign control_funct12 = IFID_instruction[31:20];
    assign control_instruction_access_fault = IFID_instruction_access_fault;
    assign control_instruction_misaligned = IFID_instruction_misaligned;
    assign control_mie = CSR_file_mstatus[3];
    assign control_mtip = CSR_file_mip[7];
    assign control_mtie = CSR_file_mie[7];
    assign control_valid_instruction = IFID_flush_upon_wrong_speculation;

    assign ImmediateGenerator_instruction = IFID_instruction;
    assign register_file_register_to_read1 = IFID_instruction[19:15];
    assign register_file_register_to_read2 = IFID_instruction[24:20];
    assign hazard_rs1 = IFID_instruction[19:15];
    assign hazard_rs2 = IFID_instruction[24:20];
    assign hazard_rd = IFID_instruction[11:7];
    assign hazard_rw = control_regwrite;
    assign hazard_memuse = control_memread || control_memwrite || (atomic_decode_phase == 3);
    assign hazard_print = control_print;
    assign hazard_decoding_multiply = (IFID_instruction[6:0] == 7'b0110011 && IFID_instruction[31:25] == 1);
    assign hazard_decoding_atomic = control_atomic && IFID_flush_upon_wrong_speculation && (atomic_decode_phase != 3);
    assign hazard_CSR_file_write_in_main_ID = control_CSR_file_write;
    assign hazard_CSR_to_write_in_main_ID = control_CSR_to_write; 

    assign CSR_forwarding_ID_CSR_value_select = control_CSR_value_select;

    assign ALU_control_add = control_add;
    assign ALU_control_immediate = control_immediate;
    assign ALU_control_funct3 = IFID_instruction[14:12];
    assign ALU_control_funct7 = IFID_instruction[31:25];

    always @(posedge clk) begin
        if (reset || CPU_state == 0 || hazard_IDEX_bubble) begin
            IDEX_branch <= 0;
            IDEX_jump <= 0;
            IDEX_memread <= 0;
            IDEX_memwrite <= 0;
            IDEX_regwrite <= 0;
            IDEX_stop <= 0;
            IDEX_print <= 0;
            IDEX_flush_upon_wrong_speculation <= 0;
            IDEX_multiply <= 0;
            IDEX_reserve <= 0;
            IDEX_trap <= 0;
            IDEX_CSR_file_write <= 0;
            IDEX_write_mcause <= 0;

            atomic_decode_phase <= 0;
        end
        else begin
            IDEX_pc <= IFID_pc;
            IDEX_instruction <= IFID_instruction;
            IDEX_immediate_value <= ImmediateGenerator_immediate_value;
            IDEX_immediate <= control_immediate;
            IDEX_alusrc1 <= control_alusrc1;
            IDEX_branch <= control_branch;
            IDEX_jump <= control_jump;
            IDEX_memread <= control_memread;
            IDEX_memwrite <= control_memwrite;
            IDEX_toreg <= control_toreg;
            IDEX_regwrite <= control_regwrite;
            IDEX_stop <= (IFID_instruction[6:0] == START_EXECUTION_OPCODE);
            IDEX_print <= control_print;
            IDEX_flush_upon_wrong_speculation <= IFID_flush_upon_wrong_speculation;
            IDEX_speculated_next_pc <= IFID_speculated_next_pc;
            IDEX_ALU_operation <= ALU_control_operation;
            IDEX_multiply <= (IFID_instruction[6:0] == 7'b0110011 && IFID_instruction[31:25] == 1);
            IDEX_reserve <= control_reserve;
            IDEX_forward_for_rd <= 0;
            IDEX_use_ALU_result_from_prev_inst <= 0;
            IDEX_trap <= control_trap;
            IDEX_trap_is_return <= control_trap_is_return;
            IDEX_CSR_file_write <= control_CSR_file_write;
            IDEX_CSR_to_write <= control_CSR_to_write;
            IDEX_write_mcause <= control_write_mcause;
            IDEX_mcause_to_write <= control_mcause_to_write;
            IDEX_mtval_to_write <= (control_mcause_to_write == 2) ? IFID_instruction : IFID_pc;

            case (control_CSR_value_select)
                MTVEC: IDEX_CSR_value <= CSR_file_mtvec;
                MSTATUS: IDEX_CSR_value <= CSR_file_mstatus;
                MEPC: IDEX_CSR_value <= CSR_file_mepc;
                MCAUSE: IDEX_CSR_value <= CSR_file_mcause;
                MSCRATCH: IDEX_CSR_value <= CSR_file_mscratch;
                MTVAL: IDEX_CSR_value <= CSR_file_mtval;
                MIE: IDEX_CSR_value <= CSR_file_mie;
                MIP: IDEX_CSR_value <= CSR_file_mip;
                default: IDEX_CSR_value <= 0;
            endcase

            if (CSR_forwarding_forward_EX0_to_ID) IDEX_CSR_value <= CSR_forwarding_CSR_value_to_write_in_EX0;
            if (CSR_forwarding_forward_EX1_to_ID) IDEX_CSR_value <= CSR_forwarding_CSR_value_to_write_in_EX1;

            if (control_atomic && IFID_flush_upon_wrong_speculation) case (atomic_decode_phase)
            0: begin
                atomic_decode_phase <= 1;
                IDEX_immediate <= 1;
                IDEX_memread <= 1;
                IDEX_toreg <= 1;
                IDEX_regwrite <= 1;
                IDEX_flush_upon_wrong_speculation <= 0;
                IDEX_ALU_operation <= 4'b0010;
            end
            1: begin
                atomic_decode_phase <= 2;
                IDEX_flush_upon_wrong_speculation <= 0;
            end
            2: begin
                atomic_decode_phase <= 3;
                IDEX_forward_for_rd <= 1;
                IDEX_flush_upon_wrong_speculation <= 0;
            end
            3: begin
                atomic_decode_phase <= 0;
                IDEX_immediate <= 1;
                IDEX_memwrite <= 1;
                IDEX_ALU_operation <= 4'b0010;
                IDEX_use_ALU_result_from_prev_inst <= 1;
            end
        endcase
        end
    end

endmodule