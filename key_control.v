module key_control(clk, key, pressed, released);

input clk;
input key;
output pressed;
output released;

reg key_value = 1'b1, key_safe = 1'b1, key_delayed = 1'b1;
 
always @(posedge clk) begin
  key_value <= key;
  key_safe <= key_value;
  key_delayed <= key_safe;
end

assign pressed = key_delayed & ~key_safe;
assign released = ~key_delayed & key_safe; 

endmodule
