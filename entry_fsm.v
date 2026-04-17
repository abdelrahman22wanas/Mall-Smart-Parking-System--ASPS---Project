// ============================================================
// Module  : entry_fsm
// Project : ASPS
// Desc    : Entry gate finite state machine.
//           States: IDLE → CAR_DETECT → COUNT → back to IDLE
//           If full flag is set when car arrives → FULL_ALARM.
// ============================================================
module entry_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       car_pulse,    // clean pulse from debounce_edge
    input  wire       full_flag,
    output reg        inc_count,    // tell counter to increment
    output reg        buf_write,    // tell buffer to store timestamp
    output reg        alarm_full
);

// FSM state encoding
localparam IDLE       = 2'd0;
localparam CAR_DETECT = 2'd1;
localparam COUNT      = 2'd2;
localparam FULL_ALARM = 2'd3;

reg [1:0] state, next_state;

// --- State register ---
always @(posedge clk) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
end

// --- Next-state logic ---
always @(*) begin
    case (state)
        IDLE: begin
            if (car_pulse && !full_flag) next_state = CAR_DETECT;
            else if (car_pulse &&  full_flag) next_state = FULL_ALARM;
            else                             next_state = IDLE;
        end
        CAR_DETECT: next_state = COUNT;
        COUNT:      next_state = IDLE;
        FULL_ALARM: next_state = IDLE;   // alarm lasts 1 cycle
        default:    next_state = IDLE;
    endcase
end

// --- Output logic (Moore) ---
always @(*) begin
    inc_count  = 1'b0;
    buf_write  = 1'b0;
    alarm_full = 1'b0;
    case (state)
        COUNT:      begin inc_count = 1'b1; buf_write = 1'b1; end
        FULL_ALARM: alarm_full = 1'b1;
        default:    ;
    endcase
end

endmodule
