;   Programme du tutorial TP FIP2
;	

;   Defining assembling parameters
    LIST	    p=16f877
    INCLUDE	    "p16f877.inc"
    ERRORLEVEL	    -302		; No warnings about banksel
    ERRORLEVEL	    -205		; No warnings about found directives
 
; ------------------------------------------------------------------------------
; MEMORY
; ------------------------------------------------------------------------------
    ; Variables for the ADC conversion to ASCII
    CVT		EQU	    20h
    CNT		EQU	    21h
    SUM		EQU	    22h
    SAV		EQU	    23h
    CNT2	EQU	    24h

    ; Output buffer
    OUT1	EQU	    30h
    OUT2	EQU	    31h
    OUT3	EQU	    32h
    OUT4	EQU	    33h	
    OUT5	EQU	    34h
	
    ; Interrupt counter
    INT_CNT	EQU	    40h
    LAST_CHAR	EQU	    41h
   
    ; Operating mode store
    MODE	EQU	    50h
   
;   CONFIG
;   __config 0xFF39
    __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON
    
;   Start at the reset vector
    ORG	    0x000
    NOP
    
; ------------------------------------------------------------------------------
; JUMP TO INIT
; ------------------------------------------------------------------------------
    
    GOTO	init
    
; ------------------------------------------------------------------------------
; INTERRUPT ROUTINES
; ------------------------------------------------------------------------------
    ; Interrupt vector
    ORG	    0x004
    
INTERRUPT_HANDLER:
    ; Handle the interrupts in the project
    ; Used to identify which interrupt has occured
    ; --> Note : PIR1 can trigger an disabled interrupt, a check is then necessary
    ; Used registers : / (Depend on the interrupt)
    
    BANKSEL	    PIR1
    BTFSC	    PIR1,   TMR1IF	; Handle Timer 1 Interrupt
	CALL	    TIMER1_INTERRUPT
	
    BTFSC	    PIR1,   RCIF	    
	CALL	    USART_INTERRUPT	; Handle Timer 0 Interrupt

    RETFIE				; Return from interrupt
	
; ------------------------------------------------------------------------------
; INTERRUPTS INITIALIZATION
; ------------------------------------------------------------------------------
INT_INIT:
    ; Initialize the interrupt system
    ; Used register : W
    
    BANKSEL	    PIE1
    MOVLW	    B'00100001'		; /
					; /
					; USART Reception interrupt
					; /
					; /
					; /
					; /
					; Timer 1 IF
    MOVWF	    PIE1
    
    BANKSEL	    INTCON
    MOVLW	    B'11000001'		; GIE
					; PEIE (For Timer 1)
					; /
					; /
					; /
					; /
					; /
					; /
    MOVWF	    INTCON
    
    BANKSEL	    PIR1		; Clear Interrupt flags
    BCF		    PIR1,   TMR1IF  
    BCF		    PIR1,   RCIF
    
    MOVLW	    0x00
    MOVWF	    MODE		; Initialize the operating mode to 0x00 : Automatic
   
; ------------------------------------------------------------------------------
; ADC
; ------------------------------------------------------------------------------
    
ADC_INIT:
    ; Initilize the USART peripheral.
    ; Used register : W
    
    BANKSEL	ADCON1
    
    MOVLW	B'00001110'		; Left justifY
					; 1 analog channel
					; VDD and VSS references
    MOVWF	ADCON1		

    BANKSEL	ADCON0	
    MOVLW	B'01000001'		; Fosc/8
					; A/D enabled
    MOVWF	ADCON0
       
    RETURN				; End of function
    
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
    
    CALL	ADC_CONVERT		; Start the conversion

ADC_WAIT:
    BTFSC	ADCON0,	    GO		; Waiting for the conversion to end
	GOTO	ADC_WAIT

    RETURN				; End of function
    
; ------------------------------------------------------------------------------
; USART
; ------------------------------------------------------------------------------
    
USART_INIT:
    ; Initilize the USART peripheral.
    ; Used register : W
    
    BANKSEL	    TRISC
    MOVLW	    B'10111111'		; TX as OUT (RC6), RX as IN (RC7)
    MOVWF	    TRISC

    BANKSEL	    SPBRG
    MOVLW	    .51			; Baud rate divider for 9600 (9615 exactly)
    MOVWF	    SPBRG

    BANKSEL	    TXSTA
    MOVLW	    B'00100100'		; Don't care.
					; 8 bit data
					; Transmit enable
					; Asynchronous
					; /
					; High speed mode
					; Transmit status bit empty
					; 9th bit of data (unused)
    MOVWF	    TXSTA

    BANKSEL	    RCSTA
    MOVLW	    B'10010000'		; Serial port Enabled
					; 8 bit data
					; Don't care
					; Continous receive enabled
					; Disable address
					; No framing error
					; No overrun error
					; 9th bit of data (unused)
    MOVWF	    RCSTA
       
    RETURN				; End of function
    
