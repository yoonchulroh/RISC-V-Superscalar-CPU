`timescale 1ns / 1ps

module CSR_file (
    input clk,
    input reset,
    input CPU_state,

    input timer_mtip,

    input write0,
    input [2:0] CSR_to_write0,
    input [31:0] value_to_write0,

    input write1,
    input [2:0] CSR_to_write1,
    input [31:0] value_to_write1,

    input write_mcause0,
    input [31:0] mcause_to_write0,
    input [31:0] mtval_to_write0,
    input write_mcause1,
    input [31:0] mcause_to_write1,
    input [31:0] mtval_to_write1,

    input mstatus_trap_shift0, mstatus_trap_shift1,
    input mstatus_return_shift0, mstatus_return_shift1,

    output reg [31:0] mtvec,
    output reg [31:0] mstatus,
    output reg [31:0] mepc,
    output reg [31:0] mcause,
    output reg [31:0] mscratch,
    output reg [31:0] mtval,
    output reg [31:0] mie,
    output reg [31:0] mip
);

    localparam MTVEC = 3'b000,
               MSTATUS = 3'b001,
               MEPC = 3'b010,
               MCAUSE = 3'b011,
               MSCRATCH = 3'b100,
               MTVAL = 3'b101,
               MIE = 3'b110,
               MIP = 3'b111;

    reg [31:0] stored_mtvec, stored_mstatus, stored_mepc, stored_mcause, stored_mscratch, stored_mtval, stored_mie;

    always @(posedge clk) begin
        if (reset || CPU_state == 0) begin
            stored_mtvec <= 0;
            stored_mstatus <= {19'b0, 2'b11, 3'b0, 1'b0, 3'b0, 1'b0, 3'b0};
            stored_mepc <= 0;
            stored_mcause <= 0;
            stored_mscratch <= 0;
            stored_mtval <= 0;
            stored_mie <= 0;
        end
        else begin
            if (write0) case (CSR_to_write0)
                MTVEC: stored_mtvec <= value_to_write0;
                MSTATUS: stored_mstatus <= value_to_write0;
                MEPC: stored_mepc <= value_to_write0;
                MCAUSE: stored_mcause <= value_to_write0;
                MSCRATCH: stored_mscratch <= value_to_write0;
                MTVAL: stored_mtval <= value_to_write0;
                MIE: stored_mie <= value_to_write0;
                default: ;
            endcase

            if (write1) case (CSR_to_write1)
                MTVEC: stored_mtvec <= value_to_write1;
                MSTATUS: stored_mstatus <= value_to_write1;
                MEPC: stored_mepc <= value_to_write1;
                MCAUSE: stored_mcause <= value_to_write1;
                MSCRATCH: stored_mscratch <= value_to_write1;
                MTVAL: stored_mtval <= value_to_write1;
                MIE: stored_mie <= value_to_write1;
                default: ;
            endcase

            if (write_mcause0) stored_mcause <= mcause_to_write0;
            if (write_mcause1) stored_mcause <= mcause_to_write1;
            if (write_mcause0) stored_mtval <= mtval_to_write0;
            if (write_mcause1) stored_mtval <= mtval_to_write1;

            // {19 empty bits, 2 bit MPP, 3 empty bits, 1 bit MPIE, 3 empty bits, 1 bit MIE, 3 empty bits}
            if (mstatus_trap_shift0) stored_mstatus <= {19'b0, 2'b11, 3'b0, stored_mstatus[3], 3'b0, 1'b0, 3'b0};
            if (mstatus_return_shift0) stored_mstatus <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, stored_mstatus[7], 3'b0};
            if (mstatus_trap_shift1) begin
                stored_mstatus <= {19'b0, 2'b11, 3'b0, stored_mstatus[3], 3'b0, 1'b0, 3'b0};
                if (write0 && CSR_to_write0 == MSTATUS) stored_mstatus <= {19'b0, 2'b11, 3'b0, value_to_write0[3], 3'b0, 1'b0, 3'b0}; // forward from CSR write in pipeline 0
            end
            if (mstatus_return_shift1) begin
                stored_mstatus <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, stored_mstatus[7], 3'b0};
                if (write0 && CSR_to_write0 == MSTATUS) stored_mstatus <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, value_to_write0[7], 3'b0}; // forward from CSR write in pipeline 0
            end
        end
    end

    always @(*) begin
        mtvec = stored_mtvec;
        mstatus = stored_mstatus;
        mepc = stored_mepc;
        mcause = stored_mcause;
        mscratch = stored_mscratch;
        mtval = stored_mtval;
        mie = stored_mie;
        // MTIP on bit 7, MIP is read-only
        mip = {24'b0, timer_mtip, 7'b0};

        if (write0) case (CSR_to_write0)
            MTVEC: mtvec = value_to_write0;
            MSTATUS: mstatus = value_to_write0;
            MEPC: mepc = value_to_write0;
            MCAUSE: mcause = value_to_write0;
            MSCRATCH: mscratch = value_to_write0;
            MTVAL: mtval = value_to_write0;
            MIE: mie = value_to_write0;
            default: ;
        endcase

        if (write1) case (CSR_to_write1)
            MTVEC: mtvec = value_to_write1;
            MSTATUS: mstatus = value_to_write1;
            MEPC: mepc = value_to_write1;
            MCAUSE: mcause = value_to_write1;
            MSCRATCH: mscratch = value_to_write1;
            MTVAL: mtval = value_to_write1;
            MIE: mie = value_to_write1;
            default: ;
        endcase 

        if (write_mcause0) mcause = mcause_to_write0;
        if (write_mcause1) mcause = mcause_to_write1;
        if (write_mcause0) mtval = mtval_to_write0;
        if (write_mcause1) mtval = mtval_to_write1;

        // {19 empty bits, 2 bit MPP, 3 empty bits, 1 bit MPIE, 3 empty bits, 1 bit MIE, 3 empty bits}
        if (mstatus_trap_shift0) mstatus = {19'b0, 2'b11, 3'b0, stored_mstatus[3], 3'b0, 1'b0, 3'b0};
        if (mstatus_return_shift0) mstatus = {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, stored_mstatus[7], 3'b0};
        if (mstatus_trap_shift1) mstatus = {19'b0, 2'b11, 3'b0, stored_mstatus[3], 3'b0, 1'b0, 3'b0};
        if (mstatus_return_shift1) mstatus = {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, stored_mstatus[7], 3'b0};
    end

endmodule