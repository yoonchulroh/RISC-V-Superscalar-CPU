/**
 * sim.cpp - Verilator Simulation for RISC-V Top Module
 * * Simulates top.v by:
 * 1. Asserting reset
 * 2. Sending instructions from code.hex via UART
 * 3. Waiting for output
 */

#include "Vtop_for_verilator.h"
#include <verilated.h>

#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <queue>
#include <string>
#include <vector>

// UART timing parameters (must match top.v)
constexpr int CLK_FREQUENCY = 100000000;
constexpr int BAUD_RATE = 115200;
constexpr int CLKS_PER_BIT = CLK_FREQUENCY / BAUD_RATE;

// Simulation limits per loop iteration
constexpr uint64_t MAX_CYCLES_PER_LOOP = 100000000; // 10M cycles per loop limit

/**
 * UART Transmitter state machine for sending bits to the DUT
 */
class UartTx {
public:
  enum State { IDLE, START_BIT, DATA_BITS, STOP_BIT };

  UartTx()
      : state(IDLE), bit_output(1), clk_count(0), bit_index(0),
        current_byte(0) {}

  // Queue a byte to transmit
  void enqueue(uint8_t byte) { tx_queue.push(byte); }

  // Returns true if there's data pending or currently transmitting
  bool busy() const { return state != IDLE || !tx_queue.empty(); }

  // Called every clock cycle, returns the UART output bit
  uint8_t tick() {
    switch (state) {
    case IDLE:
      bit_output = 1; // Idle high
      if (!tx_queue.empty()) {
        current_byte = tx_queue.front();
        tx_queue.pop();
        state = START_BIT;
        clk_count = 0;
      }
      break;

    case START_BIT:
      bit_output = 0; // Start bit is low
      clk_count++;
      if (clk_count >= CLKS_PER_BIT) {
        clk_count = 0;
        bit_index = 0;
        state = DATA_BITS;
      }
      break;

    case DATA_BITS:
      bit_output = (current_byte >> bit_index) & 1; // LSB first
      clk_count++;
      if (clk_count >= CLKS_PER_BIT) {
        clk_count = 0;
        bit_index++;
        if (bit_index >= 8) {
          state = STOP_BIT;
        }
      }
      break;

    case STOP_BIT:
      bit_output = 1; // Stop bit is high
      clk_count++;
      if (clk_count >= CLKS_PER_BIT) {
        clk_count = 0;
        state = IDLE;
      }
      break;
    }
    return bit_output;
  }

private:
  State state;
  uint8_t bit_output;
  int clk_count;
  int bit_index;
  uint8_t current_byte;
  std::queue<uint8_t> tx_queue;
};

/**
 * UART Receiver state machine for receiving bits from the DUT
 */
class UartRx {
public:
  enum State { IDLE, START_BIT, DATA_BITS, STOP_BIT };

  UartRx() : state(IDLE), clk_count(0), bit_index(0), current_byte(0) {}

  // Called every clock cycle with the UART input bit
  // Returns true if a byte was received (available in getReceivedByte())
  bool tick(uint8_t rx_bit) {
    bool byte_received = false;

    switch (state) {
    case IDLE:
      if (rx_bit == 0) {
        // Detected start bit (falling edge)
        state = START_BIT;
        clk_count = 0;
      }
      break;

    case START_BIT:
      clk_count++;
      // Sample at the middle of the start bit
      if (clk_count >= CLKS_PER_BIT / 2) {
        if (rx_bit == 0) {
          // Valid start bit, continue
          clk_count = 0;
          bit_index = 0;
          current_byte = 0;
          state = DATA_BITS;
        } else {
          // False start, go back to idle
          state = IDLE;
        }
      }
      break;

    case DATA_BITS:
      clk_count++;
      if (clk_count >= CLKS_PER_BIT) {
        clk_count = 0;
        // Sample the data bit
        current_byte |= (rx_bit << bit_index);
        bit_index++;
        if (bit_index >= 8) {
          state = STOP_BIT;
        }
      }
      break;

    case STOP_BIT:
      clk_count++;
      if (clk_count >= CLKS_PER_BIT) {
        clk_count = 0;
        if (rx_bit == 1) {
          // Valid stop bit
          received_byte = current_byte;
          byte_received = true;
        }
        state = IDLE;
      }
      break;
    }
    return byte_received;
  }

  uint8_t getReceivedByte() const { return received_byte; }

private:
  State state;
  int clk_count;
  int bit_index;
  uint8_t current_byte;
  uint8_t received_byte;
};

/**
 * Parse a hex string line and convert to 4-byte little-endian format
 */
bool parseHexLine(const std::string &line, uint8_t *bytes) {
  if (line.empty())
    return false;

  // Remove any whitespace or newlines
  std::string cleanLine;
  for (char c : line) {
    if (std::isxdigit(c)) {
      cleanLine += c;
    }
  }

  if (cleanLine.length() != 8) {
    return false;
  }

  // Parse 32-bit hex value
  uint32_t value = std::stoul(cleanLine, nullptr, 16);

  // Convert to little-endian byte order
  bytes[0] = (value >> 0) & 0xFF;
  bytes[1] = (value >> 8) & 0xFF;
  bytes[2] = (value >> 16) & 0xFF;
  bytes[3] = (value >> 24) & 0xFF;

  return true;
}

