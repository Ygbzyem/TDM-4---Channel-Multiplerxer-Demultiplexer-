// =============================================================
// Testbench : tx_shift_reg_tb
// Muc dich  : Kiem tra doc lap module tx_shift_reg theo cac
//             test case trong spec (muc 27 - Test doc lap,
//             muc 28 - Test shift).
// =============================================================
`timescale 1ns/1ps

module tx_shift_reg_tb;

    reg        clk;
    reg        rst;
    reg [7:0]  mux_out;
    reg        load;
    wire       serial_out;

    integer errors = 0;

    // DUT
    tx_shift_reg dut (
        .clk        (clk),
        .rst        (rst),
        .mux_out    (mux_out),
        .load       (load),
        .serial_out (serial_out)
    );

    // Clock 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: load 1 byte roi doc ra 8 bit serial theo dung "cycle model"
    // (LOAD PHASE khong tinh la 1 sampling bit, sau do 8 sampling
    //  events tuong ung 8 data bits - muc 16).
    task run_byte(input [7:0] byte_in, input [7:0] expected);
        integer i;
        reg [7:0] captured;
        begin
            // LOAD PHASE
            @(negedge clk);
            mux_out = byte_in;
            load    = 1'b1;
            @(posedge clk); // tai edge nay tx_shift_reg <= mux_out
            @(negedge clk);
            load = 1'b0;

            // Ngay sau load, serial_out phai la MSB (BIT 7) - chua shift
            captured[7] = serial_out;

            // 7 sampling events con lai, moi lan shift o posedge truoc do
            for (i = 6; i >= 0; i = i - 1) begin
                @(posedge clk); // SHIFT xay ra o day
                @(negedge clk);
                captured[i] = serial_out;
            end

            if (captured !== expected) begin
                $display("FAIL: input=%b expected=%b got=%b", byte_in, expected, captured);
                errors = errors + 1;
            end else begin
                $display("PASS: input=%b -> serial=%b", byte_in, captured);
            end
        end
    endtask

    initial begin
        // Init + reset
        rst     = 1'b1;
        load    = 1'b0;
        mux_out = 8'h00;
        @(negedge clk);
        @(negedge clk);

        if (serial_out !== 1'b0) begin
            $display("FAIL: sau reset serial_out phai = 0");
            errors = errors + 1;
        end else begin
            $display("PASS: sau reset serial_out = 0");
        end

        rst = 1'b0;

        // Test 1..5 (muc 27)
        run_byte(8'hAA, 8'b10101010); // Test 1
        run_byte(8'hCC, 8'b11001100); // Test 2
        run_byte(8'hF0, 8'b11110000); // Test 3
        run_byte(8'h0F, 8'b00001111); // Test 4
        run_byte(8'h12, 8'b00010010); // Test 5

        // Test shift them (muc 28)
        run_byte(8'b10000001, 8'b10000001);

        // Frame day du CH0..CH3 (muc 19 / 35): AA CC F0 0F
        run_byte(8'hAA, 8'b10101010);
        run_byte(8'hCC, 8'b11001100);
        run_byte(8'hF0, 8'b11110000);
        run_byte(8'h0F, 8'b00001111);

        if (errors == 0)
            $display("=== ALL TESTS PASSED ===");
        else
            $display("=== %0d TEST(S) FAILED ===", errors);

        $finish;
    end

endmodule
