module main(
    input clk,
    output reg [7:0] LED,

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

initial LED <= 8'b0;

reg [1:0] state = STATE_RESET;
reg [1:0] state_previous = STATE_RESET;
reg [3:0] current_sensor = SENSOR_ALS; // Defaults to the first sensor
wire reset_sensors = state == STATE_IDLE && state_previous != STATE_IDLE;

reg [31:0] counter;

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

wire [1:0] ftdi_state;
wire baud_tick;

reg rs = 1'b1;

always @(posedge clk) if (counter > 32'd3) rs = 1'b0;

FTDI #(.FREQUENCY(50_000_000),
       .BAUD_RATE(2))
    ftdi(.clk(clk),
         .reset(rs),
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

always @(posedge clk) LED <= { FTDI_DTR, FTDI_TX, FTDI_RX, FTDI_CTS, ftdi_state, baud_tick, 1'b1 };

always @(posedge clk) begin
    if (counter <= 32'd50_000_000) begin
        counter <= counter + 1'b1;
    end
    else begin
        counter <= 32'b0;
    end
end

always @(posedge clk) begin // state_previous
  state_previous <= state;
end

always @(posedge clk) begin // FSM
  // todo: add conditions
    case (state)
        STATE_RESET: if (state_previous == STATE_RESET) state <= STATE_IDLE;
        STATE_IDLE: begin
          // general logic: go to STATE_MEASURE if
          // sensor is ready and initiate_sensor flag is set
          case (current_sensor)
            SENSOR_ALS: if (als_ready && initiate_sensor) state <= STATE_MEASURE;
          endcase
        end
        STATE_MEASURE: begin
          // general logic: go to STATE_TRANSMIT if
          // init_ftdi is up and ftdi_ready is true
          case (current_sensor)
            SENSOR_ALS: if (initiate_sensor) state <= STATE_TRANSMIT;
          endcase
        end
        STATE_TRANSMIT: begin
          // general logic: go to STATE_IDLE if
          // ftdi_ready is true

          // TODO
          
        end
        default: state <= STATE_RESET;
    endcase
end

always @(posedge clk) begin // initiate_sensor
  if (state == STATE_IDLE) begin
    case (current_sensor)
      SENSOR_ALS: initiate_sensor = als_ready;
    endcase
  end
  else begin
    initiate_sensor = 1'b0;
  end
end

always @(posedge clk) begin // initiate_ftdi
  if (state == STATE_MEASURE) begin
    case (current_sensor)
      SENSOR_ALS: if (als_ready && ~initiate_sensor) begin
      end
    endcase
  end
  else begin
    initiate_ftdi <= 1'b0;
  end
end

endmodule
