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
	LDI		R16, (1 << CLKPS2)	//Configura prescaler a 16 (16 MHz / 16 = 1 MHz)
	STS		CLKPR, R16

	// Inicializar timer0
	LDI		R16, (1<<CS01) | (1<<CS00)	//Configuraci�n para el prescaler de 64 (ver datasheet)
	OUT		TCCR0B, R16			// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100			//Poner a 100
	OUT		TCNT0, R16			// Cargar valor inicial en TCNT0
	
	//PORTD y PORTC como salida e inicialmente apagado 
	LDI		R16, 0xFF
	OUT		DDRD, R16			//Setear puerto D como salida
	OUT		DDRC, R16
	LDI		R16, 0x00
	OUT		PORTD, R16			//Apagar puerto D
	OUT		PORTC, R16

	//PORTB como entrada
	LDI		R16, 0x00
	OUT		DDRB, R16			//Setear puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16			//Habilidar pull-up en puerto B

	//Configuraci�n del display

	DISPLAY_VAL:	.db		0x7E, 0x30,	0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B
	//						 0	    1	  2		3	 4     5	  6     7     8		9
	CALL SET_INICIO

//===================== CONFIGURACI�N INTERRUPCIONES =======================

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
//bot�n
	LDI		R20, 0x00
	LDI		R19, 0x00
	LDI		R18, 0x00
	LDI		R17, 0x00
	LDI		R16, 0x00
	
	LPM		R23, Z				// Mostrar en el display1 0
	LPM		R25, Z				// Mostrar en el display2 0

	SEI
//============================================================================
MAIN:

	OUT		PORTC, R19			// Muestro el valor del contador binario (botones)
	SBRS	R22, 0				//Verifico si el bit0 del contador del timer0 es 1 ya que este bit0 se alterna constantemente
	RJMP	CONTADOR_1			// Si el bit0 es 0 salta al segundo display
	CBI		PORTC, PC4			// Apago el pin para el transistor del primer display
	LDI		R16, 0x00			//Cargo un inmediato a un registro
	OUT		PORTD, R16			//Apago todo el puerto para que no tenga el efecto fantasma 
	SBI		PORTC, PC5			//Enciendo el pin para el transistor del segundo delay
	OUT		PORTD, R25			//Muestro el valor del display (R25 est� en la subrutina suma)
	RJMP	MAIN				//Regresa al loop
CONTADOR_1:									
	CBI		PORTC, PC5			//Esta parte tiene la misma l�gica solo que para encender el display 1 y alternar el valor de los pines para los transistores
	LDI		R16, 0x00
	OUT		PORTD, R16
	SBI		PORTC, PC4
	OUT		PORTD, R23

	OUT		PORTC, R19			// Muestro el valor del contador binario (botones)
	RJMP	MAIN

//================================================= RUTINAS NO INTERRUPCI�N ==================================================================
SET_INICIO:
	LDI		ZL, LOW(DISPLAY_VAL <<1)	//Coloca el direccionador indirecto en la posici�n inicial
	LDI		ZH, HIGH(DISPLAY_VAL <<1)
	RET

SUMA:
    CALL    SET_INICIO			//Reiniciar el puntero Z al inicio de la tabla
    LDI     R16, 0x00			//Inicializar R16 para usarlo como �ndice

LOOP1:
    CP      R16, R21			//Comparar el �ndice con el valor de las unidades
    BREQ    UNIDADES_ENCONTRADAS//Si coincide, salir del bucle
    INC     R16					//Incrementar el �ndice
    ADIW    Z, 1				//Mover el puntero Z al siguiente valor en la tabla
    RJMP    LOOP1				//Repetir el bucle

UNIDADES_ENCONTRADAS:
    LPM     R23, Z              //Cargar el valor de la tabla en R23 (unidades)
    
    CPI     R21, 0x0A           //�Las unidades est�n en 9?
    BRNE    INCREMENTAR_UNIDADES //Si no est�n en 9, solo incrementar

    ; Si estaban en 9, reiniciar unidades y aumentar decenas
    LDI     R21, 0x00           //Reiniciar el contador de unidades
    CALL    SET_INICIO          //Reiniciar el puntero Z al inicio de la tabla
    LPM     R23, Z              //Cargar el valor de 0 en R23 (unidades)
    INC     R24                 //Incrementar el contador de decenas
    CPI     R24, 0x06           //�Lleg� a 6? para hacer los 60s
    BRNE    ACTUALIZAR_DECENAS  //Si no, actualizar el valor de las decenas
    ; Si lleg� a 10, reiniciar decenas
    LDI     R24, 0x00           //Reiniciar el contador de decenas

