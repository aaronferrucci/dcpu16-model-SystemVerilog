
`timescale 1ns / 1ns

`define DUT sim_top.dut
`define CLK_PERIOD 10
module test_program #(parameter TEST = "test.hex");

  logic clk = 0;
  initial begin
    fork
      begin : first_block
        $display("first block");
        #20;
      end : first_block
      begin : second_block
        $display("second block");
      end : second_block
    join_any
  end

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
        if (`DUT.instruction == 16'h3FF0)
          $display("%t: < ILLEGAL OPCODE (success code)>", $time());
        else
          $display("%t: < ILLEGAL OPCODE (0x%0X)>", $time(), `DUT.instruction);
      end : catch_illegal_opcode

      // Q: do I want a clock?  Maybe for counting instruction execution
      // cycles?
      begin : clock_thread
        forever
          #`CLK_PERIOD clk = ~clk;
      end : clock_thread
    join_any

    $display("%t: simulation complete", $time());

    $stop;
  end

endmodule
