`timescale 1ns / 1ps

module next_pc_predictor_writer (
    input [31:0] next_pc_predictor_write_pc0,
    input next_pc_predictor_targetwrite0, next_pc_predictor_takenwrite0, next_pc_predictor_jumpwrite0, next_pc_predictor_raswrite0,
    input next_pc_predictor_taken0, next_pc_predictor_is_jump0, next_pc_predictor_is_return0,
    input [31:0] next_pc_predictor_target_to_write0,
    input [31:0] next_pc_predictor_return_address_to_push0,

    input [31:0] next_pc_predictor_write_pc1,
    input next_pc_predictor_targetwrite1, next_pc_predictor_takenwrite1, next_pc_predictor_jumpwrite1, next_pc_predictor_raswrite1,
    input next_pc_predictor_taken1, next_pc_predictor_is_jump1, next_pc_predictor_is_return1,
    input [31:0] next_pc_predictor_target_to_write1,
    input [31:0] next_pc_predictor_return_address_to_push1,

    output [31:0] next_pc_predictor_write_pc,
    output next_pc_predictor_targetwrite, next_pc_predictor_takenwrite, next_pc_predictor_jumpwrite, next_pc_predictor_raswrite,
    output next_pc_predictor_taken, next_pc_predictor_is_jump, next_pc_predictor_is_return,
    output [31:0] next_pc_predictor_target_to_write,
    output [31:0] next_pc_predictor_return_address_to_push
);

    wire select0;

    assign select0 = (next_pc_predictor_targetwrite0 || next_pc_predictor_takenwrite0 || next_pc_predictor_jumpwrite0 || next_pc_predictor_raswrite0);

    assign next_pc_predictor_write_pc = select0 ? next_pc_predictor_write_pc0 : next_pc_predictor_write_pc1;
    assign next_pc_predictor_targetwrite = select0 ? next_pc_predictor_targetwrite0 : next_pc_predictor_targetwrite1;
    assign next_pc_predictor_takenwrite = select0 ? next_pc_predictor_takenwrite0 : next_pc_predictor_takenwrite1;
    assign next_pc_predictor_jumpwrite = select0 ? next_pc_predictor_jumpwrite0 : next_pc_predictor_jumpwrite1;
    assign next_pc_predictor_raswrite = select0 ? next_pc_predictor_raswrite0 : next_pc_predictor_raswrite1;
    assign next_pc_predictor_taken = select0 ? next_pc_predictor_taken0 : next_pc_predictor_taken1;
    assign next_pc_predictor_is_jump = select0 ? next_pc_predictor_is_jump0 : next_pc_predictor_is_jump1;
    assign next_pc_predictor_is_return = select0 ? next_pc_predictor_is_return0 : next_pc_predictor_is_return1;
    assign next_pc_predictor_target_to_write = select0 ? next_pc_predictor_target_to_write0 : next_pc_predictor_target_to_write1;
    assign next_pc_predictor_return_address_to_push = select0 ? next_pc_predictor_return_address_to_push0 : next_pc_predictor_return_address_to_push1;

endmodule