/**
 * Read instructions from code.hex file
 */
std::vector<std::vector<uint8_t>> readHexFile(const std::string &filename) {
  std::vector<std::vector<uint8_t>> instructions;
  std::ifstream file(filename);

  if (!file.is_open()) {
    std::cerr << "Error: Cannot open file " << filename << std::endl;
    return instructions;
  }

  std::string line;
  while (std::getline(file, line)) {
    uint8_t bytes[4];
    if (parseHexLine(line, bytes)) {
      instructions.push_back({bytes[0], bytes[1], bytes[2], bytes[3]});
    }
  }

  file.close();
  return instructions;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  if (argc != 2) {
    std::cerr << "Error: valid parameter count is 1" << std::endl;
    return 1;
  }
  const std::string hexFile = argv[1];

  std::cout << "=== RISC-V Verilator Simulation ===" << std::endl;

  // Read hex file once
  auto instructions = readHexFile(hexFile);
  if (instructions.empty()) {
    std::cerr << "No valid instructions found in " << hexFile << std::endl;
    return 1;
  }

  std::cout << "Loaded " << instructions.size() << " instructions."
            << std::endl;

  // Create DUT instance (Instantiated ONCE, used across all loops)
  Vtop_for_verilator *top = new Vtop_for_verilator;

  // Simulation parameters
  constexpr uint64_t IDLE_TIMEOUT = CLKS_PER_BIT * 20;

  // --- MAIN TEST ---
  std::cout << "----------------------------------------" << std::endl;
  std::cout << "Starting Simulation" << std::endl;

  // 1. Assert Reset Phase
  top->reset = 1;      // Assert Reset
  top->uart_input = 1; // UART Line Idle (High)

  // Clock the DUT with reset asserted for 100 cycles to be safe
  for (int i = 0; i < 100; i++) {
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
  }

  // Deassert Reset
  top->reset = 0;

  // 2. Refresh Simulation State
  UartTx tx;
  UartRx rx;

  // Queue all instructions for this run
  for (const auto &instr : instructions) {
    for (uint8_t byte : instr) {
      tx.enqueue(byte);
    }
  }

  // RX Packet State Machine
  enum RxState { WAIT_FOR_LENGTH, READ_DATA };
  RxState rx_state = WAIT_FOR_LENGTH;
  int data_bytes_remaining = 0;
  std::vector<uint8_t> packet_buffer;

  uint64_t loop_cycles = 0;
  uint64_t idle_cycles = 0;
  int bytes_received = 0;
  bool timeout = false;

  // 3. Run Simulation
  while (loop_cycles < MAX_CYCLES_PER_LOOP) {
    // Rising edge
    top->clk = 1;

    // Feed UART Input from our TX instance
    top->uart_input = tx.tick();

    top->eval();

    // Monitor UART Output into our RX instance
    if (rx.tick(top->uart_output)) {
      uint8_t byte = rx.getReceivedByte();
      bytes_received++;

      if (rx_state == WAIT_FOR_LENGTH) {
        data_bytes_remaining = byte;
        packet_buffer.clear();
        // std::cout << "RX: Packet Length: " << (int)byte << std::endl; //
        // Optional debug

        if (data_bytes_remaining == 0) {
          // Print nothing for zero-length packets
          // Continue receiving more packets
        } else {
          rx_state = READ_DATA;
        }
      } else if (rx_state == READ_DATA) {
        packet_buffer.push_back(byte);
        data_bytes_remaining--;

        if (data_bytes_remaining == 0) {
          if (packet_buffer.size() == 1) {
            // Single byte: print as ASCII character
            std::cout << static_cast<char>(packet_buffer[0]) << std::flush;
          } else {
            // Multi-byte: interpret as signed integer (little-endian)
            uint64_t value = 0;
            for (size_t i = 0; i < packet_buffer.size() && i < 8; i++) {
              value |= (static_cast<uint64_t>(packet_buffer[i]) << (i * 8));
            }
            // Sign-extend based on actual packet size
            size_t bits = packet_buffer.size() * 8;
            if (bits < 64 && (value >> (bits - 1)) & 1) {
              value |= ~((1ULL << bits) - 1);
            }
            std::cout << static_cast<int64_t>(value) << std::flush;
          }

          rx_state = WAIT_FOR_LENGTH;
          // Continue receiving more packets
        }
      }

      idle_cycles = 0; // Reset idle counter on activity
    }

    // Falling edge
    top->clk = 0;
    top->eval();

    loop_cycles++;

    // Timeout Logic
    // If TX is done, we wait for a bit of silence (idle timeout)
    if (!tx.busy()) {
      idle_cycles++;

      // Case A: We received data, waiting for stream to end
      if (bytes_received > 0 && idle_cycles >= MAX_CYCLES_PER_LOOP) {
        break; // Done
      }

      // Case B: We haven't received anything yet
      // Wait longer (e.g., 200 bit times) before declaring failure
      if (bytes_received == 0 && idle_cycles >= MAX_CYCLES_PER_LOOP) {
        std::cout << "Warning: No output received (Timeout)." << std::endl;
        timeout = true;
        break;
      }
    }
  }

  std::cout << std::endl;
  std::cout << "Simulation finished. Cycles: " << loop_cycles
            << ", Bytes RX: " << bytes_received << std::endl;

  // Cleanup
  top->final();
  delete top;

  return 0;
}