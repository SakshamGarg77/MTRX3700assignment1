// ============================================================================
// score_core.v : increments by 1 on any hit; resets on start or reset
// ============================================================================

module score_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_pulse,
    input  wire       game_active,
    input  wire [17:0] hit_pulse,
    output reg  [15:0] score
);

    // Score counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            score <= 16'd0;
        end else if (start_pulse) begin
            // Start pulse - reset score
            score <= 16'd0;
        end else if (game_active && (|hit_pulse)) begin
            // Game active and hit detected - increment score
            score <= score + 16'd1;
        end
    end

endmodule
