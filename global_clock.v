// ============================================================
// Module  : global_clock
// Project : ASPS
// Desc    : Free-running 16-bit counter that provides a
//           monotonically increasing timestamp.
//           Each tick = one system clock period (250 ms).
// ============================================================
module global_clock (
    input  wire        clk,
    input  wire        rst,
    output reg  [15:0] cur_time
);

always @(posedge clk) begin
    if (rst) cur_time <= 16'd0;
    else     cur_time <= cur_time + 1'b1;
end

endmodule
