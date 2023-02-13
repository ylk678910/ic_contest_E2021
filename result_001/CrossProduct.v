module CrossProduct (input clk,
                     input reset,
                     input start_flg,
                     input signed [10:0] Ax,
                     input signed [10:0] Bx,
                     input signed [10:0] Ay,
                     input signed [10:0] By,
                     output cmp_flg,
                     output reg A_bigger_B_flg);
    
    reg signed [10:0] Mul_A;
    reg signed [10:0] Mul_B;
    reg signed [20:0] tmp;
    wire signed [20:0] Mul_O;
    reg [1:0]timer;
    assign cmp_flg = (timer == 2'd3);
    
    Mul M0(
    .clk(clk),
    .reset(reset),
    .A(Mul_A),
    .B(Mul_B),
    .out(Mul_O));
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer <= 2'd0;
        end
        else if(!start_flg) begin
            timer <= 2'd0;
        end
        else if (start_flg) begin
            timer <= timer + 2'd1;
        end
        else begin
            timer <= 2'd0;
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Mul_A <= 11'b0;
            Mul_B <= 11'b0;
        end
        else if(!start_flg) begin
            Mul_A <= 11'b0;
            Mul_B <= 11'b0;
        end
        else if (start_flg) begin
            case(timer)
                2'd0: begin
                    Mul_A <= Bx;
                    Mul_B <= Ay;
                end
                2'd1: begin
                    Mul_A <= Ax;
                    Mul_B <= By;
                end
                2'd2: begin
                    Mul_A <= 11'd0;
                    Mul_B <= 11'd0;
                end
                default: begin
                    Mul_A <= 11'd0;
                    Mul_B <= 11'd0;
                end
            endcase
        end
        else begin
            Mul_A <= 11'd0;
            Mul_B <= 11'd0;
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tmp <= 21'd0;
        end
        else if(!start_flg) begin
            tmp <= 21'd0;
        end
        else if (start_flg) begin
            case(timer)
                2'd0: begin
                    tmp <= 21'd0;
                end
                2'd1: begin
                    tmp <= Mul_O;
                end
                2'd2: begin
                    tmp <= tmp;
                end
                default: begin
                    tmp <= 21'd0;
                end
            endcase
        end
        else begin
            tmp <= 21'd0;
        end
    end
    
    wire [20:0] div = $signed(tmp) - $signed(Mul_O);
    wire cmp = !div[20];
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            A_bigger_B_flg <= 1'd0;
        end
        else if(!start_flg) begin
            A_bigger_B_flg <= 1'd0;
        end
        else if (start_flg) begin
            if (timer == 2'd2) begin
                A_bigger_B_flg <= cmp;
            end
            else begin
                A_bigger_B_flg <= A_bigger_B_flg;
            end
        end
        else begin
            A_bigger_B_flg <= A_bigger_B_flg;
        end
    end
endmodule
