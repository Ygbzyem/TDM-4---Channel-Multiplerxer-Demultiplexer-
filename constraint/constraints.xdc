# =============================================================
# constraints.xdc - Vivado design constraints for tdm_top
#
# *** OPEN ITEM - target clock frequency is NOT specified anywhere
# in the Master System Specification and has not been confirmed by
# the team. The 100 MHz / 10 ns period below is a common default for
# entry-level Xilinx boards (e.g. Basys3, Nexys A7) and is used here
# ONLY so synthesis/implementation can be exercised end-to-end in
# Vivado. Replace T_CLK_NS (and re-run timing analysis) once the
# team agrees on a real target frequency. ***
# =============================================================

# -----------------------------------------------------------
# Clock constraint
# -----------------------------------------------------------
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# -----------------------------------------------------------
# I/O pin locations - PLACEHOLDER ONLY
#
# tdm_top has no fixed target board yet, so no PACKAGE_PIN /
# IOSTANDARD values are set below. Uncomment and fill in once the
# team picks a board (pin numbers below are illustrative Basys3
# examples, NOT verified against any real board file):
#
# set_property PACKAGE_PIN W5  [get_ports clk]
# set_property IOSTANDARD LVCMOS33 [get_ports clk]
#
# set_property PACKAGE_PIN V17 [get_ports rst]
# set_property IOSTANDARD LVCMOS33 [get_ports rst]
#
# set_property PACKAGE_PIN {V1 U1 U2 V2 W2 W3 V3 W4} [get_ports {CH0[*]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {CH0[*]}]
# ... (repeat per CH1/CH2/CH3, TDM_DATA, CH0_OUT..CH3_OUT, using
#      whichever pins/IOSTANDARD match the board actually used)
# -----------------------------------------------------------

# -----------------------------------------------------------
# Input/output delay - not modeled (all I/O treated as
# synchronous to `clk` with no external board-level delay budget
# yet). Add set_input_delay / set_output_delay here once real I/O
# timing requirements are defined.
# -----------------------------------------------------------
