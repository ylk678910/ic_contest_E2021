module Mul (input clk,
            input reset,
            input signed [10:0] A,
            input signed [10:0] B,
            output signed [20:0] out);
    
    assign out = A * B;
endmodule
