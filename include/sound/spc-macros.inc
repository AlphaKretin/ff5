
; lohi: define low and high byte of 16-bit value
.macro lohi symbol
        .ident(.sprintf("%s_lo"), .string(symbol)) = symbol
        .ident(.sprintf("%s_hi"), .string(symbol)) = symbol + 1
.endmac

; bsfx: branch if sound effect
.macro bsfx label
        cmp     x,#$10
        bcs     label
.endmac

; bnsfx: branch if not sound effect
.macro bnsfx label
        cmp     x,#$10
        bcc     label
.endmac

; aslw: 16-bit shift left
.macro aslw addr
        asl     addr
        rol     addr + 1
.endmac

; lsrw: 16-bit shift right
.macro lsrw addr
        lsr     addr + 1
        ror     addr
.endmac
