/*
 * PWM_SERVO.c
 *
 * Created: 5/04/2025 10:59:03
 *  Author: Bryan Morales
 */ 
#include <avr/io.h>

void initPWM(){
	DDRB |= (1 << DDB1); // PB1 as output (OC1A)
	TCCR1A = 0;
	TCCR1A |= (1 << COM1A1); // Set as non inverted
	//TCCR1A |= (1 << WGM11) | (1 << WGM10); // Set mode 7 => Fast PWM and top = 0x03FF
	TCCR1A |= (1 << WGM10); // Set mode 5 => Fast PWM and top = 0xFF
	
	
	TCCR1B = 0;
	TCCR1B |= (1 << WGM12);
	TCCR1B |= (1 << CS11) | (1 << CS10); // Prescaler 64
	
}

void initADC(){
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // Se ponen los 5V como referencia

	ADMUX	|= (1 << ADLAR); // Justificaci[on a la izquierda
	ADMUX	|= (1 << MUX1) | (1<< MUX0); //Select ADC3
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE); // Enable interruption
	ADCSRA	|= (1 << ADEN); // Enable ADC
	
	ADCSRA	|= (1<< ADSC); // Start conversion
}