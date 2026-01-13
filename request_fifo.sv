// request_fifo.sv
// Synchronous FIFO for buffering load-store requests
// Simple circular buffer implementation

module request_fifo #(
    parameter DATA_WIDTH = 65,  // 1(wr) + 32(addr) + 32(data)
    parameter DEPTH      = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Write interface
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    
    // Read interface
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    // FIFO storage
    logic [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    
    // Pointers
    logic [$clog2(DEPTH):0] wr_ptr;  // Extra bit for full/empty distinction
    logic [$clog2(DEPTH):0] rd_ptr;
    
    // Status flags
    logic [$clog2(DEPTH):0] count;
    
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    
    // Write pointer management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Read pointer management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end
    
    // Count management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count <= count + 1;  // Write only
                2'b01:   count <= count - 1;  // Read only
                default: count <= count;      // Both or neither
            endcase
        end
    end
    
    // Write data to FIFO
    always_ff @(posedge clk) begin
        if (wr_en && !full) begin
            fifo_mem[wr_ptr[$clog2(DEPTH)-1:0]] <= wr_data;
        end
    end
    
    // Read data from FIFO
    assign rd_data = fifo_mem[rd_ptr[$clog2(DEPTH)-1:0]];

endmodule
