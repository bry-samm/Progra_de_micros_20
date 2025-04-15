/*
 * MANUAL_PWM.c
 *
 * Created: 15/04/2025 10:54:41
 *  Author: bsmor
 */ 

#include <avr/io.h>

void initTM0(){
	
	DDRD |= (1 << PORTD2); // PD6 como salida (LED)
	
	TCCR0A = 0; // Modo normal
	TCCR0B = (1 << CS00); // Prescaler 1


	TIMSK0 = (1 << TOIE0); // Habilitar interrupción overflow
	
}
