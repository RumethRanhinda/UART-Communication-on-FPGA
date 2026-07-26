module uart_top_fpga (
    input  wire       CLOCK_50,   // 50MHz Onboard Clock
    input  wire       KEY_0,      // TX Trigger Button
    input  wire       KEY_1,      // Display Reset Button
    input  wire [3:0] SW,         // 4 Onboard DIP Switches
    input  wire       UART_RXD,   // Serial RX
    output wire       UART_TXD,   // Serial TX 
    output wire [7:0] SEG_OUT     // 7-Segment Display Output
);

    wire       w_Tx_Trigger;
    wire [7:0] w_Rx_Byte;
    wire       w_Rx_DV;
    wire       w_Parity_Error;

    // Display Holding Registers (Memory Latch)
    // Initialized to 0 so the display turns on showing '0'
    reg [3:0] r_Display_Hex = 4'h0; 
    reg       r_Display_Err = 1'b0; 

    // Button Edge Detector 
    button_pulse BTN_INST (
        .i_Clock(CLOCK_50),
        .i_Btn_Raw(KEY_0),
        .o_Pulse(w_Tx_Trigger)
    );

    // UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(5208),        // 9600 Baud rate
        .PARITY_TYPE(0)             // 0 = Even Parity
    ) TX_INST (
        .i_Clock(CLOCK_50),
        .i_Tx_DV(w_Tx_Trigger),        
        .i_Tx_Byte({4'b0000, SW}),  // Pad the 4 switches with 4 bits of leading zeros
        .o_Tx_Active(),
        .o_Tx_Serial(UART_TXD),
        .o_Tx_Done()
    );

    // UART Receiver
    uart_rx #(
        .CLKS_PER_BIT(5208),        // 9600 Baud rate
        .PARITY_TYPE(0)             // 0 = Even Parity
    ) RX_INST (
        .i_Clock(CLOCK_50),
        .i_Rx_Serial(UART_RXD),
        .o_Rx_DV(w_Rx_DV),
        .o_Rx_Byte(w_Rx_Byte),
        .o_Rx_Parity_Error(w_Parity_Error)
    );

    // Memory Latch & Reset Logic
    always @(posedge CLOCK_50) begin
        if (KEY_1 == 1'b0) begin 
            // Reset button pressed: clear display to 0 and clear errors
            r_Display_Hex <= 4'h0;
            r_Display_Err <= 1'b0;
            
        end else if (w_Parity_Error == 1'b1) begin
            // If the receiver flags a parity error, immediately latch the error state.
            // Entirely ignore w_Rx_Byte.
            r_Display_Err <= 1'b1;
            
        end else if (w_Rx_DV == 1'b1) begin
            // Only triggers if the receiver confirms the frame is 100% clean.
            r_Display_Hex <= w_Rx_Byte[3:0];
            r_Display_Err <= 1'b0;
        end
    end

    // 7-Segment Decoder
    // Driven by the Memory Latch
    hex_to_7_seg DISPLAY_INST (
        .i_Hex(r_Display_Hex),    
        .i_Parity_Err(r_Display_Err),
        .o_Segment(SEG_OUT)
    );

endmodule