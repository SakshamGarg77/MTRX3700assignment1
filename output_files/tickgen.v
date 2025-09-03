// ============================================================================
// tickgen.v : Generate a 1 Hz tick from 50 MHz (parameterizable)
// ============================================================================

module tickgen #(
    parameter CLK_HZ = 50_000_000,
    parameter TICK_HZ = 1
)(
    input  wire clk,
    output reg  tick = 1'b0
);

    // Calculate division factor for desired tick rate
    localparam integer DIV = CLK_HZ/(2*TICK_HZ); // half period for clean toggle
    
    // Counter register
    reg [$clog2(DIV)-1:0] cnt = 0;

    // Tick generation logic
    always @(posedge clk) begin
        if (cnt == DIV-1) begin
            // Counter reached maximum - generate tick and reset
            cnt  <= 0;
            tick <= 1'b1;
        end else begin
            // Continue counting
            cnt  <= cnt + 1;
            tick <= 1'b0;
        end
    end

endmodule
