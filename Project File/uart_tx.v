module uart_tx #(
    parameter CLKS_PER_BIT = 5208, 	// 50MHz Clock / 9600 Baud rate
    parameter PARITY_TYPE  = 0    	// 0 = Even Parity, 1 = Odd Parity
)(
    input  wire       i_Clock,		// 50Hz Clock
    input  wire       i_Tx_DV,     	// Data Valid pulse to start transmission
    input  wire [7:0] i_Tx_Byte,   	// Data to transmit
    output reg        o_Tx_Active,	// Signals the tranmitter is active
    output reg        o_Tx_Serial,	// Transmitting wire
    output reg        o_Tx_Done		// Signals the end of transmission
);

    // State Machine States
    localparam s_IDLE          = 3'b000;	// Idle state
    localparam s_TX_START_BIT  = 3'b001;	// Transmitting start bit
    localparam s_TX_DATA_BITS  = 3'b010;	// Transmitting data bit
    localparam s_TX_PARITY_BIT = 3'b011; 	//	Transmitting Parity bit
    localparam s_TX_STOP_BIT   = 3'b100;	// Transmitting Stop bit
    localparam s_CLEANUP       = 3'b101;	// Cleanup state back to idle
    
    reg [2:0] r_SM_Main     = 0;		// State Variable
    reg [15:0] r_Clock_Count = 0;	// To hold clock counts
    reg [2:0] r_Bit_Index   = 0;		// The transmitting bit
    reg [7:0] r_Tx_Data     = 0;		// The byte that is being sent
    reg       r_Parity_Bit  = 0;

    always @(posedge i_Clock) begin
        case (r_SM_Main)
            s_IDLE: begin
                o_Tx_Serial <= 1'b1;  // Transmitter is High for Idle
                o_Tx_Done   <= 1'b0;
                r_Clock_Count <= 0;
                r_Bit_Index   <= 0;
                
                if (i_Tx_DV == 1'b1) begin
                    o_Tx_Active <= 1'b1;
                    r_Tx_Data   <= i_Tx_Byte;
                    
                    // Calculate parity immediately upon receiving the valid byte
                    if (PARITY_TYPE == 0) begin
                        r_Parity_Bit <= ^i_Tx_Byte;     // Even Parity via unary XOR
                    end else begin
                        r_Parity_Bit <= ~(^i_Tx_Byte);  // Odd Parity
                    end
                    
                    r_SM_Main   <= s_TX_START_BIT;
                end else begin
                    o_Tx_Active <= 1'b0;
                end
            end
            
            s_TX_START_BIT: begin
                o_Tx_Serial <= 1'b0; // Start bit is low
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    r_SM_Main     <= s_TX_DATA_BITS;
                end
            end
            
            s_TX_DATA_BITS: begin
                o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= s_TX_PARITY_BIT;
                    end
                end
            end
            
            s_TX_PARITY_BIT: begin
                o_Tx_Serial <= r_Parity_Bit; // Output the calculated parity bit
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    r_SM_Main     <= s_TX_STOP_BIT;
                end
            end
            
            s_TX_STOP_BIT: begin
                o_Tx_Serial <= 1'b1; // Stop bit is high
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    o_Tx_Done     <= 1'b1;
                    r_SM_Main     <= s_CLEANUP;
                end
            end
            
            s_CLEANUP: begin
                o_Tx_Active <= 1'b0;
                o_Tx_Done   <= 1'b1;
                r_SM_Main   <= s_IDLE;
            end
            
            default: r_SM_Main <= s_IDLE;
        endcase
    end
endmodule