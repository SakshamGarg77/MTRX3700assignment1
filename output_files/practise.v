Number 1

// Basically responsible for generating a 1 cycle pulse
// Our fpga clock is too fast for humans to see 
// we keep everythig in the same clock domain 
module clk_en
#(
    parameter integer CLK_HZ  = 50_000_000, // input clock frequency in Hz (actual board clock)
    parameter integer TICK_HZ = 1 // Our desired pulse rate in hz
)(
    input  wire clk, // our fast fpga clock (50Mhz)
    input  wire rst_n, // async reset
    output reg  tick // output - 1 clock cycle wide pulse
);
    // number of clock cycles per desired pulse 
         // we use localparam instead of parameter because we dont want this value to change at any point
    localparam integer DIV = (CLK_HZ/TICK_HZ);
         
         //free running counter
    reg [31:0] cnt;
     
          
         // synchronous logic with async active low reset
         //  On reset: clear counter tick=0
    //  Otherwise increment; when reaching DIV1, wrap and assert 1-cycle tick.
    always @(posedge clk or negedge rst_n) begin
         
        
        if (!rst_n) begin
                  
            cnt  <= 32'd0; // start countig from 0 
            tick <= 1'b0;   // when reset no tick
                                
                                
        end else begin
                  
            if (cnt == DIV-1) begin
                                
                                // case 1 - counter reached terminal count 
                cnt  <= 32'd0;  // wrap up counter
                tick <= 1'b1;   
            end else begin
                                //case 2 -  counter has not yet reached terminal count
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end
        end
    end
endmodule


Number 2

// lfsr8.v : 8-bit Fibonacci LFSR, taps x^8 + x^6 + x^5 + x^4 + 1
// purpose - produces a squence of semi random 8 bit values
// used to pick random leds 
//replacemnt for $random which is not sythesizable  
module lfsr8 (
    input  wire clk, // our main clock
    input  wire rst_n, // async reset active low
    input  wire step_en, 
    output reg  [7:0] q //current 8 bit shift reg value
);


    // this is the feedack bit - xor of selected taps from current q
         // zero biased indexing
    wire fb = q[7] ^ q[5] ^ q[4] ^ q[3];
     
          
         // Our squential logic
         // will reset asynchronously if rst_n goes low
    always @(posedge clk or negedge rst_n) begin
         
        if (!rst_n)
                  // all zero state would lock the lfsr 
                  q <= 8'h5A;       // 0x5A - 01011010        
        else if (step_en) 
                  
                  // When step_en=1: shift register left by 1
            // - q[6:0] move up into q[7:1]
            // - new bit (fb) enters q[0]
                  q <= {q[6:0], fb}; 
    end
endmodule


Number 3 

// main purpose - detect exactly one scoreable toggle 
// you get 1 cycle pulse when player hits the correct switch
//after teh correct toggle other toggles are ignored 
module whack_detect
#(
    parameter integer WIDTH = 18 // number or switches/ moles
)(
    input  wire              clk,
    input  wire              rst_n, // async reset
    input  wire              game_active, //game enable
    input  wire              spawn_pulse,     // from scheduler when a new mole spawns
    input  wire [WIDTH-1:0]  sw_stable,       // debounced switches
    input  wire [WIDTH-1:0]  active_mask,     // one-hot which mole is lit
    output reg               hit_pulse_once,  // 1cycle pulse only once per mole window
    output reg               scored_window    // holds 1 after a successful hit until next spawn
);


