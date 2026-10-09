// =============================================================
// tb_tdm_top_filebased.v
//
// File-driven testbench for tdm_top. Instead of hardcoding
// CH0..CH3 values in the testbench body (as tb_tdm_top.v does),
// this testbench reads a list of test vectors from a .hex file,
// drives them one at a time into the DUT, and writes the settled
// CH0_OUT..CH3_OUT for each vector into a result .hex file, in
// the same packed-32-bit format as the input.
//
// This does not replace tb_tdm_top.v (still 38/38 PASS on its
// own hardcoded cases) - it runs alongside it, as a separate
// entry point for regression against an external reference
// (e.g. a Python golden model that reads the same input file,
// computes its own expected output, and diffs it against the
// result file this testbench produces).
//
// SELF-CHECKING: for this design, TDM is lossless and introduces
// no transformation other than the pipeline delay - so the correct
// expected output for a vector is simply that same vector's input
// bytes, {CH0,CH1,CH2,CH3}. This testbench therefore also compares
// {CH0_OUT,CH1_OUT,CH2_OUT,CH3_OUT} against the vector it just fed
// in, and prints PASS/FAIL per vector plus a final summary - so you
// get a correct/incorrect verdict directly from this run, without
// needing an external golden model just to answer "is this right".
// A golden model is still useful if you introduce something a plain
// identity check can't catch (e.g. adding a parity/CRC bit and
// checking the receiver computed it correctly) - in that case use
// the OUTPUT_FILE this testbench writes as the "actual" side of that
// comparison.
//
// -------------------------------------------------------------
// Input file format  (default: testbench/vectors/input_vectors.hex)
//   - One test vector per line: a single packed 32-bit hex value
//     equal to {CH0, CH1, CH2, CH3} (8 bits each, MSB-first byte
//     order within the 32-bit value).
//       e.g. "a53cf05a" -> CH0=0xA5 CH1=0x3C CH2=0xF0 CH3=0x5A
//   - Blank lines and `//` / `/* */` comments are allowed - both
//     are already handled by $readmemh per the Verilog LRM.
//   - Up to MAX_VECTORS lines are read; raise the parameter below
//     if a larger input file is needed. The actual count does not
//     need to be hardcoded anywhere else - it is auto-detected at
//     run time (see "auto-detect vector count" below).
//
// Output file format (default: golden_model/verification_logs/rtl_output.hex)
//   - One line per input line, same packed-32-bit-hex format,
//     holding {CH0_OUT, CH1_OUT, CH2_OUT, CH3_OUT} sampled after
//     the vector has had time to fully settle.
//
// SETTLE_CYCLES is deliberately a multiple of 32 (1 frame = 32
// clocks): this makes the sampling point land on the same
// bit_count phase every time regardless of which vector came
// before it, so results are reproducible run-to-run and
// simulator-to-simulator (see the header comment in tb_tdm_top.v
// for the background on why bit_count phase matters here).
//
// Run from the repository root:
//   iverilog -g2012 -o testbench/sim_filebased \
//       testbench/tb_tdm_top_filebased.v \
//       src/tdm_top.v src/tdm_counter.v src/tdm_mux.v \
//       src/tx_shift_reg.v src/rx_shift_reg.v src/tdm_demux.v
//   vvp testbench/sim_filebased
//
// IN VIVADO: this testbench only reaches $finish after every vector
// in the file has been processed, which can take longer than
// Vivado's default simulation runtime (often 1000 ns). If you just
// click "Run" (or the sim GUI's default runtime), it pauses partway
// through and the output file can look empty or truncated, because
// $fclose (which flushes everything to disk) hasn't executed yet.
// Use "Run All" (Tcl: run -all) so the simulation runs to $finish.
// Each line is also explicitly flushed with $fflush right after it
// is written, so even a partial/paused run shows whatever vectors
// have completed so far, not nothing.
// =============================================================
`timescale 1ns/1ps

module tb_tdm_top_filebased;

    parameter MAX_VECTORS   = 256;
    parameter SETTLE_CYCLES = 64;   // multiple of 32 -> deterministic sampling phase
    parameter SYNC_BIT_COUNT = 24;
    parameter INPUT_FILE    = "C:/Users/tungd/OneDrive/Desktop/TDM/input_vectors.hex";           duong link file input
    parameter OUTPUT_FILE   = "C:/Users/tungd/OneDrive/Desktop/TDM/rtl_output_vectors.hex";      duong link xuat file output

    reg clk = 0;
    reg rst;
    reg [7:0] CH0, CH1, CH2, CH3;
    wire       TDM_DATA;
    wire [7:0] CH0_OUT, CH1_OUT, CH2_OUT, CH3_OUT;

    always #5 clk = ~clk;

    tdm_top DUT (
        .clk      (clk),
        .rst      (rst),
        .CH0      (CH0),
        .CH1      (CH1),
        .CH2      (CH2),
        .CH3      (CH3),
        .TDM_DATA (TDM_DATA),
        .CH0_OUT  (CH0_OUT),
        .CH1_OUT  (CH1_OUT),
        .CH2_OUT  (CH2_OUT),
        .CH3_OUT  (CH3_OUT)
    );

    reg [31:0] vectors [0:MAX_VECTORS-1];
    integer    num_vectors;
    integer    idx;
    integer    fd_out;
    reg        found_end;

    reg [31:0] expected, actual;
    integer    checks, errors;

    initial begin
        // -----------------------------------------------------
        // 1) load vectors from the .hex file
        // -----------------------------------------------------
        for (idx = 0; idx < MAX_VECTORS; idx = idx + 1)
            vectors[idx] = 32'hxxxx_xxxx;   // sentinel: "not filled by the file"

        $readmemh(INPUT_FILE, vectors);

        // auto-detect vector count: stop at the first still-unfilled
        // (all-X) entry, so the file's own length drives the loop -
        // nothing here needs to be hardcoded when the file changes.
        found_end   = 1'b0;
        num_vectors = MAX_VECTORS;
        for (idx = 0; idx < MAX_VECTORS; idx = idx + 1) begin
            if (!found_end && (^vectors[idx] === 1'bx)) begin
                found_end   = 1'b1;
                num_vectors = idx;
            end
        end

        if (num_vectors == 0) begin
            $display("[filebased-tb] ERROR: no vectors read from %s (missing/empty file, or MAX_VECTORS too small)", INPUT_FILE);
            $finish;
        end
        $display("[filebased-tb] loaded %0d test vector(s) from %s", num_vectors, INPUT_FILE);

        // -----------------------------------------------------
        // 2) open the result file
        // -----------------------------------------------------
        fd_out = $fopen(OUTPUT_FILE, "w");
        if (fd_out == 0) begin
            $display("[filebased-tb] ERROR: cannot open %s for writing", OUTPUT_FILE);
            $finish;
        end

        // -----------------------------------------------------
        // 3) reset - with the #1 fix documented in tb_tdm_top.v's
        //    header (avoids a same-edge race between this block's
        //    "rst = 0" and the DUT's own posedge-clk reset sampling)
        //
        //    IMPORTANT: CH0..CH3 are preloaded with the FIRST vector
        //    (vectors[0]) *before* the reset-hold cycles, not with
        //    0. tx_shift_reg's cold-start fix (see src/tx_shift_reg.v)
        //    preloads tx_shift with mux_out on every clock while rst
        //    is held - so whatever CH0 happens to be during the last
        //    reset-held cycle is what gets latched as the very first
        //    byte on TDM_DATA. Holding CH0..CH3 at 0 during reset and
        //    only setting the real vector afterwards would silently
        //    reintroduce the old "CH1 comes out before CH0" cold-start
        //    bug that tx_shift_reg.v was specifically fixed to avoid.
        // -----------------------------------------------------
        rst = 1;
        {CH0, CH1, CH2, CH3} = vectors[0];
        repeat (2) @(posedge clk);
        #1;
        rst = 0;

        // -----------------------------------------------------
        // 4) drive every vector, one at a time: dump the settled
        //    output to the result file AND self-check it against
        //    the vector just fed in (expected == input, see the
        //    "SELF-CHECKING" note in the header)
        // -----------------------------------------------------
        checks = 0;
        errors = 0;
        for (idx = 0; idx < num_vectors; idx = idx + 1) begin
           if (idx > 0)
            while (DUT.u_counter.bit_count != SYNC_BIT_COUNT[4:0]) @(posedge clk);
            {CH0, CH1, CH2, CH3} = vectors[idx];
            repeat (SETTLE_CYCLES) @(posedge clk);

            actual   = {CH0_OUT, CH1_OUT, CH2_OUT, CH3_OUT};
            expected = vectors[idx];

            $fdisplay(fd_out, "%08h", actual);
            $fflush(fd_out);   // visible on disk even if the run is paused before $finish

            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("[filebased-tb] [FAIL] vector #%0d : input=%08h expected_out=%08h actual_out=%08h",
                          idx, vectors[idx], expected, actual);
            end else begin
                $display("[filebased-tb] [PASS] vector #%0d : %08h", idx, actual);
            end
        end

        $fclose(fd_out);
        $display("======================================================");
        $display(" [filebased-tb] TONG KET: %0d vector, %0d loi", checks, errors);
        if (errors == 0) $display(" >>> TAT CA VECTOR PASSED (output khop input tung bit)");
        else              $display(" >>> CO %0d VECTOR FAILED - xem chi tiet [FAIL] phia tren", errors);
        $display(" ket qua chi tiet da ghi vao: %s", OUTPUT_FILE);
        $display("======================================================");
        $finish;
    end

endmodule