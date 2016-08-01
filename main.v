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

initial LED <= 8'b0;


reg [31:0] counter;

wire [15:0] data;

assign als_result = data[11:4];

assign initiate = 1'b0; //counter == 32'd50_000_000;

wire ready;

ALS #(.FQ_FACTOR(50)) als(
    .clk(clk),
    .initiate(initiate),
    .ready(ready),
    .data(data),
    .reset(1'b0),
    
    .ALS_CS(ALS_CS),
    .ALS_SDO(ALS_SDO),
    .ALS_SCK(ALS_SCK)
);

FTDI ftdi(.clk(clk),
          .reset(1'b0),
          .FTDI_DTR(FTDI_DTR),
          .FTDI_RX(FTDI_RX),
          .FTDI_TX(FTDI_TX),
          .FTDI_CTS(FTDI_CTS));

always @(posedge clk) begin
    if (counter == 32'd50_000_000) begin
        LED <= { FTDI_DTR, FTDI_TX, 6'b0 };
    end
end

always @(posedge clk) begin
    if (counter <= 32'd50_000_000)
        counter <= counter + 1'b1;
    else
        counter <= 32'b0;
end
    

endmodule
