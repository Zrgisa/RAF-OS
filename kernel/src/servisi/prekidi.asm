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
		pusha
		in      al, KBD                          
		mov	   [kbdata], al
			
		call ctrl_test
			
		cmp word [KBFLAGS], 0001h
		jne .not_ctrl_z
		cmp byte [kbdata] , Z_DOWN
		jne .not_ctrl_z
		
		;URADI NESTO
				
	.not_ctrl_z:
		mov     al, EOI                         
		out	    Master_8259, al
		popa
			int 80h
	iret
		
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
;-------------------------------------------------------
; proveravanje da li je pritisnut ctrl
; ukoliko je ctrl pritisnut setuje flagove
; ukoliko je ctrl optusten restujemo iste
;-------------------------------------------------------


ctrl_test:
		pusha
		cmp     al, LEFT_CTRL_DN                  
		je      .left_ctrl_down                           
		cmp     al, LEFT_CTRL_UP                  
		je      .left_ctrl_up                                                
		jmp     .is_not_ctrl                      
	.left_ctrl_down:	
		bts word [KBFLAGS], 0                   
		jmp	    .is_ctrl				
	.left_ctrl_up:	
		btr word [KBFLAGS], 0               
	.is_ctrl:	
		xor     al, al                           
	.is_not_ctrl:	
		popa
	ret
	
	


inBios				db 0					; flag koji oznacava da li smo u BIOSu
temp_ax				dw 0
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

;-------------------------------------------------------
; promenljive
;-------------------------------------------------------
LEFT_SHIFT_DN     			equ 02Ah 
LEFT_SHIFT_UP     			equ 0AAh                   
RIGHT_SHIFT_DN     		equ 036h
RIGHT_SHIFT_UP     		equ 0B6h
LEFT_CTRL_DN 	 			equ 1Dh
LEFT_CTRL_UP 				equ 9Dh
Z_DOWN 							equ 2Ch
Z_UP 								equ 0ACh
KBD            						equ 060h                     
EOI            						equ 020h                     
Master_8259    					equ 020h
KBFLAGS:    		db 0
kbdata: 				db 0
kura         db 'kura', 13, 10, 0