;
; Laboratorio3.asm
;
; Created: 14/02/2025 23:54:55
; Author : Bryan Samuel Morales Paredes
; Este programa tiene un contador manual de 4 bits y un segundo contador mostrado en un display que aumenta cada segundo
; de 0 a 9, al resetear aumenta un segundo display el cual lleva las decenas, todo esto funciona mediante interrupciones

//============================================================== LABORATORIO 3 ===============================================================
.include "M328PDEF.inc"

.cseg
.org	0x0000
	JMP	START
	
.org	PCI0addr
	JMP	ISR_BOTON

.org	OVF0addr
	JMP	ISR_TIMER0
	
	
//=====================================================================
START:
//Configuración de la pila
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
	LDI		R16, (1 << CLKPS2)	//Configura prescaler a 16 (16 MHz / 16 = 1 MHz)
	STS		CLKPR, R16

	// Inicializar timer0
	LDI		R16, (1<<CS01) | (1<<CS00)	//Configuración para el prescaler de 64 (ver datasheet)
	OUT		TCCR0B, R16	// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100	//Poner a 100
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	
	//PORTD y PORTC como salida e inicialmente apagado 
	LDI		R16, 0xFF
	OUT		DDRD, R16	//Setear puerto D como salida
	OUT		DDRC, R16
	LDI		R16, 0x00
	OUT		PORTD, R16	//Apagar puerto D
	OUT		PORTC, R16

	//PORTB como entrada
	LDI		R16, 0x00
	OUT		DDRB, R16	//Setear puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16	//Habilidar pull-up en puerto B

	//Configuración del display

	DISPLAY_VAL:	.db		0x7E, 0x30,	0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B
	//						 0	    1	  2		3	 4     5	  6     7     8		9
	CALL SET_INICIO



	
//===================== CONFIGURACIÓN INTERRUPCIONES =======================

//Para el timer
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16

//Para los botones
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)
	STS		PCMSK0, R16
	
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16

//Setear algunos registros en 0

//Timer
	LDI		R24, 0x00
	LDI		R23, 0x00
	LDI		R22, 0x00
	LDI		R21, 0x00
//botón
	LDI		R20, 0x00
	LDI		R19, 0x00
	LDI		R18, 0x00
	LDI		R17, 0x00
	LDI		R16, 0x00
	
	LPM		R23, Z
	LPM		R25, Z

	SEI
//============================================================================
MAIN:


	OUT		PORTC, R19
	SBRS	R22, 0
	RJMP	CONTADOR_1
	CBI		PORTC, PC4
	LDI		R16, 0x00
	OUT		PORTD, R16
	SBI		PORTC, PC5
	//LPM		R25, Z
	OUT		PORTD, R25
	RJMP	MAIN
CONTADOR_1:
	CBI		PORTC, PC5
	LDI		R16, 0x00
	OUT		PORTD, R16
	SBI		PORTC, PC4
	//LPM		R23, Z
	OUT		PORTD, R23

	OUT		PORTC, R19
	RJMP	MAIN

//================================================= RUTINAS NO INTERRUPCIÓN ==================================================================
SET_INICIO:
	LDI		ZL, LOW(DISPLAY_VAL <<1)	//Coloca el direccionador indirecto en la posición inicial
	LDI		ZH, HIGH(DISPLAY_VAL <<1)
	RET

SUMA:
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    LDI     R16, 0x00           ; Inicializar R16 para usarlo como índice

LOOP1:
    CP      R16, R21            ; Comparar el índice con el valor de las unidades
    BREQ    UNIDADES_ENCONTRADAS ; Si coincide, salir del bucle
    INC     R16                 ; Incrementar el índice
    ADIW    Z, 1                ; Mover el puntero Z al siguiente valor en la tabla
    RJMP    LOOP1               ; Repetir el bucle

UNIDADES_ENCONTRADAS:
    LPM     R23, Z              ; Cargar el valor de la tabla en R23 (unidades)
    
    CPI     R21, 0x0A           ; ¿Las unidades están en 9?
    BRNE    INCREMENTAR_UNIDADES ; Si no están en 9, solo incrementar

    ; Si estaban en 9, reiniciar unidades y aumentar decenas
    LDI     R21, 0x00           ; Reiniciar el contador de unidades
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    LPM     R23, Z              ; Cargar el valor de 0 en R23 (unidades)
    INC     R24                 ; Incrementar el contador de decenas (justo después del reinicio)
    CPI     R24, 0x0A           ; ¿Llegó a 10?
    BRNE    ACTUALIZAR_DECENAS  ; Si no, actualizar el valor de las decenas
    ; Si llegó a 10, reiniciar decenas
    LDI     R24, 0x00           ; Reiniciar el contador de decenas

