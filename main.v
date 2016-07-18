module main(
    input clk,
    output [7:0] LED,
    
    input FDTI_DTR,
    output FDTI_RX,
    input FDTI_TX,
    output FDTI_CTS,
    
    output ALS_CS,
    input ALS_SDO,
    output ALS_SCK
);

reg [31:0] counter;

assign LED = counter[31:24];

always @(posedge clk) begin
    counter <= counter + 1'b1;
end

endmodule
