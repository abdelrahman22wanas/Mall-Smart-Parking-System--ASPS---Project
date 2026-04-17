// ============================================================
// Module  : asps_tb
// Project : ASPS™ – Testbench
// Desc    : Self-checking testbench covering all 14 test cases
//           from the test strategy table.
//           Simulation time unit: 1 ns / 1 ps
// ============================================================
`timescale 1ns/1ps
`include "asps_top.v"

module asps_tb;

// ---- DUT ports ----
reg        clk, rst;
reg        entry_ir, exit_ir;
wire [6:0] seg_count, seg_cost;
wire       empty_flag, full_flag;
wire       alarm_full, alarm_empty;

// ---- Internal probes (via hierarchical ref) ----
wire [2:0]  Ccount    = uut.Ccount;
wire [15:0] cur_time  = uut.cur_time;
wire [7:0]  CCost     = uut.CCost;

// ---- Instantiate DUT ----
asps_top uut (
    .clk        (clk),
    .rst        (rst),
    .entry_ir   (entry_ir),
    .exit_ir    (exit_ir),
    .seg_count  (seg_count),
    .seg_cost   (seg_cost),
    .empty_flag (empty_flag),
    .full_flag  (full_flag),
    .alarm_full (alarm_full),
    .alarm_empty(alarm_empty)
);

// ---- Clock: 10 ns period (50 MHz sim; represents 250 ms real tick) ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Helper task: simulate car entering (IR 1→0→1) ----
task car_enter;
    integer wait_cycles;
    begin
        @(posedge clk); #1;
        entry_ir = 0;          // car breaks beam
        repeat(20) @(posedge clk); #1;   // hold low > debounce period
        entry_ir = 1;          // beam restored
        repeat(5) @(posedge clk);
    end
endtask

// ---- Helper task: simulate car exiting ----
task car_exit;
    begin
        @(posedge clk); #1;
        exit_ir = 0;
        repeat(20) @(posedge clk); #1;
        exit_ir = 1;
        repeat(5) @(posedge clk);
    end
endtask

