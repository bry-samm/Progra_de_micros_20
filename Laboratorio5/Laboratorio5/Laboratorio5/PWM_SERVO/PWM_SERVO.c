/*
 * PWM_SERVO.c
 *
 * Created: 5/04/2025 10:59:03
 *  Author: Bryan Morales
 */ 
#include <avr/io.h>
void initPWM(){
	DDRD |= (1 << DDD6); // Set PORTD6 as output
	TCCR0A = 0;
	TCCR0A |= (1 << COM0A1); // Set as non inverted
	TCCR0A |= (1 << WGM01) | (1 << WGM00); // Set mode 3 => Fast PWM and top = 0xFF
	
	TCCR0B = 0;
	TCCR0B |= (1 << CS01) | (1 << CS00); //64
	
}

void initADC(){
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // Se ponen los 5V como referencia

	ADMUX	|= (1 << ADLAR); // Justificaci[on a la izquierda
	ADMUX	|= (1 << MUX1) | (1<< MUX0); //Seleccionar el ADC3
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE); // Habilitar interrupción
	ADCSRA	|= (1 << ADEN); //
	
	ADCSRA	|= (1<< ADSC);
}