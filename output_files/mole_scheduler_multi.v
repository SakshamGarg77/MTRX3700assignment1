// ============================================================================
// mole_scheduler_multi.v : choose 1 of N moles, keep ON then GAP, repeat
// ============================================================================

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
    input  wire [7:0]        rnd,           // randomness input
    output reg  [N_MOLES-1:0] active_mask
);

    // State machine definitions
    localparam S_IDLE = 2'd0,
               S_ON   = 2'd1,
               S_GAP  = 2'd2;

    // Internal registers
    reg [1:0]  state;
    reg [15:0] ms_cnt;

    // Random mole selection logic
    wire [4:0] idx_raw = rnd[4:0];
    wire [4:0] idx_fit = (idx_raw >= N_MOLES[4:0]) ? (idx_raw - N_MOLES[4:0]) : idx_raw;

    // Generate one-hot mask for selected mole
    wire [N_MOLES-1:0] onehot_next = ({{(N_MOLES){1'b0}}} | ({{(N_MOLES-1){1'b0}},1'b1} << idx_fit));

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            state       <= S_IDLE;
            ms_cnt      <= 16'd0;
            active_mask <= {N_MOLES{1'b0}};
        end else if (!game_active) begin
            // Game inactive - return to idle
            state       <= S_IDLE;
            ms_cnt      <= 16'd0;
            active_mask <= {N_MOLES{1'b0}};
        end else if (tick_1ms) begin
            // Game active - process state machine
            case (state)
                S_IDLE: begin
                    // Select new mole and start ON timer
                    active_mask <= onehot_next;
                    ms_cnt      <= MOLE_ON_MS[15:0];
                    state       <= S_ON;
                end
                S_ON: begin
                    // Mole is active - countdown timer
                    if (ms_cnt == 0) begin
                        // Timer expired - turn off mole and start gap
                        active_mask <= {N_MOLES{1'b0}};
                        ms_cnt      <= GAP_MS[15:0];
                        state       <= S_GAP;
                    end else begin
                        // Continue countdown
                        ms_cnt <= ms_cnt - 16'd1;
                    end
                end
                S_GAP: begin
                    // Gap between moles - countdown timer
                    if (ms_cnt == 0) begin
                        // Gap expired - return to idle for next mole
                        state <= S_IDLE;
                    end else begin
                        // Continue countdown
                        ms_cnt <= ms_cnt - 16'd1;
                    end
                end
                default: 
                    state <= S_IDLE;
            endcase
        end
    end

endmodule
