module main(
    input clk,
    input [3:0] KEY,
    output [6:0] HEX3,
    output [6:0] HEX2,
    output [6:0] HEX1,
    output [6:0] HEX0,
    output reg [7:0] LEDG,
    output reg [9:0] LEDR,

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

parameter STATE_RESET = 3'd0;
parameter STATE_IDLE = 3'd1;
parameter STATE_MEASURE = 3'd2;
parameter STATE_TRANSMIT = 3'd3;
parameter STATE_DONE = 3'd4;

parameter SENSOR_COUNT = 4'd1;
parameter SENSOR_ALS = 4'd0;

initial LEDR <= 10'b0;
initial LEDG <= 8'b0;

reg [2:0] state = STATE_RESET;
reg [2:0] state_previous = STATE_RESET;
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

wire initiate_sensors;

assign initiate_ftdi = state == STATE_TRANSMIT && state_previous != STATE_TRANSMIT;

wire als_ready, als_done;

ALS #(.FQ_FACTOR(50)) als(
    .clk(clk),
    .initiate(initiate_sensors),
    .ready(als_ready),
    .done(als_done),
    .data(als_result),
    .reset(reset_sensors),

    .ALS_CS(ALS_CS),
    .ALS_SDO(ALS_SDO),
    .ALS_SCK(ALS_SCK)
);

// ------------------------------------

localparam SENSORS_READY_VALUE = 1'b1;
wire sensors_ready = { als_ready }; // add more sensors when necessary
wire sensors_done = { als_done };
wire all_sensors_ready = sensors_ready == SENSORS_READY_VALUE;
assign initiate_sensors = OK_RELEASED && all_sensors_ready == SENSORS_READY_VALUE;

// ------------------------------------

wire [1:0] ftdi_state;
wire baud_tick;

wire ftdi_ready, ftdi_done;

reg [7:0] ftdi_data = 8'd0;

FTDI #(.FREQUENCY(50_000_000),
       .BAUD_RATE(9600))
    ftdi(.clk(clk),
         .reset(1'b0),
         .data(ftdi_data),
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

always @(posedge clk) begin
  if (state == STATE_MEASURE) begin
    case (current_sensor)
      SENSOR_ALS: ftdi_data <= als_result;
    endcase
  end
  else begin
    ftdi_data <= 8'd0;
  end
end

always @(posedge clk) begin
  case (state)
    STATE_RESET: if (state_previous == STATE_RESET) state <= STATE_IDLE;
    STATE_IDLE: begin
      if (OK_RELEASED && all_sensors_ready == SENSORS_READY_VALUE) begin
        state <= STATE_MEASURE;
      end
    end
    STATE_MEASURE: begin
      if (sensors_done) begin //(sensors_done[current_sensor]) begin
        state <= STATE_TRANSMIT;
      end
    end
    STATE_TRANSMIT: begin
      if (ftdi_done | 1'b1) begin
        if (current_sensor == SENSOR_COUNT) begin
          state <= STATE_DONE;
        end
        else begin
          state <= STATE_MEASURE;
        end
      end
    end
    STATE_DONE: begin
      if (OK_PRESSED) begin
        state <= STATE_IDLE;
      end
    end
  endcase
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
      hex_data[3] <= LETTER_R;
      hex_data[2] <= LETTER_D;
      hex_data[1] <= LETTER_OFF;
      hex_data[0] <= LETTER_OFF;
    end
    STATE_DONE: begin
      hex_data[3] <= LETTER_A;
      hex_data[2] <= LETTER_L;
      hex_data[1] <= { 1'd0, als_result[7:4] };
      hex_data[0] <= { 1'd0, als_result[3:0] };
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
