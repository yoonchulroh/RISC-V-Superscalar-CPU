`timescale 1ns / 1ps

module SimpleDMem #(
    parameter DMEM_SIZE = 400 // in bytes, should be a multiple of 4
) (
    input clk,
    input reset,

    input [31:0] address, // lower 2 bits may be ignored, depending on maskmode
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
    reg [$clog2(DMEM_SIZE / 4) - 1 : 0] BRAM_address;
    reg [7:0] data_to_write0, data_to_write1, data_to_write2, data_to_write3;

    reg [7:0] readdata0, readdata1, readdata2, readdata3;

    always @(*) begin
        BRAM_read = 0;

        BRAM_write0 = 0;
        BRAM_write1 = 0;
        BRAM_write2 = 0;
        BRAM_write3 = 0;

        BRAM_address = (address >> 2);

        case (address[1:0])
            0: begin
                data_to_write0 = data_to_write[7:0];
                data_to_write1 = data_to_write[15:8];
                data_to_write2 = data_to_write[23:16];
                data_to_write3 = data_to_write[31:24];
            end
            1: begin
                data_to_write1 = data_to_write[7:0];
                data_to_write2 = 0;
                data_to_write3 = 0;
                data_to_write0 = 0;
            end
            2: begin
                data_to_write2 = data_to_write[7:0];
                data_to_write3 = data_to_write[15:8];
                data_to_write0 = 0;
                data_to_write1 = 0;
            end
            3: begin
                data_to_write3 = data_to_write[7:0];
                data_to_write0 = 0;
                data_to_write1 = 0;
                data_to_write2 = 0;
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
            if (memread && address < DMEM_SIZE) BRAM_read = 1;
            else if (memwrite && address < DMEM_SIZE) case (maskmode)
                0: case (address[1:0]) // Write 1 byte.
                    0: BRAM_write0 = 1;
                    1: BRAM_write1 = 1;
                    2: BRAM_write2 = 1;
                    3: BRAM_write3 = 1;
                endcase
                1: case (address[1]) // Write 2 bytes. Assume address is aligned to a multiple of 2.
                    0: begin
                        BRAM_write0 = 1;
                        BRAM_write1 = 1;
                    end
                    1: begin
                        BRAM_write2 = 1;
                        BRAM_write3 = 1;
                    end
                endcase
                2: begin // Write 4 bytes. Assume address is aligned to a multiple of 4. 
                    BRAM_write0 = 1;
                    BRAM_write1 = 1;
                    BRAM_write2 = 1;
                    BRAM_write3 = 1;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        latched_address <= address[1:0];
        latched_maskmode <= maskmode;
        latched_sext <= sext;

        if (BRAM_read) begin
            readdata0 <= BRAM_data0[BRAM_address];
            readdata1 <= BRAM_data1[BRAM_address];
            readdata2 <= BRAM_data2[BRAM_address];
            readdata3 <= BRAM_data3[BRAM_address];
        end

        if (BRAM_write0) BRAM_data0[BRAM_address] <= data_to_write0;
        if (BRAM_write1) BRAM_data1[BRAM_address] <= data_to_write1;
        if (BRAM_write2) BRAM_data2[BRAM_address] <= data_to_write2;
        if (BRAM_write3) BRAM_data3[BRAM_address] <= data_to_write3;
    end
    
    always @(*) begin
        readdata = 0;
        case (latched_maskmode)
            0: begin // Read 1 byte.
                case (latched_address)
                    0: readdata[7:0] = readdata0;
                    1: readdata[7:0] = readdata1;
                    2: readdata[7:0] = readdata2;
                    3: readdata[7:0] = readdata3;
                endcase
                if (latched_sext && readdata[7] == 1) readdata[31:8] = ~24'b0;
            end
            1: begin // Read 2 bytes. Assume that address is aligned to multiple of 2.
                case (latched_address[1])
                    0: begin
                        readdata[7:0] = readdata0;
                        readdata[15:8] = readdata1;
                    end
                    1: begin
                        readdata[7:0] = readdata2;
                        readdata[15:8] = readdata3;
                    end
                endcase
                if (latched_sext && readdata[15] == 1) readdata[31:16] = ~16'b0;
            end
            2: begin // Read 4 bytes. Assume that address is aligned to multiple of 4
                readdata[7:0] = readdata0;
                readdata[15:8] = readdata1;
                readdata[23:16] = readdata2;
                readdata[31:24] = readdata3;
            end
            default: readdata = 0;
        endcase
    end 

endmodule