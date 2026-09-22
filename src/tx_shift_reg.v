// =============================================================
// Module      : tx_shift_reg
// Owner       : Member 3
// Description : Parallel-to-Serial (PISO) shift register for the
//               TX path of the TDM 4-Channel Multiplexer/Demux.
//
//               Nhan mot byte 8-bit tu tdm_mux (mux_out) va xuat
//               ra tung bit mot theo thu tu MSB-first tren
//               serial_out (noi ra TDM_DATA).
//
// Rules followed (theo spec):
//   - Khong tao counter (bit_counter / channel_counter / byte_counter)
//   - Khong tao clock rieng, chi dung "clk" duy nhat
//   - Khong dung FSM (khong enum / state / next_state)
//   - Reset dong bo, active-high
//   - Thu tu uu tien: RESET > LOAD > SHIFT
//   - serial_out luon = tx_shift_reg[7] (MSB hien tai)
// =============================================================

module tx_shift_reg (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] mux_out,
    input  wire       load,
    output wire       serial_out
);

    // Ten internal register duoc doi thanh "tx_shift" de tranh
    // trung ten voi module "tx_shift_reg" (muc 26 cua spec).
    reg [7:0] tx_shift;

    always @(posedge clk) begin
        if (rst)
            tx_shift <= 8'h00;          // RESET: uu tien cao nhat
        else if (load)
            tx_shift <= mux_out;        // LOAD: nap byte moi (MSB se ra truoc)
        else
            tx_shift <= {tx_shift[6:0], 1'b0}; // SHIFT: dich trai, LSB moi = 0
    end

    // serial_out luon phan anh MSB hien tai cua thanh ghi
    assign serial_out = tx_shift[7];

endmodule
