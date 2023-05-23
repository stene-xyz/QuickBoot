QuickBoot bootloader
This bootloader allows for loading large assembly programs from a floppy
without requiring any complexities like a filesystem or "packing" stage
in the software build process. To use QuickBoot, simply include this file
before ANY program code (but after the BITS 16 instruction). When running
from a floppy (or as a floppy image), this will load the next 63 sectors
(32 KiB minus the boot sector) to 2000h:0000 and jump to it.
