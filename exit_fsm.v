// ============================================================
// Module  : exit_fsm
// Project : ASPS
// Desc    : Exit gate finite state machine.
//           States: IDLE → CAR_DETECT → CALC_COST → IDLE
//           If empty flag is set when car tries to exit → EMPTY_ALARM.
// ============================================================
module exit_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       car_pulse,    // clean pulse from debounce_edge
    input  wire       empty_flag,
    output reg        dec_count,    // tell counter to decrement
    output reg        buf_read,     // tell buffer to pop timestamp
    output reg        alarm_empty
);

localparam IDLE        = 2'd0;
localparam CAR_DETECT  = 2'd1;
localparam CALC_COST   = 2'd2;
localparam EMPTY_ALARM = 2'd3;

reg [1:0] state, next_state;

always @(posedge clk) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: begin
            if (car_pulse && !empty_flag) next_state = CAR_DETECT;
            else if (car_pulse && empty_flag) next_state = EMPTY_ALARM;
            else                              next_state = IDLE;
        end
        CAR_DETECT:  next_state = CALC_COST;
        CALC_COST:   next_state = IDLE;
        EMPTY_ALARM: next_state = IDLE;
        default:     next_state = IDLE;
    endcase
end

always @(*) begin
    dec_count   = 1'b0;
    buf_read    = 1'b0;
    alarm_empty = 1'b0;
    case (state)
        CALC_COST:   begin dec_count = 1'b1; buf_read = 1'b1; end
        EMPTY_ALARM: alarm_empty = 1'b1;
        default:     ;
    endcase
end

endmodule
