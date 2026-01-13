// load_store_tb.sv
// Basic directed testbench for Load-Store Subsystem (Vivado Compatible)
// Tests: single read/write, back-to-back, read-after-write

`timescale 1ns/1ps

module load_store_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // Request interface
    logic                    req_valid;
    logic                    req_ready;
    logic                    req_wr;
    logic [ADDR_WIDTH-1:0]   req_addr;
    logic [DATA_WIDTH-1:0]   req_wdata;
    
    // Response interface
    logic                    resp_valid;
    logic                    resp_ready;
    logic [DATA_WIDTH-1:0]   resp_rdata;
    logic                    resp_error;
    
    // Test control
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // ========================================
    // DUT Instantiation
    // ========================================
    load_store_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_ADDR_WIDTH(10),
        .USE_FIFO(1),
        .FIFO_DEPTH(4)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .req_valid  (req_valid),
        .req_ready  (req_ready),
        .req_wr     (req_wr),
        .req_addr   (req_addr),
        .req_wdata  (req_wdata),
        .resp_valid (resp_valid),
        .resp_ready (resp_ready),
        .resp_rdata (resp_rdata),
        .resp_error (resp_error)
    );
    
    // ========================================
    // Clock Generation
    // ========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ========================================
    // Main Test Sequence
    // ========================================
    initial begin
        logic [DATA_WIDTH-1:0] read_data;
        integer i;
        
        // Initialize signals
        rst_n = 0;
        req_valid = 0;
        req_wr = 0;
        req_addr = 0;
        req_wdata = 0;
        resp_ready = 1;  // Always ready to accept responses
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
        $display("[%0t] Reset complete", $time);
        
        $display("\n========================================");
        $display("Test 1: Single Write");
        $display("========================================");
        
        // Write to address 0x100 with data 0xDEADBEEF
        @(posedge clk);
        req_valid = 1;
        req_wr = 1;
        req_addr = 32'h0000_0100;
        req_wdata = 32'hDEAD_BEEF;
        
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        req_wr = 0;
        
        wait(resp_valid);
        @(posedge clk);
        $display("[%0t] WRITE: Addr=0x%h, Data=0x%h", $time, 32'h0000_0100, 32'hDEAD_BEEF);
        repeat(5) @(posedge clk);
        
        $display("\n========================================");
        $display("Test 2: Single Read (Read back Test 1 data)");
        $display("========================================");
        
        // Read from address 0x100
        @(posedge clk);
        req_valid = 1;
        req_wr = 0;
        req_addr = 32'h0000_0100;
        
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        
        wait(resp_valid);
        read_data = resp_rdata;
        @(posedge clk);
        
        $display("[%0t] READ:  Addr=0x%h, Data=0x%h", $time, 32'h0000_0100, read_data);
        test_count = test_count + 1;
        if (read_data == 32'hDEAD_BEEF) begin
            $display("[PASS] Single Read: Expected=0x%h, Got=0x%h", 32'hDEAD_BEEF, read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Single Read: Expected=0x%h, Got=0x%h", 32'hDEAD_BEEF, read_data);
            fail_count = fail_count + 1;
        end
        repeat(5) @(posedge clk);
        
        $display("\n========================================");
        $display("Test 3: Back-to-back Writes");
        $display("========================================");
        
        // Write 1
        @(posedge clk);
        req_valid = 1;
        req_wr = 1;
        req_addr = 32'h0000_0200;
        req_wdata = 32'h1111_1111;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        @(posedge clk);
        $display("[%0t] WRITE: Addr=0x%h, Data=0x%h", $time, 32'h0000_0200, 32'h1111_1111);
        
        // Write 2
        @(posedge clk);
        req_valid = 1;
        req_wr = 1;
        req_addr = 32'h0000_0204;
        req_wdata = 32'h2222_2222;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        @(posedge clk);
        $display("[%0t] WRITE: Addr=0x%h, Data=0x%h", $time, 32'h0000_0204, 32'h2222_2222);
        
        // Write 3
        @(posedge clk);
        req_valid = 1;
        req_wr = 1;
        req_addr = 32'h0000_0208;
        req_wdata = 32'h3333_3333;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        @(posedge clk);
        $display("[%0t] WRITE: Addr=0x%h, Data=0x%h", $time, 32'h0000_0208, 32'h3333_3333);
        
        repeat(5) @(posedge clk);
        
        $display("\n========================================");
        $display("Test 4: Back-to-back Reads");
        $display("========================================");
        
        // Read 1
        @(posedge clk);
        req_valid = 1;
        req_wr = 0;
        req_addr = 32'h0000_0200;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        read_data = resp_rdata;
        @(posedge clk);
        $display("[%0t] READ:  Addr=0x%h, Data=0x%h", $time, 32'h0000_0200, read_data);
        test_count = test_count + 1;
        if (read_data == 32'h1111_1111) begin
            $display("[PASS] B2B Read 1: Expected=0x%h, Got=0x%h", 32'h1111_1111, read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] B2B Read 1: Expected=0x%h, Got=0x%h", 32'h1111_1111, read_data);
            fail_count = fail_count + 1;
        end
        
        // Read 2
        @(posedge clk);
        req_valid = 1;
        req_wr = 0;
        req_addr = 32'h0000_0204;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        read_data = resp_rdata;
        @(posedge clk);
        $display("[%0t] READ:  Addr=0x%h, Data=0x%h", $time, 32'h0000_0204, read_data);
        test_count = test_count + 1;
        if (read_data == 32'h2222_2222) begin
            $display("[PASS] B2B Read 2: Expected=0x%h, Got=0x%h", 32'h2222_2222, read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] B2B Read 2: Expected=0x%h, Got=0x%h", 32'h2222_2222, read_data);
            fail_count = fail_count + 1;
        end
        
        // Read 3
        @(posedge clk);
        req_valid = 1;
        req_wr = 0;
        req_addr = 32'h0000_0208;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        read_data = resp_rdata;
        @(posedge clk);
        $display("[%0t] READ:  Addr=0x%h, Data=0x%h", $time, 32'h0000_0208, read_data);
        test_count = test_count + 1;
        if (read_data == 32'h3333_3333) begin
            $display("[PASS] B2B Read 3: Expected=0x%h, Got=0x%h", 32'h3333_3333, read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] B2B Read 3: Expected=0x%h, Got=0x%h", 32'h3333_3333, read_data);
            fail_count = fail_count + 1;
        end
        
        repeat(5) @(posedge clk);
        
        $display("\n========================================");
        $display("Test 5: Read-After-Write (RAW) Hazard");
        $display("========================================");
        
        // Write
        @(posedge clk);
        req_valid = 1;
        req_wr = 1;
        req_addr = 32'h0000_0300;
        req_wdata = 32'hAAAA_AAAA;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        @(posedge clk);
        $display("[%0t] WRITE: Addr=0x%h, Data=0x%h", $time, 32'h0000_0300, 32'hAAAA_AAAA);
        
        // Immediate Read
        @(posedge clk);
        req_valid = 1;
        req_wr = 0;
        req_addr = 32'h0000_0300;
        wait(req_ready);
        @(posedge clk);
        req_valid = 0;
        wait(resp_valid);
        read_data = resp_rdata;
        @(posedge clk);
        $display("[%0t] READ:  Addr=0x%h, Data=0x%h", $time, 32'h0000_0300, read_data);
        test_count = test_count + 1;
        if (read_data == 32'hAAAA_AAAA) begin
            $display("[PASS] RAW Hazard: Expected=0x%h, Got=0x%h", 32'hAAAA_AAAA, read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] RAW Hazard: Expected=0x%h, Got=0x%h", 32'hAAAA_AAAA, read_data);
            fail_count = fail_count + 1;
        end
        
        repeat(5) @(posedge clk);
        
        // ========================================
        // Test Summary
        // ========================================
        $display("\n========================================");
        $display("TEST SUMMARY");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
        end else begin
            $display("\n*** SOME TESTS FAILED ***");
        end
        $display("========================================\n");
        
        repeat(10) @(posedge clk);
        $finish;
    end
    
    // ========================================
    // Timeout Watchdog
    // ========================================
    initial begin
        #100000;  // 100us timeout
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end

endmodule
