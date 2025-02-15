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
	LDI		R16, (1 << CLKPCE)	//Habilita la escritura en CLKPR
	STS		CLKPR, R16
	LDI		R16, (1 << CLKPS2)	//Configura prescaler a 16 (16 MHz / 16 = 1 MHz)
	STS		CLKPR, R16

	// Inicializar timer0
	LDI		R16, (1<<CS02) | (1<<CS00)	//Configuración para el prescaler de 64 (ver datasheet)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER 0 a 64
	LDI		R16, 158
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0

	//Deshabilitar el serial
	LDI		R16, 0x00
	STS		UCSR0B, R16


	//PORTC y PORTD como salida e inicialmente apagado 
	LDI		R16, 0xFF
	OUT		DDRC, R16	//Setear puerto C como salida
	OUT		DDRD, R16	//Setear puerto D como salida
	LDI		R16, 0x00
	OUT		PORTD, R16	//Apagar puerto D
	OUT		PORTC, R16	//Apagar puerto C

	//PORTB como entrada
	LDI		R16, 0x00
	OUT		DDRB, R16	//Setear puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16	//Habilidar pull-up en puerto B

	//Configuración del display
	DISPLAY_VAL:	.db		0x7E, 0x30,	0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B,	0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47
	//						 0	    1	  2		3	 4     5	  6     7     8		9	  A		B	  C		D	  E		F
	CALL SET_INICIO

	//Iniciar registros desde 0
	LDI		R23, 0x00	//Registro para el contador paralelo al display
	LDI		R22, 0x00	//Registros para colocar el valor de Z
	LDI		R21, 0x00	//Registro para la comparación del botón
	LDI		R20, 0x00	//Registro para la lectura del botón
	LDI		R19, 0x00	//Contador de led (timer)
	LDI		R18, 0x00
	LDI		R17, 0x00
	LDI		R16, 0x00

MAIN:
	IN		R16, TIFR0	// Leer registro TIMER 0 
	SBRS	R16, TOV0	// Salta si la bandera de overflow está encendida
	RJMP	DISPLAY		// Si está apagado regresa al loop principal
	SBI		TIFR0, TOV0 // Verifica si la bandera de overflow y lo reinicia 
	LDI		R16, 158
	OUT		TCNT0, R16	// Volver a cargar valor inicial al Timer0
	INC		R17			//Incrementa 100 ms 
	CPI		R17, 10		//Salta si ya pasaron 100ms * 10 = 1s
	BRNE	DISPLAY		//Si no ha pasado el segundo regresa al loop principal
	CLR		R17
	CALL	CONTADOR
	CALL	COMPARAR
	
	//
DISPLAY:
	IN		R20, PINB	//Escribe el valor de PINB en un registro
	CP		R21, R20	//Compara los registros, salta si son diferentes
	BREQ	MAIN		//Regresa al loop principal
	CALL	DELAY		//LLama a la subrutina DELAY
	IN		R20, PINB	//Vuelve a hacer el mismo procedimiento para verificar
	CP		R21, R20			
	BREQ	MAIN
	MOV		R21, R20	//Mueve el registro actual al registro previo
	SBIS	PINB, 1
	CALL	SUMA
	SBIS	PINB, 0
	CALL	RESTA
	LPM		R22, Z
	OUT		PORTD, R22
	CPI		R23, 0x00
	RJMP	MAIN

CONTADOR:
	INC		R19
    CPI		R19, 0x10   //Son iguales? hay overflow?
    BRNE    FIN_SUM_T	//Si no, continuar
    LDI     R19, 0x00	//Si sí, reiniciar a 0
FIN_SUM_T:
	OUT		PORTC, R19
	RET


COMPARAR:
	MOV		R24, R23
	INC		R24
    CP      R19, R23  ; Compara R19 con R23
    BREQ	END
	RET
END:
	SBI		PIND, PD7
	LDI		R19, 0x00
	OUT		PORTC, R19
    RET


//=====================================================================================
SUMA:
	INC		R23
	ADIW	Z, 1
	CPI		R23, 0x10
	BRNE	FIN_SUM
	CALL	SET_INICIO
	LDI		R23, 0x00
FIN_SUM:
	RET

RESTA:
    CPI     R23, 0x00     ; ¿Está en 0?
    BREQ    SET_MAX	      ; Si, colocar en 0x47
	DEC		R23
    SBIW    Z, 1          ; Decrementar
    RET
SET_MAX:
	LDI		R23, 0x0F
	CALL	SET_INICIO
    ADIW	Z, 15
    RET
	

SET_INICIO:
	LDI		ZL, LOW(DISPLAY_VAL <<1)
	LDI		ZH, HIGH(DISPLAY_VAL <<1)
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


