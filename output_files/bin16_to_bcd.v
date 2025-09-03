// ============================================================================
// bin16_to_bcd.v : 16-bit unsigned -> 4 BCD digits (thousands..ones)
// Double-dabble (shift-add-3) algorithm, purely combinational.
// ============================================================================

module bin16_to_bcd(
    input  wire [15:0] bin,
    output reg  [3:0]  bcd3,  // thousands
    output reg  [3:0]  bcd2,  // hundreds
    output reg  [3:0]  bcd1,  // tens
    output reg  [3:0]  bcd0   // ones
);

    // Internal variables
    integer i;
    reg [31:0] sh; // [31:28]=ones, [27:24]=tens, [23:20]=hundreds, [19:16]=thousands, [15:0]=bin

    // Double-dabble conversion algorithm
    always @* begin
        // Initialise shift register with input binary value
        sh = {16'd0, bin};
        
        // Perform 16 iterations of shift-add-3 algorithm
        for (i = 0; i < 16; i = i + 1) begin
            // Add 3 to any BCD digit >= 5 before shifting
            if (sh[31:28] >= 5) sh[31:28] = sh[31:28] + 4'd3; // ones
            if (sh[27:24] >= 5) sh[27:24] = sh[27:24] + 4'd3; // tens
            if (sh[23:20] >= 5) sh[23:20] = sh[23:20] + 4'd3; // hundreds
            if (sh[19:16] >= 5) sh[19:16] = sh[19:16] + 4'd3; // thousands
            
            // Left shift the entire register
            sh = sh << 1;
        end
        
        // Extract BCD digits from final result
        bcd0 = sh[31:28];  // ones
        bcd1 = sh[27:24];  // tens
        bcd2 = sh[23:20];  // hundreds
        bcd3 = sh[19:16];  // thousands
    end

endmodule
