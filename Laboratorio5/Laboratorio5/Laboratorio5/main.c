/*
 * Laboratorio5.c
 * 
 * Created: 4/04/2025 19:02:23
 * Author: Bryan Morales
 * Description: Movimiento de dos servos por medio de PWM y atenuar la intensidad de un led con una se�al PWM manual, todos haciendo uso de un ADC (potenci�metro)
 */
//************************************************************************************

// Encabezado (librer�as)
#define	F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include "PWM_SERVO/PWM_SERVO.h"
#include "PWM2_SERVO/PWM2_SERVO.h"
#include "MANUAL_PWM/MANUAL_PWM.h"

uint8_t		multiplexar_ADC = 0;
uint8_t		ADC_value;
uint8_t		pwm_counter;

//Manual PWM
uint8_t		manual_PWM;
#define PWM_TOP 20 // Periodo total = 2000 us = 2ms = 500Hz aprox (ajustable)

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
	initPWM2();
	initTM0();
	
	sei();
}

//************************************************************************************
// Interrupt subroutines

ISR(ADC_vect){
	multiplexar_ADC = ADMUX & 0x0F; //Create a mask
	ADC_value = ADCH;
	if (multiplexar_ADC == 3){
		uint8_t angle = (ADC_value * 180) / 255;
		OCR1A = SERVO_MIN + (angle * (SERVO_MAX - SERVO_MIN) / 180);
		// Change to ADC4 0100
		ADMUX = (ADMUX & 0xF0) | 4; // I made the "&" with 0xF0 because in the high bits are the configuration of the MUX and i want to save this values
	}
	else if (multiplexar_ADC == 4)
	{
		uint8_t angle2 = (ADC_value * 180) / 255;
		OCR2A = SERVO_MIN_2 + (angle2 * (SERVO_MAX_2 - SERVO_MIN_2) / 180);
		// Change to ADC3  0011
		ADMUX = (ADMUX & 0xF0) | 5; // I do not write ADMUX |= (ADMUX & 0xF0) | 3; because y want to erase de prevous configuration of the MUX
	}
	else if (multiplexar_ADC == 5){
		manual_PWM = (ADC_value * PWM_TOP) / 255; // Rescale value 

		//manual_PWM = ADC_value; // ADC de 0-255 directamente como duty
		ADMUX = (ADMUX & 0xF0) | 3; // Vuelve a ADC3
	}


	ADCSRA |= (1 << ADSC); // Start new conversion
}

/*

	lectura_ADC = ADCH;
	
	uint8_t angle = (lectura_ADC * 180) / 255;  
	
	// Convert an angle using a rule of three
	//OCR0A determinate the duty cycle, the values of SERVO_MIN and SERVO_MAX are explained in library PWM_SERVO.h
	//Converts an angle (0� to 180�) into a value that must be entered into OCR0A so that the servo motor receives the correct pulse and moves to that angle.
	
	OCR1A = SERVO_MIN + (angle * (SERVO_MAX - SERVO_MIN) / 180); 
	
	//Use another rule of three to convert the angle into steps in the range of SERVO_MIN to SERVO_MAX
	
*/

ISR(TIMER0_OVF_vect){ // Is executed when occurs overflow
	pwm_counter++; // Increase counter
	if (pwm_counter < manual_PWM){
		PORTD |= (1 << PORTD2);  // LED ON
	}
	else{
		PORTD &= ~(1 << PORTD2); // LED OFF
	}
	if (pwm_counter >= PWM_TOP){ // counter reset if counter have the value of PWM_TOP
		pwm_counter = 0;
	}
}
