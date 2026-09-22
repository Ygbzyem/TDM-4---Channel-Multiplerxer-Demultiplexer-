`timescale 1ns/1ps

module tb_rx_shift_reg;

    reg clk;
    reg rst;
    reg serial_in;
    reg byte_boundary;

    wire [7:0] rx_data;
    wire       byte_done;

    rx_shift_reg dut (
        .clk(clk),
        .rst(rst),
        .serial_in(serial_in),
        .byte_boundary(byte_boundary),
        .rx_data(rx_data),
        .byte_done(byte_done)
    );

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    task send_byte;

        input [7:0] data;

        integer i;

        begin

            for (i = 7; i >= 0; i = i - 1) begin

                serial_in = data[i];

                if (i == 0)
                    byte_boundary = 1'b1;
                else
                    byte_boundary = 1'b0;

                @(posedge clk);

                #1;

                if (i == 0) begin
                    if (rx_data !== data) begin
                        $display(
                            "ERROR: expected=%h got=%h",
                            data,
                            rx_data
                        );
                      $stop;
                    end
                    if (byte_done !== 1'b1) begin
                        $display(
                            "ERROR: byte_done should be 1"
                        );
                        $stop;
                    end
                end
                else begin
                    if (byte_done !== 1'b0) begin
                        $display(
                            "ERROR: byte_done should be 0"
                        );
                        $stop;
                    end
                end
            end
            serial_in = 1'b0;
            byte_boundary = 1'b0;
            @(posedge clk);
            #1;
            if (byte_done !== 1'b0) begin
                $display(
                    "ERROR: byte_done did not clear"
                );
                $stop;
            end
        end
    endtask

initial begin

    clk           = 1'b0;
    rst           = 1'b1;
    serial_in     = 1'b0;
    byte_boundary = 1'b0;

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    send_byte(8'hAA);
    send_byte(8'hCC);
    send_byte(8'hF0);
    send_byte(8'h0F);

    send_byte(8'h12);
    send_byte(8'h34);
    send_byte(8'h56);
    send_byte(8'h78);

    send_byte(8'h81);
    send_byte(8'hA5);

    $display("");
    $display("======================================");
    $display("PASS: RX SHIFT REGISTER TEST PASSED");
    $display("======================================");
    $display("");
    $finish;
end
endmodule
