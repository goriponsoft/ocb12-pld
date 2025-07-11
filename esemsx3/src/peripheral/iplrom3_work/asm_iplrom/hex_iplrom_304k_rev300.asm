; ==============================================================================
;   IPL-ROM v3.00 for OCM-PLD v3.9.1 or later
; ------------------------------------------------------------------------------
;   Initial Program Loader for Cyclone & EPCS (Altera)
;   Revision 3.00
;
; Copyright (c) 2021-2025 Takayuki Hara
; All rights reserved.
;
; Redistribution and use of this source code or any derivative works, are
; permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;	 this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;	 notice, this list of conditions and the following disclaimer in the
;	 documentation and/or other materials provided with the distribution.
; 3. Redistributions may not be sold, nor may they be used in a commercial
;	 product or activity without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
; OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
; ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; ------------------------------------------------------------------------------
; IPL-ROM Revision 2.00 for 512 KB unpacked with Dual-EPBIOS support
; EPCS16 [or higher] start adr 100000h - Optimized by KdL 2020.01.09
;
; Coded in TASM80 v3.2ud w/ TWZ'CA3 for OCM-PLD Pack v3.4 or later
; TASM is at https://www.ticalc.org
;
; SDHC support by Yuukun-OKEI, thanks to MAX
; ------------------------------------------------------------------------------
; History:
;   2022/Oct/22nd  v3.00  t.hara  Overall revision.  Coded in ZMA v1.0.15
;   2024/Jan/21st         KdL     Added C-BIOS support and other features.
;   2025/Jan/20th         KdL     Added smart profile management routine.
; ==============================================================================

; --------------------------------------------------------------------
;	EPBIOS address
; --------------------------------------------------------------------
epcs_bios1_start_address				:= 0x34000 >> 9

; --------------------------------------------------------------------
;	HEX-file location
; --------------------------------------------------------------------
destination_address						:= 0xB400		; B400h~BFFFh, 3072 bytes

; --------------------------------------------------------------------
;	MegaSD Information
; --------------------------------------------------------------------
megasd_sd_register						:= 0x4000		; Command register for read/write access of SD/SDHC/MMC/EPCS Controller (4000h-57FFh)
megasd_mode_register					:= 0x5800		; Mode register for write access of SD/SDHC/MMC/EPCS Controller (5800h-5FFFh)
megasd_status_register					:= 0x5800		; status register for read access of SD/SDHC/MMC/EPCS Controller (5800h-5BFFh)
megasd_last_data_register				:= 0x5C00		; last data register for read access of SD/SDHC/MMC/EPCS Controller (5C00h-5FFFh)

eseram8k_bank0							:= 0x6000		; 4000h~5FFFh bank selector
eseram8k_bank1							:= 0x6800		; 6000h~7FFFh bank selector
eseram8k_bank2							:= 0x7000		; 8000h~9FFFh bank selector
eseram8k_bank3							:= 0x7800		; A000h~BFFFh bank selector

; --------------------------------------------------------------------
;	I/O
; --------------------------------------------------------------------
primary_slot_register					:= 0xA8

; --------------------------------------------------------------------
;	Expanded I/O
; --------------------------------------------------------------------
exp_io_vendor_id_port					:= 0x40			; Vendor ID register for Expanded I/O
exp_io_1chipmsx_id						:= 0xD4			; KdL's switch device ID

smart_profile_location					:= 3072 - 128	; smart profile, last 128 bytes of IPL-ROM area

; --------------------------------------------------------------------
;	Work area
; --------------------------------------------------------------------
buffer									:= 0xC000		; read buffer (!! Expect the lower 8 bits to be 0 !!)
fat_buffer								:= 0xC200		; read buffer for FAT entry
dram_code_address						:= 0xF000		; program code address on DRAM (!! Expect the lower 8 bits to be 0 !!)

; --------------------------------------------------------------------
			org			dram_code_address
begin_of_code:											; !!!! Address 0xB400 and ROM !!!!

			di
;			ld			a, 0x40							; commented out if handled by the preloader
;			ld			[eseram8k_bank0], a				; BANK 40h
;			ld			a, [megasd_status_register]
			rrca										; Is the activation this time PowerOnReset?
			jr			nc, not_power_on_reset
			ld			[bios_updating], a				; Delete the bios_updating flag
not_power_on_reset:

self_copy::
			ld			sp, 0xFFFF
			ld			bc, end_of_code - init_stack
			ld			de, init_stack
			ld			hl, init_stack - begin_of_code + destination_address		; HL = B417h
			push		de
			ldir
			ret											; jump to PAGE3

