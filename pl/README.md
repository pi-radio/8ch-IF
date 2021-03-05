# Pi-Radio Non-Realtime FPGA Project

## Dependencies
* [Vivado 2020.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html)

## Building the project
The following command will create the project, run synthesis, implementation, generate the bitstream and export the hardware (`.xdc`) in `project/zcu111_rfsoc_trd.sdk`. We will use the `.xdc` file to configure the Petalinux project.
```console
$ vivado -mode batch -source scripts/create_project.tcl -nolog -nojournal
```