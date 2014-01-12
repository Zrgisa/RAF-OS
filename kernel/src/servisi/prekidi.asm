; ======================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ======================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
;
; Podesavanje BIOS prekida
; -----------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Vanja Petrovic Tankovic RN05/09, 15.01.2011.)
; -----------------------------------------------------------------------------
; Promenjen int 09h (detektuje Ctrl+z)
;------------------------------------------------------------------------------

_set_interrupts:
		pusha
		cli
		push 	es
		xor		ax, ax
		mov		es, ax
		
		; Prvo pamtimo stare bios prekide (08, 09, 10, 13, 14, 15, 1A, bez 16) 
		mov		bx, [es:08h*4]
		mov		[stari_int08_off], bx
		mov		bx, [es:08h*4+2]
		mov      [stari_int08_seg], bx
		mov		bx, [es:09h*4]
		mov		[stari_int09_off], bx
		mov		bx, [es:09h*4+2]
		mov      [stari_int09_seg], bx		
		mov		bx, [es:10h*4]
		mov		[stari_int10_off], bx
		mov		bx, [es:10h*4+2]
		mov     [stari_int10_seg], bx		
		mov		bx, [es:13h*4]
		mov		[stari_int13_off], bx
		mov		bx, [es:13h*4+2]		
		mov     [stari_int13_seg], bx				
		mov		bx, [es:14h*4]
		mov		[stari_int14_off], bx
		mov		bx, [es:14h*4+2]		
		mov     [stari_int14_seg], bx				
		mov		bx, [es:15h*4]
		mov		[stari_int15_off], bx
		mov		bx, [es:15h*4+2]		
		mov     [stari_int15_seg], bx				
		mov		bx, [es:1Ah*4]
		mov		[stari_int1A_off], bx
		mov		bx, [es:1Ah*4+2]		
		mov     [stari_int1A_seg], bx				
	
		; Modifikacija u tabeli vektora prekida tako da pokazuju na nase rutine	
		; dok stare BIOS vektore postavljamo od lokacije 7A
		mov     ax, [stari_int08_off]		
		mov     [es:7Ah*4], ax
		mov     ax, [stari_int08_seg]
		mov     [es:7Ah*4+2], ax
		mov     ax, [stari_int10_off]		
		mov     [es:7Bh*4], ax
		mov     ax, [stari_int10_seg]
		mov     [es:7Bh*4+2], ax		
		mov     ax, [stari_int13_off]		
		mov     [es:7Ch*4], ax
		mov     ax, [stari_int13_seg]
		mov     [es:7Ch*4+2], ax
		mov     ax, [stari_int14_off]		
		mov     [es:7Dh*4], ax
		mov     ax, [stari_int14_seg]
		mov     [es:7Dh*4+2], ax
		mov     ax, [stari_int15_off]		
		mov     [es:7Eh*4], ax
		mov     ax, [stari_int15_seg]
		mov     [es:7Eh*4+2], ax
		mov     ax, [stari_int1A_off]		
		mov     [es:7Fh*4], ax
		mov     ax, [stari_int1A_seg]
		mov     [es:7Fh*4+2], ax
		mov     ax, [stari_int09_off]		
		mov     [es:80h*4], ax
		mov     ax, [stari_int09_seg]
		mov     [es:80h*4+2], ax	 	
		
		mov     ax, novi_int08				
		mov     [es:08h*4], ax
		mov     ax, cs
		mov     [es:08h*4+2], ax	
		mov     ax, novi_int09				
		mov     [es:09h*4], ax
		mov     ax, cs
		mov     [es:09h*4+2], ax
		mov     ax, novi_int10				
		mov     [es:10h*4], ax
		mov     ax, cs
		mov     [es:10h*4+2], ax
		mov     ax, novi_int13			
		mov     [es:13h*4], ax
		mov     ax, cs
		mov     [es:13h*4+2], ax
		mov     ax, novi_int14				
		mov     [es:14h*4], ax
		mov     ax, cs
		mov     [es:14h*4+2], ax
		mov     ax, novi_int15				
		mov     [es:15h*4], ax
		mov     ax, cs
		mov     [es:15h*4+2], ax
		mov     ax, novi_int1A				
		mov     [es:1Ah*4], ax
		mov     ax, cs
		mov     [es:1Ah*4+2], ax
		
		pop		es				
		sti
		popa
		ret
		
novi_int08:									; Poziva stari int 08h pa zatim rutinu za stampanje
		int 	7Ah							; Pozivamo originalni int 08h
		call	printer
		iret
		
