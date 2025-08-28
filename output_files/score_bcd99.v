// score_bcd99.v : 2-digit BCD score counter (00..99), increments on hit_pulse_any.
// Resets to 00 on reset or start_pulse. Saturates at 99.
module score_bcd99 (
    input  wire clk,
    input  wire rst_n,         // active-low
    input  wire start_pulse,   // one-cycle pulse on KEY0 press
    input  wire game_active,
    input  wire hit_pulse_any, // OR of all per-mole hit pulses (1 cycle)
    output reg  [3:0] tens,    // BCD 0..9
    output reg  [3:0] ones     // BCD 0..9
);
    wire inc = game_active && hit_pulse_any;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tens <= 4'd0; ones <= 4'd0;
        end else if (start_pulse) begin
            tens <= 4'd0; ones <= 4'd0;
        end else if (inc) begin
            if (tens == 4'd9 && ones == 4'd9) begin
                // saturate at 99
                tens <= 4'd9; ones <= 4'd9;
            end else if (ones == 4'd9) begin
                ones <= 4'd0;
                tens <= tens + 4'd1;
            end else begin
                ones <= ones + 4'd1;
            end
        end
    end
endmodule
