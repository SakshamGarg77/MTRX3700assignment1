// whack_detect.v : generate a 1-cycle pulse when a switch toggles while its mole is on
module whack_detect
#(
    parameter integer WIDTH = 18
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              game_active,
    input  wire [WIDTH-1:0]  sw_stable,     // debounced switches
    input  wire [WIDTH-1:0]  active_mask,   // which mole is lit
    output reg  [WIDTH-1:0]  hit_pulse
);
    reg [WIDTH-1:0] sw_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_d1     <= {WIDTH{1'b0}};
            hit_pulse <= {WIDTH{1'b0}};
        end else begin
            sw_d1     <= sw_stable;
            // toggled = XOR of current vs previous sample
            hit_pulse <= (game_active ? (sw_stable ^ sw_d1) & active_mask : {WIDTH{1'b0}});
        end
    end
endmodule
