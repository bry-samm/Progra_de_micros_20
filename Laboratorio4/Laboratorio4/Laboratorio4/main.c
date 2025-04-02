/*
 * Laboratorio4.c
 * 
 * Created: 28/03/2025 23:09:24
 * Author: Bryan Morales
 * Description:
 */
//************************************************************************************
// Encabezado (Libraries)#define F_CPU 16000000#include <avr/io.h>#include <avr/interrupt.h>uint8_t		contador_mostrar_dis;uint8_t		contador_leds;uint8_t		lectura_ADC;
uint8_t		segmentos_unidades;
uint8_t		segmentos_decenas;int		valores_display[16] = {0x7D, 0x48, 0x3E, 0x6E, 0x4B, 0x67, 0x77, 0x4C, 0x7F, 0x6F, 0x5F, 0x73, 0x35, 0x7A, 0x7A, 0x17 };/****************************************/// Function prototypesvoid setup();void RESTA_BOTON(void);
void SUMA_BOTON(void);void initTMR0();void initADC();/****************************************/// Main Functionint main(void){	setup();		while (1)	{			}}/****************************************/// NON-Interrupt subroutinesvoid setup(){
	cli();
	
	CLKPR	= (1 << CLKPCE); //Habilitar la configuración del oscilador CPU
	CLKPR	= (1 << CLKPS2); // 16 PRESCALER -> 1MHz
	
	DDRD = 0xFF;     // Configuro PORTD como salida
	PORTD = 0x00;    // PORTD inicialmente apagado (LEDS)
	
	// Configuración de botones en PORTB
	DDRB &= ~((1 << PB0) | (1 << PB1));  // PB0 y PB1 como entradas
	PORTB |= (1 << PB0) | (1 << PB1);    // Activar pull-ups 
	
	// Configuración de transistores en PORTC para multiplexar
	DDRC |= (1 << PC0) | (1 << PC1) | (1 << PC2);  // PORTC como salida
	
	PORTC &= ~((1 << PC0) | (1 << PC1) | (1 << PC2));  // Transistores PC0, PC1, PC2 apagados inicialmente
	
	// Habilitar interrupción en PB0 y PB1 (PCI0)
	PCICR |= (1 << PCIE0);               // Habilitar interrupciones en PORTB
	PCMSK0 |= (1 << PCINT0) | (1 << PCINT1);  // PB0 y PB1 (PCINT0 y PCINT1)
	
	initTMR0();
	initADC();
	
	sei();
}void RESTA_BOTON(void){	contador_leds--;	PORTD = contador_leds;			//Decrementa el valor de PORTD}void SUMA_BOTON(void) {
	contador_leds++;
	PORTD = contador_leds;			//Incrementa el valor de PORTD
}void initTMR0(){	TCCR0A  = 0;	TCCR0B  |= (1 << CS01) | (1 << CS00);	TCNT0   = 200;	TIMSK0  = (1 << TOIE0);}void initADC(){
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
	if (!(PINB & (1 << PB0))) {  // Si PB0 está presionado (pull-up)
		RESTA_BOTON();
	}
	if (!(PINB & (1 << PB1))) {  // Si PB1 está presionado
		SUMA_BOTON();
	}
}

ISR(TIMER0_OVF_vect){
	TCNT0 = 200;
	contador_mostrar_dis++;
	PORTD = 0;  // Apagar todos los segmentos primero
	PORTC &= ~((1 << PC0) | (1 << PC1) | (1 << PC2));  // Apagar todos los transistores
	
	switch(contador_mostrar_dis){
		case 1:
		PORTC |= (1 << PC2);  // Encender transistor display 1
		PORTD = contador_leds;  // Mostrar valor para display 1
		break;
		case 2:
		PORTC |= (1 << PC0);  // Encender transistor display 2
		PORTD = segmentos_unidades;  // Mostrar valor para display 2
		break;
		case 3:
		PORTC |= (1 << PC1);  // Encender transistor display 3
		PORTD = segmentos_decenas;  // Mostrar valor para display 3
		break;
		default:
		contador_mostrar_dis = 0;
	}
}

ISR(ADC_vect)
{
	lectura_ADC = ADCH;
	
	uint8_t indice = (lectura_ADC * 16) / 256;  // Convertir ADC a índice 
	
	uint8_t numero_a_mostrar = valores_display[indice];  // Obtener valor del array
	uint8_t unidades = numero_a_mostrar % 10;
	uint8_t decenas  = (numero_a_mostrar / 10) % 10;

	// Obtener los dígitos de 7 segmentos
	segmentos_unidades = valores_display[unidades];
	segmentos_decenas  = valores_display[decenas];
	
	
	ADCSRA	|= (1<< ADSC);
}