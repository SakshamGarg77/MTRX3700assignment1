// ============================================================================
// top_whack_toggle.v : DE2/DE2-115 top: CLOCK_50, KEY[0] (active-low), LEDR[0]
// ============================================================================

module top_whack_toggle (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,        // KEY[0] used, active-low
    output reg  [17:0] LEDR        // LEDR[0] blinks
);

    // ------------------------------------------------------------------------
    // Button Debouncing and Edge Detection
    // ------------------------------------------------------------------------
    wire key0_db;  // 1 while stably pressed
    debounce #(.CLK_HZ(50_000_000), .DEBOUNCE_MS(10))
    u_db (
        .clk(CLOCK_50), 
        .btn_n(KEY[0]), 
        .db_level(key0_db)
    );

    reg key0_db_d;
    always @(posedge CLOCK_50) 
        key0_db_d <= key0_db;
    
    wire key0_rise = key0_db & ~key0_db_d;  // one-cycle pulse on press

    // ------------------------------------------------------------------------
    // Pause Control
    // ------------------------------------------------------------------------
    reg paused = 1'b0;
    always @(posedge CLOCK_50) begin
        if (key0_rise) 
            paused <= ~paused;
    end

    // ------------------------------------------------------------------------
    // Clock Generation
    // ------------------------------------------------------------------------
    wire tick1Hz;
    tickgen #(.CLK_HZ(50_000_000), .TICK_HZ(1))
    u_tick (
        .clk(CLOCK_50), 
        .tick(tick1Hz)
    );

    // ------------------------------------------------------------------------
    // LED Control
    // ------------------------------------------------------------------------
    // LEDR[0] toggles on tick when not paused
    always @(posedge CLOCK_50) begin
        if (!paused && tick1Hz)
            LEDR[0] <= ~LEDR[0];
    end

    // Clear other LEDs
    always @* begin
        LEDR[17:1] = 17'b0;
    end

endmodule
