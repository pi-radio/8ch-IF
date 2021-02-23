# Instructions for building the SD card images

## Create the project
```console
$ petalinux-create -t project -s piradio_plnx.bsp
```

## Configure the project with the latest `.xsa` file
```console
$ cd plnx
$ petalinux-config --get-hw-description=../pl/project
```
In the dialog indicate in the 'FPGA Manager' the location of the Vivado project.

## Build the project
```console
% petalinux-build
```

## Create the SD card images
First, navigate to the `apu/plnx/images/linux` folder.
```console
$ cd images/linux
```
Create `bitstream.bif` if this file doesn't exist with the following contents
```console
all:
{
	[destination_device = pl] system.bit /* Bitstream file name */
}
```
Then, execute the following commands to build the binaries
```console
$ petalinux-package --force --boot --fsbl zynqmp_fsbl.elf --pmufw pmufw.elf --u-boot u-boot.elf
$ bootgen -image bitstream.bif -arch zynqmp -o zcu111_rfsoc_trd_wrapper.bit.bin -w
```
Copy the files to the `sdcard` folder
```console
$ cp pl.dtbo zcu111_rfsoc_trd_wrapper.bit.bin ../../../../sdcard/mts
$ cp BOOT.BIN image.ub boot.scr ../../../../sdcard
```

## Package the modified project in `.bsp` format
Navigate to the `apu/plnx` folder and execute the following command.
```console
$ petalinux-config
```
In the dialog clear the location of the Vivado project of the FPGA Manager. Then, package the project by executing the following commands.
```console
$ cd ..
$ petalinux-package --bsp -p plnx --clear --output piradio_plnx.bsp --force
```

## More information
For more information about building the Petalinux image please refer to this [guide](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/571605227/Petalinux+Build+Tutorial+for+ZU+RFSoC+ZCU111+2020.1).
