module tdm_demux (
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] rx_data,
    input  wire [1:0] channel_select,
    input  wire       byte_done,

    output reg  [7:0] CH0_OUT,
    output reg  [7:0] CH1_OUT,
    output reg  [7:0] CH2_OUT,
    output reg  [7:0] CH3_OUT
);

    always @(posedge clk) begin
        if (rst) begin
            CH0_OUT <= 8'b0;
            CH1_OUT <= 8'b0;
            CH2_OUT <= 8'b0;
            CH3_OUT <= 8'b0;
        end
        else if (byte_done) begin
            case (channel_select)
                2'b00: CH0_OUT <= rx_data;
                2'b01: CH1_OUT <= rx_data;
                2'b10: CH2_OUT <= rx_data;
                2'b11: CH3_OUT <= rx_data;
            endcase
        end
    end

endmodule

