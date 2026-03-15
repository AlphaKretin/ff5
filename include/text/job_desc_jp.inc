.list off
.ifndef JOB_DESC_INC
JOB_DESC_INC = 1

.global JobDesc, JobDescPtrs

.scope JobDesc

        Start := bank_start JobDesc

; ##############################################################################
; ###          AUTOMATICALLY GENERATED CODE, DO NOT MODIFY MANUALLY          ###
; ##############################################################################

        ARRAY_LENGTH = 22

        _0 := JobDesc + 0
        _1 := JobDesc + 12
        _2 := JobDesc + 27
        _3 := JobDesc + 236
        _4 := JobDesc + 77
        _5 := JobDesc + 230
        _6 := JobDesc + 97
        _7 := JobDesc + 236
        _8 := JobDesc + 126
        _9 := JobDesc + 236
        _10 := JobDesc + 236
        _11 := JobDesc + 236
        _12 := JobDesc + 236
        _13 := JobDesc + 141
        _14 := JobDesc + 236
        _15 := JobDesc + 236
        _16 := JobDesc + 162
        _17 := JobDesc + 184
        _18 := JobDesc + 236
        _19 := JobDesc + 236
        _20 := JobDesc + 236
        _21 := JobDesc + 212

; ##############################################################################

.endscope

.endif
.list on
