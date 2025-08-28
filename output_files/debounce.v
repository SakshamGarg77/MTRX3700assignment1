// debounce.v : vector debouncer sampled by tick_en (e.g., 1 kHz)
// STABLE_TICKS is how many consecutive samples must match.
module debounce_1bit
#(
    parameter integer STABLE_TICKS = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire tick_en,   // sampling strobe (e.g., 1ms)
    input  wire din,
    output reg  dout
);
    reg [7:0] ctr;
    reg last;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr  <= 8'd0;
            last <= 1'b0;
            dout <= 1'b0;
        end else if (tick_en) begin
            if (din == last) begin
                if (ctr < STABLE_TICKS[7:0]) ctr <= ctr + 8'd1;
            end else begin
                ctr  <= 8'd0;
                last <= din;
            end

            if (ctr == STABLE_TICKS[7:0]) dout <= last;
        end
    end
endmodule

module debounce
#(
    parameter integer WIDTH        = 1,
    parameter integer STABLE_TICKS = 10
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              tick_en,
    input  wire [WIDTH-1:0]  din,
    output wire [WIDTH-1:0]  dout
);
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : g_db
            debounce_1bit #(.STABLE_TICKS(STABLE_TICKS)) u (
                .clk(clk), .rst_n(rst_n), .tick_en(tick_en),
                .din(din[i]), .dout(dout[i])
            );
        end
    endgenerate
endmodule
