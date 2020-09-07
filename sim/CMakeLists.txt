find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# SystemC dependencies
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

# Find SystemC using SystemC's CMake integration
find_package(SystemCLanguage QUIET)

add_executable(test_led test_led_matrix.cpp)
add_custom_command(TARGET test_led POST_BUILD
			  COMMAND echo "running executable"
			  COMMAND ./test_led +trace)
# Add the Verilated circuit to the target
verilate(test_led SYSTEMC COVERAGE TRACE
  INCLUDE_DIRS "../hdl/"
  VERILATOR_ARGS -f ..//input.vc -O2 -x-assign 0 --pins-bv 33
  SOURCES ../hdl/led_driver.sv)
verilator_link_systemc(test_led)
