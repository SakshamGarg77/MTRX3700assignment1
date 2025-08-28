// Generate a 1 Hz tick from 50 MHz (parameterizable)
module tickgen #(
    parameter CLK_HZ = 50_000_000,
    parameter TICK_HZ = 1
)(
    input  wire clk,
    output reg  tick = 1'b0
);
    localparam integer DIV = CLK_HZ/(2*TICK_HZ); // half period for clean toggle
    reg [$clog2(DIV)-1:0] cnt = 0;

    always @(posedge clk) begin
        if (cnt == DIV-1) begin
            cnt  <= 0;
            tick <= 1'b1;
        end else begin
            cnt  <= cnt + 1;
            tick <= 1'b0;
        end
    end
endmodule
