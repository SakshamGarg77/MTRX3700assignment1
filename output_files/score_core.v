// score_core.v : increments by 1 on any hit; resets on start or reset
module score_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_pulse,
    input  wire       game_active,
    input  wire [17:0] hit_pulse,
    output reg  [15:0] score
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) score <= 16'd0;
        else if (start_pulse) score <= 16'd0;
        else if (game_active && (|hit_pulse)) score <= score + 16'd1;
    end
endmodule
