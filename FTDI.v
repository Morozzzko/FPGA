module FTDI(input clk,
            input reset,
            input [7:0] data,
            input initialize,
            input FTDI_DTR,
            output reg FTDI_RX = 1'b1,
            input FTDI_TX,
            output FTDI_CTS,
            output baud_tick,
            output reg [1:0] state_test);
parameter FREQUENCY = 4; // 50 MHz
parameter BAUD_RATE = 2; 
parameter BAUD_RG_WIDTH = 4; // floor(log_2(50_000_000)) + 1
parameter BAUD_INCREMENT_BY = (BAUD_RATE << BAUD_RG_WIDTH) / FREQUENCY;
        
localparam STATE_RESET = 2'b00;
localparam STATE_IDLE = 2'b01;
localparam STATE_SENDING = 2'b10; 

reg [1:0] state = STATE_RESET;
reg [3:0] data_counter = 3'b0;

reg [7:0] data_to_send = 8'b0;

always @(*) begin
    case (state)
        STATE_RESET: state_test <= 2'b00;
        STATE_IDLE: state_test <= 2'b01;
        STATE_SENDING: state_test <= 2'b10;
        default: state_test <= 2'b11;
    endcase
end

reg [BAUD_RG_WIDTH:0] baud_counter = 0;

assign baud_tick = baud_counter[BAUD_RG_WIDTH];

assign should_initialize = state == STATE_IDLE & FTDI_DTR & initialize;

assign FTDI_CTS = state == STATE_IDLE;


// data_counter
always @(posedge clk) begin
    case (state)
        STATE_SENDING: begin
            if (baud_tick) data_counter <= data_counter + 1'b1;
        end
        default: data_counter <= 4'b0;
    endcase
end

// data_to_send
always @(posedge clk) begin
    case (state) 
        STATE_RESET: data_to_send <= 8'b0;
        STATE_IDLE: if (should_initialize) data_to_send <= data;
    endcase
end

// baud rate generator

always @(posedge clk) begin
    baud_counter <= baud_counter[BAUD_RG_WIDTH-1:0] + BAUD_INCREMENT_BY;
end

// FSM

always @(posedge clk) begin
    case (state)
        STATE_RESET: state <= STATE_IDLE;
        STATE_IDLE: begin
            if (reset) state <= STATE_RESET;
            else if (should_initialize) state <= STATE_SENDING;
        end
        STATE_SENDING: begin
            if (reset) state <= STATE_RESET;
            else if (data_counter > 4'h9) state <= STATE_IDLE;
        end
    endcase
end

// FTDI_RX
always @(posedge clk) begin
    if (state == STATE_SENDING) begin
        case (data_counter)
            4'h0: FTDI_RX <= 1'b0; // start bit
            4'h1: FTDI_RX <= data_to_send[0];
            4'h2: FTDI_RX <= data_to_send[1];
            4'h3: FTDI_RX <= data_to_send[2];
            4'h4: FTDI_RX <= data_to_send[3];
            4'h5: FTDI_RX <= data_to_send[4];
            4'h6: FTDI_RX <= data_to_send[5];
            4'h7: FTDI_RX <= data_to_send[6];
            4'h8: FTDI_RX <= data_to_send[7];
            default: FTDI_RX <= 1'b1; // stop bit
        endcase
    end
    else begin
        FTDI_RX <= 1'b1;
    end
end

endmodule
