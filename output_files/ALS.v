module ALS(
    input clk,
    input initiate,
    output ready,
    output reg [15:0] data,
   
    output reg ALS_CS,
    input ALS_SDO,
    output reg ALS_SCK
);

localparam FQ_FACTOR = 50; // DE0-Nano operates at 50 MHz, ALS requires 1-4 MHz
localparam FQ_UPDATE_RATIO = FQ_FACTOR / 2; // How frequent to invert ALS_SCK

localparam STATE_RESET = 2'b00;
localparam STATE_IDLE = 2'b01;
localparam STATE_READING = 2'b10;

reg [5:0] fq_counter;
reg [1:0] state = STATE_RESET;
reg [3:0] spi_counter;
reg ALS_SCK_PREVIOUS;

assign ready = state == STATE_IDLE;
assign ALS_SCK_POSEDGE = (ALS_SCK_PREVIOUS == 1'b0) && (ALS_SCK == 1'b1);
assign ALS_SCK_NEGEDGE = (ALS_SCK_PREVIOUS == 1'b1) && (ALS_SCK == 1'b0);
assign READING_DONE = spi_counter = 4'hF && ALS__SCK_POSEDGE;

// ALS_SCK_PREVIOUS

always @(posedge clk) begin
    if (state == STATE_RESET) begin
        ALS_SCK_PREVIOUS <= 1'b1;
    end
    else begin
        if (ALS_SCK == ALS_SCK_PREVIOUS) begin
            ALS_SCK_PREVIOUS <= ~ALS_SCK_PREVIOUS;
        end
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
    else if (state == STATE_READING && 1'b0) begin // TODO: ADD CONDITION TO LEAVE
        ALS_CS <= 1'b1;
    end
end

// spi_counter
always @(posedge clk) begin
    if (state == STATE_RESET) begin
        spi_counter <= 4'b0;
    end
    else if (state == STATE_READING && ALS_SCK_NEGEDGE) begin
        spi_counter <= spi_counter + 1'b1;
    end
end

// data

always @(posedge clk) begin
    if (state == STATE_RESET) begin
        spi_counter <= 4'b0;
    end
    else if(state == STATE_READING && ALS_SCK_POSEDGE) begin
        data <= {data[15:1], ALS_SDO};
    end
end

endmodule
