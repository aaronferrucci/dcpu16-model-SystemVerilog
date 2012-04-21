
all: compile sim

SIM_TOP := sim_top
MODEL := dcpu16_model
MODEL_DIR := ../model
TEST_PROGRAM := test_program

compile: lib test_program top
lib:
	vlib work
# model:
# 	vlog +incdir+$(MODEL_DIR) -sv $(MODEL_DIR)/$(MODEL).sv

top:
	vlog +incdir+$(MODEL_DIR) -sv $(SIM_TOP).sv

TEST := example.hex
sim:
	[ -f $(TEST) ]
	vsim -c -do \
          "vsim \
          -G$(SIM_TOP)/TEST=\"$(TEST)\" \
          $(SIM_TOP); \
          run -a; \
          quit -code 0;"

test_program:
	vlog -sv $(TEST_PROGRAM).sv


clean:
	rm -rf work
	rm -f vsim.wlf transcript