novi_int09:

		in      al, KBD                     		; Citanje sken koda iz I/O registra tastature
		cmp     al, Z_DOWN	            	; Poredjenje sken koda sa sken kodom tastera S 
		jne     not_ctrl_z                     	; U koliko nije pritisnut taster S izlazimo na kraj
		
        mov     ah, 02h                     		; Provera da li je pritisnut taster CTRL pomocu prekida 16h funkcija 02h.
        int     16h                         			; U AL upisuje bajt koji predstavljaju flagove tastature (treci bit je za CTRL taster)
        or      al, 11111011b               	; Da bi proverili treci bit, radimo logicko ili po bitovima i
        cmp     al, 11111111b               	; ukoliko je rezultat 11111111 onda znamo da je pritisnut taster CTRL.
	
        jne     not_ctrl_z
			cmp byte[is_shell] , 00h
			je not_ctrl_z
				mov byte[is_shell] , 00h

				
				jmp jump_proc
			ctrl_z:	
				call make_files
				call upisi
					
			;DEBUG
				;mov si,is_shell				; ispisuje se poruka da je pokrenut
				;call _print_string
					
				
				
	not_ctrl_z:
		mov     al, EOI                         
		out	    Master_8259, al

		int 80h
	iret
	
	upisi:
					mov bx, process_name
					mov ax, process_name
					call _string_length
					mov cx, ax
					mov ax, process_file_sav 
					call _write_file
					
					mov bx, process_stack
					mov cx, word[stack_size]
					mov ax, process_file_sta
					call _write_file
					
					mov bx, app_start
					mov cx, word[Velicina]
					mov ax, process_file_pme
					call _write_file
					
					mov bx, process_vm
					mov cx, 4000
					mov ax, process_file_vme
					call _write_file
					
	
	ret
		
novi_int10:									; int 10h ne menja flagove tako da ne moramo da ih azuriramo
		inc		byte [inBios]				; i time dobijamo na brzini, s obzirom da je on sam po sebi
		int 	7Bh							; dovoljno spor
		dec		byte [inBios]
		iret
novi_int13:
		pushf
		inc		byte [inBios]
		popf
		int 	7Ch			
		mov		word [temp_ax], ax			
		pop		ax
		mov		word [temp_ip], ax			; Skidamo IP i CS sa steka da bi dosli do
		pop		ax							; starih flagova na steku
		mov		word [temp_cs], ax
		pop		ax							; Skidamo stare flagove sa steka 
		pushf								; i ubacujemo nove flagove koji su dobijeni
		mov		ax,	word [temp_cs]			; nakon poziva starog int 13h
		push	ax
		mov		ax, word [temp_ip]			; Vracamo IP i CS na stek da bi mogli da se
		push 	ax							; vratimo iz prekida
		mov		ax,	word [temp_ax]		
		dec		byte [inBios]
		iret
novi_int14:
		pushf
		inc		byte [inBios]
		popf
		int 	7Dh			
		mov		word [temp_ax], ax			
		pop		ax
		mov		word [temp_ip], ax			; Skidamo IP i CS sa steka da bi dosli do
		pop		ax							; starih flagova na steku
		mov		word [temp_cs], ax
		pop		ax							; Skidamo stare flagove sa steka 
		pushf								; i ubacujemo nove flagove koji su dobijeni
		mov		ax,	word [temp_cs]			; nakon poziva starog int 14h
		push	ax
		mov		ax, word [temp_ip]			; Vracamo IP i CS na stek da bi mogli da se
		push 	ax							; vratimo iz prekida
		mov		ax,	word [temp_ax]		
		dec		byte [inBios]
		iret
novi_int15:
		pushf	
		inc		byte [inBios]
		popf
		int 	7Eh			
		mov		word [temp_ax], ax			
		pop		ax
		mov		word [temp_ip], ax			; Skidamo IP i CS sa steka da bi dosli do
		pop		ax							; starih flagova na steku
		mov		word [temp_cs], ax
		pop		ax							; Skidamo stare flagove sa steka 
		pushf								; i ubacujemo nove flagove koji su dobijeni
		mov		ax,	word [temp_cs]			; nakon poziva starog int 15h
		push	ax
		mov		ax, word [temp_ip]			; Vracamo IP i CS na stek da bi mogli da se
		push 	ax							; vratimo iz prekida
		mov		ax,	word [temp_ax]		
		dec		byte [inBios]
		iret
novi_int1A:
		pushf
		inc		byte [inBios]
		popf
		int 	7Fh			
		mov		word [temp_ax], ax			
		pop		ax
		mov		word [temp_ip], ax			; Skidamo IP i CS sa steka da bi dosli do
		pop		ax							; starih flagova na steku
		mov		word [temp_cs], ax
		pop		ax							; Skidamo stare flagove sa steka 
		pushf								; i ubacujemo nove flagove koji su dobijeni
		mov		ax,	word [temp_cs]			; nakon poziva starog int 1Ah
		push	ax
		mov		ax, word [temp_ip]			; Vracamo IP i CS na stek da bi mogli da se
		push 	ax							; vratimo iz prekida
		mov		ax,	word [temp_ax]		
		dec		byte [inBios]
		iret

