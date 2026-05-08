// ECE:3350 SISC processor project
// Testbench for bubble sort and multiplication programs

`timescale 1ns/100ps

module sisc_tb;

    // -------------------------
    // Clock and reset
    // -------------------------
    reg clk, rst_f;

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------
    // DUT instantiation
    // -------------------------
    sisc dut (
        .clk(clk),
        .rst_f(rst_f)
    );

    // -------------------------
    // Helpers
    // -------------------------
    integer i;
    integer errors;

    // Max cycles before we declare a hang
    parameter MAX_CYCLES = 100000;
    integer cycle_count;

    // -------------------------
    // Tasks
    // -------------------------

    // Hard reset the processor
    task do_reset;
        begin
            rst_f = 0;
            @(negedge clk);
            @(negedge clk);
            rst_f = 1;
            cycle_count = 0;
        end
    endtask

    // Load instruction memory from file
    task load_imem;
        input [255:0] filename; // string passed as a packed reg
        begin
            $readmemh(filename, dut.u8.ram_array);
        end
    endtask

    // Load data memory from file
    task load_dmem;
        input [255:0] filename;
        begin
            $readmemh(filename, dut.u11.ram_array);
        end
    endtask

    // Run until HLT (opcode == 0xF) or MAX_CYCLES, whichever comes first
    task run_until_halt;
        begin
            cycle_count = 0;
            // Wait for fetch state to be past reset, then watch opcode
            @(posedge clk); // clear any edge artifact
            while (dut.opcode !== 4'hF && cycle_count < MAX_CYCLES) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end
            // Let the HLT instruction fully propagate through the pipeline
            repeat(8) @(posedge clk);
            if (cycle_count >= MAX_CYCLES)
                $display("  WARNING: hit cycle limit (%0d cycles) — possible infinite loop!", MAX_CYCLES);
            else
                $display("  Halted after %0d cycles.", cycle_count);
        end
    endtask

    // -------------------------
    // Sort test
    // -------------------------
    task test_sort;
        // Expected sorted result: [-7, -2, 0, 5, 10, 18]
        // In hex (32-bit signed two's complement):
        //   -7  = FFFFFFF9
        //   -2  = FFFFFFFE
        //    0  = 00000000
        //    5  = 00000005
        //   10  = 0000000A
        //   18  = 00000012
        reg [31:0] expected [1:6];
        integer    pass;
        begin
            $display("\n=== BUBBLE SORT TEST ===");
            errors = 0;

            expected[1] = 32'hFFFFFFF9; // -7
            expected[2] = 32'hFFFFFFFE; // -2
            expected[3] = 32'h00000000; //  0
            expected[4] = 32'h00000005; //  5
            expected[5] = 32'h0000000A; // 10
            expected[6] = 32'h00000012; // 18

            // Load programs and reset
            load_imem("sort_instr.data");
            load_dmem("sort_data.data");
            do_reset;

            $display("  Input:  [5, -2, 18, 10, 0, -7]");

            run_until_halt;

            // Check results in data memory (addresses 1..6)
            $display("  Checking sorted output...");
            pass = 1;
            for (i = 1; i <= 6; i = i + 1) begin
                if (dut.u11.ram_array[i] !== expected[i]) begin
                    $display("  FAIL  Mem[%0d]: got %08h, expected %08h",
                             i, dut.u11.ram_array[i], expected[i]);
                    errors = errors + 1;
                    pass = 0;
                end else begin
                    $display("  OK    Mem[%0d] = %08h (%0d)",
                             i, dut.u11.ram_array[i], $signed(dut.u11.ram_array[i]));
                end
            end

            if (pass)
                $display("  SORT PASSED");
            else
                $display("  SORT FAILED (%0d error(s))", errors);
        end
    endtask

    // -------------------------
    // Multiply test
    // -------------------------
    task test_mult;
        // A = 0x87654321, B = 0x789ABCDE
        // Expected product (64-bit): 0x3FC94E45_A0F6729E
        //   Mem[2] = 0xA0F6729E  (low word)
        //   Mem[3] = 0x3FC94E45  (high word)
        reg [31:0] exp_lo, exp_hi;
        integer    pass;
        begin
            $display("\n=== MULTIPLICATION TEST ===");
            errors = 0;
            exp_lo = 32'hA0F6729E;
            exp_hi = 32'h3FC94E45;

            // Load programs and reset
            load_imem("mult_instr.data");
            load_dmem("mult_data.data");
            do_reset;

            $display("  A = 0x87654321,  B = 0x789ABCDE");
            $display("  Expected: 0x3FC94E45_A0F6729E");

            run_until_halt;

            // Check results
            $display("  Checking product...");
            pass = 1;

            if (dut.u11.ram_array[2] !== exp_lo) begin
                $display("  FAIL  Mem[2] (lo): got %08h, expected %08h",
                         dut.u11.ram_array[2], exp_lo);
                errors = errors + 1;
                pass = 0;
            end else begin
                $display("  OK    Mem[2] (lo) = %08h", dut.u11.ram_array[2]);
            end

            if (dut.u11.ram_array[3] !== exp_hi) begin
                $display("  FAIL  Mem[3] (hi): got %08h, expected %08h",
                         dut.u11.ram_array[3], exp_hi);
                errors = errors + 1;
                pass = 0;
            end else begin
                $display("  OK    Mem[3] (hi) = %08h", dut.u11.ram_array[3]);
            end

            if (pass)
                $display("  MULTIPLY PASSED");
            else
                $display("  MULTIPLY FAILED (%0d error(s))", errors);
        end
    endtask

    // -------------------------
    // Main test sequence
    // -------------------------
    initial begin
        $display("========================================");
        $display("  SISC Processor Test Suite");
        $display("========================================");

        test_sort;
        test_mult;

        $display("\n========================================");
        $display("  All tests complete.");
        $display("========================================\n");
        $finish;
    end

endmodule