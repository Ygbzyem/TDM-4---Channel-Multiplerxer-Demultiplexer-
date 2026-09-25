module rx_shift_reg(
    input wire       clk,
    input wire       rst,
    input wire       serial_data,
    input wire       byte_boundary,

    output reg [7:0] rx_data,
    output reg       byte_done
);

    reg [7:0] rx_shift;

    always @(posedge clk) begin

        if (rst) begin

            rx_shift  <= 8'h00;
            rx_data   <= 8'h00;
            byte_done <= 1'b0;

        end
        else begin

            // byte_done chỉ có hiệu lực 1 clock
            byte_done <= 1'b0;

            // MSB-first shift
            rx_shift <= {
                rx_shift[6:0],
                serial_data
            };

            // System/TDM báo bit cuối byte
            if (byte_boundary) begin

                // Dùng giá trị shift MỚI
                rx_data <= {
                    rx_shift[6:0],
                    serial_data
                };

                byte_done <= 1'b1;

            end

        end

    end

endmodule
