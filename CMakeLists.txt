cmake_minimum_required(VERSION 3.8)
project(ice40)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()
include(cmake/fpga_build_project.cmake)

fpga_build_project(
    TARGET led_matrix
    TOP_LEVEL_VERILOG "${CMAKE_CURRENT_SOURCE_DIR}/hdl/top_level.sv"
    PCF_FILE "${CMAKE_CURRENT_SOURCE_DIR}/constr/icebreaker.pcf"
    HDL_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/hdl/cores/hdl"
  )
fpga_build_project(
    TARGET uart
    TOP_LEVEL_VERILOG "${CMAKE_CURRENT_SOURCE_DIR}/hdl/uart_top.sv"
    PCF_FILE "${CMAKE_CURRENT_SOURCE_DIR}/constr/icebreaker.pcf"
    HDL_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/hdl/cores/hdl"
  )
