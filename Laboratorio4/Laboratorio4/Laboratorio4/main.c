/*
 * Laboratorio4.c
 * 
 * Created: 28/03/2025 23:09:24
 * Author: Bryan Morales
 * Description:
 */
//************************************************************************************
// Encabezado (Libraries)#define F_CPU 16000000#include <avr/io.h>#include <avr/interrupt.h>/****************************************/// Function prototypesvoid setup();void RESTA_BOTON(void);
void SUMA_BOTON(void);/****************************************/// Main Functionint main(void){	setup();		while (1)	{	}}/****************************************/// NON-Interrupt subroutinesvoid setup(){
	cli();
	DDRD = 0xFF;     // Configuro PORTD como salida
	PORTD = 0x00;    // PORTD inicialmente apagado (LEDS)
	
	// Configuración de botones en PORTB
	DDRB &= ~((1 << PB0) | (1 << PB1));  // PB0 y PB1 como entradas
	PORTB |= (1 << PB0) | (1 << PB1);    // Activar pull-ups 
	
	// Configuración de transistores en PORTC para multiplexar
	DDRC |= (1 << PC0) | (1 << PC1) | (1 << PC2);  // PORTC como salida
	
	PORTC &= ~((1 << PC0) | (1 << PC1));  // Transistores PC0 y PC1 apagados inicialmente
	PORTC |= (1 << PC2);                  // Transistor PC2 encendido inicialmente
	
	// Habilitar interrupción en PB0 y PB1 (PCI0)
	PCICR |= (1 << PCIE0);               // Habilitar interrupciones en PORTB
	PCMSK0 |= (1 << PCINT0) | (1 << PCINT1);  // PB0 y PB1 (PCINT0 y PCINT1)
	sei();
}void RESTA_BOTON(void){	PORTD--;			//Decrementa el valor de PORTD}void SUMA_BOTON(void) {
	PORTD++;			//Incrementa el valor de PORTD
}/****************************************/// Interrupt routinesISR(PCINT0_vect) {
	// Verificar estado actual de los botones
	if (!(PINB & (1 << PB0))) {  // Si PB0 está presionado (pull-up)
		RESTA_BOTON();
	}
	if (!(PINB & (1 << PB1))) {  // Si PB1 está presionado
		SUMA_BOTON();
	}
}