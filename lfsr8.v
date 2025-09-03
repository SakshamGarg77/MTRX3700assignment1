// ============================================================================
// lfsr8.v : 8-bit Fibonacci LFSR, taps x^8 + x^6 + x^5 + x^4 + 1
// ============================================================================

module lfsr8 (
    input  wire clk,
    input  wire rst_n,
    input  wire step_en,
    output reg  [7:0] q
);

    // Feedback polynomial: x^8 + x^6 + x^5 + x^4 + 1
    wire fb = q[7] ^ q[5] ^ q[4] ^ q[3];

    // LFSR shift register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to non-zero seed
            q <= 8'h5A;
        end else if (step_en) begin
            // Shift left and insert feedback bit
            q <= {q[6:0], fb};
        end
    end

endmodule
