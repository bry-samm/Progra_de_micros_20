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
	CALL INIT_TMR0
	//PORTC como salida e inicialmente apagado 
	LDI		R16, 0xFF
	OUT		DDRC, R16	//Setear puerto C como salida
	LDI		R16, 0x00
	OUT		PORTC, R16	//Apagar puerto C

	LDI		R21, 0x00
	// Loop Infinito
MAIN_LOOP:
	IN		R16, TIFR0 // Leer registro de interrupci n de TIMER 0 
	SBRS	R16, TOV0 // Salta si el bit 0 est "set" (TOV0 bit) 
	RJMP	MAIN_LOOP // Reiniciar loop
	SBI		TIFR0, TOV0 // Limpiar bandera de "overflow"
	LDI		R16, 100
	OUT		TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	INC		R20
	CPI		R20, 10 // R20 = 50 after 500ms (since TCNT0 is set to 10 ms)
	BRNE	MAIN_LOOP
	CLR		R20
	INC		R21
    CPI     R21, 0x10     ; ¿Llegó a 0x10?
    BRNE    FIN_SUM_1     ; Si no, continuar
    LDI     R21, 0x00     ; Si sí, reiniciar a 0
FIN_SUM_1:
    OUT		PORTC, R21
	RJMP	MAIN_LOOP
/****************************************/
// NON-Interrupt subroutines
INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16 // Cargar valor inicial en TCNT0
	RET
