#include <fmt/chrono.h>
#include <fmt/color.h>

int main() {
  auto now = std::chrono::system_clock::now();
  fmt::print("\nDate and time: {}\n", now);
  fmt::print("Time: {:%H:%M}\n", now);
  return 0;
}           