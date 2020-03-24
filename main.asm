;
; Lab_7_ATmega2560_ASM.asm
;
; Created: 20.03.2020
; Author : Serhii-PC
;

.nolist
.include "m2560def.inc"
.list
.def _flag  = r0;	0bit - 5algo, 1bit - 8algo, 3bit - button1, 4bit - button2, 5bit - buzzer
.def _algo5_io = r19
.def _algo8_io = r24
.def _algo5_count = r22
.def _algo8_count = r23
.def _temp1 = r16
.def _temp2 = r17
.def _temp3 = r18

;=================FLASH=====================
		.CSEG;interrupts vector
		.org 0x00
	rjmp initial	
		.org OC1Aaddr
	rjmp TIMER1_COMPA;Timer1

TIMER1_COMPA:
	in _temp1, SREG
	push _temp1
	;buzzer
	sbrs _flag, 5
	rjmp buzzer_off
	sbi PORTB, 0
	clt
	bld _flag, 5
	rjmp algo
	buzzer_off:
		cbi PORTB, 0
	algo:
	sbrs _flag, 0
	rjmp algo8
	cpi _algo5_count, 9;end algo5
	breq _algo5_reset
	brne next
	_algo5_reset:
		clt
		bld _flag, 0
		rjmp algo8
	cpi _algo5_count, 8;last iteration
	breq algo5_clr
	brne next
	algo5_clr: 
		clr _algo5_io
		rjmp algo8
	next:
		inc _algo5_count
		out PORTA, _algo5_io
		lsl _algo5_io
		lsl _algo5_io
		cpi _algo5_count, 4
		breq second_parts
		brne algo8
		second_parts:
			ldi _algo5_io, 2
algo8:
	sbrs _flag, 1
	rjmp end
	cpi _algo8_count, 0;end algo 8
	breq algo8_reset
	brne next8
	algo8_reset:
		clt
		bld _flag, 1
		rjmp end
	cpi _algo8_count, 1;last iteration
	breq algo8_clr
	brne next
	algo8_clr: 
		clr _algo8_io
		rjmp end
	next8:
		out PORTF, _algo8_io
		mov _temp3, _algo8_count
		dec _algo8_count
		dec _temp3
		dec _temp3
		sbrc _flag, 2
		rjmp right;right - 1
		left:
			set
			bld _flag, 2
			left_loop:
				lsl _algo8_io
				dec _temp3
				cpi _temp3, 0
				brne left_loop
		rjmp end
		right:
			clt
			bld _flag, 2
			right_loop:
				lsr _algo8_io
				dec _temp3
				cpi _temp3, 0
				brne right_loop
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
	ldi _temp1, 0x86
	ldi _temp2, 0x46
	sts	OCR1AH, _temp1
	sts OCR1AL, _temp2
	ldi _temp1, 0x00
	sts TCCR1A, _temp1
	ldi _temp1, (1 << WGM12) | (1 << CS12)
	sts TCCR1B, _temp1
	ldi _temp1, (1 << OCIE1A)
	sts TIMSK1, _temp1
	;---------------------
	clr _temp1
	clr _temp2
	clr _temp3
	clr _flag
	clr _algo5_io
	clr _algo5_count
	clr _algo8_io
	clr _algo8_count
	sei 
;----------------------------------------------------------------
main:	
		clt
		lds	_temp2, PINL
		sbrc _temp2, PL3
		bld _flag, 3
		lds	_temp2, PINL
		sbrc _temp2, PL5
		bld _flag, 4
		sbrc _flag, 3
		rjmp next_button
		lds	_temp2, PINL
		sbrs _temp2, PL3
		rcall delay
		lds	_temp2, PINL
		sbrs _temp2, PL3
		rcall button1_pressed
	next_button:
		sbrc _flag, 4
		rjmp main
		lds	_temp2, PINL
		sbrs _temp2, PL5
		rcall delay
		lds	_temp2, PINL
		sbrs _temp2, PL5
		rcall button2_pressed
		rjmp main

button1_pressed:
		clr _algo5_count
		ldi _algo5_io, 1
		set
		bld _flag, 5
		bld _flag, 3
		bld _flag, 0
		rcall delay
		ret

button2_pressed:
		ldi _algo8_io, (1 << 7)
		ldi _algo8_count, 9
		set
		bld _flag, 5
		bld _flag, 4
		bld _flag, 2
		bld _flag, 1
		ret
		   
delay:       
	ldi r20, 255      
	ldi r21, 255
	ldi r25, 1 
	del:                
		subi r20, 1       
		sbci r21, 0          
		sbci r25, 0  
	brcc del     
ret               