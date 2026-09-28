// =============================================================
// Testbench : tb_tx_shift_reg
// Purpose   : Verify tx_shift_reg.v against Member 3 spec section 27/28
//             (independent byte tests) and confirm the MSB-first
//             serial sequence + reset behavior + timing (no bit loss).
// =============================================================
`timescale 1ns/1ps

module tb_tx_shift_reg;

    reg        clk;
    reg        rst;
    reg  [7:0] mux_out;
    reg        load;
    wire       serial_out;

    integer errors = 0;

    tx_shift_reg dut (
        .clk       (clk),
        .rst       (rst),
        .mux_out   (mux_out),
        .load      (load),
        .serial_out(serial_out)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Load one byte, then capture 8 serial bits (MSB-first) into `captured`,
    // sampling on the same posedge clk RX would use.
    task send_byte(input [7:0] byte_in, input [7:0] expected);
        integer i;
        reg [7:0] captured;
        begin
            // LOAD phase: pulse load for exactly 1 clock
            @(negedge clk);
            mux_out = byte_in;
            load    = 1'b1;
            @(negedge clk);   // after this, LOAD edge has occurred
            load    = 1'b0;

            // 8 data-bit sampling events (RX-equivalent), one per clock,
            // skipping the LOAD edge itself.
            captured = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                captured = {captured[6:0], serial_out}; // sample MSB-first
                @(negedge clk);
            end

            if (captured === expected) begin
                $display("PASS: in=%b out=%b (expected %b)", byte_in, captured, expected);
            end else begin
                $display("FAIL: in=%b out=%b (expected %b)", byte_in, captured, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk     = 0;
        rst     = 1;
        load    = 0;
        mux_out = 8'h00;

        @(negedge clk);
        @(negedge clk);
        rst = 0;

        // Reset check
        if (serial_out !== 1'b0) begin
            $display("FAIL: serial_out not 0 after reset");
            errors = errors + 1;
        end else begin
            $display("PASS: serial_out = 0 after reset");
        end

        // Spec section 27 test vectors
        send_byte(8'hAA, 8'b10101010); // Test 1
        send_byte(8'hCC, 8'b11001100); // Test 2
        send_byte(8'hF0, 8'b11110000); // Test 3
        send_byte(8'h0F, 8'b00001111); // Test 4
        send_byte(8'h12, 8'b00010010); // Test 5

        // Timing-table example from review: CH0 = 8'b10100101
        send_byte(8'b10100101, 8'b10100101);

        // Section 28 shift test
        send_byte(8'b10000001, 8'b10000001);

        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\n%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
