
.include "m328pdef.inc"
.include "myMacro.inc"
.include "UART_Macros.inc"
.def A = r16
.def AH = r17
.def B = r18
.def BH = r19
.def C=R20
.DEF CH=R21
.def d=r22
.def dh=r23


.DEF HELPER= R24 
.DEF LDR_ADMUX_SAVE=R25   

.DEF WATER_ADMUX_SAVE=R26

.DEF FLAME_ADMUX_SAVE=R27
.DEF GAS_ADMUX_SAVE=R28

	
.org 0x00
; I/O Pins Configuration
; UART Configuration
SBI DDRD,1 ; Set PD1 (TX) as Output
CBI PORTD,1 ; TX Low (initial state)
CBI DDRD,0 ; Set PD0 (RX) as Input
SBI PORTD,0 ; Enable Pull-up Resistor on RX

Serial_begin ; Initialize UART Protocol

SBI DDRD, 4 ; Set PD4 pin for Output to LED
CBI PORTD, 4 ; LED OFF
SBI DDRB, 4 ; Set PB4 pin for Output to LED
CBI PORTB, 4 ; LED OFF
SBI DDRD, 7 ; Set PD7 pin for Output to LED
CBI PORTD, 7 ; LED OFF
SBI DDRD,2; Set PD2 pin for Output to LED
CBI PORTD, 2 ; LED OFF
LDI HELPER,0b11000111

; ADC Configuration for Light Detection (LDR)
LDI A, 0b11000111 ; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
STS ADCSRA, A

LDI A, 0b01100000 ; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
STS ADMUX, A ; Select ADC0 (PC0 pin) as the analog input for the LDR
SBI PORTC, PC0 ; Enable Pull-up Resistor for LDR

; Save the state of ADCSRA and ADMUX for LDR
MOV LDR_ADMUX_SAVE, A

; ADC Configuration for Water Level Sensor
LDI B, 0b11000111 ; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
STS ADCSRA, B

LDI B, 0b01100001 ; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
STS ADMUX, B ; Select ADC1 (PC1 pin) as the analog input for the water level sensor
SBI PORTC, PC1 ; Enable Pull-up Resistor for water level sensor

; Save the state of ADCSRA and ADMUX for Water Level Sensor

MOV WATER_ADMUX_SAVE, B

; ADC Configuration for fLAME Sensor
LDI C, 0b11000111 ; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
STS ADCSRA, C

LDI C, 0b01100010; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
STS ADMUX, C ; Select ADC1 (PC1 pin) as the analog input for the FLAME  sensor
SBI PORTC, PC2 ; Enable Pull-up Resistor for FLAME sensor

; Save the state of ADCSRA and ADMUX for Water Level Sensor

MOV FLAME_ADMUX_SAVE, C

; ADC Configuration for MQ2 GAS Sensor
LDI D, 0b11000111 ; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
STS ADCSRA, D

LDI D, 0b01100101; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
STS ADMUX, D ; Select ADC1 (PC1 pin) as the analog input for the water level sensor
SBI PORTD, PC5 ; Enable Pull-up Resistor for GAS sensor

; Save the state of ADCSRA and ADMUX for GAS Sensor

MOV GAS_ADMUX_SAVE, D

loop:
	
	Serial_writeReg_ASCII AH
	Serial_writeReg_ASCII BH
	Serial_writeReg_ASCII CH
	Serial_writeReg_ASCII DH


	; Restore ADC configuration for LDR
	MOV A, HELPER
	STS ADCSRA, A
	MOV A, LDR_ADMUX_SAVE
	STS ADMUX, A
    ; Start Analog to Digital Conversion for LDR
    LDS A, ADCSRA
    ORI A, (1 << ADSC)
    STS ADCSRA, A

    ; Wait for LDR conversion to complete
    wait_ldr:
    LDS A, ADCSRA
    sbrc A, ADSC
    rjmp wait_ldr

    ; Read LDR value
    LDS A, ADCL
    LDS AH, ADCH
	
	; Restore ADC configuration for Water Level Sensor
	MOV B, HELPER
	STS ADCSRA, B
	MOV B, WATER_ADMUX_SAVE
	STS ADMUX, B
    ; Start Analog to Digital Conversion for water level sensor
    LDS B, ADCSRA
    ORI B, (1 << ADSC)
    STS ADCSRA, B

    ; Wait for water level sensor conversion to complete
    wait_water:
    LDS B, ADCSRA
    sbrc B, ADSC
    rjmp wait_water
    ; Read water level sensor value
    LDS B, ADCL
    LDS BH, ADCH

	; Restore ADC configuration for FLAME Sensor
	MOV C, HELPER
	STS ADCSRA, C
	MOV C, FLAME_ADMUX_SAVE
	STS ADMUX, c
    ; Start Analog to Digital Conversion for FLAME sensor
    LDS C, ADCSRA
    ORI C, (1 << ADSC)
    STS ADCSRA, C

    ; Wait for fLAME sensor conversion to complete
    flame_waIt:
    LDS c, ADCSRA
    sbrc c, ADSC
    rjmp flame_waIt
    ; Read flame sensor value
    LDS c, ADCL
    LDS ch, ADCH

	; Restore ADC configuration for GAS Sensor
	MOV D, HELPER
	STS ADCSRA, D
	MOV D, GAS_ADMUX_SAVE
	STS ADMUX, D

	; Start Analog to Digital Conversion for MQ2
    LDS D, ADCSRA
    ORI D, (1 << ADSC)
    STS ADCSRA, D
	; Wait for MQ2 conversion to complete
    wait_MQ2:
    LDS D, ADCSRA
    sbrc D, ADSC
    rjmp wait_MQ2
	; Read MQ2 value
    LDS D, ADCL
    LDS DH, ADCH
	
	Serial_writeReg AH
	delay 20
	Serial_writeReg BH
	delay 20
	Serial_writeReg CH
	delay 20
	Serial_writeReg DH
	delay 20
	
    cpi AH,128 ; compare LDR reading with our desired threshold
	brlo LED_OFF ; jump if same or higher (AH >= 128)
	SBI PORTB,PB4 ; LED ON
	

	rjmp pass1
	LED_OFF:
	CBI PORTB,PB4 ; LED OFF

    pass1:
    cpi BH, 200 ; adjust the threshold for water level
    brsh WATER_LOW ; jump if lower (BH >= 100)
	CBI PORTD,PD7
	
	
   

    rjmp pass2

    WATER_LOW:
	SBI PORTD,PD7
	
    

	pass2:

	cpi CH,128
	BRSH FLAME_NOT_EXSIST
	CBI PORTD,PD4
    rjmp PASS3
	FLAME_NOT_EXSIST:
	SBI PORTD,PD4

	PASS3:

	cpi DH,128 ; compare MQ2 reading with our desired threshold
	brlo GAS_NOT_DETECT ; jump if same or higher (AH >= 128)
	CBI PORTD,PD2 ; LED ON
	
	rjmp loop
	GAS_NOT_DETECT:
	SBI PORTD,PD2 ; LED ON
	
	rjmp loop


