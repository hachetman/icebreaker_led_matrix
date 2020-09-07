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
    localparam
        S_START   = 0,
        S_R1      = 1,
        S_R1E     = 2,
        S_R2      = 3,
        S_R2E     = 4,
        S_SHIFT0  = 5,
        S_SHIFT   = 6,
        S_SHIFTN  = 7,
        S_BLANK   = 8,
        S_UNBLANK = 9;

    // FM6126 Init Values
    localparam FM_R1     = 16'h7FFF;
    localparam FM_R2     = 16'h0040;


    wire  [4:0] addr;
    wire  [7:0] subframe;
    wire [12:0] frame;
    wire  [5:0] x;
    wire  [5:0] y0, y1;
    wire  [2:0] rgb0, rgb1;

    reg  [31:0] cnt;
    reg  [15:0] init_reg;
    reg   [6:0] init_lcnt;
    reg   [3:0] state;

    assign {frame, subframe, addr, x} = cnt;
    assign y0 = {1'b0, addr};
    assign y1 = {1'b1, addr};

    always @(posedge clk)
        if (reset) begin
            led_rgb0              <= 0;
            led_rgb1              <= 0;
            led_addr              <= 0;
            cnt                   <= 0;
            blank                 <= 2'b11;
            latch                 <= 2'b00;
            sclk                  <= 2'b00;
            state                 <= S_START;
        end
        else
            case (state)

                S_START:          // Exit reset; start shifting column data.
                    begin
                        blank     <= 2'b11; // blank until first row is latched
                        // Setup FM6126 init
                        init_reg  <= FM_R1;
                        init_lcnt <= 52;
                        state     <= S_R1;
                        // ChipOne panels can skip the init sequence
                        //state     <= S_SHIFT;
                    end

                // Setting FM6126 Registers
                S_R1:
                    begin
                        led_rgb0  <= init_reg[15] ? 3'b111 : 3'b000;
                        led_rgb1  <= init_reg[15] ? 3'b111 : 3'b000;
                        init_reg  <= {init_reg[14:0], init_reg[15]};

                        latch     <= init_lcnt[6] ? 2'b11 : 2'b00;
                        init_lcnt <= init_lcnt - 1;

                        cnt       <= cnt + 1;
                        sclk      <= 2'b10;

                        if (cnt[5:0] == 63) begin
                            state <= S_R1E;
                        end
                    end

                S_R1E:
                    begin
                        latch     <= 2'b00;
                        sclk      <= 2'b00;
                        init_reg  <= FM_R2;
                        init_lcnt <= 51;
                        state     <= S_R2;
                    end

                S_R2:
                    begin
                        led_rgb0  <= init_reg[15] ? 3'b111 : 3'b000;
                        led_rgb1  <= init_reg[15] ? 3'b111 : 3'b000;
                        init_reg  <= {init_reg[14:0], init_reg[15]};

                        latch     <= init_lcnt[6] ? 2'b11 : 2'b00;
                        init_lcnt <= init_lcnt - 1;

                        cnt       <= cnt + 1;
                        sclk      <= 2'b10;

                        if (cnt[5:0] == 63) begin
                            state <= S_R2E;
                        end
                    end

                S_R2E:
                    begin
                        latch      <= 2'b00;
                        sclk       <= 2'b00;
                        cnt        <= 0;
                        state      <= S_SHIFT;
                    end

                // Beginning of the data out "loop"
                S_SHIFT0:         // Shift first column.
                    begin
                        led_rgb0  <= rgb0;
                        led_rgb1  <= rgb1;
                        cnt       <= cnt + 1;
                        blank     <= 2'b00;
                        sclk      <= 2'b10;
                        state     <= S_SHIFT;
                    end

                S_SHIFT:          // Shift a column.
                    begin
                        led_rgb0  <= rgb0;
                        led_rgb1  <= rgb1;
                        cnt       <= cnt + 1;
                        sclk      <= 2'b10;
                        if (x == 62) // next column will be the last.
                            state <= S_SHIFTN;
                    end

                S_SHIFTN:         // Shift the last column; start BLANK.
                    begin
                        blank     <= 2'b01;
                        led_rgb0  <= rgb0;
                        led_rgb1  <= rgb1;
                        state     <= S_BLANK;
                    end

                S_BLANK:          // Drain shift register; pulse LATCH.
                    begin
                        blank     <= 2'b11;
                        latch     <= 2'b11;
                        sclk      <= 2'b00;
                        state     <= S_UNBLANK;
                    end

                S_UNBLANK:        // End BLANK; start next row.
                    begin
                        led_addr  <= addr;
                        cnt       <= cnt + 1;
                        blank     <= 2'b10;
                        latch     <= 2'b00;
                        state     <= S_SHIFT0;
                    end

            endcase

    painter paint0(
        .clk(clk),
        .reset(reset),
        .frame(frame),
        .subframe(subframe),
        .x(x[5:0]),
        .y(y0),
        .rgb(rgb0));

    painter paint1(
        .clk(clk),
        .reset(reset),
        .frame(frame),
        .subframe(subframe),
        .x(x[5:0]),
        .y(y1),
        .rgb(rgb1));

endmodule // led_driver
