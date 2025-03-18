# Timing Analysis with OpenSTA

This directory contains scripts for performing static timing analysis (STA) on the synthesized designs using OpenSTA.

## Setup

- OpenSTA binary is located at `/home/joyen/Desktop/OpenSTA/app/sta`
- Liberty files are from the SkyWater 130nm PDK

## Available Scripts

### `timing_analysis.tcl`

Main OpenSTA script that performs timing analysis on the synthesized design. It:
- Reads the liberty file
- Loads the synthesized netlist
- Applies SDC constraints
- Generates timing reports (setup, hold, etc.)
- Outputs detailed reports to the report directory

### `generate_sdf.tcl`

Script to generate Standard Delay Format (SDF) files for the design. SDF files can be used for gate-level simulation with accurate timing.

### `sample_constraints.sdc`

A sample Synopsys Design Constraints (SDC) file that can be used as a starting point for defining timing constraints.

### `run_sta.sh`

A shell script that sets up the environment and runs the OpenSTA timing analysis.

## Usage

To perform timing analysis after synthesis:

```bash
make sta
```

To generate an SDF file for the design:

```bash
make generate_sdf
```

To view a summary of timing reports (if already generated):

```bash
make timing_report
```

## Note on SDC Constraints

The timing analysis relies on proper SDC constraints. If you don't have SDC constraints for your design, you can:

1. Use the sample_constraints.sdc as a starting point
2. Copy it to build/synth/mk_router.sdc
3. Modify it according to your design's timing requirements

Adjust clock periods, input/output delays, and other timing constraints based on your specific needs.
