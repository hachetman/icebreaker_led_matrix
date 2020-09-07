cmake_minimum_required(VERSION 3.8)
project(ice40)

include(cmake/fpga_build_project.cmake)

fpga_build_project(
    TARGET led_matrix
    TOP_LEVEL_VERILOG "${CMAKE_CURRENT_SOURCE_DIR}/hdl/top_level.sv"
    PCF_FILE "${CMAKE_CURRENT_SOURCE_DIR}/constr/icebreaker.pcf"
    HDL_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/hdl"
  )
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_subdirectory(sim)
