// memory_bram.sv
// Simple Block RAM with 2-cycle read latency
// Write is single-cycle (synchronous)

module memory_bram #(
    parameter ADDR_WIDTH = 10,  // 1KB memory (1024 words)
    parameter DATA_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Memory interface
    input  logic                    mem_en,      // Memory enable
    input  logic                    mem_wr,      // Write enable (1=write, 0=read)
    input  logic [ADDR_WIDTH-1:0]   mem_addr,    // Address
    input  logic [DATA_WIDTH-1:0]   mem_wdata,   // Write data
    output logic [DATA_WIDTH-1:0]   mem_rdata,   // Read data (2-cycle latency)
    output logic                    mem_rvalid   // Read data valid
);

    // Memory array
    logic [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];
    
    // Pipeline registers for 2-cycle read latency
    logic [DATA_WIDTH-1:0] rdata_stage1;
    logic                  rvalid_stage1;
    logic                  rvalid_stage2;
    
    // Write operation (single cycle)
    always_ff @(posedge clk) begin
        if (mem_en && mem_wr) begin
            ram[mem_addr] <= mem_wdata;
        end
    end
    
    // Read operation - Stage 1 (address pipeline)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_stage1  <= '0;
            rvalid_stage1 <= 1'b0;
        end else begin
            if (mem_en && !mem_wr) begin
                rdata_stage1  <= ram[mem_addr];
                rvalid_stage1 <= 1'b1;
            end else begin
                rdata_stage1  <= '0;
                rvalid_stage1 <= 1'b0;
            end
        end
    end
    
    // Read operation - Stage 2 (data pipeline)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_rdata     <= '0;
            rvalid_stage2 <= 1'b0;
        end else begin
            mem_rdata     <= rdata_stage1;
            rvalid_stage2 <= rvalid_stage1;
        end
    end
    
    assign mem_rvalid = rvalid_stage2;
    
    // Initialize memory (optional, for simulation)
    initial begin
        for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
            ram[i] = '0;
        end
    end

endmodule
