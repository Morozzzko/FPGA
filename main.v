module main(
    input clk,
    input [3:0] KEY,
    output [6:0] HEX3,
    output [6:0] HEX2,
    output [6:0] HEX1,
    output [6:0] HEX0,
    output reg [7:0] LEDG,

    input FTDI_DTR,
    output FTDI_RX,
    input FTDI_TX,
    output FTDI_CTS,

    output ALS_CS,
    input ALS_SDO,
    output ALS_SCK
);

// Search for `case (current_sensor)` for the list of all
// places where you have to modify code to add new sensors
// The core concepts of sensors modules:
// 1. 8-bit data output
// 2. Done flag is raised once data is available
// 3. Done flag is not reset until a new query is run
// 4. Ready and done flags are not the same

parameter STATE_RESET = 2'b00;
parameter STATE_IDLE = 2'b01;
parameter STATE_MEASURE = 2'b10;
parameter STATE_TRANSMIT = 2'b11;
parameter SENSOR_ALS = 4'd0;

initial LEDG <= 8'b0;

reg [1:0] state = STATE_RESET;
reg [1:0] state_previous = STATE_RESET;
reg [3:0] current_sensor = SENSOR_ALS; // Defaults to the first sensor
wire reset_sensors = state == STATE_IDLE && state_previous != STATE_IDLE;


// ------------------------------------

wire OK_PRESSED;
wire OK_RELEASED;

key_control key3(.clk(clk),
                 .key(KEY[3]),
                 .pressed(OK_PRESSED),
                 .released(OK_RELEASED));


// ------------------------------------

localparam LETTER_A = 5'h10;
localparam LETTER_D = 5'h11;
localparam LETTER_E = 5'h12;
localparam LETTER_L = 5'h13;
localparam LETTER_O = 5'h14;
localparam LETTER_O_SMALL = 5'h15;
localparam LETTER_R = 5'h16;
localparam LETTER_S = 5'h17;
localparam LETTER_T = 5'h18;
localparam LETTER_OFF = 5'h1F;

reg [4:0] hex_data[0:3];

DCDEC #(.A(LETTER_A), 
        .D(LETTER_D), 
        .E(LETTER_E), 
        .L(LETTER_L), 
        .O(LETTER_O),
        .O_SMALL(LETTER_O_SMALL),
        .R(LETTER_R), 
        .S(LETTER_S), 
        .T(LETTER_T),
        .OFF(LETTER_OFF))
       hex3(.in(hex_data[3]),
            .out(HEX3));    

DCDEC #(.A(LETTER_A), 
        .D(LETTER_D), 
        .E(LETTER_E), 
        .L(LETTER_L), 
        .O(LETTER_O),
        .O_SMALL(LETTER_O_SMALL),
        .R(LETTER_R), 
        .S(LETTER_S),  
        .T(LETTER_T),
        .OFF(LETTER_OFF))
       hex2(.in(hex_data[2]),
            .out(HEX2));

DCDEC #(.A(LETTER_A), 
        .D(LETTER_D), 
        .E(LETTER_E), 
        .L(LETTER_L), 
        .O(LETTER_O),
        .O_SMALL(LETTER_O_SMALL),
        .R(LETTER_R), 
        .S(LETTER_S),  
        .T(LETTER_T),
        .OFF(LETTER_OFF))
       hex1(.in(hex_data[1]),
            .out(HEX1));

DCDEC #(.A(LETTER_A), 
        .D(LETTER_D), 
        .E(LETTER_E), 
        .L(LETTER_L), 
        .O(LETTER_O),
        .O_SMALL(LETTER_O_SMALL),
        .R(LETTER_R), 
        .S(LETTER_S),  
        .T(LETTER_T),
        .OFF(LETTER_OFF))
       hex0(.in(hex_data[0]),
            .out(HEX0));

// ------------------------------------


wire [7:0] als_result;

reg initiate_sensor = 1'b0;
reg initiate_ftdi = 1'b0;

wire als_ready, als_done;
wire ftdi_ready, ftdi_done;

ALS #(.FQ_FACTOR(50)) als(
    .clk(clk),
    .initiate(initiate_sensor && current_sensor == SENSOR_ALS),
    .ready(als_ready),
    .done(als_done),
    .data(als_result),
    .reset(reset_sensors),

    .ALS_CS(ALS_CS),
    .ALS_SDO(ALS_SDO),
    .ALS_SCK(ALS_SCK)
);

// ------------------------------------

wire [1:0] ftdi_state;
wire baud_tick;

FTDI #(.FREQUENCY(50_000_000),
       .BAUD_RATE(2))
    ftdi(.clk(clk),
         .reset(1'b0),
         .data(8'h4A),
         .FTDI_DTR(FTDI_DTR),
         .FTDI_RX(FTDI_RX),
         .FTDI_TX(FTDI_TX),
         .FTDI_CTS(FTDI_CTS),
         .initialize(initiate_ftdi),
         .baud_tick(baud_tick),
         .ready(ftdi_ready),
         .done(ftdi_done),
         .state_test(ftdi_state));

// ------------------------------------
always @(posedge clk) LEDG <= { FTDI_DTR, FTDI_TX, FTDI_RX, FTDI_CTS, ftdi_state, baud_tick, 1'b1 };

always @(posedge clk) begin // state_previous
  state_previous <= state;
end

// ------------------------------------
            
initial begin
  hex_data[3] <= LETTER_OFF;
  hex_data[2] <= LETTER_OFF;
  hex_data[1] <= LETTER_OFF;
  hex_data[0] <= LETTER_OFF;
end

always @(posedge clk) begin // hex_data
  case (state) 
    STATE_IDLE: begin
      hex_data[3] <= LETTER_P;
      hex_data[2] <= LETTER_R;
      hex_data[1] <= LETTER_OFF;
      hex_data[0] <= 5'd1;
    end
    default: begin
      hex_data[3] <= LETTER_OFF;
      hex_data[2] <= LETTER_OFF;
      hex_data[1] <= LETTER_OFF;
      hex_data[0] <= LETTER_OFF;
    end
  endcase
end

endmodule
