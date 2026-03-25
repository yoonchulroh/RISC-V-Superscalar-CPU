`timescale 1ns / 1ps

module return_address_stack #(
    parameter RETURN_ADDRESS_STACK_SIZE = 8
) (
    input clk,
    input reset,
    input raswrite,
    input is_jump,
    input is_return,
    input push,
    input pop,
    input [31:0] address_to_push_from_cpu,
    input [31:0] address_to_push_from_predictor,

    output reg [31:0] top_address
);

    reg [31:0] return_address_buffer [RETURN_ADDRESS_STACK_SIZE - 1 : 0];
    reg [$clog2(RETURN_ADDRESS_STACK_SIZE) - 1 : 0] return_address_buffer_top;
    reg [$clog2(RETURN_ADDRESS_STACK_SIZE) - 1 : 0] return_address_buffer_next_top;

    always @(*) begin
        return_address_buffer_next_top = return_address_buffer_top;

        if (push || (raswrite && is_jump)) begin
            return_address_buffer_next_top = (return_address_buffer_top < RETURN_ADDRESS_STACK_SIZE - 1) ? (return_address_buffer_top + 1) : 0;
        end
        else if (pop || (raswrite && is_return)) begin
            return_address_buffer_next_top = (return_address_buffer_top > 0) ? (return_address_buffer_top - 1) : (RETURN_ADDRESS_STACK_SIZE - 1);
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            return_address_buffer_top <= 0;
            top_address <= 0;
        end
        else begin
            top_address <= return_address_buffer[return_address_buffer_top];
            return_address_buffer_top <= return_address_buffer_next_top;

            if (raswrite && is_jump) begin
                return_address_buffer[return_address_buffer_next_top] <= address_to_push_from_cpu;
                top_address <= address_to_push_from_cpu;
                //$display("Pushed %d from CPU.", address_to_push_from_cpu);
            end
            else if (push) begin
                return_address_buffer[return_address_buffer_next_top] <= address_to_push_from_predictor;
                top_address <= address_to_push_from_predictor;
                //$display("Pushed %d from predictor.", address_to_push_from_predictor);
            end

            //if (pop || (raswrite && is_return)) $display("Popped %d.", return_address_buffer[return_address_buffer_top]);
        end
    end

endmodule