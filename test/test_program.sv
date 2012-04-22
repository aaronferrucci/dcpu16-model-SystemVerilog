
`timescale 1ns / 1ns

`define DUT sim_top.dut
`define CLK_PERIOD 10
module test_program #(parameter TEST = "test.hex");

  bit success = 0;
  logic clk = 0;

  initial begin
    fork
      begin : main_thread
        `DUT.reset();
        `DUT.load(TEST);

        `DUT.dumpheader();

        forever begin
          @(posedge clk);
          `DUT.dumpstate();
          `DUT.step();
        end
      end : main_thread

      begin : catch_illegal_opcode
        wait (`DUT.illegal_opcode.triggered);
        if (`DUT.instruction == 16'h3FF0) begin
          $display("%t: < ILLEGAL OPCODE (success code)>", $time());
          success = 1;
        end
        else begin
          $display("%t: < ILLEGAL OPCODE (0x%0X)>", $time(), `DUT.instruction);
        end
      end : catch_illegal_opcode

      // Q: do I want a clock?  Maybe for counting instruction execution
      // cycles?
      begin : clock_thread
        forever
          #`CLK_PERIOD clk = ~clk;
      end : clock_thread
    join_any

    $display("%t: simulation complete, success code: %0d", $time(), success);

    $stop;
  end

endmodule
