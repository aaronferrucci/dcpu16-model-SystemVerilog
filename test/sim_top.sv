`default_nettype none

`include "dcpu16_model.sv"
module sim_top();
  parameter TEST = "test.hex";
  dcpu16_model dut = new;
  test_program #(
    .TEST (TEST)
  ) pgm ();
endmodule

`default_nettype wire
