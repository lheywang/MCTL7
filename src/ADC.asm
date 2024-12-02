; Defining assembling parameters
list	    p=16f877
include	    "p16f877.inc"
ERRORLEVEL  -302		    ; No warnings about banksel
ERRORLEVEL  -205		    ; No warnings about found directives
      
; Defining a code section (relocatable)
ADC	    CODE
	   
; ------------------------------------------------------------------------------

; Now the labels
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
    ; Used register : W$
    
    BSF		ADCON0,	    GO
    
    RETURN
    
ADC_GET:
    ; ADC Convert shall be runned before
    ; Used register : W
    
    BTFSC	ADCON0,	    GO
	goto	ADC_GET
    
    RETURN			    ; End of function
    
; ------------------------------------------------------------------------------

    END				    ; End of file
    RETURN
    