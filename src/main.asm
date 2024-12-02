;   Programme du tutorial TP FIP2
;	

;   Defining assembling parameters
    LIST	    p=16f877
    INCLUDE	    "p16f877.inc"
    ERRORLEVEL	    -302		; No warnings about banksel
    ERRORLEVEL	    -205		; No warnings about found directives
   	
;   CONFIG
;   __config 0xFF39
    __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON
    
;   Start at the reset vector
    ORG	    0x000
    NOP
    
    GOTO	init
    
; ------------------------------------------------------------------------------
; MEMORY
; ------------------------------------------------------------------------------
    CVT		EQU	    20h
    CNT		EQU	    21h
    
; ------------------------------------------------------------------------------
; ADC
; ------------------------------------------------------------------------------
    
ADC_INIT:
    ; Initilize the USART peripheral.
    ; Used register : W
    BANKSEL	ADCON1
    
    MOVLW	B'00001110'	; Left justifY
				; 1 analog channel
				; VDD and VSS references
    MOVWF	ADCON1		

    BANKSEL	ADCON0	
    MOVLW	B'01000001'	; Fosc/8
				; A/D enabled
    MOVWF	ADCON0
       
    RETURN			; End of function
    
; ------------------------------------------------------------------------------
    
ADC_CONVERT:
    ; Transmit the value of W over USART
    ; Used register : W
    ; Return registe : W
    
    BSF		ADCON0,	    GO
    
    RETURN
    
ADC_GET:
    ; ADC Convert shall be runned before
    ; Used register : /
    
    CALL	ADC_CONVERT	    ; Start the conversion
    
    BTFSC	ADCON0,	    GO	    ; Waiting for the conversion to end
	GOTO	ADC_GET

    RETURN			    ; End of function
    
; ------------------------------------------------------------------------------
; USART
; ------------------------------------------------------------------------------
    
USART_INIT:
    ; Initilize the USART peripheral.
    ; Used register : W
    
    BANKSEL	    TRISC
    MOVLW	    B'10111111'	    ; TX as OUT (RC6), RX as IN (RC7)
    MOVWF	    TRISC

    BANKSEL	    SPBRG
    MOVLW	    .51		    ; Baud rate divider for 9600 (9615 exactly)
    MOVWF	    SPBRG

    BANKSEL	    TXSTA
    MOVLW	    B'00100100'	    ; Don't care.
				    ; 8 bit data
				    ; Transmit enable
				    ; Asynchronous
				    ; /
				    ; High speed mode
				    ; Transmit status bit empty
				    ; 9th bit of data (unused)
    MOVWF	    TXSTA

    BANKSEL	    RCSTA
    MOVLW	    B'10000000'	    ; Serial port Enabled
				    ; 8 bit data
				    ; Don't care
				    ; Continous receive disabled
				    ; Disable address
				    ; No framing error
				    ; No overrun error
				    ; 9th bit of data (unused)
    MOVWF	    RCSTA
       
    RETURN			    ; End of function
    
; ------------------------------------------------------------------------------
    
USART_SEND:
    ; Transmit the value of W over USART
    ; Used register : W
    
    BANKSEL	    TXSTA	    ; Selection of bank
    
    BTFSS	    TXSTA, TRMT	    ; Check register status
	GOTO	    USART_SEND
    
    BANKSEL	    TXREG	    ; Select TXREG Bank
    MOVWF	    TXREG	    ; Write A to TXREG
    
    RETURN			    ; End of function
    
; ------------------------------------------------------------------------------
; CONVERSION
; ------------------------------------------------------------------------------
GET_VOLT:
    ; Get the integer part of the voltage
    ; Used register : W
    ; Input register : W
    ; Return register : W
    
    BANKSEL	    TMR0	    ; Dummy selection of the bank 0$
    
    MOVWF	    CVT		    ; Place W into CVT
    
    MOVLW	    .0
    MOVWF	    CNT		    ; Initialize counter at 0

CVT_SUB:
    CLRC			    ; Clear carry
    MOVLW	    .51		    ; Place 51 in the W register
    SUBWF	    CVT,    W	    ; Remove 51 of CVT
    MOVWF	    CVT
    
    BNC		    CVT_END	    ; Exit if negative found
    
    INCF	    CNT		    ; If not carry nor zero : Increment and restart
    GOTO	    CVT_SUB
    
CVT_END:
    MOVFW	    CNT		    
    RETURN
    
; ------------------------------------------------------------------------------
; MAIN
; ------------------------------------------------------------------------------

init:
    ; Config Serial port (RX)
    CALL	    USART_INIT
    
    ; Config ADC readings.
    CALL	    ADC_INIT
    
    
    ; Jump to the start
    GOTO	    start
    
start:
    CALL	    ADC_GET
    MOVFW	    ADRESH	    ; Copy the result into W
    CALL	    GET_VOLT
    ADDLW	    30h
    
    CALL	    USART_SEND
    GOTO	    start
    
    END				     ; Fin du code