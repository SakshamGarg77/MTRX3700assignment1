// clk_en.v : generate a 1-cycle enable pulse at TICK_HZ from CLK_HZ
module clk_en
#(
    parameter integer CLK_HZ  = 50_000_000,
    parameter integer TICK_HZ = 1
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick
);
    localparam integer DIV = (CLK_HZ/TICK_HZ);
    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 32'd0;
            tick <= 1'b0;
        end else begin
            if (cnt == DIV-1) begin
                cnt  <= 32'd0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end
        end
    end
endmodule
