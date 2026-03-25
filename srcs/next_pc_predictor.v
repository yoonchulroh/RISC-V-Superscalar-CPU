`timescale 1ns / 1ps

module next_pc_predictor #(
    parameter NEXT_PC_PREDICTOR_BUFFER_SIZE = 64, // should be an exponent of 2
    parameter GLOBAL_HISTORY_REGISTER_SIZE = 6,
    parameter RETURN_ADDRESS_STACK_SIZE = 8
) (
    input clk,
    input reset,
    input [31:0] read_pc,
    input [31:0] write_pc,
    input takenwrite,
    input targetwrite,
    input jumpwrite,
    input raswrite,
    input taken,
    input is_jump,
    input is_return,
    input [31:0] target_to_write,
    input [31:0] return_address_to_push,
    input predicted_jump_used,
    input predicted_return_used,
    input [31:0] return_address_to_push_from_predictor,
    // input cpu_state_temp,

    output reg [31:0] predicted_target,
    output reg predicted_jump, predicted_return,
    output reg [31:0] return_address_to_push_from_predictor_candidate
);
    localparam NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH = $clog2(NEXT_PC_PREDICTOR_BUFFER_SIZE);

    integer i;

    reg [31:0] BRAM_target_for_index [NEXT_PC_PREDICTOR_BUFFER_SIZE - 1 : 0];
    reg BRAM_target_for_index_read, BRAM_target_for_index_write;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] BRAM_target_for_index_read_address;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] BRAM_target_for_index_write_address;
    reg [31:0] BRAM_target_for_index_data_to_write;
    reg [31:0] BRAM_target_for_index_readdata;

    reg [31:0] BRAM_tag_for_index [NEXT_PC_PREDICTOR_BUFFER_SIZE - 1 : 0];
    reg BRAM_tag_for_index_read, BRAM_tag_for_index_write;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] BRAM_tag_for_index_read_address;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] BRAM_tag_for_index_write_address;
    reg [31:0] BRAM_tag_for_index_data_to_write;
    reg [31:0] BRAM_tag_for_index_readdata;

    reg [NEXT_PC_PREDICTOR_BUFFER_SIZE - 1 : 0] target_for_index_valid;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_valid_read_address;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_valid_write_address;
    reg target_for_index_valid_readdata;

    reg [1:0] target_for_index_taken [NEXT_PC_PREDICTOR_BUFFER_SIZE - 1 : 0];
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_taken_read_address;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_taken_write_address;
    reg [1:0] target_for_index_taken_readdata;

    reg [NEXT_PC_PREDICTOR_BUFFER_SIZE - 1 : 0] target_for_index_is_jump;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_is_jump_read_address;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_is_jump_write_address;
    reg target_for_index_is_jump_readdata;

    reg [NEXT_PC_PREDICTOR_BUFFER_SIZE - 1 : 0] target_for_index_is_return;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_is_return_read_address;
    reg [NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH - 1 : 0] target_for_index_is_return_write_address;
    reg target_for_index_is_return_readdata;
    
    reg [GLOBAL_HISTORY_REGISTER_SIZE - 1 : 0] global_history_register;

    reg [GLOBAL_HISTORY_REGISTER_SIZE - 1 : 0] PCIF_global_history_register;
    reg [GLOBAL_HISTORY_REGISTER_SIZE - 1 : 0] IFID_global_history_register;
    reg [GLOBAL_HISTORY_REGISTER_SIZE - 1 : 0] IDEX_global_history_register;
    reg [GLOBAL_HISTORY_REGISTER_SIZE - 1 : 0] EXMEM_global_history_register;

    reg [31:0] latched_read_pc;

    // Signals for the return address stack
    wire [31:0] return_address_stack_top_address;

    return_address_stack #(
        .RETURN_ADDRESS_STACK_SIZE(RETURN_ADDRESS_STACK_SIZE)
    ) return_address_stack_inst (
        .clk(clk),
        .reset(reset),
        .raswrite(raswrite),
        .is_jump(is_jump),
        .is_return(is_return),
        .push(predicted_jump_used),
        .pop(predicted_return_used),
        .address_to_push_from_cpu(return_address_to_push),
        .address_to_push_from_predictor(return_address_to_push_from_predictor),

        .top_address(return_address_stack_top_address)
    );

    always @(*) begin
        BRAM_target_for_index_read = 1;
        BRAM_tag_for_index_read = 1;

        if (targetwrite) begin
            BRAM_target_for_index_write = 1;
            BRAM_tag_for_index_write = 1;
        end
        else begin
            BRAM_target_for_index_write = 0;
            BRAM_tag_for_index_write = 0;
        end

        BRAM_target_for_index_read_address = read_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        BRAM_tag_for_index_read_address = read_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        target_for_index_valid_read_address = read_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        target_for_index_taken_read_address = read_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2] ^ global_history_register;
        target_for_index_is_jump_read_address = read_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        target_for_index_is_return_read_address = read_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2]; 

        BRAM_target_for_index_write_address = write_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        BRAM_tag_for_index_write_address = write_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        target_for_index_valid_write_address = write_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        target_for_index_taken_write_address = write_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2] ^ EXMEM_global_history_register;
        target_for_index_is_jump_write_address = write_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];
        target_for_index_is_return_write_address = write_pc[NEXT_PC_PREDICTOR_INDEX_BIT_WIDTH + 1 : 2];

        BRAM_target_for_index_data_to_write = target_to_write;
        BRAM_tag_for_index_data_to_write = write_pc;
    end

    always @(posedge clk) begin
        if (reset) begin
            target_for_index_valid <= 0;
            for (i = 0; i < NEXT_PC_PREDICTOR_BUFFER_SIZE; i = i + 1) target_for_index_taken[i] <= 2'b01;
            target_for_index_is_jump <= 0;
            target_for_index_is_return <= 0;

            global_history_register <= 0;
            PCIF_global_history_register <= 0;
            IFID_global_history_register <= 0;
            IDEX_global_history_register <= 0;
            EXMEM_global_history_register <= 0;
        end
        else begin
            if (targetwrite) target_for_index_valid[target_for_index_valid_write_address] <= 1;

            if (takenwrite) begin
                global_history_register <= {global_history_register[GLOBAL_HISTORY_REGISTER_SIZE - 2 : 0], taken};
                if (taken && target_for_index_taken[target_for_index_taken_write_address] != 2'b11) begin
                    target_for_index_taken[target_for_index_taken_write_address] <= target_for_index_taken[target_for_index_taken_write_address] + 1;
                end
                if (~taken && target_for_index_taken[target_for_index_taken_write_address] != 2'b00) begin
                    target_for_index_taken[target_for_index_taken_write_address] <= target_for_index_taken[target_for_index_taken_write_address] - 1;
                end
            end

            if (jumpwrite) begin
                target_for_index_is_jump[target_for_index_is_jump_write_address] <= is_jump;
                target_for_index_is_return[target_for_index_is_return_write_address] <= is_return;
            end

            PCIF_global_history_register <= global_history_register;
            IFID_global_history_register <= PCIF_global_history_register;
            IDEX_global_history_register <= IFID_global_history_register;
            EXMEM_global_history_register <= IDEX_global_history_register;
        end

        latched_read_pc <= read_pc;
        return_address_to_push_from_predictor_candidate <= read_pc + 4;

        if (BRAM_target_for_index_read) BRAM_target_for_index_readdata <= BRAM_target_for_index[BRAM_target_for_index_read_address];
        if (BRAM_target_for_index_write) BRAM_target_for_index[BRAM_target_for_index_write_address] <= BRAM_target_for_index_data_to_write;

        if (BRAM_tag_for_index_read) BRAM_tag_for_index_readdata <= BRAM_tag_for_index[BRAM_tag_for_index_read_address];
        if (BRAM_tag_for_index_write) BRAM_tag_for_index[BRAM_tag_for_index_write_address] <= BRAM_tag_for_index_data_to_write;

        target_for_index_valid_readdata <= target_for_index_valid[target_for_index_valid_read_address];
        target_for_index_taken_readdata <= target_for_index_taken[target_for_index_taken_read_address];
        target_for_index_is_jump_readdata <= target_for_index_is_jump[target_for_index_is_jump_read_address];
        target_for_index_is_return_readdata <= target_for_index_is_return[target_for_index_is_return_read_address];

        /*
        if (cpu_state_temp == 1) begin
            //$display("Read value %d for pc %d", BRAM_target_for_index[BRAM_target_for_index_read_address], read_pc);
            //if (targetwrite) $display("Wrote value %d for pc  %d", BRAM_target_for_index_data_to_write, write_pc);
            //$display("Predicted %d for pc %d. Current top: %d.", predicted_target, latched_read_pc, return_address_stack_top_address);
        end
        */
    end

    always @(*) begin
        predicted_target = latched_read_pc + 4;
        predicted_jump = 0;
        predicted_return = 0;

        if (target_for_index_valid_readdata == 1 && BRAM_tag_for_index_readdata == latched_read_pc) begin
            if (target_for_index_is_return_readdata == 1) begin
                predicted_target = return_address_stack_top_address;
                predicted_return = 1;
            end
            else if (target_for_index_is_jump_readdata == 1) begin
                predicted_target = BRAM_target_for_index_readdata;
                predicted_jump = 1;
            end
            else if (target_for_index_taken_readdata >= 2) begin
                predicted_target = BRAM_target_for_index_readdata;
            end
        end
    end

endmodule