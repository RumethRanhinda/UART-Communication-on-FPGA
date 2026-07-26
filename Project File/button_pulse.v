module button_pulse (
    input  wire i_Clock,
    input  wire i_Btn_Raw,  // KEY[0] Input
    output wire o_Pulse
);

    reg [2:0] r_Shift_Reg = 3'b111; // Initialize unpressed condition

    always @(posedge i_Clock) begin
        // Shift the button state through at each clock cycle
        r_Shift_Reg <= {r_Shift_Reg[1:0], i_Btn_Raw};
    end

    // Trigger a high pulse only at the falling edge of KEY[0] input 
    assign o_Pulse = (r_Shift_Reg[2] == 1'b1 && r_Shift_Reg[1] == 1'b0);

endmodule