; --------------------------------------------------------------------
init_stack::
			include		"../subroutine/ocm_iplrom_vdp.asm"

init_switch_io::
;			ld			a, exp_io_1chipmsx_id			; commented out if handled by the preloader
;			out			[exp_io_vendor_id_port], a
load_smart_profile::
			in			a, [0x48]
			bit			5, a
			jr			nz, skip_smart_profile			; if warm reset, skip
			; cold reset
			ld			hl, smart_profile_location + destination_address
			ld			a, [hl]
			cp			a, 'I'							; 'I'PL-ROM tag
			jr			nz, skip_smart_profile
			inc			hl
			ld			a, [hl]
			cp			a, 'G'							; 'G'en tag
			jr			nz, skip_smart_profile
			inc			hl
			ld			a, [hl]
			cp			a, '1'							; '1'st tag
			jr			nz, skip_smart_profile
			; header found ("IG1")
			inc			hl
			ld			a, [hl]
			cp			a, 0x80							; enabler code $80
			jr			nz, skip_smart_profile
			; enabler found
			sub			a, 4							; subtracts header and enabler size
			ld			b, a							; b = 124
loop_smart_profile:
			inc			hl
			ld			a, [hl]							; a = smart code to be set
			or			a, a
			jr			z, skip_smart_profile			; if a = 0, early end of smart profile
			out			[0x41], a						; execute the smart command
			djnz		loop_smart_profile
skip_smart_profile:

			call		sd_initialize

check_already_loaded::
			ld			a, [bios_updating]
			cp			a, 0xD4							; If it is a quick reset, boot EPBIOS

			ld			a, DOS_ROM1_BANK
			ld			[eseram8k_bank2], a				; init ESE-RAM Bank#2

			jr			z, force_bios_load_from_epbios

			call		ab_check						; check "AB" mark
			jr			nz, force_bios_load_from_sdcard

			ld			a, OPT_ROM_BANK
			ld			[eseram8k_bank2], a				; init ESE-RAM Bank#2
			call		cbios_check						; check for C-BIOS Logo ROM
			jp			boot_up_bios					; MSX BIOS is already there

force_bios_load_from_sdcard::
			call		load_from_sdcard				; load BIOS from SD card
force_bios_load_from_epbios::
			call		load_from_epcs					; load BIOS from EPCS serial ROM

			ld			a, ICON_ERROR
stop_with_error::
			call		vdp_put_icon
			ld			a, 0x35							; Lock Hard Reset Key
			out			[0x41], a
			ld			a, 0x1F							; Set MegaSD Blink OFF
			out			[0x41], a
			ld			a, 0x23							; Set Lights Mode ON + Red Led ON
			out			[0x41], a
			ld			[bios_updating], a				; Delete the bios_updating flag
			halt										; stop

; --------------------------------------------------------------------
;	[C][C][B][B][B][B][B][B]
epbios_image_table::
			db			4								; MEGASDHC 4BANK
			db			4 | 0b10000000					; Fill 0x00
			db			7								; MAIN-ROM, XBASIC2, MSX-MUSIC, SUB-ROM, KANJI
			db			0b01000000						; Fill 0xFF or 0xC9
			db			8								; JIS1-KANJI
			db			0xFE							; END MARK ( JIS2_DISABLE )

sdbios_image_table::
			db			32								; ALL
			db			0xFF							; END MARK ( JIS2_ENABLE )

; --------------------------------------------------------------------
			include		"../subroutine/ocm_iplrom_serial_rom.asm"
			include		"../subroutine/ocm_iplrom_fat_driver.asm"
			include		"../subroutine/ocm_iplrom_serial_rom_304k.asm"		; Assuming load_bios is immediately next.
			include		"../subroutine/ocm_iplrom_load_bios.asm"
			include		"../subroutine/ocm_iplrom_sd_driver.asm"
			include		"../subroutine/ocm_iplrom_vdp_standard_icon_single_epbios.asm"
end_of_code:
	remain_fat_sectors	:= $							; 2 bytes
	root_entries		:= $ + 2						; 3 bytes
	data_area			:= $ + 5						; 3 bytes
	bank_id				:= $ + 8						; 1 byte
	bios_updating		:= $ + 9						; 1 byte	0xD4: Updating now, the others: Not loaded
	animation_id		:= $ + 10						; 3 bytes

			if (end_of_code - begin_of_code) > smart_profile_location
				error "The size is too BIG. (" + (end_of_code - begin_of_code) + "byte)"
			else
				message "Size is not a problem. (" + (end_of_code - begin_of_code) + "byte)"
			endif
