// ============================================================================
// score_bcd99.v : 2-digit BCD score counter (00..99), increments on hit_pulse_any.
// Resets to 00 on reset or start_pulse. Saturates at 99.
// ============================================================================

module score_bcd99 (
    input  wire clk,
    input  wire rst_n,         // active-low
    input  wire start_pulse,   // one-cycle pulse on KEY0 press
    input  wire game_active,
    input  wire hit_pulse_any, // OR of all per-mole hit pulses (1 cycle)
    output reg  [3:0] tens,    // BCD 0..9
    output reg  [3:0] ones     // BCD 0..9
);

    // Increment enable signal
    wire inc = game_active && hit_pulse_any;

    // BCD counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            tens <= 4'd0; 
            ones <= 4'd0;
        end else if (start_pulse) begin
            // Start pulse - reset score
            tens <= 4'd0; 
            ones <= 4'd0;
        end else if (inc) begin
            // Increment score with BCD arithmetic
            if (tens == 4'd9 && ones == 4'd9) begin
                // Saturate at 99
                tens <= 4'd9; 
                ones <= 4'd9;
            end else if (ones == 4'd9) begin
                // Ones digit overflow - increment tens
                ones <= 4'd0;
                tens <= tens + 4'd1;
            end else begin
                // Normal increment of ones digit
                ones <= ones + 4'd1;
            end
        end
    end

endmodule
