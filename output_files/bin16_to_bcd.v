// bin16_to_bcd.v : 16-bit unsigned -> 4 BCD digits (thousands..ones)
// Double-dabble (shift-add-3) algorithm, purely combinational.
module bin16_to_bcd(
    input  wire [15:0] bin,
    output reg  [3:0]  bcd3,  // thousands
    output reg  [3:0]  bcd2,  // hundreds
    output reg  [3:0]  bcd1,  // tens
    output reg  [3:0]  bcd0   // ones
);
    integer i;
    reg [31:0] sh; // [31:28]=ones, [27:24]=tens, [23:20]=hundreds, [19:16]=thousands, [15:0]=bin

    always @* begin
        sh = {16'd0, bin};
        for (i=0; i<16; i=i+1) begin
            if (sh[31:28] >= 5) sh[31:28] = sh[31:28] + 4'd3; // ones
            if (sh[27:24] >= 5) sh[27:24] = sh[27:24] + 4'd3; // tens
            if (sh[23:20] >= 5) sh[23:20] = sh[23:20] + 4'd3; // hundreds
            if (sh[19:16] >= 5) sh[19:16] = sh[19:16] + 4'd3; // thousands
            sh = sh << 1;
        end
        bcd0 = sh[31:28];
        bcd1 = sh[27:24];
        bcd2 = sh[23:20];
        bcd3 = sh[19:16];
    end
endmodule
