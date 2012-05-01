
all: compile sim

SIM_TOP := sim_top
MODEL := dcpu16_model
MODEL_DIR := ../model
TEST_PROGRAM := test_program

# Pointers to "golden reference"
GREF_DIR := ../../dcpu16
GREF_ASM := $(GREF_DIR)/a16.exe
GREF_EMU := $(GREF_DIR)/dcpu.exe

TESTS_DIR := $(GREF_DIR)/tests
RESULTS_DIR := results
UTILS_DIR := utils

compile: lib test_program top
lib:
	vlib work
top:
	vlog +incdir+$(MODEL_DIR) -sv $(SIM_TOP).sv
VSIM_EXIT := [ expr ![ examine sim_top.pgm.success ] ]
TARGET_PROGRAM := $(TESTS_DIR)/testskip3.hex
sim:
	[ -f $(TARGET_PROGRAM) ]
	vsim -c -do \
          "vsim \
          -G$(SIM_TOP)/TARGET_PROGRAM=\"$(TARGET_PROGRAM)\" \
          $(SIM_TOP); \
          run -a; \
          quit -code $(VSIM_EXIT);"

sim_debug:
	[ -f $(TARGET_PROGRAM) ]
	vsim -do \
          "vsim \
          -G$(SIM_TOP)/TARGET_PROGRAM=\"$(TARGET_PROGRAM)\" \
          $(SIM_TOP); \
          run -a;"

test_program:
	vlog -sv $(TEST_PROGRAM).sv

clean:
	rm -rf work
	rm -f vsim.wlf transcript
	rm -rf results

$(TARGET_PROGRAM): $(TARGET_PROGRAM:.hex=.s)
	$(GREF_ASM) -o $(TARGET_PROGRAM) -O hex $(TARGET_PROGRAM:.hex=.s)

.PHONY: gref_tools
gref_tools:
	make -C $(GREF_DIR) a16
	make -C $(GREF_DIR) dcpu

$(RESULTS_DIR):
	mkdir -p $(RESULTS_DIR)

.PHONY: test
test: $(RESULTS_DIR) gref_tools $(TARGET_PROGRAM)
	@echo -e "\nverifying golden reference and sv model against '$(TARGET_PROGRAM)'\n"
	$(GREF_EMU) $(TARGET_PROGRAM) 2>&1 | \
          perl filter_gref_output.pl > \
          $(RESULTS_DIR)/gref_$(notdir $(TARGET_PROGRAM)).out
	vsim -c -do \
          "vsim \
          -G$(SIM_TOP)/TARGET_PROGRAM=\"$(TARGET_PROGRAM)\" \
          $(SIM_TOP); \
          run -a; \
          quit -code $(VSIM_EXIT);"
	cat transcript | \
          perl filter_model_output.pl > \
          $(RESULTS_DIR)/model_$(notdir $(TARGET_PROGRAM)).out
	diff -b \
          $(RESULTS_DIR)/gref_$(notdir $(TARGET_PROGRAM)).out \
          $(RESULTS_DIR)/model_$(notdir $(TARGET_PROGRAM)).out

	
