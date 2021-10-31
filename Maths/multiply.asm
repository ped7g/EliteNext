HLequSRmulQdiv256:      ;X.Y=x1lo.S*M/256  	\ where M/256 is gradient
                        ld  hl,(varRS)
                        ld  a,(varQ)
HLeqyHLmulAdiv256:      push    bc,,de
                        ld  de,0        ; de = XY
                        ld  b,a         ; b = Q
                        ShiftHLRight1
                        sla b
                        jr  nc,.LL126
.LL125:                 ex de,hl
                        add hl,de       
                        ex  de,hl       ; de = de + rs
.LL126:                 ShiftHLRight1
                        sla b
                        jr      c,.LL125
                        jr      nz,.LL126
                        ex      de,hl   ; hl = result
                        pop     bc,,de                        
                        ret


                   ; .MAD	\ -> &22AD  \ Multiply and Add  (DE also) X.A(Lo.Hi) = Q*A + R.S (Lo.Hi)
madXAequQmulAaddRS:     ld      ixh,a
                        and		$7F
                        ld      e,a
                        ld      a,(varQ)
                        ld		ixl,a
                        and		$7F
                        ld      d,a
madDEequDmulA
    mul                                 ;de = d * e
	ld		a,ixh
	xor		ixl
	and		$80
	or		d
	ld		d,a
madDEaddRS:
	ld		hl,(varR)
    ;ld      a,(varR)
    ;ld      l,a
    ;ld      a,(varS)
    ;ld      h,a
	call	madXAAddHLDESigned
;
;   add     hl,de                       ; hl = R.S + DE
    ex      de,hl                       ; de = R.S + DE
    ClearCarryFlag
    ld      ixl,e
    ld      a,d
    ret


madXAAddHLDESigned:     ld      a,h
                        and     SignOnly8Bit
                        ld      b,a                         ;save sign bit in b
                        xor     d                           ;if h sign and d sign were different then bit 7 of a will be 1 which means 
                        JumpIfNegative .ADDHLDEOppSGN        ;Signs are opposite there fore we can subtract to get difference
.ADDHLDESameSigns:       ld      a,b
                        or      d
                        JumpIfNegative .ADDHLDESameNeg       ; optimisation so we can just do simple add if both positive
                        add     hl,de
                        ret
.ADDHLDESameNeg:         ld      a,h                         ; so if we enter here then signs are the same so we clear the 16th bit
                        and     SignMask8Bit                ; we could check the value of b for optimisation
                        ld      h,a
                        ld      a,d
                        and     SignMask8Bit
                        ld      d,a
                        add     hl,de
                        ld      a,SignOnly8Bit
                        or      h                           ; now set bit for negative value, we won't bother with overflow for now TODO
                        ld      h,a
                        ret
.ADDHLDEOppSGN:          ld      a,h                         ; so if we enter here then signs are the same so we clear the 16th bit                     ; here HL and DE are opposite 
                        and     SignMask8Bit                ; we could check the value of b for optimisation
                        ld      h,a
                        ld      a,d
                        and     SignMask8Bit
                        ld      d,a
                        or      a
                        sbc     hl,de
                        jr      c,.ADDHLDEOppInvert
.ADDHLDEOppSGNNoCarry:   ld      a,b                         ; we got here so hl > de therefore we can just take hl's previous sign bit
                        or      h
                        ld      h,a                         ; set the previou sign value
                        ret
.ADDHLDEOppInvert:       NegHL                                                   ; we need to flip the sign and 2'c the Hl result
                        ld      a,b
                        xor     SignOnly8Bit                ; flip sign bit
                        or      h
                        ld      h,a                         ; recover sign
                        ret 

; multiplication of two 16-bit numbers into a 16-bit product
; enter : de = 16-bit multiplicand
;         hl = 16-bit multiplicand
; exit  : hl = 16-bit product
;         carry reset
;
; uses  : af, bc, de, hl	
mulDEbyHL:              push    bc
                        ld a,d                      ; a = xh
                        ld d,h                      ; d = yh
                        ld h,a                      ; h = xh
                        ld c,e                      ; c = xl
                        ld b,l                      ; b = yl
                        mul                         ; yh * yl
                        ex de,hl
                        mul                         ; xh * yl
                        add hl,de                   ; add cross products
                        ld e,c
                        ld d,b
                        mul                         ; yl * xl
                        ld a,l                      ; cross products lsb
                        add a,d                     ; add to msb final
                        ld h,a
                        ld l,e                      ; hl = final
                        ; 83 cycles, 19 bytes
                        xor a                       ; reset carry
                        pop     bc
                        ret
; multiplication of two S156-bit numbers into a 16-bit 2'd compliment product
; enter : de = 16-bit multiplicand
;         hl = 16-bit multiplicand
; exit  : hl = 16-bit product
;         carry reset
;
; uses  : af, bc, de, hl	
mulDEbyHLSignByte       DB      0
mulDEbyHLSgnTo2c:       xor     a
                        ld      (mulDEbyHLSignByte),a 
.SignDE:                ld      a,d
                        test    $80
                        jr      z,.SignHL
.NegativeDE:            and     $7F
                        ld      d,a
                        ld      a,$80
                        ld      (mulDEbyHLSignByte),a
.SignHL:                ld      a,h
                        test    $80
                        jr      z,.AbsoluteMultiply
.NegativeHL:            and     $7F
                        ld      h,a
                        ld      a,(mulDEbyHLSignByte)
                        xor     $80
                        ld      (mulDEbyHLSignByte),a
.AbsoluteMultiply:      call    mulDEbyHL
.RecoverSign:           ld      a,(mulDEbyHLSignByte)
                        test    $80
                        ret     z
.Negateghl: 				xor 	a
                        sub 	l
                        ld 		l,a
                        sbc 	a,a
                        sub 	h
                        ld 		h,a
                        ret
                        
mulDESgnbyHLUnsgnTo2c:  xor     a
                        ld      (mulDEbyHLSignByte),a 
.SignDE:                ld      a,d
                        test    $80
                        jr      z,.AbsoluteMultiply
.NegativeDE:            and     $7F
                        ld      d,a
                        ld      a,$80
                        ld      (mulDEbyHLSignByte),a
.AbsoluteMultiply:      call    mulDEbyHL
.RecoverSign:           ld      a,(mulDEbyHLSignByte)
                        test    $80
                        ret     z
.Negateghl:             xor 	a
                        sub 	l
                        ld 		l,a
                        sbc 	a,a
                        sub 	h
                        ld 		h,a
                        ret                        
	    
