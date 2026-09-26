// =============================================================
// Module      : tx_shift_reg
// File        : TDM_Project/rtl/tx_shift_reg.v
// Author      : Member 3
// Description : TX Parallel-to-Serial (PISO) shift register.
//               Loads one 8-bit byte from mux_out, then serializes
//               it MSB-first onto serial_out, 1 bit per clock.
//
//               Interface, bit order and load/shift behavior follow
//               the locked Member 3 Design Specification exactly:
//                 - Synchronous, active-high reset
//                 - load = 1  -> tx_shift <= mux_out   (LOAD)
//                 - load = 0  -> shift left, LSB filled with 0 (SHIFT)
//                 - serial_out = tx_shift[7] (MSB-first)
//                 - No internal counter, no internal clock, no FSM
//                 - load is generated externally (system/top level,
//                   driven by tdm_counter timing) - NOT generated here
// =============================================================

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
            tx_shift <= 8'h00;
        else if (load)
            tx_shift <= mux_out;              // LOAD: parallel load new byte
        else
            tx_shift <= {tx_shift[6:0], 1'b0}; // SHIFT: shift left, MSB out first
    end

    // Combinational tap of current MSB -> stable for one full clock period
    // following the edge that produced it (see spec: cycle model).
    assign serial_out = tx_shift[7];

endmodule
