#include <fmt/chrono.h>
#include <fmt/color.h>

#include <magic_enum/magic_enum.hpp>
#include <iostream>

enum Color { RED = -10, BLUE = 0, GREEN = 10, ALPHA = 5 };

int main() {
  // FMT Example
  auto now = std::chrono::system_clock::now();
  fmt::print("\nDate and time: {}\n", now);
  fmt::print("Time: {:%H:%M}\n", now);

  // MAGIC_ENUM Example
  for (const auto& [value, name] : magic_enum::enum_entries<Color>()) {
    fmt::print("{} value {}\n", name, static_cast<int>(value));
  }
  fmt::print("Test");
  return 0;
}