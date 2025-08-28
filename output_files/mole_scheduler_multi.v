// mole_scheduler_multi.v : choose 1 of N moles, keep ON then GAP, repeat
module mole_scheduler_multi
#(
    parameter integer N_MOLES      = 18,
    parameter integer MOLE_ON_MS   = 900,  // how long a mole stays ON
    parameter integer GAP_MS       = 250   // idle gap before next mole
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              game_active,
    input  wire              tick_1ms,
    // randomness
    input  wire [7:0]        rnd,
    output reg  [N_MOLES-1:0] active_mask
);
    localparam S_IDLE = 2'd0,
               S_ON   = 2'd1,
               S_GAP  = 2'd2;

    reg [1:0] state;
    reg [15:0] ms_cnt;

    // pick index 0..N_MOLES-1 from rnd
    wire [4:0] idx_raw = rnd[4:0];
    wire [4:0] idx_fit = (idx_raw >= N_MOLES[4:0]) ? (idx_raw - N_MOLES[4:0]) : idx_raw;

    // next mask helper
    wire [N_MOLES-1:0] onehot_next = ({{(N_MOLES){1'b0}}} | ({{(N_MOLES-1){1'b0}},1'b1} << idx_fit));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            ms_cnt      <= 16'd0;
            active_mask <= {N_MOLES{1'b0}};
        end else if (!game_active) begin
            state       <= S_IDLE;
            ms_cnt      <= 16'd0;
            active_mask <= {N_MOLES{1'b0}};
        end else if (tick_1ms) begin
            case (state)
                S_IDLE: begin
                    active_mask <= onehot_next;
                    ms_cnt      <= MOLE_ON_MS[15:0];
                    state       <= S_ON;
                end
                S_ON: begin
                    if (ms_cnt == 0) begin
                        active_mask <= {N_MOLES{1'b0}};
                        ms_cnt      <= GAP_MS[15:0];
                        state       <= S_GAP;
                    end else begin
                        ms_cnt <= ms_cnt - 16'd1;
                    end
                end
                S_GAP: begin
                    if (ms_cnt == 0) begin
                        state <= S_IDLE;
                    end else begin
                        ms_cnt <= ms_cnt - 16'd1;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
