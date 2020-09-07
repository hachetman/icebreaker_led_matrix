module led_driver
  (
   input  wire        clk,
   input  wire        reset,
   output reg   [2:0] led_rgb0,
   output reg   [2:0] led_rgb1,
   output reg   [4:0] led_addr,
   output reg   [1:0] blank,
   output reg   [1:0] latch,
   output reg   [1:0] sclk);

// State machine.
enum {S_START, S_SHIFT, S_LATCH} state;
initial state = S_START;

reg [5:0] column_cnt;

always_ff @(posedge clk) begin
    if (reset) begin
        column_cnt   <= 0;
        state                 <= S_START;
    end
    else
      case (state)

          S_START:          // Exit reset; start shifting column data.
            begin
                state     <= S_SHIFT;
            end

          S_SHIFT:          // Shift a column.
            begin
                column_cnt <= column_cnt + 1;
                if (column_cnt == 63) // next column will be the last.
                      state <= S_LATCH;
            end

          S_LATCH:          // Drain shift register; pulse LATCH.
            begin
                state     <= S_SHIFT;
                led_addr  <= led_addr + 1;
                column_cnt <= 0;
            end

      endcase
end
always_comb begin
    led_rgb0 = 0;
    led_rgb1 = 0;
    blank = 0;
    sclk = 0;
    latch = 0;
    case (state)
          S_START:          // Exit reset; start shifting column data.
            begin
                blank     = 2'b11; // blank until first row is latched
            end
          S_SHIFT:          // Shift a column.
            begin
                led_rgb0  = {column_cnt[2:0]};
                led_rgb1  = {column_cnt[2:0]};
                sclk      = 2'b10;
            end

          S_LATCH:          // Drain shift register; pulse LATCH.
            begin
                blank     = 2'b10;
                latch     = 2'b10;
            end

    endcase
end
endmodule // led_driver
