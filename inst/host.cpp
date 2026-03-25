#include <atomic>
#include <chrono>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// Linux Serial Headers
#include <asm/termbits.h> // Required for termios2 and BOTHER
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

// --- Configuration ---
const std::string SERIAL_PORT = "/dev/ttyUSB1";
const int TARGET_BAUD_RATE = 115200; // 5M Baud (Change to 115200 if needed)

const int RX_TIMEOUT_SEC = 3;

// Global control flags
std::atomic<bool> g_stop_receiving(false);
std::mutex g_io_mutex; // Mutex to prevent cout collision between threads

// --- Helper: Convert 32-bit int to Little Endian Bytes ---
std::vector<uint8_t> to_little_endian(uint32_t value) {
  std::vector<uint8_t> bytes(4);
  bytes[0] = value & 0xFF;
  bytes[1] = (value >> 8) & 0xFF;
  bytes[2] = (value >> 16) & 0xFF;
  bytes[3] = (value >> 24) & 0xFF;
  return bytes;
}

// --- Serial Port Configuration ---
int configure_serial(const std::string &port, int baud_rate) {
  int fd = open(port.c_str(), O_RDWR | O_NOCTTY | O_SYNC);
  if (fd < 0) {
    perror("Error opening serial port");
    return -1;
  }

  struct termios2 tty;

  // Use ioctl with TCGETS2/TCSETS2 for custom baud rates (Linux specific)
  if (ioctl(fd, TCGETS2, &tty) != 0) {
    perror("Error getting termios2");
    close(fd);
    return -1;
  }

  // Clear specific flags
  tty.c_cflag &= ~PARENB;  // No parity
  tty.c_cflag &= ~CSTOPB;  // 1 Stop bit
  tty.c_cflag &= ~CSIZE;   // Clear size mask
  tty.c_cflag |= CS8;      // 8 data bits
  tty.c_cflag &= ~CRTSCTS; // Disable hardware flow control (enable if needed)
  tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines

  // Raw input mode
  tty.c_lflag &= ~ICANON;
  tty.c_lflag &= ~ECHO;
  tty.c_lflag &= ~ECHOE;
  tty.c_lflag &= ~ISIG;
  tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Disable software flow control
  tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL);
  tty.c_oflag &= ~OPOST; // Prevent special interpretation of output bytes (e.g.
                         // newline chars)
  tty.c_oflag &= ~ONLCR;

  // Set Custom Baud Rate
  tty.c_cflag &= ~CBAUD;
  tty.c_cflag |= BOTHER;
  tty.c_ispeed = baud_rate;
  tty.c_ospeed = baud_rate;

  // Setup non-blocking read with timeout (VTIME in deciseconds)
  // We set a small timeout so the read loop doesn't block indefinitely,
  // allowing the thread to check g_stop_receiving.
  tty.c_cc[VMIN] = 0;
  tty.c_cc[VTIME] = 1; // 0.1 seconds

  if (ioctl(fd, TCSETS2, &tty) != 0) {
    perror("Error setting termios2");
    close(fd);
    return -1;
  }

  return fd;
}

// --- Receiver Thread ---
void receive_thread_func(int fd) {
  uint8_t buffer[1];
  std::vector<uint8_t> current_packet;
  int expected_len = -1; // -1 indicates we are waiting for the length byte

  while (!g_stop_receiving) {
    int n = read(fd, buffer, 1);

    if (n > 0) {
      uint8_t byte = buffer[0];

      if (expected_len == -1) {
        // This byte is the length header
        expected_len = static_cast<int>(byte);
        current_packet.clear();

        // If length is 0, handle immediately (empty packet)
        if (expected_len == 0) {
          std::lock_guard<std::mutex> lock(g_io_mutex);
          std::cout << "[RX] Empty Packet Received." << std::endl;
          expected_len = -1;
        }
      } else {
        // This is a data byte
        current_packet.push_back(byte);

        if (current_packet.size() == static_cast<size_t>(expected_len)) {
          // Packet complete
          std::lock_guard<std::mutex> lock(g_io_mutex);

          if (expected_len == 1) {
            // Single byte: print as ASCII character
            std::cout << static_cast<char>(current_packet[0]) << std::flush;
          } else {
            // Multi-byte: interpret as signed integer (little-endian)
            uint64_t value = 0;
            for (size_t i = 0; i < current_packet.size() && i < 8; i++) {
              value |= (static_cast<uint64_t>(current_packet[i]) << (i * 8));
            }
            // Sign-extend based on actual packet size
            size_t bits = current_packet.size() * 8;
            if (bits < 64 && (value >> (bits - 1)) & 1) {
              value |= ~((1ULL << bits) - 1);
            }
            std::cout << static_cast<int64_t>(value) << std::flush;
          }

          // Reset for next packet
          expected_len = -1;
        }
      }
    }
  }
}

// --- Main Execution ---
// Main Execution
int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Error: valid parameter count is 1" << std::endl;
    return 1;
  }
  const std::string INPUT_FILE = argv[1];
  // 1. Setup Serial
  std::cout << "Connecting to " << SERIAL_PORT << " at " << TARGET_BAUD_RATE
            << " baud..." << std::endl;
  int serial_fd = configure_serial(SERIAL_PORT, TARGET_BAUD_RATE);
  if (serial_fd < 0)
    return 1;

  // 2. Start Receiver Thread
  std::thread rx_thread(receive_thread_func, serial_fd);

  // 3. Open Hex File
  std::ifstream file(INPUT_FILE);
  if (!file.is_open()) {
    std::cerr << "Failed to open " << INPUT_FILE << std::endl;
    g_stop_receiving = true;
    rx_thread.join();
    close(serial_fd);
    return 1;
  }

  // 4. Parse and Send
  std::string line;
  int instruction_count = 0;
  while (std::getline(file, line)) {
    if (line.empty())
      continue;

    try {
      // Parse hex string to 32-bit int
      uint32_t instruction = std::stoul(line, nullptr, 16);

      // Convert to Little Endian
      std::vector<uint8_t> raw_bytes = to_little_endian(instruction);

      // Write to Serial
      int written = write(serial_fd, raw_bytes.data(), raw_bytes.size());
      if (written != raw_bytes.size()) {
        std::cerr << "Write error on instruction: " << line << std::endl;
      } else {
        instruction_count++;
      }
    } catch (const std::exception &e) {
      std::cerr << "Skipping invalid line: " << line << " (" << e.what() << ")"
                << std::endl;
    }
  }

  {
    std::lock_guard<std::mutex> lock(g_io_mutex);
    std::cout << "Sent " << instruction_count << " instructions. Waiting "
              << RX_TIMEOUT_SEC << " seconds for response..." << std::endl;
  }

  // 5. Wait for Timeout
  std::this_thread::sleep_for(std::chrono::seconds(RX_TIMEOUT_SEC));

  // 6. Cleanup
  g_stop_receiving = true;
  if (rx_thread.joinable()) {
    rx_thread.join();
  }

  close(serial_fd);

  return 0;
}