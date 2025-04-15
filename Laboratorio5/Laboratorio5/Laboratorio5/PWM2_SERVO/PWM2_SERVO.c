/*
 * PWM2_SERVO.c
 *
 * Created: 7/04/2025 16:45:32
 *  Author: Bryan Morales
 */ 

#include <avr/io.h>

void initPWM2(){
	DDRB |= (1 << DDB3); // PB3 as output (OC2A)
	TCCR2A = 0;
	TCCR2A |= (1 << COM2A1); // Set as non inverted
	TCCR2A |= (1 << WGM21) | (1 << WGM20); // Set mode 3 => Fast PWM and top = 0xFF
	
	TCCR2B = 0;
	TCCR2B |= (1 << CS22); // Prescaler 64
}

