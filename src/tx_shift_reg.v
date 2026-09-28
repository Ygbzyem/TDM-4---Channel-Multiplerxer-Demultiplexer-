module tx_shift_reg (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] mux_out,
    input  wire       load,
    output wire       serial_out
);

    reg [7:0] tx_shift;

    always @(posedge clk) begin
        if (rst)
            tx_shift <= mux_out;
        else if (load)
            tx_shift <= mux_out;              // LOAD: parallel load new byte
        else
            tx_shift <= {tx_shift[6:0], 1'b0}; // SHIFT: shift left, MSB out first
    end

    // Combinational tap of current MSB -> stable for one full clock period
    // following the edge that produced it (see spec: cycle model).
    assign serial_out = tx_shift[7];

endmodule
