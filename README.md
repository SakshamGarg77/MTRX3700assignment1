# MTRX3700 Assignment 1 - Whack-a-Mole Game

## Project Overview
A complete Whack-a-Mole game implementation for the DE2-115 FPGA board using Verilog. The game features 18 moles, a 30-second timer, score tracking, and 7-segment display output.

## File Structure
```
MTRX3700assignment1/
├── README.md                           # This file
├── assignment1.qpf                     # Quartus project file
├── assignment1.qsf                     # Quartus settings file
├── seven_seg.qpf                       # Seven segment project file
├── seven_seg.qsf                       # Seven segment settings file
├── seven_seg.qws                       # Seven segment workspace file
├── DE2-115-PinAssignments.csv          # Pin assignment file
├── clk_en.v                            # Clock enable generator
├── lfsr8.v                             # Linear feedback shift register
└── output_files/                       # Generated output files
    ├── bin16_to_bcd.v                  # Binary to BCD converter
    ├── debounce.v                      # Switch debouncer
    ├── mole_scheduler_multi.v          # Mole scheduling state machine
    ├── score_bcd99.v                   # 2-digit BCD score counter
    ├── score_core.v                    # Basic score incrementer
    ├── seg7_hex.v                      # 7-segment display decoder
    ├── tickgen.v                       # Clock tick generator
    ├── top_whack_final.v               # Empty file
    ├── top_whack_step2.v               # Main game controller
    ├── top_whack_toggle.v              # Simple toggle demo
    └── whack_detect.v                  # Hit detection logic
```

## File Descriptions

### Root Level Files

#### `clk_en.v` - Clock Enable Generator
**Purpose**: Generates periodic enable pulses from a high-frequency clock.

**Functions**:
- `clk_en`: Main module that divides input clock to generate tick pulses
  - Parameters: `CLK_HZ` (input frequency), `TICK_HZ` (desired output frequency)
  - Outputs: Single-cycle pulse at specified frequency
  - Used for: 1ms and 1Hz timing signals

#### `lfsr8.v` - Linear Feedback Shift Register
**Purpose**: Generates pseudo-random numbers for mole selection.

**Functions**:
- `lfsr8`: 8-bit Fibonacci LFSR with polynomial x^8 + x^6 + x^5 + x^4 + 1
  - Inputs: Clock, reset, step enable
  - Outputs: 8-bit random value
  - Used for: Random mole selection

### Output Files Directory

#### `bin16_to_bcd.v` - Binary to BCD Converter
**Purpose**: Converts 16-bit binary numbers to 4-digit BCD representation.

**Functions**:
- `bin16_to_bcd`: Implements double-dabble algorithm
  - Inputs: 16-bit binary value
  - Outputs: 4 BCD digits (thousands, hundreds, tens, ones)
  - Algorithm: Shift-add-3 method for pure combinational conversion

#### `debounce.v` - Switch Debouncer
**Purpose**: Eliminates switch bounce by requiring stable input for multiple clock cycles.

**Functions**:
- `debounce_1bit`: Single-bit debouncer
  - Parameters: `STABLE_TICKS` (number of consecutive stable samples)
  - Logic: Counts stable samples, outputs when threshold reached
- `debounce`: Multi-bit vector debouncer
  - Parameters: `WIDTH` (number of bits), `STABLE_TICKS`
  - Implementation: Generates multiple single-bit debouncers

#### `mole_scheduler_multi.v` - Mole Scheduling State Machine
**Purpose**: Controls which mole is active and for how long.

**Functions**:
- `mole_scheduler_multi`: Main scheduling module
  - Parameters: `N_MOLES`, `MOLE_ON_MS`, `GAP_MS`
  - States: IDLE → ON → GAP → IDLE
  - Logic: Randomly selects mole, keeps active for specified time, then gap
  - Outputs: One-hot mask indicating active mole

#### `score_bcd99.v` - 2-Digit BCD Score Counter
**Purpose**: Tracks score in BCD format with saturation at 99.