ACTUALIZAR_DECENAS:
    CALL    SET_INICIO          //Reiniciar el puntero Z al inicio de la tabla
    LDI     R16, 0x00           //Inicializar R16 para usarlo como �ndice (el que coloca en su valor original el puntero para poder aumentarlo luego)
LOOP2:
    CP      R16, R24            //Comparar si R16 con el valor de las decenas
    BREQ    DECENAS_ENCONTRADAS //Si coincide, salir del bucle
    INC     R16                 //Incrementar R16 y el puntero 
    ADIW    Z, 1                //Mover el puntero Z al siguiente valor en la tabla
    RJMP    LOOP2               //Repetir el bucle hasta que alcance el valor

DECENAS_ENCONTRADAS:
    LPM     R25, Z              //Cargar el valor de la tabla en R25 (decenas)

INCREMENTAR_UNIDADES:
    INC     R21                 //Solo incrementar las unidades si no estaban en 9

FIN_SUM:
    RET

//============= progra por IA ==========================
/*SUMA:
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    MOV     R16, R21            ; Cargar el valor de las unidades en R16
    ADD     ZL, R16             ; Sumar el valor de R16 al puntero Z (apuntar al valor correcto)
    LPM     R23, Z              ; Cargar el valor de la tabla en R23 (unidades)
    
    INC     R21                 ; Incrementar el contador de unidades
    CPI     R21, 0x0A           ; �Lleg� a 10?
    BRNE    FIN_SUM             ; Si no, terminar
    
    ; Si lleg� a 10, reiniciar unidades y aumentar decenas
    LDI     R21, 0x00           ; Reiniciar el contador de unidades
    INC     R24                 ; Incrementar el contador de decenas
    CPI     R24, 0x0A           ; �Lleg� a 10?
    BRNE    FIN_SUM             ; Si no, terminar
    
    ; Si lleg� a 10, reiniciar decenas
    LDI     R24, 0x00           ; Reiniciar el contador de decenas

FIN_SUM:
    CALL    SET_INICIO          ; Reiniciar el puntero Z al inicio de la tabla
    MOV     R16, R24            ; Cargar el valor de las decenas en R16
    ADD     ZL, R16             ; Sumar el valor de R16 al puntero Z (apuntar al valor correcto)
    LPM     R25, Z              ; Cargar el valor de la tabla en R25 (decenas)
    RET*/


SUMA_BOTON:
    INC     R19			//Incrementar R19
    CPI     R19, 0x10	//�Lleg� a 0x10?
    BRNE    FIN_SUM_BOTON	//Si no, continuar
    LDI     R19, 0x00	//Si s�, reiniciar a 0
FIN_SUM_BOTON:
    RET

RESTA:
    CPI     R19, 0x00	//�Est� en 0?
    BREQ    SET_MAX		//Si, colocar en 0x0F
    DEC     R19			//Decrementar
    RET
SET_MAX:
    LDI     R19, 0x0F
    RET


//================================================== RUTINAS DE INTERRUPCI�N =====================================================================
ISR_TIMER0:
	PUSH	R16
	IN		R16,  SREG
	PUSH	R16

	LDI		R16, 100			//Poner a 100
	OUT		TCNT0, R16			// Cargar valor inicial en TCNT0
	
	INC		R22					//Incrementar un registro para llegar al segundo
	CPI		R22, 100			// R22 tiene que llegar a 100 ya que 10ms * 100 = 1s
	BRNE	FIN_SUM_TIMER		// Si no llega termina la interrupci�n
	CALL	SUMA				//Si es 100, llamar la funci�n suma para el display
	LDI		R22, 0x00			//Resetea el contador

FIN_SUM_TIMER:

	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

//Interrupci�n de bot�n 
ISR_BOTON:
    PUSH	R16
    IN		R16, SREG
    PUSH	R16

    SBIS	PINB, PB0			// Si PB0 est� presionado restar
    CALL	RESTA				// Llamar a la rutina para disminuir el contador
    SBIS	PINB, PB1			// Si PB1 est� presionado sumar
    CALL	SUMA_BOTON			// Llamar a la rutina para aumentar el contador

	// Peque�o retardo para antirrebote (de igual forma el circuito f�sico tiene un anti rebote f�sico)
	//Resistencia de 220 ohm y un capacitor cer�mico de 10nF
    LDI     R16, 10             // Cargar un valor peque�o para el retardo
DELAY_LOOP:
    DEC     R16                 // Decrementar el contador de retardo
    BRNE    DELAY_LOOP          // Repetir hasta que el contador llegue a cero

    POP		R16
    OUT		SREG, R16
    POP		R16
    RETI