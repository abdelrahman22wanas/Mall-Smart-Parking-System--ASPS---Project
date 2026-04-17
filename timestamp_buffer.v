// ============================================================
// Module  : timestamp_buffer
// Project : ASPS
// Desc    : FIFO buffer holding up to 3 entry timestamps.
//           write_en  : push cur_time on car entry.
//           read_en   : pop oldest timestamp on car exit;
//                       oldest_time holds the retrieved value.
// ============================================================
module timestamp_buffer (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_en,       // car entered
    input  wire        read_en,        // car exited
    input  wire [15:0] cur_time,       // current global tick
    output reg  [15:0] oldest_time,    // timestamp of oldest car
    output reg  [1:0]  fill_count      // 0-3 entries stored
);

reg [15:0] ts_buf [0:2];   // storage array (3 slots) — 'buf' is a Verilog keyword
integer i;

always @(posedge clk) begin
    if (rst) begin
        ts_buf[0] <= 0; ts_buf[1] <= 0; ts_buf[2] <= 0;
        oldest_time <= 0;
        fill_count  <= 0;
    end else begin
        // --- WRITE (push new timestamp to back) ---
        if (write_en && fill_count < 3) begin
            ts_buf[fill_count] <= cur_time;
            fill_count         <= fill_count + 1;
        end

        // --- READ (pop oldest entry = ts_buf[0], shift left) ---
        if (read_en && fill_count > 0) begin
            oldest_time <= ts_buf[0];
            for (i = 0; i < 2; i = i + 1)
                ts_buf[i] <= ts_buf[i+1];
            ts_buf[fill_count-1] <= 0;
            fill_count <= fill_count - 1;
        end
    end
end

endmodule
