// ============================================================
// Module  : updown_counter
// Project : ASPS - Alamein Mall Smart Parking System
// Desc    : Parameterised n-bit synchronous up/down counter
//           used for Ccount (car count, max = 3).
// ============================================================
module updown_counter #(
    parameter N   = 3,          // bit width
    parameter MAX = 3           // garage capacity
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       inc,      // increment (car enters)
    input  wire       dec,      // decrement (car exits)
    output reg  [N-1:0] count
);

always @(posedge clk) begin
    if (rst) begin
        count <= {N{1'b0}};
    end else begin
        if      (inc && (count < MAX)) count <= count + 1'b1;
        else if (dec && (count > 0  )) count <= count - 1'b1;
        // ignore inc when full, dec when empty (guard in FSM too)
    end
end

endmodule
