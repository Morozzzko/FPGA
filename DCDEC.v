module DCDEC(in, out);
input [4:0] in;
output reg [6:0] out;

parameter A = 5'h10;
parameter D = 5'h11;
parameter E = 5'h12;
parameter L = 5'h13;
parameter O = 5'h14;
parameter O_SMALL = 5'h15;
parameter R = 5'h16;
parameter S = 5'h17;
parameter T = 5'h18;
parameter OFF = 5'h1F;


always @(in) begin
  case (in) 
    5'h00: out <= 7'b1000000;
    5'h01: out <= 7'b1111001;
    5'h02: out <= 7'b0100100;
    4'h03: out <= 7'b0110000;
    5'h04: out <= 7'b0011001;
    5'h05: out <= 7'b0010010;
    5'h06: out <= 7'b0000010;
    5'h07: out <= 7'b1111000;
    5'h08: out <= 7'b0000000;
    5'h09: out <= 7'b0010000;
    5'h0A: out <= 7'b0001000;
    5'h0B: out <= 7'b0000011;
    5'h0C: out <= 7'b1000110;
    5'h0D: out <= 7'b0100001;
    5'h0E: out <= 7'b0000110;
    5'h0F: out <= 7'b0001110;
    A: out <= 7'b0001000; 
    D: out <= 7'b0100001; 
    E: out <= 7'b0000110;
    L: out <= 7'b1000111;
    O: out <= 7'b1000000;
    O_SMALL: out <= 7'b0100011;
    R: out <= 7'b0101111; 
    S: out <= 7'b0010010; 
    T: out <= 7'b0000111; 
    OFF: out <= 7'b1111111;
    default: out <= 7'b1111111;
  endcase
end

endmodule
