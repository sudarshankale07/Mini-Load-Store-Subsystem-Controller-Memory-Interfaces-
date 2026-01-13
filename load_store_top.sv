// load_store_top.sv
// Top-level integration of Load-Store Subsystem
// Includes controller, BRAM, and optional FIFO

module load_store_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_ADDR_WIDTH = 10,  // 1KB memory
    parameter USE_FIFO = 1,         // 1=enable FIFO, 0=direct connection
    parameter FIFO_DEPTH = 4
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Request interface (from CPU/master)
    input  logic                    req_valid,
    output logic                    req_ready,
    input  logic                    req_wr,
    input  logic [ADDR_WIDTH-1:0]   req_addr,
    input  logic [DATA_WIDTH-1:0]   req_wdata,
    
    // Response interface (to CPU/master)
    output logic                    resp_valid,
    input  logic                    resp_ready,
    output logic [DATA_WIDTH-1:0]   resp_rdata,
    output logic                    resp_error
);

    // Internal signals between FIFO and controller
    logic                    ctrl_req_valid;
    logic                    ctrl_req_ready;
    logic                    ctrl_req_wr;
    logic [ADDR_WIDTH-1:0]   ctrl_req_addr;
    logic [DATA_WIDTH-1:0]   ctrl_req_wdata;
    
    // Memory interface signals
    logic                    mem_en;
    logic                    mem_wr;
    logic [MEM_ADDR_WIDTH-1:0] mem_addr;
    logic [DATA_WIDTH-1:0]   mem_wdata;
    logic [DATA_WIDTH-1:0]   mem_rdata;
    logic                    mem_rvalid;
    
    // FIFO signals
    logic [64:0]             fifo_wr_data;  // 1 + 32 + 32
    logic [64:0]             fifo_rd_data;
    logic                    fifo_full;
    logic                    fifo_empty;
    logic                    fifo_wr_en;
    logic                    fifo_rd_en;
    
    // ========================================
    // Optional FIFO instantiation
    // ========================================
    generate
        if (USE_FIFO) begin : gen_with_fifo
            // Pack request data into FIFO
            assign fifo_wr_data = {req_wr, req_addr, req_wdata};
            assign fifo_wr_en   = req_valid && !fifo_full;
            assign req_ready    = !fifo_full;
            
            // Unpack FIFO data to controller
            assign {ctrl_req_wr, ctrl_req_addr, ctrl_req_wdata} = fifo_rd_data;
            assign ctrl_req_valid = !fifo_empty;
            assign fifo_rd_en     = ctrl_req_ready && !fifo_empty;
            
            request_fifo #(
                .DATA_WIDTH(65),
                .DEPTH(FIFO_DEPTH)
            ) u_fifo (
                .clk      (clk),
                .rst_n    (rst_n),
                .wr_en    (fifo_wr_en),
                .wr_data  (fifo_wr_data),
                .full     (fifo_full),
                .rd_en    (fifo_rd_en),
                .rd_data  (fifo_rd_data),
                .empty    (fifo_empty)
            );
            
        end else begin : gen_no_fifo
            // Direct connection (no FIFO)
            assign ctrl_req_valid = req_valid;
            assign req_ready      = ctrl_req_ready;
            assign ctrl_req_wr    = req_wr;
            assign ctrl_req_addr  = req_addr;
            assign ctrl_req_wdata = req_wdata;
        end
    endgenerate
    
    // ========================================
    // Load-Store Controller
    // ========================================
    load_store_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_controller (
        .clk         (clk),
        .rst_n       (rst_n),
        .req_valid   (ctrl_req_valid),
        .req_ready   (ctrl_req_ready),
        .req_wr      (ctrl_req_wr),
        .req_addr    (ctrl_req_addr),
        .req_wdata   (ctrl_req_wdata),
        .resp_valid  (resp_valid),
        .resp_ready  (resp_ready),
        .resp_rdata  (resp_rdata),
        .resp_error  (resp_error),
        .mem_en      (mem_en),
        .mem_wr      (mem_wr),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_rdata   (mem_rdata),
        .mem_rvalid  (mem_rvalid)
    );
    
    // ========================================
    // Memory BRAM
    // ========================================
    memory_bram #(
        .ADDR_WIDTH(MEM_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_memory (
        .clk        (clk),
        .rst_n      (rst_n),
        .mem_en     (mem_en),
        .mem_wr     (mem_wr),
        .mem_addr   (mem_addr[MEM_ADDR_WIDTH-1:0]),  // Truncate to memory size
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_rvalid (mem_rvalid)
    );

endmodule
