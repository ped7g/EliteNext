; Divide 8-bit values
; In: Divide E by divider C
; Out: A = result, B = rest
;
;;;Div8:
;;;    xor a
;;;    ld b,8
;;;Div8_Loop:
;;;    rl e
;;;    rla
;;;    sub c
;;;    jr nc,Div8_NoAdd
;;;    add a,c
;;;Div8_NoAdd:
;;;    djnz Div8_Loop
;;;    ld b,a
;;;    ld a,e
;;;    rla
;;;    cpl
;;;    ret

;;Inputs: DE is the numerator, BC is the divisor
;;Outputs: DE is the result
;;         A is a copy of E
;;         HL is the remainder
;;         BC is not changed
;; so DE = DE /BC
;140 bytes
;145cc	

MacroDEDivBC:       MACRO
                    rla
                    adc     hl,hl
                    sbc     hl,bc
                    jr      nc,$+3
                    add     hl,bc
                    ENDM

DEequDEDivBC:    
    xor a 
    sbc hl,hl
    ld a,d
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    rla 
    cpl 
    ld d,a

    ld a,e
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    MacroDEDivBC
    rla
    cpl 
    ld e,a
    ret
    
    
    
;divdide by 16 using undocumented instrunctions
;Input: BC = Dividend, DE = Divisor, HL = 0
;Output: BC = Quotient, HL = Remainder
; Our use
; BC = A0
; DE = 0C
; so BC = a * 256 / C
DIV16Amul256dCUNDOC:    JumpIfAGTENusng	  c,DEV16ATooLarge                                          ; first off if a > c ten return 255
                        ld      b,a
                        ld      e,c
                        ld      c,0
                        ld      d,0
                        jp      DIV16UNDOC
DIV16Amul256dQUNDOC:    ld      b,a
                        ld      c,0
                        ld      hl,varQ
                        ld      a,(hl)
                        ld      d,0
                        ld      e,a
DIV16BCDivDEUNDOC:
DIV16UNDOC:             ld      hl,0
                        ld      a,b 
                        ld      b,16
DIV16UNDOCLOOP:         sll	c		; unroll 16 times
                        rla			; ...
                        adc	hl,hl		; ...
                        sbc	hl,de		; ...
                        jr	nc,DIV16UNDOCSKIP		; ...
                        add	hl,de		; ...
                        dec	c		; ...
DIV16UNDOCSKIP:         djnz DIV16UNDOCLOOP
                        ld   b,a
                        ret
DEV16ATooLarge:         ld     bc,$00FF
                        ret

; "> asm_div8 C_Div_D - C is the numerator, D is the denominator, A is the remainder, B is 0, C is the result of C/D,D,E,H,L are not changed"
asm_div8:               ld b,8
                        xor a
div8_loop:	            sla c
                        rla
                        cp d
                        jr c,div8_skip:
                        inc c
                        sub d
div8_skip:	            djnz div8_loop
                        ret
; ">asm_div16: HL_Div_C: HL is the numerator,  C is the denominator, output A is the remainder, B is 0, C,DE is not changedHL is the quotient"
asm_div16:              ld b,16
                        xor a
div16_loop:	            sla l
                        rl	h
;    add hl,hl
                        rla
                        cp c
                        jr c,div16_skip
                        inc l
                        sub c
div16_skip:		        djnz div16_loop
                        ret
;
; Divide 16-bit values (with 16-bit result)
; In: Divide BC by divider DE
; Out: BC = result, HL = rest
;
HLDivC_Iteration: 	MACRO
					add	hl,hl		; unroll 16 times
					rla				; ...
					cp	c			; ...
					jr	1F
					sub	c			; ...
1:					
					inc	l			; ...
					ENDM



; ">div1616: BC = BC / DE. HL = remainder"
Div1616:            ld hl,0
                    ld a,b
                    ld b,8
