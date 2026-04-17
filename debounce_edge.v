// ============================================================
// Module  : debounce_edge
// Project : ASPS
// Desc    : Two-FF synchroniser + simple debounce counter +
//           rising-edge detector.
//           clean_pulse goes high for exactly ONE clock cycle
//           on each debounced falling edge of raw_in (IR fires).
// ============================================================
module debounce_edge (
    input  wire clk,
    input  wire rst,
    input  wire raw_in,       // raw IR sensor input
    output reg  clean_pulse   // single-cycle pulse on car detect
);

// --- Two-FF synchroniser ---
reg ff1, ff2;
always @(posedge clk) begin
    if (rst) begin ff1 <= 1; ff2 <= 1; end
    else     begin ff1 <= raw_in; ff2 <= ff1; end
end

// --- Debounce counter (4-bit ~16 cycles stable) ---
reg [3:0] db_cnt;
reg       db_state;

always @(posedge clk) begin
    if (rst) begin
        db_cnt   <= 0;
        db_state <= 1;
        clean_pulse <= 0;
    end else begin
        clean_pulse <= 0;       // default: no pulse

        if (ff2 != db_state) begin
            db_cnt <= db_cnt + 1;
            if (db_cnt == 4'hF) begin   // stable for 16 cycles
                db_state <= ff2;
                db_cnt   <= 0;
                // falling edge = car interrupts beam (IR: 1→0)
                if (db_state == 1 && ff2 == 0)
                    clean_pulse <= 1;
            end
        end else begin
            db_cnt <= 0;        // reset counter if signal bounces back
        end
    end
end

endmodule
