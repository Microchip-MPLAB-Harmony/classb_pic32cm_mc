	AREA Classb_TestResult, CODE, READONLY
	THUMB
; /* CLASSB_TEST_STATUS CLASSB_GetTestResult(CLASSB_TEST_TYPE test_type,
;       CLASSB_TEST_ID test_id) */
	EXPORT CLASSB_GetTestResult

; /* void CLASSB_ClearTestResults(CLASSB_TEST_TYPE test_type) */
	EXPORT CLASSB_ClearTestResults

; /* void _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE test_type,
;       CLASSB_TEST_ID test_id, CLASSB_TEST_STATUS value) */
	EXPORT _CLASSB_UpdateTestResult

; /* SRAM address for SST results */
SST_RES_ADDRESS EQU 0x20000000
; /* SRAM address for RST results */
RST_RES_ADDRESS EQU 0x20000004
; /* Result mask is 0x03 (2-bit results) */
RESULT_BIT_MASK EQU 0x03
; /* CLASSB_TEST_STATUS */
CLASSB_TEST_NOT_EXECUTED EQU 0x0

; /* Load to clear*/
REG_CLEAR_VAL EQU 0x00000000

CLASSB_GetTestResult
; /* Input arguments are test_type and test_id */
; /* test_type in r0, test_id in r1 */
    ; /* push used registers */
    push    {r4-r7}
    ldr     r4, =SST_RES_ADDRESS
    cmp	    r0, #0
    beq     GetResTestTypeSST
    ldr     r4, =RST_RES_ADDRESS
GetResTestTypeSST
    ldr	    r6, =RESULT_BIT_MASK
    ; /* Load test result into r5 */
    ldrh    r5, [r4]
    ; /* Extract the test result and return via r0 */
    mov	    r0, r5
    rors    r0, r0, r1
    ands    r0, r0, r6
    ; /* Load 1s complement result into r7 */
    ldrh    r7, [r4, #8]
    ; /* Check whether the read results are 1s complements */
    eors    r5, r7, r5
    asrs    r5, r1
    ands    r5, r5, r6
    cmp	    r5, #3
    beq	    TestResultValid
    ; /* Result mismatch. Return CLASSB_TEST_NOT_EXECUTED */
    ldr	    r0, =CLASSB_TEST_NOT_EXECUTED
TestResultValid
    pop     {r4-r7}
    bx	    r14

_CLASSB_UpdateTestResult
; /* Input arguments are test_type, test_id and value */
; /* test_type in r0, test_id in r1, value in r2 */
    ; /* push used registers */
    push    {r4-r7}
    ldr     r4, =SST_RES_ADDRESS
    cmp	    r0, #0
    beq     UpdateResTestTypeSST
    ldr     r4, =RST_RES_ADDRESS
UpdateResTestTypeSST
    ;/* read the existing result */
    ldrh    r5, [r4]
    ldr     r6, =RESULT_BIT_MASK
    lsls    r6, r6, r1
    mvns    r6, r6
    ; /* Now r6 has ((~RESULT_BIT_MASK) << test_id) */
    ands    r5, r5, r6
    mov     r7, r2
    lsls    r7, r7, r1
    orrs    r5, r5, r7
    strh    r5, [r4]
    ; /* Load the 1s complement of the result */
    ; /* For SSTs, this address is 0x20000008 */
    ; /* For RSTs, this address is 0x2000000c */
    ; /* Take 1s complement of the value */
    mvns    r2, r5
    strh    r2, [r4, #8]

    pop     {r4-r7}
    bx	    r14

CLASSB_ClearTestResults
; /* Input arguments are test_type and test_id */
; /* test_type in r0 */
    ; /* push used registers */
    push    {r4-r7}
    ldr     r4, =SST_RES_ADDRESS
    cmp	    r0, #0
    beq     ClearResTestTypeSST
    ldr     r4, =RST_RES_ADDRESS
ClearResTestTypeSST
    ldr	    r5, =REG_CLEAR_VAL
    strh    r5, [r4]
    ; /* Store 1s complement of the result */
    mvns    r5, r5
    ; /* Add 4 to get the address of 1s complement result */
    adds    r4, #8
    strh    r5, [r4]
    pop     {r4-r7}
    bx	    r14
    
    ALIGN
    
	END