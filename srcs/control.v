`timescale 1ns / 1ps

module control #(
    parameter PRINT_OPCODE = 7'b0101011
) (
    input [6:0] opcode,
    input [4:0] funct5,
    input [2:0] funct3,
    input [11:0] funct12,
    input instruction_access_fault, instruction_misaligned,
    input mie, mtip, mtie,
    input [1:0] atomic_decode_phase,
    input valid_instruction,

    output reg add,
    output reg immediate,
    output reg [1:0] alusrc1,

    output reg branch,
    output reg [1:0] jump,

    output reg memread,
    output reg memwrite,

    output reg [1:0] toreg,
    output reg regwrite,

    output reg reserve,
    output reg atomic,

    output reg trap,
    output reg trap_is_return,
    output reg CSR_file_write,
    output reg [2:0] CSR_to_write,
    output reg [2:0] CSR_value_select,
    output reg write_mcause,
    output reg [31:0] mcause_to_write,
    
    output reg print);

    localparam MTVEC = 3'b000,
               MSTATUS = 3'b001,
               MEPC = 3'b010,
               MCAUSE = 3'b011,
               MSCRATCH = 3'b100,
               MTVAL = 3'b101,
               MIE = 3'b110,
               MIP = 3'b111;

    always @(*) begin
        add = 0;
        immediate = 0;
        alusrc1 = 0;
        branch = 0;
        jump = 0;
        memread = 0;
        memwrite = 0;
        toreg = 0;
        regwrite = 0;
        reserve = 0;
        atomic = 0;
        trap = 0;
        trap_is_return = 0;
        CSR_file_write = 0;
        CSR_to_write = MEPC; // write mepc by default (in case of traps)
        CSR_value_select = MTVEC; // select mtvec by default
        print = 0;
        write_mcause = 0;
        mcause_to_write = 0;

        if (instruction_access_fault || instruction_misaligned) begin
            trap = 1;
            CSR_value_select = MTVEC; // select mtvec
            CSR_file_write = 1;
            CSR_to_write = MEPC; // write to mepc
            write_mcause = 1;

            if (instruction_access_fault) mcause_to_write = 1; // mcause for instruction access fault
            else mcause_to_write = 0;
        end
        else if (valid_instruction == 1 && mie == 1 && mtip == 1 && mtie == 1 && atomic_decode_phase == 0) begin
            trap = 1;
            CSR_value_select = MTVEC;
            CSR_file_write = 1;
            CSR_to_write = MEPC;
            write_mcause = 1;
            mcause_to_write = {1'b1, 31'd7};
        end
        else case (opcode)
            7'b0110011: begin // R-format
                regwrite = 1;
            end
            7'b0010011: begin // I-format
                immediate = 1;
                regwrite = 1;
            end
            7'b0000011: begin // Load
                add = 1;
                immediate = 1;
                memread = 1;
                toreg = 1;
                regwrite = 1;
            end
            7'b0100011: begin // Store
                add = 1;
                immediate = 1;
                memwrite = 1;
            end
            7'b1100011: begin // Branch
                branch = 1;
            end
            7'b0110111: begin // lui
                add = 1;
                immediate = 1;
                alusrc1 = 1;
                regwrite = 1;
            end
            7'b0010111: begin // auipc
                add = 1;
                immediate = 1;
                regwrite = 1;
                alusrc1 = 2;
            end
            7'b1101111: begin // jal
                jump = 2;
                toreg = 2;
                regwrite = 1;
            end
            7'b1100111: begin // jalr
                add = 1;
                immediate = 1;
                jump = 3;
                toreg = 2;
                regwrite = 1;
            end
            7'b0101111: begin // reserve
                if (funct5 == 2 || funct5 == 3) begin
                    reserve = 1;

                    add = 1;
                    immediate = 1;
                    regwrite = 1;
                    toreg = 1;

                    if (funct5 == 2) memread = 1;
                    else memwrite = 1;
                end
                else begin
                    atomic = 1;
                end
            end
            7'b1110011: begin // system
                if (funct3 == 0) begin
                    trap = 1;
                    
                    if (funct12 == 12'b001100000010) begin // mret
                        trap_is_return = 1;
                        CSR_value_select = MEPC; // select mepc
                    end
                    else if (funct12 == 12'b1) begin // ebreak
                        CSR_value_select = MTVEC; // select mtvec
                        CSR_file_write = 1;
                        CSR_to_write = MEPC;
                        write_mcause = 1;
                        mcause_to_write = 3;
                    end
                    else begin // ecall
                        CSR_value_select = MTVEC; // select mtvec
                        CSR_file_write = 1;
                        CSR_to_write = MEPC;
                        write_mcause = 1;
                        mcause_to_write = 11;
                    end
                end
                else begin
                    toreg = 3;
                    regwrite = 1;
                    CSR_file_write = 1;
                    
                    case (funct12)
                        12'h300: begin // mstatus
                            CSR_value_select = MSTATUS;
                            CSR_to_write = MSTATUS;
                        end
                        12'h304: begin // mie
                            CSR_value_select = MIE;
                            CSR_to_write = MIE;
                        end
                        12'h305: begin // mtvec
                            CSR_value_select = MTVEC;
                            CSR_to_write = MTVEC;
                        end
                        12'h340: begin // mscratch
                            CSR_value_select = MSCRATCH;
                            CSR_to_write = MSCRATCH;
                        end
                        12'h341: begin // mepc
                            CSR_value_select = MEPC;
                            CSR_to_write = MEPC;
                        end
                        12'h342: begin // mcause
                            CSR_value_select = MCAUSE;
                            CSR_to_write = MCAUSE;
                        end
                        12'h343: begin // mtval
                            CSR_value_select = MTVAL;
                            CSR_to_write = MTVAL;
                        end
                        12'h344: begin // mip, read-only
                            CSR_value_select = MIP;
                        end
                        default: begin // unused CSR
                            regwrite = 0;

                            trap = 1;
                            CSR_value_select = MTVEC; // select mtvec
                            CSR_to_write = MEPC; // write to mepc
                            write_mcause = 1;
                            mcause_to_write = 2; // mcause for illegal instruction
                        end
                    endcase
                end
            end
            PRINT_OPCODE: begin
                print = 1;
            end
            default: begin // invalid opcode
                trap = 1;
                CSR_value_select = MTVEC; // select mtvec
                CSR_file_write = 1;
                CSR_to_write = MEPC; // write to mepc
                write_mcause = 1;
                mcause_to_write = 2; // mcause for illegal instruction
            end
        endcase
    end

endmodule