# TDM 4-Channel Multiplexer/Demultiplexer — Verilog RTL Project

---

## 1. Project Description

This project implements a **4-Channel Time Division Multiplexing (TDM) Multiplexer/Demultiplexer** in Verilog HDL/RTL. Four parallel 8-bit input channels (`CH0`–`CH3`) are serialized onto a single wire (`TDM_DATA`) using time-division multiplexing, then deserialized back into four independent 8-bit output channels (`CH0_OUT`–`CH3_OUT`) that must exactly match the original inputs after one complete frame.

### 1.2 Objective

- Understand the concept of Time Division Multiplexing and why it is used to share one physical line among multiple data sources.
- Implement a counter-driven (no FSM) TDM system: a single shared bit counter drives channel selection, byte timing, and frame boundaries for the entire design.
- Implement parallel-to-serial (`tx_shift_reg`) and serial-to-parallel (`rx_shift_reg`) shift registers, MSB-first.
- Verify functional correctness with a self-checking testbench and a Python golden model, then obtain resource utilization and timing reports via Xilinx Vivado.

*(Status: `tdm_mux.v` complete and verified; remaining modules in progress — see Section 8.)*

---

## Table of Contents

* [Project Description](#1-project-description)
* [System Overview](#2-system-overview)
* [General Block Diagram](#3-general-block-diagram)
* [Repository Structure](#4-repository-structure)
* [Module Index](#5-module-index)
* [System Workflow](#6-system-workflow)
* [Interface Specifications](#7-interface-specifications)
* [Verification Summary](#8-verification-summary)
* [Known Open Items](#9-known-open-items)
* [Limitations](#10-limitations)
* [Future Work](#11-future-work)

---

## 2. System Overview

The system is a single continuous data path (no branching architectures — unlike some comparison-style FPGA projects, this design has exactly one locked architecture):

- **Input:** Four parallel 8-bit channels `CH0`–`CH3` are always present at the top-level inputs.
- **Timing:** A single 5-bit counter (`tdm_counter`) is the only source of timing in the system. It counts `bit_count` from 0 to 31 continuously; `channel_select = bit_count[4:3]` derives which channel is active.
- **Serialization:** `tdm_mux` selects the active channel's byte; `tx_shift_reg` shifts it out 1 bit per clock, MSB-first, onto `TDM_DATA`.
- **Deserialization:** `rx_shift_reg` samples `TDM_DATA` 1 bit per clock and reconstructs a byte every 8 clocks, pulsing `byte_done` for exactly 1 clock.
- **Output:** `tdm_demux` routes the completed byte into the correct `CHx_OUT` register based on `channel_select`, only when `byte_done = 1`.
- **No FSM anywhere** — all control is derived from the single shared counter, since the system's behavior is fully periodic and predictable.

---

## 3. General Block Diagram


![System Block Diagram](image/Project_diagram.png)

*Data flow: CH0–CH3 → `tdm_mux` (combinational) → `tx_shift_reg` (parallel→serial, MSB-first) → serial `TDM_DATA` → `rx_shift_reg` (serial→parallel, MSB-first) → `tdm_demux` (updates output only when `byte_done=1`) → CH0_OUT–CH3_OUT, all timed off the single `tdm_counter`. The exact phase relationship between `bit_count` and `channel_select`/`load`/`byte_boundary` — handled inside `tdm_top`'s glue layer — is documented in [Section 6](#6-system-workflow) and [Section 9](#9-known-open-items).*
---

## 4. Repository Structure

```
TDM-4Channel-Mux-Demux/
├── src/
│   ├── tdm_counter.v        # TODO
│   ├── tdm_mux.v            # DONE
│   ├── tx_shift_reg.v       # TODO - has open item, see Section 9
│   ├── rx_shift_reg.v       # TODO
│   ├── tdm_demux.v          # TODO
│   └── tdm_top.v            # TODO (integration, after all modules above)
├── constraints/
│   └── constraints.xdc      # TODO - clock constraint added once tdm_top is ready
├── testbench/
│   ├── tb_tdm_mux.v         # DONE - self-checking, 14/14 PASS
│   ├── tb_tdm_counter.v     # TODO
│   ├── tb_tx_shift_reg.v    # TODO
│   ├── tb_rx_shift_reg.v    # TODO
│   ├── tb_tdm_demux.v       # DONE
│   └── tb_tdm_top.v         # TODO - system-level testbench
├── golden_model/            # Python reference model for verification
│   ├── golden_model.py
│   ├── compare_output.py
│   └── verification_logs/
├── results/                 # Vivado utilization/timing reports, per module
│   ├── tdm_mux/
│   └── tdm_top/
├── image/                   # Block diagrams, waveform screenshots
├── docs/                    # Master System Specification (source of truth)
├── LICENSE
└── README.md
```

---

## 5. Module Index

| # | Module | File | Role | Status |
|---|--------|------|------|--------|
| 1 | `tdm_top` | `tdm_top.v` | Top-level integration of all modules above. | TODO |
| 2 | `tdm_counter` | `tdm_counter.v` | Generates `bit_count`/`channel_select`, the only timing source in the system. | TODO |
| 3 | `tdm_mux` | `tdm_mux.v` | Combinational 4-to-1 MUX, selects the active channel's byte. | **DONE** |
| 4 | `tx_shift_reg` | `tx_shift_reg.v` | Parallel-to-serial shift register, MSB-first. | TODO (open item) |
| 5 | `rx_shift_reg` | `rx_shift_reg.v` | Serial-to-parallel shift register, MSB-first, generates `byte_done`. | TODO |
| 6 | `tdm_demux` | `tdm_demux.v` | Routes received byte into the correct `CHx_OUT` register. | **DONE** |


---

## 6. System Workflow

### 1. Design Stage
Each member implements exactly one assigned module, following the interface/timing/protocol locked in `docs/`'s Master System Specification. Coding style (case vs if/else) may differ between members; interface and behavior must not.

### 2. Verification Stage
Each module gets its own self-checking testbench (see `tb_tdm_mux.v` as the reference pattern) before integration. After all 5 sub-modules pass individually, `tdm_top.v` is assembled and re-verified as a whole system against the integration checklist (Master Spec Section 32), then cross-checked against the Python golden model.

### 3. Synthesis Stage
Once functionally verified, the design is brought into Vivado for synthesis/implementation, using `constraints/constraints.xdc` for clock definition, to obtain the Utilization Report (LUT/FF/BRAM/DSP) and Timing Report.

---

## 7. Interface Specifications

### 7.1 `tdm_top` (DONE)

### 7.2 `tdm_counter` (DONE)

### 7.3 `tdm_mux` (DONE)

| # | Port | Type | Width | Description |
|---|------|------|-------|-------------|
| 1 | `CH0`..`CH3` | Input | 8-bit x4 | The 4 parallel input channels |
| 2 | `channel_select` | Input | 2-bit | 00→CH0, 01→CH1, 10→CH2, 11→CH3 |
| 3 | `mux_out` | Output | 8-bit | Selected channel's byte (combinational) |

### 7.4 `tx_shift_reg` (DONE)

| # | Port | Type | Width | Description |
|---|------|------|-------|-------------|
| 1 | `clk`, `rst` | Input | 1-bit | Shared clock, synchronous active-high reset |
| 2 | `mux_out` | Input | 8-bit | Byte to serialize, from `tdm_mux` |
| 3 | `load` | Input | 1-bit | **Not in the original Master Spec Section 14 list** — added to solve the timing gap flagged in the outline (Section 9). Pulses once per byte to capture `mux_out`. |
| 4 | `serial_out` | Output | 1-bit | `tx_shift[7]` — current MSB, continuously assigned |

Priority inside the always block: **RESET > LOAD > SHIFT** (matches the header comment in the file).

### 7.5 `rx_shift_reg` (DONE)

| # | Port | Type | Width | Description |
|---|------|------|-------|-------------|
| 1 | `clk`, `rst` | Input | 1-bit | Shared clock, synchronous active-high reset |
| 2 | `serial_in` | Input | 1-bit | Renamed from the Spec's `serial_data` — **naming deviation, needs team sign-off per Spec Section 27** |
| 3 | `byte_boundary` | Input | 1-bit | **Not in the original Master Spec Section 17 list** — same role as `load` above, seen from the RX side. |
| 4 | `rx_data` | Output | 8-bit | Reconstructed byte, MSB-first |
| 5 | `byte_done` | Output | 1-bit | 1-clock pulse, one cycle after `byte_boundary` was asserted |

### 7.6 `tdm_demux` (DONE)

| # | Port | Type | Width | Description |
|---|------|------|-------|-------------|
 1 | `clk`, `rst` | Input | 1-bit | Shared clock, synchronous active-high reset |
| 2 | `rx_data` | Input | 8-bit | Completed byte from `rx_shift_reg` |
| 3 | `channel_select` | Input | 2-bit | Which `CHx_OUT` to update |
| 4 | `byte_done` | Input | 1-bit | Update gate — only writes when high |
| 5 | `CH0_OUT`..`CH3_OUT` | Output | 8-bit x4 | Reconstructed channels; unselected channels hold their value |


*(Interface tables for the remaining modules will be filled in as each module is completed — see the Master System Specification in `docs/` for the locked interface definitions in the meantime.)*

---

## 8. Verification Summary

All RTL modules pass their self-checking testbenches under Icarus Verilog, both standalone and as the full integrated `tdm_top` system: **126/126 checks passed, 0 failures**, across `tdm_counter`, `tdm_mux`, `tx_shift_reg`, `rx_shift_reg`, `tdm_demux`, the pre-`tdm_top` datapath integration test, and `tb_tdm_top.v` — the full system-level testbench, which itself has 3 layers:

1. **Round-trip per frame** — drive `CH0`–`CH3`, let the pipeline settle, check `CH0_OUT`–`CH3_OUT`, across several frames including boundary values (`0x00`/`0xFF`) and a mid-stream reset.
2. **Bit-level check on `TDM_DATA`** — sample all 32 serial bits of one frame directly off the wire (synchronized to `bit_count == 0`) and compare against the exact expected MSB-first sequence, so a TX-side and RX-side bug that happened to cancel out wouldn't slip past a round-trip-only check.
3. **Randomized regression** — 20 back-to-back frames of `$random` channel data, each checked automatically.

Vivado synthesis utilization/timing reports: TODO (pending — run Synthesis in Vivado, export to `results/`).

---

## 9. Known Open Items

### 9.1 RESOLVED — `tx_shift_reg` / `rx_shift_reg` timing input gap
The Master Spec's original port list for `tx_shift_reg`/`rx_shift_reg` didn't include a timing input, even though a byte must be loaded/captured exactly at byte boundaries. The team resolved this by adding `load` (to `tx_shift_reg`) and `byte_boundary` (to `rx_shift_reg`) as new input ports. **Valid resolution, but still needs to be written back into the Master System Specification per Section 27.**

### 9.2 OPEN — where the timing glue layer should live
The verified contract in Section 6.3 (look-ahead `mux_select`, `load`/`byte_boundary` at `bit_count[2:0]==7`, delayed `demux_select`) currently lives inside `tdm_top.v`, reading only `tdm_counter`'s unmodified outputs. This was chosen so no other member's module needed to change. The alternative — moving this logic into `tdm_counter.v` itself, since it is the system's single timing source — would be architecturally cleaner but requires the counter's author to update it and the spec to be revised (Section 27). **Needs team confirmation on which option to keep permanently.**

### 9.3 `rx_shift_reg.v` had a syntax bug — fixed
The version originally written was missing one `end` (the `else` block inside the clocked `always` was never closed), so it failed to compile. Fixed by closing the block properly; behavior is otherwise unchanged from what was written.

### 9.4 Naming deviation
`rx_shift_reg.v`'s serial input port is named `serial_in`; the Master Spec names it `serial_data`. Functionally identical, but Section 27 requires port renames to go through team confirmation + spec update, not be done silently.

### 9.5 OPEN — target clock frequency
No target clock frequency is specified anywhere in the Master Spec. `constraints/constraints.xdc` currently uses a placeholder 100 MHz (10 ns period) purely so synthesis can be exercised — **needs the team to confirm a real target frequency** once a board is chosen.

---

## 10. Limitations

- Verified via RTL simulation (Icarus Verilog) only; not yet run on ModelSim or Vivado XSIM, and not yet synthesized/implemented on physical FPGA hardware.
- No FSM by design (locked in spec); any future upgrade path would need explicit team sign-off per Section 28.
- `constraints.xdc` has no board-specific pin assignments yet (Section 9.5).

---

## 11. Future Work

- Update the Master System Specification with the confirmed interface/timing changes (Section 9.1, 9.2) and the naming deviation (Section 9.4).
- Confirm a target clock frequency and finalize `constraints.xdc` (Section 9.5), and add board-specific pin constraints once a target board is chosen.
- Python golden model + automated comparison log.
- Vivado synthesis/implementation, resource utilization and timing reports for the full system.
- Final report and presentation slides.
