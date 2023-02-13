module geofence (clk,
                 reset,
                 X,
                 Y,
                 valid,
                 is_inside);
    input clk;
    input reset;
    input [9:0] X;
    input [9:0] Y;
    output valid;
    output is_inside;
    
    localparam FALSE = 1'd0;
    localparam TRUE  = !FALSE;
    
    localparam STORE_NODE      = 3'd0;
    localparam STORE_FENCE     = 3'd1;
    localparam CACULATE_VECTOR = 3'd2;
    localparam FENCE_BUILD     = 3'd3;
    localparam ORDER_CHANGE    = 3'd4;
    localparam CACULATE_NODE   = 3'd5;
    localparam DETECT_NODE     = 3'd6;
    localparam CACULATE_OVER   = 3'd7;
    
    reg [2:0] cur_state, next_state;
    
    reg [2:0] node_ptr, node_ptr2;
    reg signed [10:0] cmp_node_x, cmp_node_y;
    reg signed [10:0] fence_node_x [5:0];
    reg signed [10:0] fence_node_y [5:0];
    reg p_n_flg, cross_start_flg;
    wire cross_cmp_flg, A_bigger_B_flg;
    reg signed [10:0] Ax, Bx, Ay, By;
    reg is_inside_tmp;
    integer i;

    assign is_inside = is_inside_tmp;
    assign valid = (cur_state == CACULATE_OVER) ? TRUE : FALSE;
    
    CrossProduct C0(
    .clk(clk),
    .reset(reset),
    .start_flg(cross_start_flg),
    .Ax(Ax),
    .Bx(Bx),
    .Ay(Ay),
    .By(By),
    .cmp_flg(cross_cmp_flg),
    .A_bigger_B_flg(A_bigger_B_flg));
    
    wire STORE_FENCE_flg     = (node_ptr == 3'd5) ? TRUE : FALSE;
    wire CACULATE_VECTOR_flg = (node_ptr == 3'd0) ? TRUE : FALSE;
    wire FENCE_BUILD_flg     = (cross_cmp_flg) ? TRUE : FALSE;
    wire ORDER_CHANGE_flg    = (node_ptr == 3'd4 && node_ptr2 == 3'd5) ? TRUE : FALSE;
    wire CACULATE_NODE_flg   = (cross_cmp_flg) ? TRUE : FALSE;
    wire DETECT_NODE_flg     = ((node_ptr != 0 && A_bigger_B_flg != p_n_flg) || (node_ptr == 3'd5)) ? TRUE : FALSE;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cur_state <= STORE_NODE;
        end
        else begin
            cur_state <= next_state;
        end
    end

    always @(*) begin
        case(cur_state)
            STORE_NODE : begin
                next_state = STORE_FENCE;
            end
            STORE_FENCE : begin
                next_state = (STORE_FENCE_flg) ? CACULATE_VECTOR : STORE_FENCE;
            end
            CACULATE_VECTOR : begin
                next_state = (CACULATE_VECTOR_flg) ? FENCE_BUILD : CACULATE_VECTOR;
            end
            FENCE_BUILD : begin
                next_state = (FENCE_BUILD_flg) ? ORDER_CHANGE : FENCE_BUILD;
            end
            ORDER_CHANGE : begin
                next_state = (ORDER_CHANGE_flg) ? CACULATE_NODE : FENCE_BUILD;
            end
            CACULATE_NODE : begin
                next_state = (CACULATE_NODE_flg) ? DETECT_NODE : CACULATE_NODE;
            end
            DETECT_NODE : begin
                next_state = (DETECT_NODE_flg) ? CACULATE_OVER : CACULATE_NODE;
            end
            CACULATE_OVER : begin
                next_state = STORE_NODE;
            end
        endcase
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cmp_node_x <= 11'd0;
            cmp_node_y <= 11'd0;
        end
        else begin
            case(cur_state)
                STORE_NODE : begin
                    cmp_node_x <= $signed({1'b0, X});
                    cmp_node_y <= $signed({1'b0, Y});
                end
                CACULATE_VECTOR : begin
                    if (node_ptr == 3'd5) begin
                        cmp_node_x <= cmp_node_x - $signed({1'b0, fence_node_x[0]});
                        cmp_node_y <= cmp_node_y - $signed({1'b0, fence_node_y[0]});
                    end
                end
                default: begin
                    cmp_node_x <= cmp_node_x;
                    cmp_node_y <= cmp_node_y;
                end
            endcase
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for(i = 0; i<6; i = i+1) begin
                fence_node_x[i] <= 11'd0;
                fence_node_y[i] <= 11'd0;
            end
        end
        else begin
            case(cur_state)
                STORE_FENCE : begin
                    fence_node_x[node_ptr] <= $signed({1'b0, X});
                    fence_node_y[node_ptr] <= $signed({1'b0, Y});
                end
                CACULATE_VECTOR : begin
                    fence_node_x[node_ptr] <= fence_node_x[node_ptr] - $signed({1'b0, fence_node_x[0]});
                    fence_node_y[node_ptr] <= fence_node_y[node_ptr] - $signed({1'b0, fence_node_y[0]});
                end
                ORDER_CHANGE : begin
                    if (!A_bigger_B_flg) begin //clock
                        fence_node_x[node_ptr]  <= fence_node_x[node_ptr2];
                        fence_node_x[node_ptr2] <= fence_node_x[node_ptr];
                        fence_node_y[node_ptr]  <= fence_node_y[node_ptr2];
                        fence_node_y[node_ptr2] <= fence_node_y[node_ptr];
                    end
                end
                default: begin
                    for(i = 0; i<6; i = i+1) begin
                        fence_node_x[i] <= fence_node_x[i] ;
                        fence_node_y[i] <= fence_node_y[i] ;
                    end
                end
            endcase
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            node_ptr <= 3'd0;
        end
        else begin
            case(cur_state)
                STORE_NODE : begin
                    node_ptr <= 3'd0;
                end
                STORE_FENCE : begin
                    if (node_ptr == 3'd5) begin
                        node_ptr <= 3'd5;
                    end
                    else begin
                        node_ptr <= node_ptr + 3'd1;
                    end
                end
                CACULATE_VECTOR : begin
                    if (node_ptr == 3'd0) begin
                        node_ptr <= 3'd1;
                    end
                    else begin
                        node_ptr <= node_ptr - 3'd1;
                    end
                end
                ORDER_CHANGE : begin
                    if (node_ptr == 3'd4 && node_ptr2 == 3'd5) begin
                        node_ptr <= 3'd0;
                    end
                    else if (node_ptr2 == 3'd5) begin
                        node_ptr <= node_ptr + 3'd1;
                    end
                    else begin
                        node_ptr <= node_ptr;
                    end
                end
                DETECT_NODE : begin
                    if (node_ptr == 3'd5) begin
                        node_ptr <= 3'd0;
                    end
                    else begin
                        node_ptr <= node_ptr + 3'd1;
                    end
                end
                default: begin
                    node_ptr <= node_ptr;
                end
            endcase
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            node_ptr2 <= 3'd1;
        end
        else begin
            case(cur_state)
                STORE_NODE : begin
                    node_ptr2 <= 3'd1;
                end
                CACULATE_VECTOR : begin
                    node_ptr2 <= 3'd2;
                end
                ORDER_CHANGE : begin
                    if (node_ptr2 == 3'd5 && node_ptr == 3'd4) begin
                        node_ptr2 <= 3'd1;
                    end
                    else if (node_ptr2 == 3'd5) begin
                        node_ptr2 <= node_ptr + 3'd2;
                    end
                    else begin
                        node_ptr2 <= node_ptr2 + 3'd1;
                    end
                end
                DETECT_NODE : begin
                    if (node_ptr2 == 3'd5) begin
                        node_ptr2 <= 3'd0;
                    end
                    else begin
                        node_ptr2 <= node_ptr2 + 3'd1;
                    end
                end
                default: begin
                    node_ptr2 <= node_ptr2;
                end
            endcase
        end
    end
    
    always @(*) begin
        case(cur_state)
            FENCE_BUILD : begin
                Ax              = fence_node_x[node_ptr];
                Bx              = fence_node_x[node_ptr2];
                Ay              = fence_node_y[node_ptr];
                By              = fence_node_y[node_ptr2];
                cross_start_flg = 1'b1;
            end
            CACULATE_NODE : begin
                Ax              = cmp_node_x - fence_node_x[node_ptr];
                Bx              = fence_node_x[node_ptr] - fence_node_x[node_ptr2];
                Ay              = cmp_node_y - fence_node_y[node_ptr];
                By              = fence_node_y[node_ptr] - fence_node_y[node_ptr2];
                cross_start_flg = 1'b1;
            end
            default: begin
                Ax              = 11'd0;
                Bx              = 11'd0;
                Ay              = 11'd0;
                By              = 11'd0;
                cross_start_flg = 1'd0;
            end
        endcase
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            p_n_flg <= FALSE;
        end
        else begin
            case(cur_state)
                STORE_NODE : begin
                    p_n_flg <= FALSE;
                end
                CACULATE_NODE : begin
                    p_n_flg <= p_n_flg;
                end
                DETECT_NODE : begin
                    if (node_ptr == 3'd0) begin
                        p_n_flg <= A_bigger_B_flg;
                    end
                    else begin
                        p_n_flg <= p_n_flg;
                    end
                end
                default: begin
                    p_n_flg <= FALSE;
                end
            endcase
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            is_inside_tmp <= FALSE;
        end
        else begin
            case(cur_state)
                STORE_NODE : begin
                    is_inside_tmp <= FALSE;
                end
                DETECT_NODE : begin
                    if(node_ptr == 3'd5) begin
                        is_inside_tmp <= TRUE;
                    end
                    else begin
                        is_inside_tmp <= FALSE;
                    end
                end
                CACULATE_OVER : begin
                    is_inside_tmp <= is_inside_tmp;
                end
                default: begin
                    is_inside_tmp <= FALSE;
                end
            endcase
        end
    end

endmodule
    
