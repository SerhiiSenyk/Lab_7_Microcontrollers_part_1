;
; Lab_7_ATmega2560_ASM.asm
;
; Created: 20.03.2020
; Author : Serhii-PC
;

; 03.12.2020 
; optimization
; 324 bytes - 222 bytes .cseg segment

.nolist
.include "m2560def.inc"
.list
.def _temp1 = r16
.def _temp2 = r17
.def _temp3 = r18
.def _temp4 = r19
.def _algo5_io = r20
.def _algo8_io = r21
.def _algo5_temp_io = r22
.def _algo8_count = r23
;=================FLASH=====================
		.CSEG;interrupts vector
		.org 0x00
	rjmp initial	
		.org OC1Aaddr
	rjmp TIMER1_COMPA;Timer1

TIMER1_COMPA:
	in _temp1, SREG
	push _temp1
	cpi _algo5_io, 0
	brne next
	cbi PORTA, 7
	rjmp algo8
	next:
		out PORTA, _algo5_io
		mov _algo5_temp_io, _algo5_io
		lsl _algo5_io
		lsl _algo5_io
		cpi _algo5_temp_io, (1 << 6)
		brne algo8
		ldi _algo5_io, 2
algo8:
	cpi _algo8_count, 0
	brne next8
	cbi PORTF, 3
	rjmp end
	next8:
		out PORTF, _algo8_io
		dec _algo8_count
		sbrs _algo8_count, 0
		rjmp right
		mov _algo8_io, _temp3
		lsl _temp3
		rjmp end
		right:
			lsr _temp4
			mov _algo8_io, _temp4			
end:
	pop _temp1
	out SREG, _temp1
reti
;--------------------------------------------------------------------
initial:
	ldi	_temp1, low(RAMEND)
	out SPL, _temp1
	ldi _temp1, high(RAMEND)
	out SPH, _temp1
	;Setting ports
	ldi _temp1, 0xFF
	ldi _temp2, 0x00
	out DDRA, _temp1;0xFF
	out DDRF, _temp1;0xFF
	out PORTA, _temp2;0x00
	out PORTF, _temp2;0x00
	ldi _temp1, (1 << PL3)|(1 << PL5)
	sts DDRL, _temp2;0x00
	sts PORTL, _temp1
	sbi DDRB, 0
	cbi PORTB, 0
	;setting timer1
	ldi _temp1, 0x26
	ldi _temp2, 0x46
	sts	OCR1AH, _temp1
	sts OCR1AL, _temp2
	ldi _temp1, 0x00
	sts TCCR1A, _temp1
	ldi _temp1, (1 << WGM12) | (1 << CS12);256 prescalar
	sts TCCR1B, _temp1
	ldi _temp1, (1 << OCIE1A)
	sts TIMSK1, _temp1
	;---------------------
	clr _temp1
	clr _temp2
	clr _temp3
	clr _temp4
	clr _algo5_io
	clr _algo8_io
	clr _algo8_count
	sei 
;----------------------------------------------------------------
main:	
	lds	_temp2, PINL
	sbrc _temp2, PL3
	rjmp next_button
	rcall delay
	lds	_temp2, PINL
	sbrs _temp2, PL3
	rcall button1_pressed
next_button:
	lds	_temp2, PINL
	sbrc _temp2, PL5
	rjmp main
	rcall delay
	lds	_temp2, PINL
	sbrs _temp2, PL5
	rcall button2_pressed
rjmp main

button1_pressed:
	ldi _algo5_io, 1
	rcall buzzer
ret

button2_pressed:
	ldi _algo8_io, (1 << 7)
	ldi _algo8_count, 8
	ldi _temp3, 1
	mov _temp4, _algo8_io
	rcall buzzer
ret
		   
buzzer:
	sbi  PORTB, 0
	rcall delay
	cbi  PORTB, 0
ret	

delay:       
	ldi r24, 255      
	ldi r25, 255
	ldi r26, 1 
	del:                
		subi r24, 1       
		sbci r25, 0          
		sbci r26, 0  
	brcc del     
ret 