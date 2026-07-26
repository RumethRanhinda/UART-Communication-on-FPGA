module uart_top (
    input  wire       CLOCK_50, 
    input  wire       UART_RXD, 
    output wire       UART_TXD, 
    output wire [7:0] LED,
    output wire       PARITY_ERR_PIN // Map this to an unused GPIO pin!
);

    wire [7:0] w_Data_Byte;
    wire       w_Data_Valid;
    wire       w_Parity_Error;
    
    // Connect received byte to the 8 onboard LEDs
    assign LED = w_Data_Byte; 
    
    // Connect the error flag to our new physical output pin
    assign PARITY_ERR_PIN = w_Parity_Error;

    // Instantiate Receiver (with Parity matching)
    uart_rx #(
        .CLKS_PER_BIT(5208),
        .PARITY_TYPE(0) // 0 = Even
    ) RX_INST (
        .i_Clock(CLOCK_50),
        .i_Rx_Serial(UART_RXD),
        .o_Rx_DV(w_Data_Valid),
        .o_Rx_Byte(w_Data_Byte),
        .o_Rx_Parity_Error(w_Parity_Error) // Hook up the new port
    );

    // Instantiate Transmitter (with Parity matching)
    uart_tx #(
        .CLKS_PER_BIT(5208),
        .PARITY_TYPE(0) // 0 = Even
    ) TX_INST (
        .i_Clock(CLOCK_50),
        .i_Tx_DV(w_Data_Valid),        
        .i_Tx_Byte(w_Data_Byte),    
        .o_Tx_Active(),
        .o_Tx_Serial(UART_TXD),
        .o_Tx_Done()
    );

endmodule