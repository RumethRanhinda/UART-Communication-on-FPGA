module uart_rx #(
    parameter CLKS_PER_BIT = 5208, 	// 9600 Baud Rate
    parameter PARITY_TYPE  = 0    	// 0 = Even Parity, 1 = Odd Parity
)(
    input  wire       i_Clock,
    input  wire       i_Rx_Serial,
    output reg        o_Rx_DV,     
    output reg [7:0]  o_Rx_Byte,
    output reg        o_Rx_Parity_Error // Flags high if parity fails
);

    // State Machine States
    localparam s_IDLE          = 3'b000;	// Idle State
    localparam s_RX_START_BIT  = 3'b001;	// Reading Start bit
    localparam s_RX_DATA_BITS  = 3'b010;	// Reading data bits
    localparam s_RX_PARITY_BIT = 3'b011; 	// Reading parity bit
    localparam s_RX_STOP_BIT   = 3'b100;	// Reading stop bit
    localparam s_CLEANUP       = 3'b101;	// Revert to original
    
    reg [2:0] r_SM_Main     = 0;
    reg [15:0] r_Clock_Count = 0;
    reg [2:0] r_Bit_Index   = 0;
    reg        r_Expected_Parity = 0;	// Storing the read parity bit

    always @(posedge i_Clock) begin
        case (r_SM_Main)
            s_IDLE: begin
                o_Rx_DV           <= 1'b0;
                o_Rx_Parity_Error <= 1'b0;
                r_Clock_Count     <= 0;
                r_Bit_Index       <= 0;
					 
                if (i_Rx_Serial == 1'b0) begin	// If start bit is detected
                    r_SM_Main <= s_RX_START_BIT;
						  o_Rx_Byte	<= 8'b00000000;	// To avoid high impedance outputs
                end
            end
            
            s_RX_START_BIT: begin
                if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
                    if (i_Rx_Serial == 1'b0) begin		// Check if the transmitting line is still 0 at the middle of the pulse
                        r_Clock_Count <= 0;
                        r_SM_Main     <= s_RX_DATA_BITS;
                    end else begin
                        r_SM_Main <= s_IDLE;				// If not go back to idle
                    end
                end else begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end
            end
            
            s_RX_DATA_BITS: begin
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count          <= 0;
                    o_Rx_Byte[r_Bit_Index] <= i_Rx_Serial;
                    
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= s_RX_PARITY_BIT; // Move to Parity Check
                    end
                end
            end
            
            s_RX_PARITY_BIT: begin
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    
                    // Calculate what the parity should be based on received data
                    if (PARITY_TYPE == 0) begin
                        r_Expected_Parity = ^o_Rx_Byte;     // Even parity
                    end else begin
                        r_Expected_Parity = ~(^o_Rx_Byte);  // Odd parity
                    end
                    
                    // Compare expected parity to the actual bit on the wire
                    if (i_Rx_Serial != r_Expected_Parity) begin
                        o_Rx_Parity_Error <= 1'b1; // Data corrupted!
                    end else begin
                        o_Rx_Parity_Error <= 1'b0; // Data is safe
                    end
                    
                    r_SM_Main <= s_RX_STOP_BIT;
                end
            end
            
            s_RX_STOP_BIT: begin
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    // Only assert Data Valid if there was no parity error
                    if (o_Rx_Parity_Error == 1'b0) begin
                        o_Rx_DV <= 1'b1; 
                    end
                    r_Clock_Count <= 0;
                    r_SM_Main     <= s_CLEANUP;
                end
            end
            
            s_CLEANUP: begin
                o_Rx_DV   <= 1'b0;
                r_SM_Main <= s_IDLE;
            end
            
            default: r_SM_Main <= s_IDLE;
        endcase
    end
endmodule