`timescale 1ns / 1ps

module timer (
    input clk,
    input reset,
    input CPU_state,

    input write_mtime, write_mtimecmp,
    input [31:0] time_value_to_write,

    output [31:0] mtime,
    output [31:0] mtimecmp,
    output mtip
);

    reg [31:0] stored_mtime, stored_mtimecmp;

    assign mtime = stored_mtime;
    assign mtimecmp = stored_mtimecmp;
    assign mtip = stored_mtime >= stored_mtimecmp;

    always @(posedge clk) begin
        if (reset || CPU_state == 0) begin
            stored_mtime <= 0;
            stored_mtimecmp <= ~32'b0;
        end
        else begin
            stored_mtime <= stored_mtime + 1;
            if (write_mtime) stored_mtime <= time_value_to_write;
            if (write_mtimecmp) stored_mtimecmp <= time_value_to_write;
        end
    end

endmodule