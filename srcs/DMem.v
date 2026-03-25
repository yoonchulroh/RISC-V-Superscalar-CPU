`timescale 1ns / 1ps

module DMem #(
    parameter DMEM_SIZE = 400 // in bytes, should be a multiple of 4
) (
    input clk,
    input reset,

    input [31:0] address, // address can be unaligned
    input [31:0] data_to_write,
    input memread,
    input memwrite,
    input [1:0] maskmode,
    input sext,

    output reg [31:0] readdata
);

    reg [1:0] latched_address;
    reg [1:0] latched_maskmode;
    reg latched_sext;

    reg [7:0] BRAM_data0 [(DMEM_SIZE / 4) - 1 : 0];
    reg [7:0] BRAM_data1 [(DMEM_SIZE / 4) - 1 : 0];
    reg [7:0] BRAM_data2 [(DMEM_SIZE / 4) - 1 : 0];
    reg [7:0] BRAM_data3 [(DMEM_SIZE / 4) - 1 : 0];

    reg BRAM_read;
    reg BRAM_write0, BRAM_write1, BRAM_write2, BRAM_write3;
    reg [$clog2(DMEM_SIZE / 4) - 1 : 0] address0, address1, address2, address3;
    reg [7:0] data_to_write0, data_to_write1, data_to_write2, data_to_write3;

    reg [7:0] readdata0, readdata1, readdata2, readdata3;

    always @(*) begin
        BRAM_read = 0;

        BRAM_write0 = 0;
        BRAM_write1 = 0;
        BRAM_write2 = 0;
        BRAM_write3 = 0;

        address0 = (address[1:0] > 0) ? (address >> 2) + 1 : (address >> 2);
        address1 = (address[1:0] > 1) ? (address >> 2) + 1 : (address >> 2);
        address2 = (address[1:0] > 2) ? (address >> 2) + 1 : (address >> 2);
        address3 = (address >> 2);

        case (address[1:0])
            0: begin
                data_to_write0 = data_to_write[7:0];
                data_to_write1 = data_to_write[15:8];
                data_to_write2 = data_to_write[23:16];
                data_to_write3 = data_to_write[31:24];
            end
            1: begin
                data_to_write1 = data_to_write[7:0];
                data_to_write2 = data_to_write[15:8];
                data_to_write3 = data_to_write[23:16];
                data_to_write0 = data_to_write[31:24];
            end
            2: begin
                data_to_write2 = data_to_write[7:0];
                data_to_write3 = data_to_write[15:8];
                data_to_write0 = data_to_write[23:16];
                data_to_write1 = data_to_write[31:24];
            end
            3: begin
                data_to_write3 = data_to_write[7:0];
                data_to_write0 = data_to_write[15:8];
                data_to_write1 = data_to_write[23:16];
                data_to_write2 = data_to_write[31:24];
            end
            default: begin
                data_to_write0 = 0;
                data_to_write1 = 0;
                data_to_write2 = 0;
                data_to_write3 = 0;
            end
        endcase

        if (reset) ;
        else begin
            if (memread) begin
                case (maskmode)
                    0: if (address < DMEM_SIZE) BRAM_read = 1; // read 1 byte
                    1: if (address < DMEM_SIZE - 1) BRAM_read = 1; // read 2 bytes
                    2: if (address < DMEM_SIZE - 3) BRAM_read = 1; // read 4 bytes
                    default: ;
                endcase
            end
            else if (memwrite) begin
                case (maskmode)
                    0: if (address < DMEM_SIZE) begin // write 1 byte
                        case (address[1:0])
                            0: BRAM_write0 = 1;
                            1: BRAM_write1 = 1;
                            2: BRAM_write2 = 1;
                            3: BRAM_write3 = 1;
                        endcase
                    end
                    1: if (address < DMEM_SIZE - 1) begin // write 2 bytes
                        case (address[1:0])
                            0: begin
                                BRAM_write0 = 1;
                                BRAM_write1 = 1;
                            end
                            1: begin
                                BRAM_write1 = 1;
                                BRAM_write2 = 1;
                            end
                            2: begin
                                BRAM_write2 = 1;
                                BRAM_write3 = 1;
                            end
                            3: begin
                                BRAM_write3 = 1;
                                BRAM_write0 = 1;
                            end
                        endcase
                    end
                    2: if (address < DMEM_SIZE - 3) begin // write 4 bytes
                        BRAM_write0 = 1;
                        BRAM_write1 = 1;
                        BRAM_write2 = 1;
                        BRAM_write3 = 1;
                    end
                    default: ;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        latched_address <= address[1:0];
        latched_maskmode <= maskmode;
        latched_sext <= sext;

        if (BRAM_read) begin
            readdata0 <= BRAM_data0[address0];
            readdata1 <= BRAM_data1[address1];
            readdata2 <= BRAM_data2[address2];
            readdata3 <= BRAM_data3[address3];
        end
        
        if (BRAM_write0) BRAM_data0[address0] <= data_to_write0;
        if (BRAM_write1) BRAM_data1[address1] <= data_to_write1;
        if (BRAM_write2) BRAM_data2[address2] <= data_to_write2;
        if (BRAM_write3) BRAM_data3[address3] <= data_to_write3;
    end

    always @(*) begin
        readdata = 0;
        case (latched_maskmode)
            0: begin
                case (latched_address)
                    0: readdata[7:0] = readdata0;
                    1: readdata[7:0] = readdata1;
                    2: readdata[7:0] = readdata2;
                    3: readdata[7:0] = readdata3;
                endcase
                if (latched_sext && readdata[7] == 1) readdata[31:8] = ~24'b0;
            end
            1: begin
                case (latched_address)
                    0: begin
                        readdata[7:0] = readdata0;
                        readdata[15:8] = readdata1;
                    end
                    1: begin
                        readdata[7:0] = readdata1;
                        readdata[15:8] = readdata2;
                    end
                    2: begin
                        readdata[7:0] = readdata2;
                        readdata[15:8] = readdata3;
                    end
                    3: begin
                        readdata[7:0] = readdata3;
                        readdata[15:8] = readdata0;
                    end
                endcase
                if (latched_sext && readdata[15] == 1) readdata[31:16] = ~16'b0;
            end
            2: begin
                case (latched_address)
                    0: begin
                        readdata[7:0] = readdata0;
                        readdata[15:8] = readdata1;
                        readdata[23:16] = readdata2;
                        readdata[31:24] = readdata3;
                    end
                    1: begin
                        readdata[7:0] = readdata1;
                        readdata[15:8] = readdata2;
                        readdata[23:16] = readdata3;
                        readdata[31:24] = readdata0;
                    end
                    2: begin
                        readdata[7:0] = readdata2;
                        readdata[15:8] = readdata3;
                        readdata[23:16] = readdata0;
                        readdata[31:24] = readdata1;
                    end
                    3: begin
                        readdata[7:0] = readdata3;
                        readdata[15:8] = readdata0;
                        readdata[23:16] = readdata1;
                        readdata[31:24] = readdata2;
                    end
                endcase
            end
            default: readdata = 0;
        endcase
    end

endmodule