`timescale 1ns/10ps

module tb_uart();
    // 50 MHz clock = 20ns period
    parameter c_CLOCK_PERIOD_NS = 20;
    parameter c_CLKS_PER_BIT    = 5208;

    reg r_Clock = 0;
    reg r_Tx_DV = 0;
    reg [7:0] r_Tx_Byte = 0;
    
    wire w_Tx_Serial;
    wire w_Tx_Done;
    wire w_Tx_Active;

    wire [7:0] w_Rx_Byte;
    wire w_Rx_DV;
    wire w_Rx_Parity_Error; 

    // Clock Generation
    always #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

    // Instantiate Transmitter (Configured for Even Parity)
    uart_tx #(
        .CLKS_PER_BIT(c_CLKS_PER_BIT),
        .PARITY_TYPE(0) // 0 = Even Parity
    ) TX_INST (
        .i_Clock(r_Clock),
        .i_Tx_DV(r_Tx_DV),
        .i_Tx_Byte(r_Tx_Byte),
        .o_Tx_Active(w_Tx_Active),
        .o_Tx_Serial(w_Tx_Serial),
        .o_Tx_Done(w_Tx_Done)
    );

    // Instantiate Receiver (Configured for Even Parity)
    uart_rx #(
        .CLKS_PER_BIT(c_CLKS_PER_BIT),
        .PARITY_TYPE(0) // 0 = Even Parity
    ) RX_INST (
        .i_Clock(r_Clock),
        .i_Rx_Serial(w_Tx_Serial), // Loopback connection
        .o_Rx_DV(w_Rx_DV),
        .o_Rx_Byte(w_Rx_Byte),
        .o_Rx_Parity_Error(w_Rx_Parity_Error) // Hook up the error flag
    );

    // Test Stimulus
    initial begin
        // Let the system stabilize
        #(c_CLOCK_PERIOD_NS * 10);

        // Send a test byte: 8'hAB (Binary: 10101011)
        @(posedge r_Clock);
        r_Tx_DV   <= 1'b1;
        r_Tx_Byte <= 8'hAB;
        
        @(posedge r_Clock);
        r_Tx_DV   <= 1'b0; // Pulse Data Valid for only one clock cycle

        // Wait for the TX module to finish sending the full 11-bit frame
        @(posedge w_Tx_Done);

        // Wait a few more clocks to ensure RX has processed the stop bit
        #(c_CLOCK_PERIOD_NS * 10);

        // Check the result
        if (w_Rx_Byte == 8'hAB && w_Rx_Parity_Error == 1'b0) begin
            $display("SUCCESS: Sent %h, Received %h, No Parity Error", 8'hAB, w_Rx_Byte);
        end else begin
            $display("ERROR: Sent %h, Received %h, Parity Error Flag: %b", 8'hAB, w_Rx_Byte, w_Rx_Parity_Error);
        end
		  
        #(c_CLOCK_PERIOD_NS * 50);

        @(posedge r_Clock);
        r_Tx_DV   <= 1'b1;
        r_Tx_Byte <= 8'hCD;
        
        @(posedge r_Clock);
        r_Tx_DV   <= 1'b0; // Turn off Data Valid pulse

        // Wait for it to finish sending
        @(posedge w_Tx_Done);

        // Wait for receiver to finish processing
        #(c_CLOCK_PERIOD_NS * 10);

        // End simulation
        #(c_CLOCK_PERIOD_NS * 5000);
        $stop;
    end
endmodule