; ------------------------------------------------------------------------------
    
USART_SEND:
    ; Transmit the value of W over USART
    ; Used register : W
    
    BANKSEL	    TXSTA		; Selection of bank
    
    BTFSS	    TXSTA, TRMT		; Check register status
	GOTO	    USART_SEND
    
    BANKSEL	    TXREG		; Select TXREG Bank
    MOVWF	    TXREG		; Write A to TXREG
    
    RETURN				; End of function
    
USART_SEND_ADC_BUF:			; Send the ADC output buffer, char by char and add \r\n
    MOVFW	    OUT1
    CALL	    USART_SEND
    
    MOVFW	    OUT2
    CALL	    USART_SEND
    
    MOVFW	    OUT3
    CALL	    USART_SEND
    
    MOVFW	    OUT4
    CALL	    USART_SEND
    
    MOVFW	    OUT5
    CALL	    USART_SEND
    
    MOVLW	    '\r'
    CALL	    USART_SEND
    
    MOVLW	    '\n'
    CALL	    USART_SEND
    
    RETURN
    
; ------------------------------------------------------------------------------
    
USART_INTERRUPT:
    ; Interrupt routine for the USART reception
    
    BANKSEL	    PIE1
    BTFSS	    PIE1,   RCIE	; Exit if the interrupt isn't enabled
	RETURN
    
    BANKSEL	    RCREG	    
    MOVFW	    RCREG		; Perform a read on the RCREG.
					; The hardware also clear the PIR1 : RCIF if there isn't anymore read to be done
    MOVWF	    LAST_CHAR
    
    MOVLW	    'a'			; Automatic mode
    SUBWF	    LAST_CHAR,	W
    BZ		    AUTOMATIC
    MOVLW	    'A'
    SUBWF	    LAST_CHAR,	W
    BZ		    AUTOMATIC
   
    MOVLW	    'r'			; Manual mode
    SUBWF	    LAST_CHAR,	W
    BZ		    MANUAL
    MOVLW	    'R'
    SUBWF	    LAST_CHAR,	W
    BZ		    MANUAL
    
    MOVLW	    'd'			; Measure needed
    SUBWF	    LAST_CHAR,	W
    BZ		    REQUEST
    MOVLW	    'D'
    SUBWF	    LAST_CHAR,	W
    BZ		    REQUEST
    
    RETURN				; Any other character will end up here, no actions
				
AUTOMATIC:				    
    BANKSEL	    T1CON
    BSF		    T1CON,	TMR1ON	; Simply enable the timer 1 operation.
					; This will trigger an interrupt after 0.2s and a print after 1s
					; The first may be delayed since we don't know the state of the TMR1 now
    
    MOVLW	    0x00
    MOVWF	    MODE		; Store the mode operation here (0x00 = Automatic)
    
    RETURN
    
MANUAL:
    BANKSEL	    T1CON
    BCF		    T1CON,	TMR1ON	; Simply disable the timer 1 operation
    
    MOVLW	    0x01
    MOVWF	    MODE		; Store the mode operation here (0x01 = Manual)
    
    RETURN
    
REQUEST:
    MOVLW	    0x01
    SUBWF	    MODE,	W	; Check the operating mode
    
    BZ		    MEASURE 
    
    RETURN				; if mode is automatic, then no measure is done
    
MEASURE:				; Make and print measure
    CALL	    ADC_GET
    MOVFW	    ADRESH		; Copy the result into W
    CALL	    GET_VOLT
    CALL	    USART_SEND_ADC_BUF	; Write the output buffer
    RETURN
    
; ------------------------------------------------------------------------------
; TIMER 1
; ------------------------------------------------------------------------------

TIMER1_INIT:
    ; Initialize the timer 1 to interrupt every 200 ms
    ; --> Interrupts will be divided by 5 to get the requested 1s period
    ; Input : Fosc / 4
    ; Prescaler : 1:8
    ; Timer input frequency : 250 kHz
    ; Used register : W
    
    BANKSEL	    T1CON
    MOVLW	    B'00110001'		; /
					; /
					; 1:8 Prescale
					; No oscillator
					; /
					; Internal clock (Fosc / 4)
					; Timer Enabled
    MOVWF	    T1CON
       
    RETURN				; End of function
    
