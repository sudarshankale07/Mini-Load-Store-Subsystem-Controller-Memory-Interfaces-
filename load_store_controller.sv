// load_store_controller.sv
// Load-Store Controller with FSM
// Handles memory requests with proper handshaking and latency

module load_store_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Request interface (from CPU/master)
    input  logic                    req_valid,
    output logic                    req_ready,
    input  logic                    req_wr,        // 1=write, 0=read
    input  logic [ADDR_WIDTH-1:0]   req_addr,
    input  logic [DATA_WIDTH-1:0]   req_wdata,
    
    // Response interface (to CPU/master)
    output logic                    resp_valid,
    input  logic                    resp_ready,
    output logic [DATA_WIDTH-1:0]   resp_rdata,
    output logic                    resp_error,    // Error flag
    
    // Memory interface (to BRAM)
    output logic                    mem_en,
    output logic                    mem_wr,
    output logic [ADDR_WIDTH-1:0]   mem_addr,
    output logic [DATA_WIDTH-1:0]   mem_wdata,
    input  logic [DATA_WIDTH-1:0]   mem_rdata,
    input  logic                    mem_rvalid
);

    // FSM states
    typedef enum logic [2:0] {
        IDLE        = 3'b000,  // Wait for request
        MEM_ACCESS  = 3'b001,  // Send to memory (cycle 1)
        MEM_WAIT    = 3'b010,  // Wait for read latency (cycle 2)
        RESPOND     = 3'b011   // Drive response
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal registers
    logic                  req_type_reg;    // 0=read, 1=write
    logic [DATA_WIDTH-1:0] rdata_reg;       // Captured read data
    logic                  cycle_count;     // For 2-cycle wait
    
    // FSM: State transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // FSM: Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (req_valid && req_ready)
                    next_state = MEM_ACCESS;
            end
            
            MEM_ACCESS: begin
                if (req_type_reg) // Write
                    next_state = RESPOND;
                else              // Read
                    next_state = MEM_WAIT;
            end
            
            MEM_WAIT: begin
                if (mem_rvalid)   // Read data ready
                    next_state = RESPOND;
            end
            
            RESPOND: begin
                if (resp_valid && resp_ready)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Capture request information
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_type_reg <= 1'b0;
        end else if (current_state == IDLE && req_valid && req_ready) begin
            req_type_reg <= req_wr;
        end
    end
    
    // Capture read data from memory
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_reg <= '0;
        end else if (mem_rvalid) begin
            rdata_reg <= mem_rdata;
        end
    end
    
    // Output: req_ready (ready to accept new request)
    always_comb begin
        req_ready = (current_state == IDLE);
    end
    
    // Output: Memory interface
    always_comb begin
        mem_en    = (current_state == MEM_ACCESS);
        mem_wr    = req_type_reg && (current_state == MEM_ACCESS);
        mem_addr  = req_addr;
        mem_wdata = req_wdata;
    end
    
    // Output: Response interface
    always_comb begin
        resp_valid = (current_state == RESPOND);
        resp_rdata = req_type_reg ? '0 : rdata_reg;  // Read: data, Write: 0
        resp_error = 1'b0;  // No error handling in simple version
    end

endmodule
