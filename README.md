# OCB12-PLD Firmware

_In-development unofficial MSX2+ firmware for OneChipBook-12 systems._
## Supported Devices

**1st Gen**
- OneChipBook-12 (a.k.a. MSXBOOK)
- 1chipMSX

**Note:** Similar modifications have been made to the source code for 1st Gen models other than OneChipBook-12 and 1chipMSX, but they have not been built or tested.
## About the automatic keymap switching feature
Hardware modification is required to use automatic keymap switching function (For modification instructions, see "docs/hardware patches for OneChipBook-12.pdf").

To use the automatic keymap switching feature, in addition to modifying the hardware, you need to rebuild the program by appropriately modifying the constants “use_fpga_pin17” and “blt_key_layout” in “keymap.vhd” and “emsx_top.vhd.onechipbook12”.

"use_fpga_pin17" specifies whether to obtain the PS/2 LED status from FPGA pin #17 (if no hardware modifications have been made, this will always be off, meaning the built-in keyboard is recognized as enabled).

"blt_key_layout" specifies layout of built-in keyboard, and is equivalent to "DefKmap" for an external keyboard.
JP keymap rom_int_ntv for built-in keyboard and keymap rom_int_cnv for other languages ​​have been added to "keymap.vhd", but due to the author's convenience, only US-JP keymap for Japanese BIOS is set correctly, so if you are using a other language BIOS or other language keyboard, you will need to modify it appropriately.
## License

Custom License - see [LICENSE](LICENSE) file for details.
