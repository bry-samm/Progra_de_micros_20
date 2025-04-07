/*
 * Laboratorio5.c
 * 
 * Created: 4/04/2025 19:02:23
 * Author: Bryan Morales
 * Description:
 */
//************************************************************************************

// voltaile uint8_t lectura _ADC????

// Encabezado (librerías)
#define	F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include "PWM_SERVO/PWM_SERVO.h"

uint8_t		lectura_ADC;
//************************************************************************************
// Function prototypes
void setup();
//************************************************************************************
// Main Function
int main(void)
{
	setup();
	while (1)
	{
	}
}
//************************************************************************************
// NON-INterrupt subroutines
void setup(){
	cli();
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS2); // Configurate to 1MHz
	
	UCSR0B = 0; //Disable serial
	
	initPWM();
	initADC();
	
	sei();
}

//************************************************************************************
// Interrupt subroutines
ISR(ADC_vect)
{
	lectura_ADC = ADCH;
	
	uint8_t angle = (lectura_ADC * 180) / 255;  // Convert an angle using a rule of three
	//OCR0A determinate the duty cycle, the values of SERVO_MIN and SERVO_MAX are explained in library PWM_SERVO.h
	//Converts an angle (0° to 180°) into a value that must be entered into OCR0A so that the servo motor receives the correct pulse and moves to that angle.
	OCR1A = SERVO_MIN + (angle * (SERVO_MAX - SERVO_MIN) / 180); //Use another rule of three to convert the angle into steps in the range of SERVO_MIN to SERVO_MAX
	
	ADCSRA	|= (1<< ADSC);		// Start a new reading
}
