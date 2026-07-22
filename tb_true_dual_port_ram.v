`timescale 1ns/1ps

module tb_true_dual_port_ram;

    parameter DATA_WIDTH      = 8;
    parameter ADDR_WIDTH      = 8;
    parameter DEPTH           = 1 << ADDR_WIDTH;
    parameter NUM_RANDOM_TESTS = 100;

    // Port A signals
    reg                   clka;
    reg                   ena;
    reg                   wea;
    reg  [ADDR_WIDTH-1:0] addra;
    reg  [DATA_WIDTH-1:0] dina;
    wire [DATA_WIDTH-1:0] douta;

    // Port B signals
    reg                   clkb;
    reg                   enb;
    reg                   web;
    reg  [ADDR_WIDTH-1:0] addrb;
    reg  [DATA_WIDTH-1:0] dinb;
    wire [DATA_WIDTH-1:0] doutb;

    // Reference model : plain array holding the value we expect to be
    // stored at each address
    reg [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];

    // Loop / bookkeeping variables
    integer i;
    integer errors;
    integer checks;

    // Variables used inside the random loop
    integer port_sel;   // 0 = Port A, 1 = Port B
    integer op_sel;      // 0 = write, 1 = read
    reg [ADDR_WIDTH-1:0] rand_addr;
    reg [DATA_WIDTH-1:0] rand_data;

    // -------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------
    true_dual_port_ram #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .clka  (clka),
        .ena   (ena),
        .wea   (wea),
        .addra (addra),
        .dina  (dina),
        .douta (douta),

        .clkb  (clkb),
        .enb   (enb),
        .web   (web),
        .addrb (addrb),
        .dinb  (dinb),
        .doutb (doutb)
    );

    // -------------------------------------------------------------------
    // Clocks
    // -------------------------------------------------------------------
    initial clka = 0;
    always #5 clka = ~clka;   // 100 MHz

    initial clkb = 0;
    always #5 clkb = ~clkb;   // same period, kept simple

    // -------------------------------------------------------------------
    // Simple tasks : one write task and one read/check task per port
    // -------------------------------------------------------------------
    task write_a(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge clka);
            ena   = 1;
            wea   = 1;
            addra = addr;
            dina  = data;
            @(negedge clka);
            ena   = 0;
            wea   = 0;
            ref_mem[addr] = data;   // update reference model
        end
    endtask

    task write_b(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge clkb);
            enb   = 1;
            web   = 1;
            addrb = addr;
            dinb  = data;
            @(negedge clkb);
            enb   = 0;
            web   = 0;
            ref_mem[addr] = data;   // update reference model
        end
    endtask

    task read_check_a(input [ADDR_WIDTH-1:0] addr);
        begin
            @(negedge clka);
            ena   = 1;
            wea   = 0;
            addra = addr;
            @(negedge clka);
            ena   = 0;
            checks = checks + 1;
            if (douta !== ref_mem[addr]) begin
                errors = errors + 1;
                $display("[FAIL] Port A addr=%0d expected=%0h got=%0h",
                           addr, ref_mem[addr], douta);
            end else begin
                $display("[PASS] Port A addr=%0d data=%0h", addr, douta);
            end
        end
    endtask

    task read_check_b(input [ADDR_WIDTH-1:0] addr);
        begin
            @(negedge clkb);
            enb   = 1;
            web   = 0;
            addrb = addr;
            @(negedge clkb);
            enb   = 0;
            checks = checks + 1;
            if (doutb !== ref_mem[addr]) begin
                errors = errors + 1;
                $display("[FAIL] Port B addr=%0d expected=%0h got=%0h",
                           addr, ref_mem[addr], doutb);
            end else begin
                $display("[PASS] Port B addr=%0d data=%0h", addr, doutb);
            end
        end
    endtask

    // -------------------------------------------------------------------
    // Main test process (single sequential block - easy to follow)
    // -------------------------------------------------------------------
    initial begin
        // Initialize all signals
        ena = 0; wea = 0; addra = 0; dina = 0;
        enb = 0; web = 0; addrb = 0; dinb = 0;
        errors = 0;
        checks = 0;

        // Initialize DUT memory and reference model to 0 so every
        // location has a known starting value
        for (i = 0; i < DEPTH; i = i + 1) begin
            dut.mem[i] = 0;
            ref_mem[i] = 0;
        end

        @(negedge clka);

        // ---------------- PART 1 : Directed tests ----------------
        $display("---- Directed Test 1: Port A write/read ----");
        write_a(8'd0, 8'hAA);
        read_check_a(8'd0);

        $display("---- Directed Test 2: Port B write/read ----");
        write_b(8'd1, 8'h55);
        read_check_b(8'd1);

        $display("---- Directed Test 3: Port A writes, Port B reads same address ----");
        write_a(8'd2, 8'h3C);
        read_check_b(8'd2);

        // ---------------- PART 2 : Constrained-random test ----------------
        $display("---- Constrained-Random Test : %0d iterations ----", NUM_RANDOM_TESTS);
        for (i = 0; i < NUM_RANDOM_TESTS; i = i + 1) begin

            // Constraint: keep address inside valid memory range using a
            // simple bit mask (works because DEPTH is a power of two)
            rand_addr = $random & (DEPTH - 1);
            rand_data = $random;

            // Constraint: randomly choose which port to use (0 = A, 1 = B)
            port_sel = $random & 1;

            // Constraint: randomly choose write or read (0 = write, 1 = read)
            op_sel = $random & 1;

            if (port_sel == 0) begin
                if (op_sel == 0)
                    write_a(rand_addr, rand_data);
                else
                    read_check_a(rand_addr);
            end else begin
                if (op_sel == 0)
                    write_b(rand_addr, rand_data);
                else
                    read_check_b(rand_addr);
            end
        end

        // ---------------- Final report ----------------
        $display("--------------------------------------------------");
        $display("TOTAL CHECKS : %0d", checks);
        $display("TOTAL ERRORS : %0d", errors);
        if (errors == 0)
            $display("RESULT : ALL TESTS PASSED");
        else
            $display("RESULT : TEST(S) FAILED");
        $display("--------------------------------------------------");

        $finish;
    end

endmodule