**Functions**:
- `score_bcd99`: BCD counter with proper carry logic
  - Inputs: Clock, reset, start pulse, game active, hit pulse
  - Logic: Increments on hit, handles BCD arithmetic, saturates at 99
  - Outputs: Tens and ones digits in BCD format

#### `score_core.v` - Basic Score Incrementer
**Purpose**: Simple binary score counter that increments on any hit.

**Functions**:
- `score_core`: Basic 16-bit counter
  - Inputs: Clock, reset, start pulse, game active, hit pulse vector
  - Logic: Increments by 1 on any hit, resets on start or reset
  - Outputs: 16-bit binary score

#### `seg7_hex.v` - 7-Segment Display Decoder
**Purpose**: Converts 4-bit hex values to 7-segment display patterns.

**Functions**:
- `seg7_hex`: Lookup table for 7-segment patterns
  - Inputs: 4-bit nibble (0-F)
  - Outputs: 7-bit segment pattern {g,f,e,d,c,b,a}
  - Pattern: Active-low segments for DE2-115 displays

#### `tickgen.v` - Clock Tick Generator
**Purpose**: Generates periodic tick pulses from system clock.

**Functions**:
- `tickgen`: Clock divider with parameterizable output frequency
  - Parameters: `CLK_HZ`, `TICK_HZ`
  - Logic: Counts to division factor, generates single-cycle pulse
  - Used for: Various timing requirements

#### `top_whack_step2.v` - Main Game Controller
**Purpose**: Top-level module that integrates all game components.

**Functions**:
- **Clock Generation**: Creates 1ms and 1Hz timing signals
- **Button Processing**: Debounces KEY0 for start button, generates start pulse
- **Game Timer**: 30-second countdown timer with game state control
- **Switch Debouncing**: Debounces all 18 toggle switches
- **Random Generation**: LFSR for mole selection
- **Mole Scheduling**: Controls which mole is active
- **Hit Detection**: Detects switch toggles on active moles
- **Score Tracking**: Maintains game score
- **Display Output**: Drives LEDs and 7-segment displays
  - HEX0/HEX1: Score display (hex)
  - HEX6/HEX7: Timer display (decimal)
  - LEDR: Active mole indicators

#### `top_whack_toggle.v` - Simple Toggle Demo
**Purpose**: Basic demonstration of button debouncing and LED control.

**Functions**:
- **Button Debouncing**: Debounces KEY0 with edge detection
- **Pause Control**: Toggles pause state on button press
- **LED Control**: Blinks LEDR[0] at 1Hz when not paused
- **Clock Generation**: 1Hz tick generator

#### `whack_detect.v` - Hit Detection Logic
**Purpose**: Detects when a switch is toggled while its corresponding mole is active.

**Functions**:
- `whack_detect`: Hit detection module
  - Parameters: `WIDTH` (number of moles)
  - Logic: XORs current and previous switch states, ANDs with active mole mask
  - Outputs: One-cycle pulse for each valid hit

## Game Flow

1. **Initialization**: Reset sets all counters to zero, game inactive
2. **Start**: Press KEY0 to begin 30-second game timer
3. **Mole Selection**: Random mole becomes active for 900ms
4. **Hit Detection**: Toggle corresponding switch while mole is active
5. **Scoring**: Each valid hit increments score
6. **Display**: Score shown on HEX0/HEX1, timer on HEX6/HEX7
7. **End**: Game ends when timer reaches zero

## Hardware Connections

- **CLOCK_50**: 50MHz system clock
- **KEY[3:0]**: Push buttons (KEY0=start, KEY3=reset)
- **SW[17:0]**: Toggle switches (one per mole)
- **LEDR[17:0]**: Red LEDs (mole indicators)
- **HEX0-HEX7**: 7-segment displays (score and timer)

## Key Features

- **18 Moles**: Configurable number of moles
- **30-Second Timer**: Configurable game duration
- **Score Tracking**: 16-bit binary score with hex display
- **Random Selection**: LFSR-based mole selection
- **Debounced Inputs**: Clean switch and button handling
- **Real-time Display**: Live score and timer updates
