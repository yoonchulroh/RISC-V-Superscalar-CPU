`timescale 1ns / 1ps

module MEM_unit # (
    parameter DMEM_SIZE = 200,
    parameter MTIME_ADDRESS = 200,
    parameter MTIMECMP_ADDRESS = 204
) (
    input clk,
    input reset,
    input CPU_state,

    input hazard_invalidate_reserve,

    // EXBR - for DMem
    input EXBR0_memread, EXBR0_memwrite,
    input [31:0] EXBR0_ALU_result, EXBR0_data_to_write, EXBR0_instruction,
    input EXBR0_reserve,

    input EXBR1_memread, EXBR1_memwrite,
    input [31:0] EXBR1_ALU_result, EXBR1_data_to_write, EXBR1_instruction,
    input EXBR1_reserve,
    input hazard_BRMEM1_bubble,

    // BRMEM - actions
    input BRMEM0_regwrite, BRMEM0_stop, BRMEM0_print,

    input BRMEM1_regwrite, BRMEM1_stop, BRMEM1_print,

    // BRMEM - infos
    input [31:0] BRMEM0_instruction, BRMEM0_pcplusfour, BRMEM0_ALU_result, BRMEM0_data_to_write,
    input [1:0] BRMEM0_toreg,
    input [31:0] BRMEM0_printdata,
    input [31:0] BRMEM0_CSR_value,

    input [31:0] BRMEM1_instruction, BRMEM1_pcplusfour, BRMEM1_ALU_result, BRMEM1_data_to_write,
    input [1:0] BRMEM1_toreg,
    input [31:0] BRMEM1_printdata,
    input [31:0] BRMEM1_CSR_value,

    // MEMWB - actions
    output reg MEMWB0_regwrite, MEMWB0_stop, MEMWB0_print,

    output reg MEMWB1_regwrite, MEMWB1_stop, MEMWB1_print,

    // MEMWB - infos
    output reg [31:0] MEMWB0_instruction, MEMWB0_pcplusfour, MEMWB0_ALU_result,
    output reg [1:0] MEMWB0_toreg,
    output reg [31:0] MEMWB0_printdata,
    output reg [31:0] MEMWB0_DMem_readdata,
    output reg [31:0] MEMWB0_CSR_value,

    output reg [31:0] MEMWB1_instruction, MEMWB1_pcplusfour, MEMWB1_ALU_result,
    output reg [1:0] MEMWB1_toreg,
    output reg [31:0] MEMWB1_printdata,
    output reg [31:0] MEMWB1_DMem_readdata,
    output reg [31:0] MEMWB1_CSR_value,

    // wires to forwarding
    output [4:0] forwarding_BRMEM0_rd,
    output forwarding_BRMEM0_rw,
    output [4:0] forwarding_BRMEM1_rd,
    output forwarding_BRMEM1_rw,
    output override_EXBR0_forwarding_for_reserve, override_EXBR1_forwarding_for_reserve,
    output EXBR0_reserve_result, EXBR1_reserve_result,

    output reg [31:0] BRMEM0_register_file_data_to_write, BRMEM1_register_file_data_to_write,

    output timer_mtip
);

    // Signals for DMem
    wire [31:0] DMem_address, DMem_data_to_write;
    wire DMem_memread, DMem_memwrite;
    wire [1:0] DMem_maskmode;
    wire DMem_sext;
    wire [31:0] DMem_readdata;

    // Regs for reserves
    reg reservation_valid;
    reg [31:0] reservation_address;
    reg BRMEM0_store_reserve_result, BRMEM1_store_reserve_result;
    reg BRMEM0_reserve_result, BRMEM1_reserve_result;

    // Signals for timer
    wire timer_write_mtime, timer_write_mtimecmp;
    wire [31:0] timer_time_value_to_write;
    // outputs
    wire [31:0] timer_mtime, timer_mtimecmp;

    DMem #(
        .DMEM_SIZE(DMEM_SIZE)
    ) DMem_inst (
        .clk(clk),
        .reset(reset),
        .address(DMem_address),
        .data_to_write(DMem_data_to_write),
        .memread(DMem_memread),
        .memwrite(DMem_memwrite),
        .maskmode(DMem_maskmode),
        .sext(DMem_sext),

        .readdata(DMem_readdata)
    );

    timer timer_inst (
        .clk(clk),
        .reset(reset),
        .CPU_state(CPU_state),
        
        .write_mtime(timer_write_mtime),
        .write_mtimecmp(timer_write_mtimecmp),
        .time_value_to_write(timer_time_value_to_write),

        .mtime(timer_mtime),
        .mtimecmp(timer_mtimecmp),
        .mtip(timer_mtip)
    );

    always @(posedge clk) begin
        if (reset || CPU_state == 0) begin
            MEMWB0_regwrite <= 0;
            MEMWB0_stop <= 0;
            MEMWB0_print <= 0;

            MEMWB1_regwrite <= 0;
            MEMWB1_stop <= 0;
            MEMWB1_print <= 0;

            reservation_valid <= 0;

            BRMEM0_store_reserve_result <= 0;
            BRMEM1_store_reserve_result <= 0;
        end
        else begin
            MEMWB0_pcplusfour <= BRMEM0_pcplusfour;
            MEMWB0_instruction <= BRMEM0_instruction;
            MEMWB0_ALU_result <= BRMEM0_ALU_result;
            MEMWB0_toreg <= BRMEM0_toreg;
            MEMWB0_regwrite <= BRMEM0_regwrite;
            MEMWB0_stop <= BRMEM0_stop;
            MEMWB0_print <= BRMEM0_print;
            MEMWB0_printdata <= BRMEM0_printdata;
            MEMWB0_DMem_readdata <= DMem_readdata;
            if (BRMEM0_store_reserve_result == 1) MEMWB0_DMem_readdata <= BRMEM0_reserve_result;
            if (BRMEM0_ALU_result == MTIME_ADDRESS) MEMWB0_DMem_readdata <= timer_mtime;
            if (BRMEM0_ALU_result == MTIMECMP_ADDRESS) MEMWB0_DMem_readdata <= timer_mtimecmp;
            MEMWB0_CSR_value <= BRMEM0_CSR_value;

            MEMWB1_pcplusfour <= BRMEM1_pcplusfour;
            MEMWB1_instruction <= BRMEM1_instruction;
            MEMWB1_ALU_result <= BRMEM1_ALU_result;
            MEMWB1_toreg <= BRMEM1_toreg;
            MEMWB1_regwrite <= BRMEM1_regwrite;
            MEMWB1_stop <= BRMEM1_stop;
            MEMWB1_print <= BRMEM1_print;
            MEMWB1_printdata <= BRMEM1_printdata;
            MEMWB1_DMem_readdata <= DMem_readdata;
            if (BRMEM1_store_reserve_result == 1) MEMWB1_DMem_readdata <= BRMEM1_reserve_result;
            if (BRMEM1_ALU_result == MTIME_ADDRESS) MEMWB1_DMem_readdata <= timer_mtime;
            if (BRMEM1_ALU_result == MTIMECMP_ADDRESS) MEMWB1_DMem_readdata <= timer_mtimecmp;
            MEMWB1_CSR_value <= BRMEM1_CSR_value;

            BRMEM0_store_reserve_result <= 0;
            BRMEM1_store_reserve_result <= 0;
            if (EXBR0_reserve == 1 && EXBR0_memread == 1) begin
                reservation_valid <= 1;
                reservation_address <= EXBR0_ALU_result;
            end
            if (hazard_BRMEM1_bubble == 0 && EXBR1_reserve == 1 && EXBR1_memread == 1) begin
                reservation_valid <= 1;
                reservation_address <= EXBR1_ALU_result;
            end
            if (EXBR0_reserve == 1 && EXBR0_memwrite == 1) begin
                BRMEM0_store_reserve_result <= 1;
                BRMEM0_reserve_result <= (reservation_valid == 1 && reservation_address == EXBR0_ALU_result) ? 0 : 1;
            end
            if (hazard_BRMEM1_bubble == 0 && EXBR1_reserve == 1 && EXBR1_memwrite == 1) begin
                BRMEM1_store_reserve_result <= 1;
                BRMEM1_reserve_result <= (reservation_valid == 1 && reservation_address == EXBR1_ALU_result) ? 0 : 1;
            end

            if (EXBR0_memwrite == 1) reservation_valid <= 0;
            if (hazard_BRMEM1_bubble == 0 && EXBR1_memwrite == 1) reservation_valid <= 0;
            if (hazard_invalidate_reserve) reservation_valid <= 0;
        end
    end

    always @(*) begin
        BRMEM0_register_file_data_to_write = (BRMEM0_toreg[0] == 1) ? ((BRMEM0_toreg[1] == 1) ? BRMEM0_CSR_value : ((BRMEM0_store_reserve_result == 1) ? BRMEM0_reserve_result : DMem_readdata))
                                                                    : ((BRMEM0_toreg[1] == 1) ? BRMEM0_pcplusfour : BRMEM0_ALU_result);
        if (BRMEM0_toreg == 2'b01 && BRMEM0_ALU_result == MTIME_ADDRESS) BRMEM0_register_file_data_to_write = timer_mtime;
        if (BRMEM0_toreg == 2'b01 && BRMEM0_ALU_result == MTIMECMP_ADDRESS) BRMEM0_register_file_data_to_write = timer_mtimecmp;

        BRMEM1_register_file_data_to_write = (BRMEM1_toreg[0] == 1) ? ((BRMEM1_toreg[1] == 1) ? BRMEM1_CSR_value : ((BRMEM1_store_reserve_result == 1) ? BRMEM1_reserve_result : DMem_readdata))
                                                                    : ((BRMEM1_toreg[1] == 1) ? BRMEM1_pcplusfour : BRMEM1_ALU_result);
        if (BRMEM1_toreg == 2'b01 && BRMEM1_ALU_result == MTIME_ADDRESS) BRMEM1_register_file_data_to_write = timer_mtime;
        if (BRMEM1_toreg == 2'b01 && BRMEM1_ALU_result == MTIMECMP_ADDRESS) BRMEM1_register_file_data_to_write = timer_mtimecmp;
    end

    assign forwarding_BRMEM0_rd = BRMEM0_instruction[11:7];
    assign forwarding_BRMEM0_rw = BRMEM0_regwrite;

    assign forwarding_BRMEM1_rd = BRMEM1_instruction[11:7];
    assign forwarding_BRMEM1_rw = BRMEM1_regwrite;

    assign DMem_memread = (EXBR0_memread || (~hazard_BRMEM1_bubble && EXBR1_memread));
    assign DMem_memwrite = ((EXBR0_memwrite && (EXBR0_reserve == 0 || (reservation_valid == 1 && reservation_address == EXBR0_ALU_result))) || (~hazard_BRMEM1_bubble && EXBR1_memwrite && (EXBR1_reserve == 0 || (reservation_valid == 1 && reservation_address == EXBR1_ALU_result))));
    assign DMem_address = (EXBR0_memread || EXBR0_memwrite) ? EXBR0_ALU_result : EXBR1_ALU_result;
    assign DMem_data_to_write = (EXBR0_memwrite) ? EXBR0_data_to_write : EXBR1_data_to_write;
    assign DMem_maskmode = (EXBR0_memread || EXBR0_memwrite) ? EXBR0_instruction[13:12] : EXBR1_instruction[13:12];
    assign DMem_sext = (EXBR0_memread || EXBR0_memwrite) ? ~EXBR0_instruction[14] : ~EXBR1_instruction[14];

    assign override_EXBR0_forwarding_for_reserve = (EXBR0_reserve == 1 && EXBR0_memwrite == 1);
    assign EXBR0_reserve_result = (reservation_valid == 1 && reservation_address == EXBR0_ALU_result) ? 0 : 1;
    assign override_EXBR1_forwarding_for_reserve = (hazard_BRMEM1_bubble == 0 && EXBR1_reserve == 1 && EXBR1_memwrite == 1);
    assign EXBR1_reserve_result = (reservation_valid == 1 && reservation_address == EXBR1_ALU_result) ? 0 : 1;

    assign timer_write_mtime = (EXBR0_memwrite && (EXBR0_ALU_result == MTIME_ADDRESS))
                               || (~hazard_BRMEM1_bubble && EXBR1_memwrite && (EXBR1_ALU_result == MTIME_ADDRESS));
    assign timer_write_mtimecmp = (EXBR0_memwrite && (EXBR0_ALU_result == MTIMECMP_ADDRESS))
                                  || (~hazard_BRMEM1_bubble && EXBR1_memwrite && (EXBR1_ALU_result == MTIMECMP_ADDRESS));
    assign timer_time_value_to_write = (EXBR0_memwrite) ? EXBR0_data_to_write : EXBR1_data_to_write;

endmodule