ACTUALIZAR_DECENAS:
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    LDI     R16, 0x00           ; Inicializar R16 para usarlo como índice
LOOP2:
    CP      R16, R24            ; Comparar el índice con el valor de las decenas
    BREQ    DECENAS_ENCONTRADAS ; Si coincide, salir del bucle
    INC     R16                 ; Incrementar el índice
    ADIW    Z, 1                ; Mover el puntero Z al siguiente valor en la tabla
    RJMP    LOOP2               ; Repetir el bucle

DECENAS_ENCONTRADAS:
    LPM     R25, Z              ; Cargar el valor de la tabla en R25 (decenas)

INCREMENTAR_UNIDADES:
    INC     R21                 ; Solo incrementar las unidades si no estaban en 9

FIN_SUM:
    RET

//============= progra por IA ==========================
/*SUMA:
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    MOV     R16, R21            ; Cargar el valor de las unidades en R16
    ADD     ZL, R16             ; Sumar el valor de R16 al puntero Z (apuntar al valor correcto)
    LPM     R23, Z              ; Cargar el valor de la tabla en R23 (unidades)
    
    INC     R21                 ; Incrementar el contador de unidades
    CPI     R21, 0x0A           ; ¿Llegó a 10?
    BRNE    FIN_SUM             ; Si no, terminar
    
    ; Si llegó a 10, reiniciar unidades y aumentar decenas
    LDI     R21, 0x00           ; Reiniciar el contador de unidades
    INC     R24                 ; Incrementar el contador de decenas
    CPI     R24, 0x0A           ; ¿Llegó a 10?
    BRNE    FIN_SUM             ; Si no, terminar
    
    ; Si llegó a 10, reiniciar decenas
    LDI     R24, 0x00           ; Reiniciar el contador de decenas

FIN_SUM:
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    MOV     R16, R24            ; Cargar el valor de las decenas en R16
    ADD     ZL, R16             ; Sumar el valor de R16 al puntero Z (apuntar al valor correcto)
    LPM     R25, Z              ; Cargar el valor de la tabla en R25 (decenas)
    RET*/


SUMA_BOTON:
    INC     R19			//Incrementar R19
    CPI     R19, 0x10	//¿Llegó a 0x10?
    BRNE    FIN_SUM_BOTON	//Si no, continuar
    LDI     R19, 0x00	//Si sí, reiniciar a 0
FIN_SUM_BOTON:
    RET

RESTA:
    CPI     R19, 0x00	//¿Está en 0?
    BREQ    SET_MAX		//Si, colocar en 0x0F
    DEC     R19			//Decrementar
    RET
SET_MAX:
    LDI     R19, 0x0F
    RET


//================================================== RUTINAS DE INTERRUPCIÓN =====================================================================
ISR_TIMER0:
	PUSH	R16
	IN		R16,  SREG
	PUSH	R16

	LDI		R16, 100	//Poner a 100
	OUT		TCNT0, R16	// Cargar valor inicial en TCNT0
	
	INC		R22
	CPI		R22, 100
	BRNE	FIN_SUM_TIMER
	CALL	SUMA
	//LPM		R23, Z

	//OUT		PORTD, R23
	LDI		R22, 0x00


FIN_SUM_TIMER:

	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

ISR_BOTON:
    PUSH	R16
    IN		R16, SREG
    PUSH	R16

    // Verificar si el botón en PB0 fue presionado (disminuir contador)
    SBIC	PINB, PB0
    RJMP	CHECK_PB1  // Si no está presionado, verificar el otro botón
    CALL	RESTA      // Llamar a la rutina para disminuir el contador

CHECK_PB1:
    // Verificar si el botón en PB1 fue presionado (aumentar contador)
    SBIC	PINB, PB1
    RJMP	FIN_ISR_BOTON  // Si no está presionado, salir de la ISR
    CALL	SUMA_BOTON     // Llamar a la rutina para aumentar el contador

FIN_ISR_BOTON:
    POP		R16
    OUT		SREG, R16
    POP		R16
    RETI
	