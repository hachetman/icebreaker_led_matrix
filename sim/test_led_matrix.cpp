// -*- SystemC -*-
// DESCRIPTION: Verilator Example: Top level main for invoking SystemC model
//
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2017 by Wilson Snyder.
//======================================================================

// SystemC global header
#include <systemc.h>

// Include common routines
#include <verilated.h>
#if VM_TRACE
#include <verilated_vcd_sc.h>
#endif

#include <sys/stat.h> // mkdir

// Include model header, generated from Verilating "top.v"
#include "Vled_driver.h"

int sc_main(int argc, char *argv[]) {
  // This is a more complicated example, please also see the simpler
  // examples/make_hello_c.

  // Prevent unused variable warnings
  if (0 && argc && argv) {
  }

  // Set debug level, 0 is off, 9 is highest presently used
  // May be overridden by commandArgs
  Verilated::debug(0);

  // Randomization reset policy
  // May be overridden by commandArgs
  Verilated::randReset(2);

  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  Verilated::commandArgs(argc, argv);

  // General logfile
  ios::sync_with_stdio();

  // Define clocks
  sc_clock clk("clk", 10, SC_NS, 0.5, 3, SC_NS, true);

  // Define interconnect
  sc_signal<bool> reset(0x0);
  sc_signal<unsigned int> led_rgb0;
  sc_signal<unsigned int> led_rgb1;
  sc_signal<unsigned int> led_addr;
  sc_signal<unsigned int> blank;
  sc_signal<unsigned int> latch;
  sc_signal<unsigned int> sclk;
  // Construct the Verilated model, from inside Vtop.h
  Vled_driver *top = new Vled_driver("top");
  // Attach signals to the model
  top->clk(clk);
  top->reset(reset);
  top->led_rgb0(led_rgb0);
  top->led_rgb1(led_rgb1);
  top->led_addr(led_addr);
  top->blank(blank);
  top->latch(latch);
  top->sclk(sclk);
#if VM_TRACE
  // Before any evaluation, need to know to calculate those signals only used
  // for tracing
  Verilated::traceEverOn(true);
#endif

  // You must do one evaluation before enabling waves, in order to allow
  // SystemC to interconnect everything for testing.
  sc_start(1, SC_NS);

#if VM_TRACE
  // If verilator was invoked with --trace argument,
  // and if at run time passed the +trace argument, turn on tracing
  VerilatedVcdSc *tfp = NULL;
  const char *flag = Verilated::commandArgsPlusMatch("trace");
  if (flag && 0 == strcmp(flag, "+trace")) {
    cout << "Enabling waves into logs/led_dump.vcd...\n";
    tfp = new VerilatedVcdSc;
    top->trace(tfp, 99); // Trace 99 levels of hierarchy
    Verilated::mkdir("logs");
    tfp->open("logs/led_dump.vcd");
  }
#endif

  // Simulate until $finish
  while (VL_TIME_Q() < 20000) {
#if VM_TRACE
    // Flush the wave files each cycle so we can immediately see the output
    // Don't do this in "real" programs, do it in an abort() handler instead
    if (tfp) {
      tfp->dump(sc_time_stamp().to_double());
      tfp->flush();
    }
#endif

    // Apply inputs
    if (VL_TIME_Q() > 1 && VL_TIME_Q() < 10) {
      reset = 1; // Assert reset
    } else if (VL_TIME_Q() > 1) {
      reset = 0; // Deassert reset
    }

    // Simulate 1ns
    sc_start(1, SC_NS);
  }

  // Final model cleanup
  top->final();

  // Close trace if opened
#if VM_TRACE
  if (tfp) {
    tfp->close();
    tfp = NULL;
  }
#endif

  //  Coverage analysis (since test passed)
#if VM_COVERAGE
  Verilated::mkdir("logs");
  VerilatedCov::write("logs/coverage.dat");
#endif

  // Destroy model
  delete top;
  top = NULL;

  // Fin
  return 0;
}
