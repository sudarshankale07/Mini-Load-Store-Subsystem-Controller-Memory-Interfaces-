Mini-Load-Store-Subsystem-Controller-Memory-Interfaces-

This project implements a load-store controller that interfaces between a CPU and memory (BRAM)

Architecture
Modules

memory_bram.sv - Block RAM with 2-cycle read latency
load_store_controller.sv - FSM-based controller with handshaking
request_fifo.sv - Optional request buffer (depth 4)
load_store_top.sv - Top-level integration

IDLE → MEM_ACCESS → MEM_WAIT (read only) → RESPOND → IDLE

