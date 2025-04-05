/*
 * Laboratorio4.c
 * 
 * Created: 28/03/2025 23:09:24
 * Author: Bryan Morales
 * Description: Contador binario de 8 bits controlado por botones paralelo a un contador hexadecimal de 8 bits controlado por
 * un potenciómetro el cual se muestra en un display, si el contador hexadecimal es mayor al binario se enciente una led como alarma 
 */
//************************************************************************************
// Encabezado (Libraries)#define F_CPU 16000000#include <avr/io.h>#include <avr/interrupt.h>#include <util/delay.h>uint8_t		contador_mostrar_dis;uint8_t		contador_leds;uint8_t		lectura_ADC;
uint8_t		segmentos_unidades;
uint8_t		segmentos_decenas;int		valores_display[16] = {0x7D, 0x48, 0x3E, 0x6E, 0x4B, 0x67, 0x77, 0x4C, 0x7F, 0x6F, 0x5F, 0x73, 0x35, 0x7A, 0x37, 0x17 };/****************************************/// Function prototypesvoid setup();void RESTA_BOTON(void);
void SUMA_BOTON(void);void initTMR0();void initADC();/****************************************/// Main Functionint main(void)
{
	setup();  // Configurar ADC y otros periféricos
	
	while (1)
	{
		//Alternativa si se desea colocar la lógica en en main
		//Se debe de agregar un delay, prefiero dejar la comparación en la interrupción para que sea instantáneo
		/* 
			if (lectura_ADC >= contador_leds) {
				PORTC |= (1 << PORTC4);  // Apagar LED si ADC es mayor o igual
			}
			else {
				PORTC &= ~(1 << PORTC4);   // Encender LED si ADC es menor
				}
				_delay_ms(10);  // Pequeño retraso para evitar interferencias
				*/
	}
}
/****************************************/// NON-Interrupt subroutinesvoid setup(){
	cli();
	
	CLKPR	= (1 << CLKPCE); //Habilitar la configuración del oscilador CPU
	CLKPR	= (1 << CLKPS2); // 16 PRESCALER -> 1MHz
	
	DDRD = 0xFF;     // Configuro PORTD como salida
	PORTD = 0x00;    // PORTD inicialmente apagado (LEDS)
	
	// Configuración de botones en PORTB
	DDRB &= ~((1 << PORTB0) | (1 << PORTB1));  // PB0 y PB1 como entradas
	PORTB |= (1 << PORTB0) | (1 << PORTB1);    // Activar pull-ups 
	
	// Configuración de transistores y led en PORTC para multiplexar y mostrar alarma
	DDRC |= (1 << PORTC0) | (1 << PORTC1) | (1 << PORTC2) | (1 << PORTC4);  // PORTC como salida
	
	PORTC &= ~((1 << PORTC0) | (1 << PORTC1) | (1 << PORTC2) | (1 << PORTC4));  // Transistores t led inicialmente apagado
	
	// Habilitar interrupción en PB0 y PB1 (PCI0)
	PCICR |= (1 << PCIE0);               // Habilitar interrupciones en PORTB
	PCMSK0 |= (1 << PCINT0) | (1 << PCINT1);  // PB0 y PB1 
	
	initTMR0();
	initADC();
	
	sei();
}void RESTA_BOTON(void){	contador_leds--;	PORTD = contador_leds;			//Decrementa el valor de PORTD}void SUMA_BOTON(void) {
	contador_leds++;
	PORTD = contador_leds;			//Incrementa el valor de PORTD
}void initTMR0(){	TCCR0A  = 0;	TCCR0B  |= (1 << CS01) | (1 << CS00); 	TCNT0   = 200;	TIMSK0  = (1 << TOIE0);}void initADC(){
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // Se ponen los 5V como referencia

	ADMUX	|= (1 << ADLAR); // Justificaci[on a la izquierda
	ADMUX	|= (1 << MUX1) | (1<< MUX0); //Seleccionar el ADC3
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE); // Habilitar interrupción
	ADCSRA	|= (1 << ADEN); //
	
	ADCSRA	|= (1<< ADSC);
}/****************************************/// Interrupt routinesISR(PCINT0_vect) {
	// Verificar estado actual de los botones
	if (!(PINB & (1 << PORTB0))) {  // Si PB0 está presionado (pull-up)
		RESTA_BOTON();
	}
	if (!(PINB & (1 << PORTB1))) {  // Si PB1 está presionado
		SUMA_BOTON();
	}
}

ISR(TIMER0_OVF_vect){
	TCNT0 = 200;
	contador_mostrar_dis++;
	PORTD = 0;  // Apagar todos los segmentos primero
	PORTC &= ~((1 << PORTC0) | (1 << PORTC1) | (1 << PORTC2));  // Apagar todos los transistores
	
	switch(contador_mostrar_dis){
		case 1:
		PORTC |= (1 << PORTC2);  // Encender transistor de leds 
		PORTD = contador_leds;  // Mostrar contador de leds
		break;
		case 2:
		PORTC |= (1 << PORTC0);  // Encender transistor display 1
		PORTD = segmentos_decenas;  // Mostrar valor para display 1
		break;
		case 3:
		PORTC |= (1 << PORTC1);  // Encender transistor display 2
		PORTD = segmentos_unidades;  // Mostrar valor para display 2
		break;
		default:
		contador_mostrar_dis = 0;
	}
	
	if (lectura_ADC >= contador_leds) {
		PORTC |= (1 << PORTC4);  // Apagar LED si ADC es mayor o igual
	}
	else {
		PORTC &= ~(1 << PORTC4);   // Encender LED si ADC es menor
	}
}

ISR(ADC_vect)
{
	lectura_ADC = ADCH;
	
	segmentos_decenas = valores_display[lectura_ADC >> 4];  // Dígito alto 
	segmentos_unidades = valores_display[lectura_ADC & 0x0F];  // Dígito bajo
	
	ADCSRA	|= (1<< ADSC);		//Inicia una nueva lectura
}