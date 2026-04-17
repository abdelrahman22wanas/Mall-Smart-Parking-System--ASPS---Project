// ============================================================
// Module  : cost_calculator
// Project : ASPS
// Desc    : Computes CCost = Ptime × cost_per_unit.
//           cost_per_unit is fixed at 1 (1 LE per time unit).
//           Updates CCost register on buf_read pulse.
// ============================================================
module cost_calculator (
    input  wire        clk,
    input  wire        rst,
    input  wire        calc_en,         // from exit_fsm (buf_read)
    input  wire [15:0] cur_time,
    input  wire [15:0] oldest_time,
    output reg  [7:0]  CCost            // displayed cost (8-bit)
);

wire [15:0] ptime = cur_time - oldest_time; // parking duration

always @(posedge clk) begin
    if (rst) begin
        CCost <= 8'd0;
    end else if (calc_en) begin
        // CCost = Ptime × 1 LE  (saturate at 255)
        CCost <= (ptime > 255) ? 8'd255 : ptime[7:0];
    end
end

endmodule