.Div16_Loop1:       rla
                    adc hl,hl
                    sbc hl,de
                    jr nc,.Div16_NoAdd1
                    add hl,de
.Div16_NoAdd1:      djnz .Div16_Loop1
                    rla
                    cpl
                    ld b,a
                    ld a,c
                    ld c,b
                    ld b,8
.Div16_Loop2:       rla
                    adc hl,hl
                    sbc hl,de
                    jr nc,.Div16_NoAdd2
                    add hl,de
.Div16_NoAdd2:      djnz .Div16_Loop2
                    rla
                    cpl
                    ld b,c
                    ld c,a
                    ret

	
	
BCDIVDE_Iteration: MACRO 
				   rla
				   adc	hl,hl
				   add	hl,de
				   jr	c,1F
				   sbc	hl,de
1:				   
				   ENDM
				   
	
; ">BC_Div_DE: BC = BC / DE. HL = remainder fast divide with unrolled loop"
;BC/DE ==> BC, remainder in HL
;NOTE: BC/0 returns 0 as the quotient.
;min: 738cc
;max: 898cc
;avg: 818cc
;144 bytes
BC_Div_DE:              xor a
                        ld h,a
                        ld l,a
                        sub e
                        ld e,a
                        sbc a,a
                        sub d
                        ld d,a
                        ld a,b
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        rla
                        ld b,a

                        ld a,c
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        BCDIVDE_Iteration 
                        rla
                        ld c,a
                        ret	
  
;Inputs:
;     DE,BC are 8.8 Fixed Point numbers
;Outputs:
;     DE is the 8.8 Fixed Point result (rounded to the least significant bit)
;if DE is 0 : 122cc or 136cc if BC is negative
;if |BC|>=128*|DE| : 152cc or 166cc if BC is negative
;Otherwise:
;min: 1107cc
;max: 1319cc
;avg: 1201cc
BC_Div_DE_88:           ld a,b  ; First, find out if the output is positive or negative
                        xor d
                        push af   ;sign bit is the result sign bit
; Now make sure the inputs are positive
                        xor b     ;A now has the value of B, since I XORed it with D twice (cancelling)
                        jp p,BC_Div_DE_88_lbl1   ;if Positive, don't negate
                        xor a
                        sub c
                        ld c,a
                        sbc a,a
                        sub b
                        ld b,a
BC_Div_DE_88_lbl1:      ld a,d  ;now make DE negative to optimize the remainder comparison
                        or d
                        jp m,BC_Div_DE_88_lbl2
                        xor a
                        sub e
                        ld e,a
                        sbc a,a
                        sub d
                        ld d,a
BC_Div_DE_88_lbl2:      or e      ;if DE is 0, we can call it an overflow ;A is the current value of D
                        jr z,div_fixed88_overflow
                        ld h,0          ;The accumulator gets set to B if no overflow.;We can use H=0 to save a few cc in the meantime
                        ld a,b;if B+DE>=0, then we'll have overflow
                        add a,e
                        ld a,d
                        adc a,h
                        jr c,div_fixed88_overflow
                        ld l,b  ;Now we can load the accumulator/remainder with B;H is already 0
                        ld a,c
                        call div_fixed88_sub
                        ld c,a
                        ld a,b      ;A is now 0
                        call div_fixed88_sub
                        ld d,c
                        ld e,a
                        pop af
                        ret p
                        xor a
                        sub e
                        ld e,a
                        sbc a,a
                        sub d
                        ld d,a
                        ret

div_fixed88_overflow:   ld de,$7FFF
                        pop af
                        ret p
                        inc de
                        inc e
                        ret

;min: 456cc
;max: 536cc
;avg: 496cc
div_fixed88_sub:        ld b,8
BC_Div_DE_88_lbl3:      rla
                        adc hl,hl
                        add hl,de
                        jr c,$+4
                        sbc hl,de
                        djnz BC_Div_DE_88_lbl3
                        adc a,a
                        ret
  