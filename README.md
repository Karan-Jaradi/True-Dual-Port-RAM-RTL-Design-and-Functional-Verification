## 1. Introduction

This project implements a **parameterized True Dual-Port RAM (TDPRAM)** in Verilog, supporting independent read/write access on both ports. It is verified using a self-checking testbench with directed and constrained-random tests.

## 2. Features

- Fully parameterized design — data width and address width (and hence memory depth) can be configured at instantiation.
- True dual-port behavior — both ports support independent read and write access to any address, unlike a simple dual-port RAM where one port is read-only.
- Independent clocks for each port, proving genuine asynchronous, port-level independence.
- Write-first synchronous read behavior — a port reading and writing the same address in the same cycle sees the newly written data immediately.
- Cross-port data visibility — data written through one port is correctly visible when read through the other port.
- Self-checking testbench with a reference model (scoreboard) that predicts expected memory contents and automatically flags mismatches.
- Constrained-random verification — address, port selection, and read/write operation are randomized within valid limits across 100+ iterations.
- Documented handling of same-address collision behavior between ports, consistent with real Block RAM design considerations.

## 3. Module Ports

### `true_dual_port_ram` — Port List

| Port Name | Direction | Width         | Description                              |
|-----------|-----------|---------------|-------------------------------------------|
| clka      | Input     | 1 bit         | Clock for Port A                          |
| ena       | Input     | 1 bit         | Enable signal for Port A                  |
| wea       | Input     | 1 bit         | Write enable for Port A                   |
| addra     | Input     | ADDR_WIDTH    | Address input for Port A                  |
| dina      | Input     | DATA_WIDTH    | Data input (write data) for Port A        |
| douta     | Output    | DATA_WIDTH    | Data output (read data) for Port A        |
| clkb      | Input     | 1 bit         | Clock for Port B                          |
| enb       | Input     | 1 bit         | Enable signal for Port B                  |
| web       | Input     | 1 bit         | Write enable for Port B                   |
| addrb     | Input     | ADDR_WIDTH    | Address input for Port B                  |
| dinb      | Input     | DATA_WIDTH    | Data input (write data) for Port B        |
| doutb     | Output    | DATA_WIDTH    | Data output (read data) for Port B        |

### Parameters

| Parameter    | Default | Description                                   |
|--------------|---------|------------------------------------------------|
| DATA_WIDTH   | 8       | Width of each memory word (bits)               |
| ADDR_WIDTH   | 8       | Number of address bits (memory depth = 2^ADDR_WIDTH) |

## 4. Verification

The design is verified using a single, sequential, self-checking Verilog testbench (`tb_true_dual_port_ram.v`), structured in two parts:

**Directed Tests**
- Write and read-back on Port A
- Write and read-back on Port B
- Cross-port check — Port A writes to an address, Port B reads the same address

**Constrained-Random Test**
- Runs for 100+ iterations
- Each iteration randomly selects:
  - a valid memory address (constrained using a bit-mask so it always stays within range)
  - which port to use (Port A or Port B)
  - whether the operation is a read or a write
- Every write updates a **reference model** array that mirrors the expected memory contents
- Every read is automatically compared against the reference model, and any mismatch is flagged as a failure

**Result Reporting**
- The testbench prints `[PASS]` or `[FAIL]` for every checked transaction
- A final summary reports total checks performed and total errors found