// previous sampled switch levels 
// we here sample every clk to detect either toggle using xor 
    reg [WIDTH-1:0] sw_d1;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
                  //on reset - clear all the history and outputs 
            sw_d1         <= {WIDTH{1'b0}};
            hit_pulse_once<= 1'b0;
            scored_window <= 1'b0;
                                
                                
                        
        end else begin
                  
                  // update prior sample register every clock for our edge detection 
            sw_d1         <= sw_stable;
            hit_pulse_once<= 1'b0;


            // Reset window score latch when a new mole appears or game stops
            if (spawn_pulse || !game_active) begin
                scored_window <= 1'b0;
            end else begin
                // edge [either direction] on the lit switch
                if (!scored_window) begin
                    if (|( (sw_stable ^ sw_d1) & active_mask )) begin
                        hit_pulse_once <= 1'b1;
                        scored_window  <= 1'b0 | 1'b1; // latch that this window has been scored
                    end
                end
            end
        end
    end
endmodule


Number 4


// hex nibble to active-low 7-seg {g,f,e,d,c,b,a}
// input - 4 bit nib 
// output - 7 bit segment (active low)
module seg7_hex (
    input  wire [3:0] nib, // 4 bit input value 
    output reg  [6:0] seg  // 7 seg outputs active low 
);
    always @* begin
        case (nib)
                  // we use a case statemnt here to map each hex value to its pattern 
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule




Number 5

// purpose - choose 1 mole and keep it on for MOLE_ON_MS
// repeat forever until game is active/on
// rnd here is a 8 bit LFSR value we take its low bits to choose an index
module mole_scheduler_multi
#(
    parameter integer N_MOLES      = 18,  // numbe rof leds 
    parameter integer MOLE_ON_MS   = 900,  // how long a mole stays ON
    parameter integer GAP_MS       = 250   // idle gap before next mole
)(
    input  wire                   clk,
    input  wire                   rst_n, // async reset 
    input  wire                   game_active, 
    input  wire                   tick_1ms,   // 1 ms strobe 
    input  wire [7:0]             rnd,           // randomness source
    output reg  [N_MOLES-1:0]     active_mask,   // one-hot active mole
    output reg                    spawn_pulse,   // 1-cycle pulse when new mole spawns
    output reg                    expire_pulse   // 1-cycle pulse when mole window ends
);


// why localparam? mentioned in a diff module
//FSM - IDLE - ON - GAP - IDLE
    localparam S_IDLE = 2'd0,
               S_ON   = 2'd1,
               S_GAP  = 2'd2;


    reg [1:0]  state;
    reg [15:0] ms_cnt; // ms count for ON/GAP durations 


    // pick index 0..N_MOLES-1 from rnd 
    wire [4:0] idx_raw = rnd[4:0];
    wire [4:0] idx_fit = (idx_raw >= N_MOLES[4:0]) ? (idx_raw - N_MOLES[4:0]) : idx_raw;
         
         // one hot mask with only idx_fit bit set 
    wire [N_MOLES-1:0] onehot_next = ({{(N_MOLES-1){1'b0}},1'b1} << idx_fit);


         
         
         
         
         
         // our main sequential process
         // 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
                  // hard reset - all off/idle
            state       <= S_IDLE;
            ms_cnt      <= 16'd0;
            active_mask <= {N_MOLES{1'b0}};
            spawn_pulse <= 1'b0;
            expire_pulse<= 1'b0;
                                
        end else if (!game_active) begin
                  
                  // if the game is not active force IDLE w no active mole 
            state       <= S_IDLE;
            ms_cnt      <= 16'd0;
            active_mask <= {N_MOLES{1'b0}};
            spawn_pulse <= 1'b0;
            expire_pulse<= 1'b0;
        end else begin
                  // default pulses to 0 each cycle 
            spawn_pulse  <= 1'b0;
            expire_pulse <= 1'b0;
            
                                
                                // drive our FSM only on the 1 ms strobe 
            if (tick_1ms) begin
                case (state)
                    S_IDLE: begin
                        active_mask <= onehot_next;
                        ms_cnt      <= MOLE_ON_MS[15:0]; // load on duration
                        state       <= S_ON;
                        spawn_pulse <= 1'b1;   // announce spawn 
                    end
                    S_ON: begin
                        if (ms_cnt == 0) begin
                                                                // times up for this mole - turn it off 
                            active_mask  <= {N_MOLES{1'b0}};
                            ms_cnt       <= GAP_MS[15:0]; // load GAP duration
                            state        <= S_GAP;
                            expire_pulse <= 1'b1;   // end of windoww
                        end else begin
                            ms_cnt <= ms_cnt - 16'd1;
                        end
                    end
                    S_GAP: begin
                        if (ms_cnt == 0) begin
                                                                // gap is over go back to idle and spawn next 
                            state <= S_IDLE;
                        end else begin
                            ms_cnt <= ms_cnt - 16'd1;
                        end
                    end
                    default: state <= S_IDLE;
                endcase
            end
        end
    end
endmodule





Number 6


// top_whack_final.v : Whack-a-Mole 
// - KEY0 (active-low) starts a 30 s game 
// - 18 LEDs act as moles one mole at a time
// - Score on HEX3..HEX0 = 0000..9999
// - Timer on HEX7..HEX6 
// - +5 bonus on every 3rd consecutive hit 


module top_whack_final #(
    parameter integer CLK_HZ       = 50_000_000,
    parameter integer GAME_SECONDS = 30,
    parameter integer N_MOLES      = 18,
    parameter integer MOLE_ON_MS   = 900,   // mole visible time 
    parameter integer GAP_MS       = 250    // gap between moles 
)(
    input  wire         CLOCK_50,
    input  wire [17:0]  SW,
    input  wire [3:0]   KEY,                 // active-LOW pushbuttons
    output wire [17:0]  LEDR,
    output wire [6:0]   HEX0, HEX1, HEX2, HEX3,  // SCORE  
    output wire [6:0]   HEX4, HEX5,             // unused=OFF
    output wire [6:0]   HEX6, HEX7              // TIMER  
);
   // Global reset use KEY3 
    wire rst_n = KEY[3];


    // Clock enables (1 ms and 1 Hz)
    wire tick_1ms, tick_1hz;
    clk_en #(.CLK_HZ(CLK_HZ), .TICK_HZ(1000)) u_ms (.clk(CLOCK_50), .rst_n(rst_n), .tick(tick_1ms));
    clk_en #(.CLK_HZ(CLK_HZ), .TICK_HZ(1   )) u_1s (.clk(CLOCK_50), .rst_n(rst_n), .tick(tick_1hz));


    // START button (KEY0) debounced 
    // DE2/DE2-115 boards wire KEY0 as active-low already.
    wire key0_db_n;  // debounced activelow: 0 = pressed
    debounce_button #(
        .CLK_HZ(50_000_000),
        .DEBOUNCE_US(50)      
    ) u_db_key0 (
        .clk   (CLOCK_50),
        .rst_n (rst_n),
        .button(KEY[0]),
        .button_pressed(key0_db_n)
    );


    // Generate start pulse on press 
    reg key0_db_n_d1;
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) key0_db_n_d1 <= 1'b1;
        else        key0_db_n_d1 <= key0_db_n;
    end
    wire start_pulse = (key0_db_n == 1'b0) && (key0_db_n_d1 == 1'b1);


    //  30 s game timer
    reg        game_active;
    reg [5:0]  sec_left;      
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            game_active <= 1'b0;
            sec_left    <= 6'd0;
        end else begin
            if (start_pulse) begin
                game_active <= 1'b1;
                sec_left    <= GAME_SECONDS[5:0];
            end else if (game_active && tick_1hz) begin
                if (sec_left > 0) sec_left <= sec_left - 6'd1;
                if (sec_left == 6'd1) game_active <= 1'b0;  // stop when reaching 0
            end
        end
    end


    // Debounced switches 
    wire [N_MOLES-1:0] sw_db;
    debounce_vec #(
        .WIDTH       (N_MOLES),
        .CLK_HZ      (50_000_000),
        .DEBOUNCE_US (8000)        // ~8 ms typical for slide switches
    ) u_db_sw (
        .clk (CLOCK_50),
        .rst_n(rst_n),
        .din (SW[N_MOLES-1:0]),
        .dout(sw_db)
    );


    // RNG 
    wire [7:0] rnd;
    lfsr8 u_rnd (.clk(CLOCK_50), .rst_n(rst_n), .step_en(tick_1ms), .q(rnd));


    //  Mole scheduler 
    wire [N_MOLES-1:0] active_mask;
    wire spawn_pulse, expire_pulse;
    mole_scheduler_multi #(
        .N_MOLES(N_MOLES),
        .MOLE_ON_MS(MOLE_ON_MS),
        .GAP_MS(GAP_MS)
    ) u_sched (
        .clk(CLOCK_50), .rst_n(rst_n),
        .game_active(game_active), .tick_1ms(tick_1ms),
        .rnd(rnd),
        .active_mask(active_mask),
        .spawn_pulse(spawn_pulse),
        .expire_pulse(expire_pulse)
    );


    //  Whack detect
    wire hit_once_pulse;
    wire window_scored;
    whack_detect #(.WIDTH(N_MOLES)) u_hit (
        .clk(CLOCK_50), .rst_n(rst_n), .game_active(game_active),
        .spawn_pulse(spawn_pulse),
        .sw_stable(sw_db), .active_mask(active_mask),
        .hit_pulse_once(hit_once_pulse),
        .scored_window(window_scored)
    );


    //  Streak bonus: +5 on every 3rd consecutive HIT 
    reg [1:0] streak;      // 0..2
    reg       bonus_pulse; // one-cycle when awarding +5
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            streak      <= 2'd0;
            bonus_pulse <= 1'b0;
        end else begin
            bonus_pulse <= 1'b0;  // default


            // Evaluate hit/miss at the end of a mole window
            if (expire_pulse && game_active) begin
                if (window_scored) begin
                    if (streak == 2'd2) begin
                        streak      <= 2'd0;   // 3rd in a row → award bonus and reset streak
                        bonus_pulse <= 1'b1;   // +5 this cycle
                    end else begin
                        streak <= streak + 2'd1;
                    end
                end else begin
                    streak <= 2'd0;            // miss resets streak
                end
            end
        end
    end


    //  Score (binary) with +1 and +5, saturate at 9999 
    wire [15:0] score_bin;
    score_bin_bonus u_score (
        .clk(CLOCK_50), .rst_n(rst_n), .start_pulse(start_pulse),
        .game_active(game_active),
        .hit_pulse(hit_once_pulse), .bonus_pulse(bonus_pulse),
        .score_bin(score_bin)
    );


    //  LEDs show the current mole 
    assign LEDR[N_MOLES-1:0] = active_mask;


    //  SCORE to HEX3..HEX0 (decimal, all four digits shown)
    wire [3:0] sc_th, sc_hu, sc_te, sc_on;
    bin16_to_bcd u_b2b (
        .bin (score_bin),
        .bcd3(sc_th),   // thousands
        .bcd2(sc_hu),   // hundreds
        .bcd1(sc_te),   // tens
        .bcd0(sc_on)    // ones
    );


    
seg7_hex u_hex0 (.nib(sc_on), .seg(HEX3));  // rightmost phys seg be HEX3
seg7_hex u_hex1 (.nib(sc_te), .seg(HEX2));
seg7_hex u_hex2 (.nib(sc_hu), .seg(HEX1));
seg7_hex u_hex3 (.nib(sc_th), .seg(HEX0));
    // TIMER on HEX7:HEX6 
    wire [3:0] t_tens = (sec_left / 10);
    wire [3:0] t_ones = (sec_left % 10);
    seg7_hex u_hex7 (.nib(t_tens), .seg(HEX7));
    seg7_hex u_hex6 (.nib(t_ones), .seg(HEX6));


    // Unused digits OFF 
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;


endmodule



Number 7


// purpose: 16-bit score, adds +1 on hit, +5 on bonus
// can count till 9999 (not possible to reach)


module score_bin_bonus (
    input  wire       clk,
    input  wire       rst_n,          // active-low
    input  wire       start_pulse,    // new game -> clear score
    input  wire       game_active,
    input  wire       hit_pulse,      // +1
    input  wire       bonus_pulse,    // +5
    output reg [15:0] score_bin
);
    wire [3:0] delta = (hit_pulse ? 4'd1 : 4'd0) + (bonus_pulse ? 4'd5 : 4'd0);
    wire [16:0] sum  = score_bin + delta;  // 17bit to catch overflow
    wire        at_max = (score_bin >= 16'd9999);


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score_bin <= 16'd0;
        end else if (start_pulse) begin
            score_bin <= 16'd0;
        end else if (game_active && (hit_pulse || bonus_pulse)) begin
            if (at_max) score_bin <= 16'd9999;
            else if (sum > 16'd9999) score_bin <= 16'd9999;
            else score_bin <= sum[15:0];
        end
    end
endmodule


Number 8

// purpose -  16-bit unsigned -> 4 BCD digits (thousands..ones), combinational
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




Number 9

// purpose -  Double register input to prevent metastability
module synchroniser (
    input  wire clk,     // system clock 
    input  wire rst_n,   // async reset, active-low
    input  wire din,     // raw asynchronous input
    output reg  dout     // synchronised output
);
    reg s1;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1   <= 1'b1;   // assume idle high
            dout <= 1'b1;
        end else begin
            s1   <= din;
            dout <= s1;
        end
    end
endmodule




Number 10

// purpose -  Debounce an ACTIVE-LOW pushbutton using a counter.
// Default: 50 MHz clock, 50 us debounce = 2500 counts 
module debounce_button #(
    parameter integer CLK_HZ       = 50_000_000,
    parameter integer DEBOUNCE_US  = 50,
    parameter integer DELAY_COUNTS = (CLK_HZ/1_000_000)*DEBOUNCE_US
)(
    input  wire clk,
    input  wire rst_n,
    input  wire button,          // raw active low: 0 = pressed
    output reg  button_pressed   // debounced active-low
);
    // 2FF synchroniser into 'clk' domain
    wire button_sync;
    synchroniser u_sync (
        .clk (clk), .rst_n(rst_n),
        .din (button),
        .dout(button_sync)
    );


    // Counter-based stability timer
    localparam integer W = (DELAY_COUNTS <= 1) ? 1 : $clog2(DELAY_COUNTS+1);
    reg [W-1:0] cnt;
    reg stable_level;  // candidate level being timed


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_pressed <= 1'b1;  // idle = not pressed
            stable_level   <= 1'b1;
            cnt            <= {W{1'b0}};
        end else begin
            if (button_sync == stable_level) begin
                if (cnt < DELAY_COUNTS[W-1:0]) cnt <= cnt + 1'b1;
                if (cnt == DELAY_COUNTS[W-1:0]) button_pressed <= stable_level;
            end else begin
                stable_level <= button_sync;      // saw a change, start timing new level
                cnt          <= {W{1'b0}};
            end
        end
    end
endmodule



Number 11


// as w etalked about in the lab we had to fix the multiple toggles at the same time this adderesses that
// a 2 FF synchroniser + counte rbit 




module debounce_level1 #(


    parameter integer CLK_HZ       = 50_000_000,                 // input clock freq 
    parameter integer DEBOUNCE_US  = 8000,                       // debounce time 
    parameter integer DELAY_COUNTS = (CLK_HZ/1_000_000)*DEBOUNCE_US
)(
    input  wire clk,     // system clock 
    input  wire rst_n,   // async reset
    input  wire din,     // asynchronous input 
    output reg  dout     // debounced level 
);
    
    wire din_sync;
    synchroniser u_sync (
        .clk (clk),
        .rst_n(rst_n),
        .din (din),
        .dout(din_sync)
    );


    //  Counter width large enough to count to DELAY_COUNTS
    
    localparam integer W = (DELAY_COUNTS <= 1) ? 1 : $clog2(DELAY_COUNTS+1);


    reg [W-1:0] cnt;         
    reg         stable_level;// candidate level we're timing toward acceptance


    // 3) Sequential logic: accept a new output only after a full stable window
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Choose safe reset defaults:
            //  - dout defaults low 
            //  - stable_level defaults low the first opposite level will restart timing
            dout         <= 1'b0;
            stable_level <= 1'b0;
            cnt          <= {W{1'b0}};


        end else begin
            if (din_sync == stable_level) begin
                // Still seeing the SAME level as our current candidate:
                // accumulate time until we reach the required stability window.
                if (cnt < DELAY_COUNTS[W-1:0])
                    cnt <= cnt + 1'b1;


               
                if (cnt == DELAY_COUNTS[W-1:0])
                    dout <= stable_level;


            end else begin
                // The input changed level (relative to our candidate):
                // start timing the NEW level from zero; don't change dout yet.
                stable_level <= din_sync;
                cnt          <= {W{1'b0}};
            end
        end
    end
endmodule






//  debounce WIDTH independent bits with the same timing params


module debounce_vec #(
    parameter integer WIDTH        = 1,             // number of inputs
    parameter integer CLK_HZ       = 50_000_000,    // shared clock
    parameter integer DEBOUNCE_US  = 8000,          // per-bit debounce in µs
    parameter integer DELAY_COUNTS = (CLK_HZ/1_000_000)*DEBOUNCE_US
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire [WIDTH-1:0]   din,   // raw inputs 
    output wire [WIDTH-1:0]   dout   // debounced outputs 
);
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : g_dbv
            debounce_level1 #(
                .CLK_HZ      (CLK_HZ),
                .DEBOUNCE_US (DEBOUNCE_US),
                .DELAY_COUNTS(DELAY_COUNTS)
            ) u_bit (
                .clk (clk),
                .rst_n(rst_n),
                .din (din[i]),
                .dout(dout[i])
            );
        end
    endgenerate
endmodule