jump_proc:
				call set_vm_buffer
				call _clear_screen
				call _show_cursor
				mov		word [temp_ax], ax
				mov		word [temp_bx], bx
				mov		word [temp_cx], bx
				
				pop		ax
				pop	 	ax
				pop		ax
				xor cl,cl
				mov si, process_stack
			petlja:
					cmp word[shell_sp], sp
					je nastav
					pop bx
					mov byte[si], bl
					inc word[stack_size]
					inc si
					mov byte[si], bh
					inc word[stack_size]
					inc si
					jmp petlja
					
			nastav:
				mov byte[si], 0
				push ax
				mov      ax,  [shell_cs]
				push ax
				
			pom1:
				cmp byte[is_shell] , 01h
				jne pom2
				mov 		ax, 	pomocna1
				push     ax
				jmp back_ax
			pom2:
				cmp byte[is_shell] , 02h
				jne pom3
				mov 		ax, 	pomocna2
				push     ax
				jmp back_ax
			pom3:
				cmp byte[is_shell] , 03h
				jne pom4
				mov 		ax, 	pomocna3
				push     ax
				jmp back_ax
			pom4:
				cmp byte[is_shell] , 04h
				jne pom5
				mov 		ax, 	pomocna4
				push     ax
				jmp back_ax
			pom5:
				mov 		ax, 	pomocna5
				push     ax
		back_ax:
				mov		bx, word[temp_bx]		
				mov 		ax, word[temp_ax]
				mov 		cx, word[temp_cx]
jmp ctrl_z

make_files:
					mov si, temp_proc
					mov  ax, temp_proc
					call _string_length
					add     si, ax  											; pomeram da bi dodao XX.SAV
					sub si , 2
					inc word[process_number] 
					
					mov ax, word[process_number]
					
					cmp ax, 9
					jg preskoci
			
					
					mov byte[si], '0'
					mov byte[si+1], 0
			
			preskoci:	
					call _int_to_string
					
					mov bx, ax
					mov ax, temp_proc
					mov cx, process_file_sav
					call _string_join
					
					mov si, process_file_sav
					
					mov di, process_file_vme
					call _string_copy
					
					mov di, process_file_pme
					call _string_copy
					
					mov di, process_file_sta
					call _string_copy
					
					mov     ax, process_file_sav
					call    _string_length

					
					mov     si, process_file_sav
					add     si, ax
				               

					mov byte [si], '.'                  
					mov byte [si+1], 'S'
					mov byte [si+2], 'A'
					mov byte [si+3], 'V'
					mov byte [si+4], 0
					
					mov     si, process_file_vme
					add     si, ax
				               
					
					
					mov byte [si], '.'                  
					mov byte [si+1], 'V'
					mov byte [si+2], 'M'
					mov byte [si+3], 'E'
					mov byte [si+4], 0
					
					
					mov     si, process_file_pme
					add     si, ax
				               

					mov byte [si], '.'                 
					mov byte [si+1], 'P'
					mov byte [si+2], 'M'
					mov byte [si+3], 'E'
					mov byte [si+4], 0
					
					
					
					mov     si, process_file_sta
					add     si, ax

					mov byte [si], '.'                  
					mov byte [si+1], 'S'
					mov byte [si+2], 'T'
					mov byte [si+3], 'A'
					mov byte [si+4], 0


ret	

set_vm_buffer:
    pusha
	mov si, process_vm
	
	mov dh, 0
	
.vmKolone:
	call .vmIspisiRed
	inc dh
	cmp dh, 25
	jne .vmKolone
	jmp .vmKraj

.vmIspisiRed:
	mov dl, 0
	
.vmSledeci:
	call _move_cursor
    
	mov bh, 0h
	mov ah, 08h		; Ispisivati prazno mesto
    int 10h
	mov word[si], ax
	add si, 2
	
	inc dl
	cmp dl, 80
	jne .vmSledeci
	
	ret
	
.vmKraj:
    popa
    ret
	
process_file_pme  	times 20 db 0
process_file_sav  	times 20 db 0
process_file_vme  	times 20 db 0
process_file_sta  	times 20 db 0	

inBios					db 0					; flag koji oznacava da li smo u BIOSu
temp_ax				dw 0
temp_cx				dw 0
temp_bx				dw 0
temp_ip				dw 0
temp_cs				dw 0
stari_int08_seg		dw 0
stari_int08_off		dw 0
stari_int09_seg		dw 0
stari_int09_off		dw 0
stari_int10_seg		dw 0
stari_int10_off		dw 0
stari_int13_seg		dw 0
stari_int13_off		dw 0
stari_int14_seg		dw 0
stari_int14_off		dw 0
stari_int15_seg		dw 0
stari_int15_off		dw 0
stari_int1A_seg		dw 0
stari_int1A_off		dw 0		

Z_DOWN 				equ 2Ch
KBD            			equ 060h                     
EOI            			equ 020h                     
Master_8259    		equ 020h

process_stack times 128 db 0
process_vm times 4000 db 0
stack_size dw 0
kura         db 'kura', 13, 10, 0