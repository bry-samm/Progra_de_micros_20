;
; Laboratorio2-Contadorxtiempo.asm
;
; Created: 07/02/2025
//Encabezado 
//Bryan Samuel Morales Paredes 23283
// Este código es un contador binario de 4 bits que aumenta cada 100ms
.include "M328PDEF.inc"
.cseg
.org 0x0000
/******************************************************************/
//Configuración de la pila 
/*****************************************************************/
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16		// SPL 
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16		// SPH 
//=================================================================================
//Configurar el microcontrolador (MCU)
SETUP:
	//Prescaler del oscilador
	LDI		R16, (1 << CLKPCE)    ; Habilita la escritura en CLKPR
	STS		CLKPR, R16
	LDI		R16, (1 << CLKPS2)      ; Configura prescaler a 16 (16 MHz / 16 = 1 MHz)
	STS		CLKPR, R16

	// Inicializar timer0
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16 // Cargar valor inicial en TCNT0

	//PORTC y PORTD como salida e inicialmente apagado 
	LDI		R16, 0xFF
	OUT		DDRC, R16	//Setear puerto C como salida
	OUT		DDRD, R16
	LDI		R16, 0x00
	OUT		PORTD, R16
	OUT		PORTC, R16	//Apagar puerto C

	//PORTB como entrada
	LDI		R16, 0x00
	OUT		DDRB, R16	//Setear puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16	//Habilidar pull-up en puerto B

	//Contador iniciar en 0
	LDI		R21, 0x00

	//Configuración del display
	DISPLAY_VAL:	.db		0x7E, 0x30,	0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B,	0x76, 0x1F, 0x4E, 0x3D, 0x4F, 0x47
	//						 0	    1	  2		3	 4     5	  6     7     8		9	  A		B	  C		D	  E		F
	LDI		ZL, LOW(DISPLAY_VAL <<1)
	LDI		ZH, HIGH(DISPLAY_VAL <<1)
MAIN:

	/*IN		R16, TIFR0 // Leer registro TIMER 0 
	SBRS	R16, TOV0 // Salta si el bit 0 "set" 
	RJMP	MAIN_LOOP // Reiniciar loop
	SBI		TIFR0, TOV0 // Verifica si la bandera de overflow y reinicia 
	LDI		R16, 100
	OUT		TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	INC		R17
	CPI		R17, 10 // R20 = 10 despues de 100ms
	BRNE	MAIN_LOOP
	CLR		R17

	//CONTADOR
	INC		R19
    CPI     R19, 0x10     ; ¿Llegó a 0x10?
    BRNE    FIN_SUM_1     ; Si no, continuar
    LDI     R19, 0x00     ; Si sí, reiniciar a 0
FIN_SUM_1:
    OUT		PORTC, R19
	RJMP	MAIN_LOOP*/

//==========================================================================
//Display de 7 segmentos 

	IN		R20, PINB	//Escribe el valor de PINB en un registro
	CP		R21, R20	//Compara los registros, salta si son diferentes
	BREQ	MAIN		//Regresa al loop principal
	CALL	DELAY		//LLama a la subrutina DELAY
	IN		R20, PINB	//Vuelve a hacer el mismo procedimiento para verificar
	CP		R21, R20			
	BREQ	MAIN
	MOV		R21, R20	//Mueve el registro actual al registro previo
	SBIS	PINB, 0
	CALL	SUMA
	SBIS	PINB, 1
	CALL	RESTA
	RJMP	MAIN

//xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
// Subrutinas no-interrupción

//=====================================================================================
SUMA:
	ADIW	Z, 1
	LD		R22, Z
	INC		R23
	CPI		R23, 0X10
	BRNE	FIN_SUM
	LDI		ZL, LOW(DISPLAY_VAL <<1)
	LDI		ZH, HIGH(DISPLAY_VAL <<1)
	LDI		R23, 0x00
FIN_SUM:
	OUT		PORTD, R22
	RET

RESTA:
	LD		R24, Z
    CPI     R24, 0x7E     ; ¿Está en 0?
    BREQ    SET_MAX_1     ; Si, colocar en 0x47
    SBIW    Z, 1           ; Decrementar
    RET
SET_MAX_1:
    ADIW	Z, 15
	OUT		PORTD, R24
    RET
	
//=====================================================================================
DELAY:		//Antirebote
	LDI		R18, 0xFF
SUB_DELAY1:
	DEC		R18
	CPI		R18, 0		//Compara, salta si son iguales
	BRNE	SUB_DELAY1
	LDI		R18, 0xFF
SUB_DELAY2:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY2
	LDI		R18, 0xFF
SUB_DELAY3:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY3
	RET
