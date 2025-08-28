// top_whack_final.v : Whack-a-Mole (DE2/DE2-115) with 30s timer & bidirectional whacks
module top_whack_final
#(
    parameter integer CLK_HZ       = 50_000_000,
    parameter integer GAME_SECONDS = 30,
    parameter integer N_MOLES      = 18,
    // tune these to slow/speed popups
    parameter integer MOLE_ON_MS   = 900,
    parameter integer GAP_MS       = 250
)(
    input  wire         CLOCK_50,          // 50 MHz
    input  wire [17:0]  SW,                // 18 toggle switches
    input  wire [3:0]   KEY,               // push buttons, ACTIVE-LOW
    output wire [17:0]  LEDR,              // 18 red LEDs (moles)
    output wire [6:0]   HEX0, HEX1,        // score (low/high nibble)
    output wire [6:0]   HEX6, HEX7         // time remaining (ones/tens)
);
    // resets: use KEY3 as async reset (active low)
    wire rst_n = KEY[3];

    // make some clock enables
    wire tick_1ms, tick_1hz;
    clk_en #(.CLK_HZ(CLK_HZ), .TICK_HZ(1000)) u_ms (.clk(CLOCK_50), .rst_n(rst_n), .tick(tick_1ms));
    clk_en #(.CLK_HZ(CLK_HZ), .TICK_HZ(1   )) u_1s (.clk(CLOCK_50), .rst_n(rst_n), .tick(tick_1hz));

    // debounced KEY0 -> start pulse (active-high on press)
    wire key0_raw = ~KEY[0]; // invert (active-high when pressed)
    wire key0_db;
    debounce #(.WIDTH(1), .STABLE_TICKS(10)) u_db_key0 (
        .clk(CLOCK_50), .rst_n(rst_n), .tick_en(tick_1ms),
        .din(key0_raw), .dout(key0_db)
    );
    reg key0_d1;
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) key0_d1 <= 1'b0;
        else        key0_d1 <= key0_db;
    end
    wire start_pulse = key0_db & ~key0_d1;

    // game timer 30s
    reg        game_active;
    reg [5:0]  sec_left;      // 0..60
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            game_active <= 1'b0;
            sec_left    <= 6'd0;
        end else begin
            if (start_pulse) begin
                game_active <= 1'b1;
                sec_left    <= GAME_SECONDS[5:0];
            end else if (game_active && tick_1hz) begin
                if (sec_left > 0)
                    sec_left <= sec_left - 6'd1;
                if (sec_left == 6'd1) // about to hit 0
                    game_active <= 1'b0;
            end
        end
    end

    // debounced switches (so toggling either way is clean)
    wire [N_MOLES-1:0] sw_db;
    debounce #(.WIDTH(N_MOLES), .STABLE_TICKS(8)) u_db_sw (
        .clk(CLOCK_50), .rst_n(rst_n), .tick_en(tick_1ms),
        .din(SW[N_MOLES-1:0]), .dout(sw_db)
    );

    // random source (step every ms so next mole is different)
    wire [7:0] rnd;
    lfsr8 u_rnd (.clk(CLOCK_50), .rst_n(rst_n), .step_en(tick_1ms), .q(rnd));

    // schedule moles
    wire [N_MOLES-1:0] active_mask;
    mole_scheduler_multi #(
        .N_MOLES(N_MOLES), .MOLE_ON_MS(MOLE_ON_MS), .GAP_MS(GAP_MS)
    ) u_sched (
        .clk(CLOCK_50), .rst_n(rst_n), .game_active(game_active), .tick_1ms(tick_1ms),
        .rnd(rnd), .active_mask(active_mask)
    );

    // detect whacks on either toggle edge
    wire [N_MOLES-1:0] hit_pulse;
    whack_detect #(.WIDTH(N_MOLES)) u_hit (
        .clk(CLOCK_50), .rst_n(rst_n), .game_active(game_active),
        .sw_stable(sw_db), .active_mask(active_mask), .hit_pulse(hit_pulse)
    );

    // score
    wire [15:0] score;
    score_core u_score (
        .clk(CLOCK_50), .rst_n(rst_n), .start_pulse(start_pulse),
        .game_active(game_active), .hit_pulse(hit_pulse), .score(score)
    );

    // drive LEDs: only show moles when active (off after game ends)
    assign LEDR[N_MOLES-1:0] = active_mask;
    // (unused LEDR bits, if any) are left unconnected

    // 7-seg: score on HEX0/HEX1 (hex)
    seg7_hex u_hex0 (.nib(score[3:0]),  .seg(HEX0));
    seg7_hex u_hex1 (.nib(score[7:4]),  .seg(HEX1));

    // 7-seg: seconds remaining on HEX6/HEX7 (decimal 0..30 using hex digits 0..9)
    wire [3:0] sec_tens = (sec_left / 10);
    wire [3:0] sec_ones = (sec_left % 10);
    seg7_hex u_hex6 (.nib(sec_ones), .seg(HEX6));
    seg7_hex u_hex7 (.nib(sec_tens), .seg(HEX7));
endmodule
