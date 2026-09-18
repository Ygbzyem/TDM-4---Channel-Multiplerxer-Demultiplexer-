
module tdm_mux (
    input  wire [7:0] CH0,
    input  wire [7:0] CH1,
    input  wire [7:0] CH2,
    input  wire [7:0] CH3,
    input  wire [1:0] channel_select,
    output reg  [7:0] mux_out
);
    always @(*) begin
        case (channel_select)
            2'b00:   mux_out = CH0;
            2'b01:   mux_out = CH1;
            2'b10:   mux_out = CH2;
            2'b11:   mux_out = CH3;
            default: mux_out = 8'h00; 
        endcase
    end

endmodule
