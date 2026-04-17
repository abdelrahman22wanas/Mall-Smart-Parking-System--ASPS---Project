// ============================================================
// Module  : asps_top
// Project : Alamein Mall Smart Parking System (ASPS™)
// Course  : CSE132 – Computer Architecture & Organization
// Desc    : Top-level structural model instantiating all
//           sub-modules and wiring them together.
//           Flags are generated using concurrent (combinational)
//           assign statements as required.
// ============================================================
`include "debounce_edge.v"
`include "entry_fsm.v"
`include "exit_fsm.v"
`include "updown_counter.v"
`include "global_clock.v"
`include "timestamp_buffer.v"
`include "cost_calculator.v"
`include "seven_seg_encoder.v"

module asps_top (
    // ---- System ----
    input  wire       clk,
    input  wire       rst,
    // ---- Sensors ----
    input  wire       entry_ir,    // IR: 1=clear, 0=car
    input  wire       exit_ir,
    // ---- Displays ----
    output wire [6:0] seg_count,   // 7-seg for Ccount
    output wire [6:0] seg_cost,    // 7-seg for CCost (ones digit)
    // ---- Status ----
    output wire       empty_flag,
    output wire       full_flag,
    output wire       alarm_full,
    output wire       alarm_empty
);

// ---- Internal wires ----
wire        entry_pulse, exit_pulse;
wire        inc_count, dec_count;
wire        buf_write,  buf_read;
wire [2:0]  Ccount;
wire [15:0] cur_time, oldest_time;
wire [7:0]  CCost;
wire [1:0]  fill_count;  // unused externally

// ============================================================
// Concurrent flag generation (combinational, per spec)
// ============================================================
assign empty_flag = (Ccount == 3'd0);
assign full_flag  = (Ccount == 3'd3);

// ============================================================
// Module instantiations
// ============================================================

// -- Debounce & edge detect: entry gate --
debounce_edge u_deb_entry (
    .clk        (clk),
    .rst        (rst),
    .raw_in     (entry_ir),
    .clean_pulse(entry_pulse)
);

// -- Debounce & edge detect: exit gate --
debounce_edge u_deb_exit (
    .clk        (clk),
    .rst        (rst),
    .raw_in     (exit_ir),
    .clean_pulse(exit_pulse)
);

// -- Entry FSM --
entry_fsm u_entry_fsm (
    .clk       (clk),
    .rst       (rst),
    .car_pulse (entry_pulse),
    .full_flag (full_flag),
    .inc_count (inc_count),
    .buf_write (buf_write),
    .alarm_full(alarm_full)
);

// -- Exit FSM --
exit_fsm u_exit_fsm (
    .clk        (clk),
    .rst        (rst),
    .car_pulse  (exit_pulse),
    .empty_flag (empty_flag),
    .dec_count  (dec_count),
    .buf_read   (buf_read),
    .alarm_empty(alarm_empty)
);

// -- Up/down counter --
updown_counter #(.N(3), .MAX(3)) u_counter (
    .clk  (clk),
    .rst  (rst),
    .inc  (inc_count),
    .dec  (dec_count),
    .count(Ccount)
);

// -- Global clock --
global_clock u_clk (
    .clk     (clk),
    .rst     (rst),
    .cur_time(cur_time)
);

// -- Timestamp buffer --
timestamp_buffer u_buf (
    .clk        (clk),
    .rst        (rst),
    .write_en   (buf_write),
    .read_en    (buf_read),
    .cur_time   (cur_time),
    .oldest_time(oldest_time),
    .fill_count (fill_count)
);

// -- Cost calculator --
cost_calculator u_cost (
    .clk        (clk),
    .rst        (rst),
    .calc_en    (buf_read),
    .cur_time   (cur_time),
    .oldest_time(oldest_time),
    .CCost      (CCost)
);

// -- 7-segment encoder: Ccount display (zero-extend 3-bit to 4-bit) --
seven_seg_encoder u_seg_count (
    .digit({1'b0, Ccount}),
    .seg  (seg_count)
);

// -- 7-segment encoder: CCost ones digit display --
seven_seg_encoder u_seg_cost (
    .digit(CCost % 10),     // display ones digit of cost
    .seg  (seg_cost)
);

endmodule
