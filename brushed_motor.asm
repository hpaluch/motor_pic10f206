; Driving Brushed 5V DC Motor using PIC 10F206
; Speed can be adjusted using Up/Down push buttons
; Copyright (C) Henryk Paluch, hpaluch at seznam dot cz, http://henryx.info
; Few ideas taken from Gooligum Tutorials at
;     http://www.gooligum.com.au/tutorials.html

; defaults
    CONSTANT DEF_DUTY = .200 ; default Duty ratio, 128 = 50%


    LIST P=PIC10F206
    INCLUDE <P10F206.INC>

    __CONFIG  _MCLRE_ON & _CP_OFF & _WDT_OFF

; PIN assignment
    CONSTANT nMOTOR = GP2 ; motor Drive via MOSFET P-channel, LOG0 Active
    CONSTANT nDown = GP1  ; input for Down button, LOG0 Active, PIC Pull-Up
    CONSTANT nUp   = GP0  ; input for Down button, LOG0 Active, PIC Pull-Up

; *** general File Registers
MY_DATA UDATA
sGPIO   RES 1
vDuty   RES 1   ; Duty ratio, 128 = 50%
c512us  RES 1   ; counter for delay 512us
cDuty   RES 1   ; current duty counter

;***** RC CALIBRATION
RCCAL   CODE    0x1FF           ; processor reset vector
        RES 1                   ; holds internal RC cal value, as a movlw k

;**** RESET, Page 0
RES_VECT  CODE    0x0000            ; processor reset vector
    MOVWF   OSCCAL
    GOTO    START                   ; go to beginning of program
; CALLS must be in Page 0
ProcessUpKey
    BTFSS GPIO,nUp
    DECF vDuty,f ; now realy decrement vDuty
    RETLW 0

ProcessDownKey
    BTFSS GPIO,nDown
    INCF vDuty,f ; now realy decrement vDuty
    RETLW 0


MAIN_PROG CODE                      ; let linker place main program
START
    MOVLW DEF_DUTY
    MOVWF vDuty

    MOVLW  ~(1<<T0CS | 1 << NOT_GPPU)      ; clear T0CS to enable GP2 pin
                                           ; and enable Pull-Up on Inputs
    OPTION
    MOVLW ~(1<<CMPON)
    MOVWF CMCON0           ; Turn Off Comparator to enable GP1 & GP0
    MOVLW ~(1<<TRISIO2 )  ; GP2 OUTPUT, other are Inputs
    TRIS GPIO
    MOVLW ~0             ; all outputs inacitve (LOG1)
    MOVWF sGPIO
    MOVWF GPIO ; Motor Off
; main motor drive loop
MY_LOOP
    CLRF cDuty
wOff
; wait for 128us
    MOVLW .32
    MOVWF c512us
w512a
    NOP
    DECFSZ c512us,f
    GOTO w512a
    INCF cDuty,f
    MOVF cDuty,w
    XORWF vDuty,w
    BTFSS STATUS,Z
    GOTO wOff
; active duty starts here
    BCF  sGPIO,nMOTOR
    MOVF sGPIO,w
    MOVWF GPIO
wOn
; wait for 128us
    MOVLW .32
    MOVWF c512us
w512b
    NOP
    DECFSZ c512us,f
    GOTO w512b
; wOn
    INCFSZ cDuty,f  ; wait on Duty till cDuty overflows...
    GOTO wOn
; turn duty inactive again
    BSF  sGPIO,nMOTOR
    MOVF sGPIO,w
    MOVWF GPIO
; check keys/ajdust vDuty
; Possible Up Key (vDuty decreases)
    DECFSZ vDuty,w ; just test vDuty -1 (in w)
    CALL ProcessUpKey
; Possible Down Key (vDuty increases)
    INCFSZ vDuty,w ; just test vDuty +1
    CALL ProcessDownKey

    GOTO MY_LOOP                          ; loop forever

    END