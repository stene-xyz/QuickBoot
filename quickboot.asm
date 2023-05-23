; QuickBoot bootloader
; This bootloader allows for loading large assembly programs from a floppy
; without requiring any complexities like a filesystem or "packing" stage
; in the software build process. To use QuickBoot, simply include this file
; before ANY program code (but after the BITS 16 instruction). When running
; from a floppy (or as a floppy image), this will load the next 63 sectors
; (32 KiB minus the boot sector) to 2000h:0000 and jump to it.
;
; MIT License
;
; Copyright (c) 2023 Johnny Stene
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

; Sections are required so offsets don't go all weird
section BOOTSECTOR start=0000h
bootloader_main:
    ; setup stack and segments
    cli
    mov ax, 07C0h
    add ax, 544
    mov ss, ax
    mov sp, 4096
    sti

    mov ax, 07C0h
    mov ds, ax

    cld

    mov si, bootloader_msg_reading
    call bootloader_print_string

bootloader_read_os:
	pusha
	mov ax, 0
	mov dl, [boot_device]
	stc
	int 13h
	pusha
	mov ah, 01h
	mov dl, [boot_device]
	int 13h
	popa
	popa

    ; Set ES to where OS will load
    push ax
    mov ax, 2000h
    mov es, ax
    pop ax
	pusha

    mov ax, 1
    mov bl, 63
	push bx
	push ax
	mov bx, ax
	mov dx, 0
	div word [boot_sectors_per_track]
	add dl, 01h
	mov cl, dl
	mov ax, bx
	mov dx, 0
	div word [boot_sectors_per_track]
	mov dx, 0
	div word [boot_sides]
	mov dh, dl
	mov ch, al
	pop ax
	pop bx
	mov dl, [boot_device]
	mov ah, 02h
	mov al, bl
	mov bx, 0
	int 13h
	jc .error
	popa
    mov si, bootloader_msg_booting
    call bootloader_print_string
	jmp 2000h:0000h

	.error:
		mov si, floppy_error_msg
		call bootloader_print_string
		popa
		jmp bootloader_main

bootloader_print_string:
    pusha
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh

    .loop:
        lodsb
        cmp al, 0
        je .done
        int 10h
        jmp .loop
    
    .done:
        popa
        ret

bootloader_msg_reading db "Reading OS...", 13, 10, 0
bootloader_msg_booting db "Booting...", 13, 10, 0

boot_sectors_per_track		dw 18
boot_sides					dw 2
boot_device					db 0

times 510-($-$$) db 0
dw 0xaa55
section KERNEL follows=BOOTSECTOR vstart=0000h
