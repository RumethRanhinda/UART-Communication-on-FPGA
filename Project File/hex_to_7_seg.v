module hex_to_7_seg (
    input  wire [3:0] i_Hex,
    input  wire       i_Parity_Err,
    output reg  [7:0] o_Segment // Order: {DP, G, F, E, D, C, B, A}
);

    always @(*) begin
        if (i_Parity_Err == 1'b1) begin
            // Parity Error: Turn ON only the Decimal Point (Bit 7)
            o_Segment = 8'b1_0000000; 
        end else begin
            case (i_Hex)
                //                  DP_GFEDCBA
                4'h0: o_Segment = 8'b0_0111111;	//0
                4'h1: o_Segment = 8'b0_0000110;	//1
                4'h2: o_Segment = 8'b0_1011011;	//2
                4'h3: o_Segment = 8'b0_1001111;	//3
                4'h4: o_Segment = 8'b0_1100110;	//4
                4'h5: o_Segment = 8'b0_1101101;	//5
                4'h6: o_Segment = 8'b0_1111101;	//6
                4'h7: o_Segment = 8'b0_0000111;	//7
                4'h8: o_Segment = 8'b0_1111111;	//8
                4'h9: o_Segment = 8'b0_1101111;	//9
                4'hA: o_Segment = 8'b0_1110111;	//A
                4'hB: o_Segment = 8'b0_1111100;	//b
                4'hC: o_Segment = 8'b0_0111001;	//C
                4'hD: o_Segment = 8'b0_1011110;	//d
                4'hE: o_Segment = 8'b0_1111001;	//E
                4'hF: o_Segment = 8'b0_1110001;	//F
                default: o_Segment = 8'b0_0111111;
            endcase
        end
    end

endmodule