; ------------------------------------------------------------------------------
TIMER1_INTERRUPT:
    ; Interrupt routine for the timer 1
    
    BANKSEL	    PIE1
    BTFSS	    PIE1,   TMR1IE	; Exit if the interrupt is unwanted
	RETURN
    
    BANKSEL	    PIR1	    
    BCF		    PIR1,   TMR1IF	; Clear Interrupt pin
    
    BANKSEL	    TMR1H		; Load 15 535 to trigger interrupt every 50 000 tick (200 ms) (An 1:8 prescaler is used)
    MOVLW	    0x3B
    MOVWF	    TMR1H
    MOVLW	    0xCA
    MOVWF	    TMR1L
    
    INCF	    INT_CNT		; Increment the interrupt counter. Located on the same bank as TMR1H
    
    MOVLW	    .5
    SUBWF	    INT_CNT,   W
    
    BZ		    TRIGGERED_INT	; Continue the interrupt
    RETURN
    
TRIGGERED_INT:				; Start the user seen interrupt 
    MOVLW	    .0			; Reset the counter
    MOVWF	    INT_CNT
    CALL	    ADC_GET
    MOVFW	    ADRESH		; Copy the result into W
    CALL	    GET_VOLT
    CALL	    USART_SEND_ADC_BUF	; Write the output buffer
    
    RETURN
    
; ------------------------------------------------------------------------------
; CONVERSION
; ------------------------------------------------------------------------------
GET_VOLT:
    ; Get the integer part of the voltage
    ; Used register : W
    ; Input register : W
    ; Return register : OUT1
    
    BANKSEL	    TMR0		; Dummy selection of the bank 0$
    
    MOVWF	    CVT			; Place W into CVT and SAV
    MOVWF	    SAV
    
    MOVLW	    .0
    MOVWF	    CNT			; Initialize counters at 0
    MOVWF	    CNT2
    
    MOVWF	    OUT1		; Clearing the output buffer
    MOVWF	    OUT2
    MOVWF	    OUT3
    MOVWF	    OUT4
    MOVWF	    OUT5
	
    MOVWF	    SUM			; Clearing the sum

CVT_SUB:				; Routine to get the integer part of the measure
    CLRC				; Clear carry
    MOVLW	    .51			; Place 51 in the W register
    SUBWF	    CVT,    W		; Remove 51 of CVT
    MOVWF	    CVT
    
    BNC		    CVT_INT		; Exit if negative found
    
    INCF	    CNT			; If not carry nor zero : Increment and restart
    
    MOVFW	    SUM			; Increment the integer part register
    ADDLW	    .51
    MOVWF	    SUM
    
    GOTO	    CVT_SUB		; Jump to the start of the integer part loop
	
CVT_INT:
    MOVFW	    CNT
    ADDLW	    30h			; Convert to ASCII character
    
    MOVWF	    OUT1		; Copy into output buffer
    
    MOVFW	    SUM			; Substract the sum of 551 to the input value
    SUBWF	    SAV			; Now, SAV contain the difference between integer and input.

CVT_SUB2:
    MOVLW	    .5			; Place 5 in the W register
    SUBWF	    SAV,    W		; Remove 51 of CVT
    MOVWF	    SAV
    
    BNC		    CVT_END		; Exit if negative found
    
    INCF	    CNT2		; If not carry nor zero : Increment and restart
    
    GOTO	    CVT_SUB2		; Jump
	
CVT_END:				; Formatting the output by sending the right characters
					; Int to ASCII : Add 0x30
    MOVFW	    CNT			; Integer part
    ADDLW	    30h
    MOVWF	    OUT1
    
    MOVLW	    ','			; Comma
    MOVWF	    OUT2
    
    MOVFW	    CNT2		; First (and last) decimal
    ADDLW	    30h
    MOVWF	    OUT3
    
    MOVLW	    ':'			; Check if the char is ':' --> Overflow of the method used
					; if true : Replace by '9'
					; else, no action needed
    SUBWF	    OUT3,   W
    
    BZ		    Double
    GOTO	    NextChar		
	    
Double:					; ':' handler
    MOVLW	    '9'			
    MOVWF	    OUT3
    GOTO	    NextChar
    
NextChar:				; Finish the conversion by adding a space and 'V'
    MOVLW	    ' '
    MOVWF	    OUT4
    
    MOVLW	    'V'
    MOVWF	    OUT5
    
    RETURN
    
; ------------------------------------------------------------------------------
; MAIN
; ------------------------------------------------------------------------------

init:
    CALL	    USART_INIT		; Config Serial port (RX)
    CALL	    ADC_INIT		; Config ADC readings.
    CALL	    INT_INIT		; Configure the interrupt subsystem
    CALL	    TIMER1_INIT		; Configure the timer 1
     
start:
    GOTO	    start		; Infinite loop to not go somewhere in the memory
    
    END					; Fin du code