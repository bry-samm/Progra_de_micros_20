;
; Laboratorio3.asm
;
; Created: 14/02/2025 23:54:55
; Author : Bryan Samuel Morales Paredes
;


.include "M328PDEF.inc"

.cseg
.org	0x0000
	JMP	START
.org	PCI0addr
	JMP	ISR_BOTON

//=====================================================================
START:
//Configuraci�n de la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16		// SPL 
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16		// SPH 
//=================================================================================
//Configurar el microcontrolador (MCU)
SETUP:
	CLI					//Deshabilito interrupciones globales
	//Prescaler del oscilador
	LDI		R16, (1 << CLKPCE)	//Habilita la escritura en CLKPR
	STS		CLKPR, R16
	LDI		R16, (1 << CLKPS2) | (1 << CLKPS0)	//Configura prescaler a 32 (32 MHz / 16 = 0.5 MHz)
	STS		CLKPR, R16

	// Inicializar timer0
	LDI		R16, (1<<CS02) | (1<<CS00)	//Configuraci�n para el prescaler de 1024 (ver datasheet)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER 0 a 1024
	LDI		R16, 1		//Poner a 
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0


	//PORTC como salida e inicialmente apagado 
	LDI		R16, 0xFF
	OUT		DDRC, R16	//Setear puerto C como salida
	LDI		R16, 0x00
	OUT		PORTC, R16	//Apagar puerto C

	//PORTB como entrada
	LDI		R16, 0x00
	OUT		DDRB, R16	//Setear puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16	//Habilidar pull-up en puerto B


//===================== CONFIGURACI�N INTERRUPCIONES =======================
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)
	STS		PCMSK0, R16

	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16


	LDI		R19, 0x00
	LDI		R18, 0x00
	LDI		R17, 0x00
	LDI		R16, 0x00

	SEI
//============================================================================
MAIN:
	/*CP		R20, R17
	BREQ	MAIN
	MOV		R20, R17
	SBRS	R17, 0
	CALL	SUMA
	SBRS	R17, 1
	CALL	RESTA

	SBRS	R17, 2
	CALL	SUMA
	SBRS	R17, 3
	CALL	RESTA*/

	OUT		PORTC, R19
	
	RJMP	MAIN


//======================= RUTINAS DE INTERRUPCI�N ==========================
ISR_BOTON:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	
CONTADOR:
	IN		R21, TIFR0	// Leer registro TIMER 0 
	SBRS	R21, TOV0	// Salta si la bandera de overflow est� encendida
	RJMP	CONTADOR	// Si est� apagado regresa al loop principal
	
	/*
	LDI		R17, 0x00
	SBIC	PINB, 0   ; Si PB0 est� en LOW (bot�n presionado)
	ORI		R17, 0b00000001  ; Activar bit 0 en R17

	SBIS	PINB, 0   ; Si PB0 est� en LOW (bot�n presionado)
	ORI		R17, 0b00000100  ; Activar bit 0 en R17

	SBIC	PINB, 1   ; Si PB1 est� en LOW (bot�n presionado)
	ORI		R17, 0b00000010  ; Activar bit 1 en R17

	SBIS	PINB, 1   ; Si PB1 est� en LOW (bot�n presionado)
	ORI		R17, 0b00001000  ; Activar bit 1 en R17
	

	//SBI		PINC, PD0
	
	*/

	INC		R19

	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI


//====================== RUTINAS NO INTERRUPCI�N ===========================
SUMA:
    INC     R19			//Incrementar R19
    CPI     R19, 0x10	//�Lleg� a 0x10?
    BRNE    FIN_SUM		//Si no, continuar
    LDI     R19, 0x00	//Si s�, reiniciar a 0
FIN_SUM:
    RET

RESTA:
    CPI     R19, 0x00	//�Est� en 0?
    BREQ    SET_MAX		//Si, colocar en 0x0F
    DEC     R19			//Decrementar
    RET
SET_MAX:
    LDI     R19, 0x0F
    RET