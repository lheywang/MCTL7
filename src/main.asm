;   Programme du tutorial TP FIP2
;	

;   Defining assembling parameters
    list	    p=16f877
    include	    "p16f877.inc"
    ERRORLEVEL	    -302		; No warnings about banksel
    ERRORLEVEL	    -205		; No warnings about found directives
   	
;   CONFIG
;   __config 0xFF39
    __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON
    
;   Start at the reset vector
    org	    0x000
    nop
    
    include "USART.asm"
    include "ADC.asm"

init:
    ; Config Serial port (RX)
    call	    USART_INIT
    
    ; Config ADC readings.
    call	    ADC_INIT
    
start:
    MOVLW	    'A'
    call	    USART_SEND
    goto	    start
    
    END			    ; Fin du code