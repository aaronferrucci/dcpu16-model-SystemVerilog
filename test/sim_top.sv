`default_nettype none

`include "dcpu16_model.sv"
module sim_top();
  parameter TARGET_PROGRAM = "test.hex";
  dcpu16_model dut = new;
  test_program #(
    .TARGET_PROGRAM (TARGET_PROGRAM)
  ) pgm ();
endmodule

`default_nettype wire