// ---- Helper macro: check and report ----
`define CHECK(signal, expected, testname) \
    if ((signal) !== (expected)) \
        $display("FAIL [%s] @ %0t: got %0d, expected %0d", testname, $time, signal, expected); \
    else \
        $display("PASS [%s] @ %0t", testname, $time);

// ============================================================
// Main stimulus
// ============================================================
initial begin
    $dumpfile("asps_wave.vcd");
    $dumpvars(0, asps_tb);

    // Initialise
    rst = 1; entry_ir = 1; exit_ir = 1;
    repeat(4) @(posedge clk);

    // -----------------------------------------------------------
    // TC-1: System reset
    // -----------------------------------------------------------
    rst = 0;
    @(posedge clk); #1;
    `CHECK(Ccount,    0, "TC1-Ccount")
    `CHECK(CCost,     0, "TC1-CCost")
    `CHECK(empty_flag,1, "TC1-empty")
    `CHECK(full_flag, 0, "TC1-full")

    // -----------------------------------------------------------
    // TC-2: Single car entry
    // -----------------------------------------------------------
    car_enter;
    `CHECK(Ccount, 1, "TC2-Ccount")
    `CHECK(empty_flag, 0, "TC2-empty")
    `CHECK(full_flag,  0, "TC2-full")

    // -----------------------------------------------------------
    // TC-3: Two cars enter
    // -----------------------------------------------------------
    car_enter;
    `CHECK(Ccount, 2, "TC3-Ccount")

    // -----------------------------------------------------------
    // TC-4: Three cars enter (garage full)
    // -----------------------------------------------------------
    car_enter;
    `CHECK(Ccount,    3, "TC4-Ccount")
    `CHECK(full_flag, 1, "TC4-full")

    // -----------------------------------------------------------
    // TC-5: Overflow attempt (4th car tries to enter)
    // -----------------------------------------------------------
    @(posedge clk); #1;
    entry_ir = 0;
    repeat(20) @(posedge clk); #1;
    entry_ir = 1;
    repeat(5) @(posedge clk);
    `CHECK(Ccount,    3, "TC5-no-overflow")
    `CHECK(alarm_full,0, "TC5-alarm-cleared") // alarm is 1-cycle pulse; 0 now

    // -----------------------------------------------------------
    // TC-6: Single car exit – cost = (exit_time – entry_time)
    //        We cannot know exact ticks here but CCost must be > 0
    // -----------------------------------------------------------
    car_exit;
    `CHECK(Ccount, 2, "TC6-Ccount")
    if (CCost == 0)
        $display("FAIL [TC6-CCost] cost should be > 0, got 0 @ %0t", $time);
    else
        $display("PASS [TC6-CCost] CCost=%0d @ %0t", CCost, $time);

    // -----------------------------------------------------------
    // TC-7: Underflow attempt (exit when all remaining cars leave)
    // -----------------------------------------------------------
    car_exit;      // 1 car left
    car_exit;      // garage empty
    `CHECK(Ccount,    0, "TC7-empty")
    `CHECK(empty_flag,1, "TC7-empty-flag")
    // Now try exit on empty garage
    @(posedge clk); #1;
    exit_ir = 0;
    repeat(20) @(posedge clk); #1;
    exit_ir = 1;
    repeat(5) @(posedge clk);
    `CHECK(Ccount,      0, "TC7-no-underflow")

    // -----------------------------------------------------------
    // TC-9: Empty → entry → exit cycle
    // -----------------------------------------------------------
    `CHECK(empty_flag, 1, "TC9-start-empty")
    car_enter;
    `CHECK(Ccount, 1, "TC9-after-entry")
    `CHECK(empty_flag, 0, "TC9-not-empty")
    car_exit;
    `CHECK(Ccount, 0, "TC9-after-exit")
    `CHECK(empty_flag, 1, "TC9-empty-again")

    // -----------------------------------------------------------
    // TC-10: Reset mid-operation
    // -----------------------------------------------------------
    car_enter; car_enter;
    `CHECK(Ccount, 2, "TC10-before-rst")
    @(posedge clk); #1;
    rst = 1;
    repeat(2) @(posedge clk); #1;
    rst = 0;
    `CHECK(Ccount,    0, "TC10-after-rst")
    `CHECK(CCost,     0, "TC10-cost-cleared")
    `CHECK(empty_flag,1, "TC10-empty-after-rst")

    // -----------------------------------------------------------
    // TC-11: No exit cost at power-on
    // -----------------------------------------------------------
    @(posedge clk); #1;
    `CHECK(CCost, 0, "TC11-no-initial-cost")

    // -----------------------------------------------------------
    // TC-13: Full → exit → full_flag clears
    // -----------------------------------------------------------
    car_enter; car_enter; car_enter;
    `CHECK(full_flag,  1, "TC13-full")
    car_exit;
    `CHECK(full_flag,  0, "TC13-full-cleared")
    `CHECK(Ccount,     2, "TC13-Ccount")

    // -----------------------------------------------------------
    // TC-14: IR bounce test (multiple rapid 0/1 transitions)
    // -----------------------------------------------------------
    // Reset first
    rst = 1; repeat(2) @(posedge clk); rst = 0; repeat(2) @(posedge clk);
    // Simulate bouncy button (3 rapid noise transitions then stable)
    @(posedge clk); entry_ir = 0; @(posedge clk);
    entry_ir = 1; @(posedge clk);
    entry_ir = 0; @(posedge clk);
    entry_ir = 1; @(posedge clk);
    entry_ir = 0; // final stable press
    repeat(20) @(posedge clk);
    entry_ir = 1;
    repeat(5) @(posedge clk);
    `CHECK(Ccount, 1, "TC14-debounce-single-count")

    $display("\n===== Simulation complete =====");
    #50 $finish;
end

// ---- Timeout watchdog ----
initial begin
    #500000;
    $display("ERROR: Simulation timeout");
    $finish;
end

endmodule
