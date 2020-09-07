`default_nettype none


// Simple pipeline for driving an LED panel with 1 bit RGB graphics.
//
// Client should instantiate the `led_main` module and define a
// `painter` module.  `painter` should be a strictly combinatoric
// module that maps <frame, subframe, x, y> into an RGB pixel value.

module top_level (
        input         CLK,
        input         BTN_N,
        output [15:0] LED_PANEL);

wire pll_clk;
wire pll_locked;
wire resetn;
wire reset;
reg   [2:0] led_rgb0;
reg   [2:0] led_rgb1;
reg   [4:0] led_addr;
wire        led_blank;
wire        led_latch;
wire        led_sclk;
wire [1:0]  blank;
wire [1:0]  latch;
wire [1:0]  sclk;
wire        P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10;
wire        P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10;

    // This panel has swapped red and blue wires.
    // assign {P1A3, P1A2, P1A1}              = led_rgb0;
    // assign {P1A9, P1A8, P1A7}              = led_rgb1;
assign {P1A1, P1A2, P1A3}              = led_rgb0;
assign {P1A7, P1A8, P1A9}              = led_rgb1;
assign {P1B10, P1B4, P1B3, P1B2, P1B1} = led_addr;
assign P1B7                            = led_blank;
assign P1B8                            = led_latch;
assign P1B9                            = led_sclk;
assign {P1A4, P1A10}                   = 0;
assign LED_PANEL = {P1B10, P1B9, P1B8, P1B7,  P1B4, P1B3, P1B2, P1B1,
                    P1A10, P1A9, P1A8, P1A7,  P1A4, P1A3, P1A2, P1A1};

led_driver driver
(
 .clk(pll_clk),
 .reset(reset),
 .led_rgb0(led_rgb0),
 .led_rgb1(led_rgb1),
 .led_addr(led_addr),
 .blank(blank),
 .latch(latch),
 .sclk(sclk));


pll_30mhz pll
(
 .clk_pin(CLK),
 .locked(pll_locked),
 .pll_clk(pll_clk));

button_debouncer db
(
 .clk(pll_clk),
 .button_pin(BTN_N),
 .level(resetn));


reset_logic rl
(
 .resetn(resetn),
 .pll_clk(pll_clk),
 .pll_locked(pll_locked),
 .reset(reset));

ddr led_blank_ddr(
        .clk(pll_clk),
        .data(blank),
        .ddr_pin(led_blank));

ddr led_latch_ddr(
        .clk(pll_clk),
        .data(latch),
        .ddr_pin(led_latch));

ddr led_sclk_ddr(
        .clk(pll_clk),
        .data(sclk),
        .ddr_pin(led_sclk));

endmodule


module button_debouncer (
        input  clk,
        input  button_pin,
        output level,
        output rising_edge,
        output falling_edge);

    localparam COUNT_BITS = 15;

    reg                  is_high;
    reg                  was_high;
    reg                  level_r;
    reg                  rising_edge_r;
    reg                  falling_edge_r;
    reg [COUNT_BITS-1:0] counter = 0;

    assign level        = level_r;
    assign falling_edge = rising_edge_r;
    assign rising_edge  = falling_edge_r;

    always @(posedge clk)
        if (counter != 0) begin
            counter            <= counter + 1;
            rising_edge_r      <= 0;
            falling_edge_r     <= 0;
            was_high           <= is_high;
        end
        else begin
            // was_high           <= is_high;
            is_high            <= button_pin;
            level_r            <= is_high;
            if (is_high != was_high) begin
                counter        <= 1;
                rising_edge_r  <= is_high;
                falling_edge_r <= ~is_high;
            end
        end

endmodule // button_debouncer



module reset_logic (
        input pll_clk,
        input pll_locked,
        input resetn,
        output reset);

    reg [3:0] count;
    wire reset_i;

    assign reset_i = ~count[3] | ~resetn;

    always @(posedge pll_clk or negedge pll_locked)
        if (~pll_locked)
            count <= 0;
        else if  (~count[3])
            count <= count + 1;

    SB_GB rst_gb (
        .USER_SIGNAL_TO_GLOBAL_BUFFER(reset_i),
        .GLOBAL_BUFFER_OUTPUT(reset));

endmodule // reset_logic


module ddr (
        input       clk,
        input [1:0] data,
        output      ddr_pin);

    SB_IO #(
        .PIN_TYPE(6'b010001)
    ) it (
        .PACKAGE_PIN(ddr_pin),
        .LATCH_INPUT_VALUE(1'b0),
        .INPUT_CLK(clk),
        .OUTPUT_CLK(clk),
        .D_OUT_0(data[0]),
        .D_OUT_1(data[1]));

endmodule // ddr
