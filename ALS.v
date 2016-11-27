module ALS(
    input clk,
    input initiate,
    input reset,
    output ready,
    output done,
    output reg [7:0] data,
   
    output reg ALS_CS = 1'b1,
    input ALS_SDO,
    output reg ALS_SCK = 1'b1
);

parameter FQ_FACTOR = 1; // DE0-Nano operates at 50 MHz, ALS requires 1-4 MHz
// sent to 1 for debugging purpose
parameter FQ_UPDATE_RATIO = FQ_FACTOR / 2; // How frequently invert ALS_SCK

parameter STATE_RESET = 2'b00;
parameter STATE_IDLE = 2'b01;
parameter STATE_READING = 2'b10;
parameter STATE_DONE = 2'b11;
   
reg [15:0] spi_data;
reg [5:0] fq_counter;
reg [1:0] state = STATE_RESET;
reg [3:0] spi_counter;
reg ALS_SCK_PREVIOUS;

assign ready = state == STATE_IDLE;
assign done = state == STATE_DONE;
assign ALS_SCK_POSEDGE = (ALS_SCK_PREVIOUS == 1'b0) && (ALS_SCK == 1'b1);
assign ALS_SCK_NEGEDGE = (ALS_SCK_PREVIOUS == 1'b1) && (ALS_SCK == 1'b0);
assign READING_DONE = spi_counter == 4'hF && ALS_SCK_POSEDGE;


// ALS_SCK_PREVIOUS

always @(posedge clk) begin
    if (state == STATE_RESET) begin
        ALS_SCK_PREVIOUS <= 1'b1;
    end
    else begin
        ALS_SCK_PREVIOUS <= ALS_SCK;
    end
end


/* Frequency division */

// fq_counter
always @(posedge clk) begin 
    if (state == STATE_RESET || fq_counter == FQ_UPDATE_RATIO) begin
        fq_counter <= 6'b0;
    end
    else begin
        fq_counter <= fq_counter + 1'b1;
    end
end

// ALS_SCK
always @(posedge clk) begin 
    if (state == STATE_RESET) begin
        ALS_SCK <= 1'b0;
    end
    else if (fq_counter == FQ_UPDATE_RATIO) begin
        ALS_SCK <= ~ALS_SCK;
    end
end

/* Reading data */

// ALS_CS
always @(posedge clk) begin
    if (state == STATE_RESET) begin
        ALS_CS <= 1'b1;
    end
    else if (state == STATE_IDLE && initiate) begin
        ALS_CS <= 1'b0;
    end
    else if (state == STATE_READING && READING_DONE) begin
        ALS_CS <= 1'b1;
    end
end

// spi_counter
always @(posedge clk) begin
    if (state == STATE_RESET || state == STATE_IDLE) begin
        spi_counter <= 4'b0;
    end
    else if (state == STATE_READING && ALS_SCK_NEGEDGE) begin
        spi_counter <= spi_counter + 1'b1;
    end
end

// data
always @(posedge clk) begin
    if (state == STATE_RESET) begin
        spi_data <= 16'b0;
    end
    else if(state == STATE_READING && ALS_SCK_POSEDGE) begin
        spi_data <= {spi_data[14:0], ALS_SDO};
    end
end

// state

always @(posedge clk) begin
    case (state) 
        STATE_RESET: state <= STATE_IDLE;
        STATE_IDLE: begin
            if (initiate) begin
                state <= STATE_READING;
            end
        end
        STATE_READING: begin
            if (READING_DONE) begin
                state <= STATE_DONE;
            end
        end
        default: state <= STATE_RESET;
    endcase
end

// data

initial data <= 8'd0;

always @(posedge clk) begin
  if (reset) begin
    data <= 8'd0;
  end 
  else if (state == STATE_READING && READING_DONE) begin
    data <= spi_data[11:4]; // indices found empirically
  end
end
endmodule
