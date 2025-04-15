/*
 * Laboratorio5.c
 * 
 * Created: 4/04/2025 19:02:23
 * Author: Bryan Morales
 * Description:
 */
//************************************************************************************

// Encabezado (librerías)
#define	F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
//#include "PWM_SERVO/PWM_SERVO.h"
//#include "PWM2_SERVO/PWM2_SERVO.h"

uint8_t		multiplexar_ADC = 0;
uint8_t		ADC_value;
uint8_t		pwm_counter;

//Servo limit 2
#define SERVO_MIN_2  9   // OCR0A for 0° (1ms of pulse)
#define SERVO_MAX_2  36

//Servo limit 1
#define SERVO_MIN  9   // OCR0A for 0° (1ms of pulse)
#define SERVO_MAX  36   // OCR0A for 180° (2ms of pulse)

//Manual PWM
uint8_t		estado_pwm;
uint8_t		manual_PWM;
#define PWM_TOP 20 // Periodo total = 2000 us = 2ms = 500Hz aprox (ajustable)

//************************************************************************************
// Function prototypes
void setup();

void initPWM2();

void initPWM();
void initADC();

void initTM0();
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


void initPWM2(){
	DDRB |= (1 << DDB3); // PB3 as output (OC2A)
	TCCR2A = 0;
	TCCR2A |= (1 << COM2A1); // Set as non inverted
	TCCR2A |= (1 << WGM21) | (1 << WGM20); // Set mode 3 => Fast PWM and top = 0xFF
	
	TCCR2B = 0;
	TCCR2B |= (1 << CS22); // Prescaler 64
}


void initPWM(){
	DDRB |= (1 << DDB1); // PB1 as output (OC1A)
	TCCR1A = 0;
	TCCR1A |= (1 << COM1A1); // Set as non inverted
	TCCR1A |= (1 << WGM10); // Set mode 5 => Fast PWM and top = 0xFF
	
	
	TCCR1B = 0;
	TCCR1B |= (1 << WGM12);
	TCCR1B |= (1 << CS11) | (1 << CS10); // Prescaler 64
}

void initADC(){
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // 5V as reference

	ADMUX	|= (1 << ADLAR); // Left justification
	
	ADMUX	|= (1 << MUX1) | (1<< MUX0); //Select ADC3
	//ADMUX	|= (1 << MUX2); //Select ADC4
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Sampling frequency = 125kHz "sampling = muestreo"
	ADCSRA	|= (1 << ADIE); // Enable interruption
	ADCSRA	|= (1 << ADEN); // Enable ADC
	
	
	ADCSRA	|= (1<< ADSC); // Start conversion
}

void initTM0(){
	
	DDRD |= (1 << PORTD2); // PD6 como salida (LED)
	
	TCCR0A = 0; // Modo normal
	TCCR0B = (1 << CS00); // Prescaler 1


	TIMSK0 = (1 << TOIE0); // Habilitar interrupción overflow
	
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
		manual_PWM = (ADC_value * PWM_TOP) / 255;

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
	//Converts an angle (0° to 180°) into a value that must be entered into OCR0A so that the servo motor receives the correct pulse and moves to that angle.
	
	OCR1A = SERVO_MIN + (angle * (SERVO_MAX - SERVO_MIN) / 180); 
	
	//Use another rule of three to convert the angle into steps in the range of SERVO_MIN to SERVO_MAX
	
*/

ISR(TIMER0_OVF_vect){
	pwm_counter++;
	if (pwm_counter < manual_PWM){
		PORTD |= (1 << PORTD2);  // LED ON
	}
	else{
		PORTD &= ~(1 << PORTD2); // LED OFF
	}
	if (pwm_counter >= PWM_TOP){
		pwm_counter = 0;
	}
}
