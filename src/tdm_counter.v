module tdm_counter (
    input  wire       clk,
    input  wire       rst,
    output reg  [4:0] bit_count,
    output wire [1:0] channel_select
);
    always @(posedge clk) begin
        if (rst)
            bit_count <= 5'd0;
        else if (bit_count == 5'd31)
            bit_count <= 5'd0;
        else
            bit_count <= bit_count + 5'd1;
    end
    assign channel_select = bit_count[4:3];
endmodule
