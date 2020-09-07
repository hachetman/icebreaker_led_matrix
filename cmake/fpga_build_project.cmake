set(FPGA_PROECT_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})

macro(fpga_build_project)
  set(options "")
  set(oneValueArgs
    TARGET
    TOP_LEVEL_VERILOG
    PCF_FILE
    HDL_INCLUDE
    )
  
  cmake_parse_arguments(FPGA "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN} )
  message("Creating an FPGA Build for Target '${FPGA_TARGET}'")
  message(${FPGA_TOP_LEVEL_VERILOG})
  
  add_custom_target(${FPGA_TARGET}.json
    COMMAND yosys -ql ${FPGA_TARGET}.yslog -p 'synth_ice40 -top top_level -json ${FPGA_TARGET}.json' ${FPGA_TOP_LEVEL_VERILOG} ${FPGA_HDL_INCLUDE}/*)
  add_custom_target(${FPGA_TARGET}.asc
    COMMAND echo ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND echo ${CMAKE_CURRENT_LIST_DIR}
    DEPENDS ${FPGA_TARGET}.json
    COMMAND nextpnr-ice40 -ql ${FPGA_TARGET}.nplog --up5k --package sg48 --freq 12 --asc ${FPGA_TARGET}.asc --pcf ${FPGA_PCF_FILE} --json ${FPGA_TARGET}.json)
  add_custom_target(${FPGA_TARGET}.bin
    DEPENDS ${FPGA_TARGET}.asc
    COMMAND icepack ${FPGA_TARGET}.asc ${FPGA_TARGET}.bin)
  add_custom_target(${FPGA_TARGET}.rpt
    DEPENDS ${FPGA_TARGET}.asc
    COMMAND icetime -d up5k -c 12 -mtr ${FPGA_TARGET}.rpt ${FPGA_TARGET}.asc)
  add_custom_target(${FPGA_TARGET}.prog
    DEPENDS ${FPGA_TARGET}.bin
    COMMAND iceprog ${FPGA_TARGET}.bin)
 
endmacro()
