# VHDL Component for Data Processing from RAM

## Project Description

This project implements a VHDL component that processes a sequence of data stored in a RAM memory. The component is designed as a Finite State Machine (FSM) and is intended for applications like outlier detection in sensor readings.

The core functionality is to read a sequence of K words (W) from a RAM, starting from a specific address (ADD). The data words (W) are 8-bit values ranging from 0 to 255. A value of 0 indicates "unspecified or unreliable data". The component's task is to:

1. **Replace unspecified data (0) with the last valid data value read.**
2. **Implement a "credibility" parameter (C) that decreases with each consecutive zero value, up to a maximum of 31.**

This component autonomously manages memory read/write operations, counter management, and state transitions to achieve the specified data processing.

## Features

- **Finite State Machine (FSM) implementation in VHDL.**
- **Reads data sequence from RAM memory.**
- **Handles "unspecified data" (value 0) by replacing it with the last valid value.**
- **Implements a credibility counter that decrements for consecutive zeros.**
- **Synchronous design with clock and reset signals.**
- **Comprehensive testbench suite for verification, including edge cases and overflow scenarios.**

## Architecture

The component's architecture is based on a Finite State Machine (FSM) that controls the data processing flow. Key internal signals and components include:

- **FSM States:**  IDLE, FETCH_INITIAL_DATA, ASK_READ_RAM, WAIT_READ_RAM, READ_W_RAM, WRITE_RAM, DONE.
- **`saved_W`:**  8-bit register to store the last valid data word read from RAM.
- **`counter_K`:** 16-bit counter to track the number of read cycles.
- **`counter_Add`:** 16-bit register to store the current memory address.
- **`counter_31`:** 5-bit counter for the credibility parameter (decrements from 31).

The FSM interacts with a RAM memory through the following signals:

- **`o_mem_addr`:** Output address to RAM.
- **`i_mem_data`:** Input data from RAM.
- **`o_mem_data`:** Output data to RAM for writing (processed data).
- **`o_mem_en`:** Output enable for RAM communication.
- **`o_mem_we`:** Output write enable for RAM (active high for write).

## Interface

The VHDL entity `project_reti_logiche` defines the component's interface:

**Inputs:**

- **`i_clk`:** Clock signal.
- **`i_rst`:** Reset signal (synchronous).
- **`i_start`:** Start signal to initiate processing.
- **`i_add`:** 16-bit input vector for the starting RAM address (ADD).
- **`i_k`:** 10-bit input vector for the sequence length (K).
- **`i_mem_data`:** 8-bit input vector from RAM memory.

**Outputs:**

- **`o_done`:** 1-bit output signal indicating the completion of the processing.
- **`o_mem_addr`:** 16-bit output vector for RAM address.
- **`o_mem_data`:** 8-bit output vector for data to be written to RAM.
- **`o_mem_we`:** 1-bit output signal for RAM write enable.
- **`o_mem_en`:** 1-bit output signal for RAM enable.

## Testing

- **Example Testbench:** Based on the example provided in the project specification.
- **Edge Case Simulations:** Tests for boundary conditions and unusual inputs.
- **Automatically Generated Tests:**  To ensure robustness and coverage.
- **Specific Test Scenarios:**
    - Multiple sequences in a row.
    - Counter K overflow handling.
    - Reset during start.
    - Start signal held high during reset.
    - Sequences containing only '0' values.
    - Sequences with more than 31 consecutive identical values.

## Usage

To use this component in a VHDL design:

1. Instantiate the `project_reti_logiche` entity.
2. Connect the input and output ports to appropriate signals in your design.
3. Provide clock (`i_clk`), reset (`i_rst`), start (`i_start`), address (`i_add`), and length (`i_k`) inputs as required.
4. Connect the RAM interface signals (`o_mem_addr`, `i_mem_data`, `o_mem_data`, `o_mem_we`, `o_mem_en`) to your RAM memory module.
5. Monitor the `o_done` output to detect the completion of the data processing sequence.
