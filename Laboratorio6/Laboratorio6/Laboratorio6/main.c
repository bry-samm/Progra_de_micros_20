/*
 * Laboratorio6.c
 * 
 * Created: 14/04/2025 23:31:09
 * Author: Bryan Morales
 * Description:
 */
//************************************************************************************
// Encabezado (librerías)
#include <avr/io.h>
#include <avr/interrupt.h>
//************************************************************************************
// Function prototypes
void setup();
void initUART();
void writeChar(char caracter);
void cadena_texto(char* texto);
void initADC();
void mostrar_menu();
void enviar_numero();

uint8_t estado = 0;
uint8_t lectura_ADC;
//************************************************************************************
// Main Function
int main(void)
{
	setup();
	mostrar_menu();
	while (1)
	{
	}
}
//************************************************************************************
// NON-INterrupt subroutines
void setup(){
	cli();
	
	DDRB = 0xFF;    // Puerto B como salida
	PORTB = 0x00;   // Iniciar en 0 (todo apagado)
	DDRD = 0b11111100;
	PORTD = 0x00;
	
	initUART();
	initADC();
	sei();
}

void initUART(){
	//Step1 : configurate pin PD0 (rx) and PD1 (tx)
	DDRD |= (1 << DDD1);
	DDRD &= ~(1 << DDD0);
	//Step 2: UCSR0A
	UCSR0A = 0;
	//Step 3: UCSR0B: enable interrupts, enable recibir, enable transmition  
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	//Step 4 : UCSR0C
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	//Step 5: UBRR0 0 103 => 9600 16kHz
	UBRR0 = 103; 

}

void initADC(){
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // 5V as reference

	ADMUX	|= (1 << ADLAR); // Left justification
	
	ADMUX	|= (1 << MUX1) | (1<< MUX0); //Select ADC3 
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Sampling frequency = 125kHz "sampling = muestreo"
	ADCSRA	|= (1 << ADIE); // Enable interruption
	ADCSRA	|= (1 << ADEN); // Enable ADC
	
	
	ADCSRA	|= (1<< ADSC); // Start conversion
}

void writeChar(char caracter){
	
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter;
}

/*
void cadena_texto(char* texto){
	for (uint8_t i = 0; *(texto+i) != '\0'; i++){
		writeChar(*(texto+i));
	}
}*/

void cadena_texto(char* texto) {
	while (*texto != '\0') {
		writeChar(*texto);
		texto++;
	}
}

void mostrar_menu(){
	writeChar(' ');
	writeChar('B');
	writeChar(':');
	writeChar(' ');
	cadena_texto("\n Ingrese el número para ejecutar la opción");
	cadena_texto("\n 1. Leer potenciómetro");
	cadena_texto("\n 2. Enviar Ascii");
}

void enviar_numero(lectura_ADC) {
	if (lectura_ADC == 0) {
		writeChar('0');
		return;
	}

	if (lectura_ADC >= 100) {
		writeChar((lectura_ADC / 100) + '0');
		lectura_ADC %= 100;
		writeChar((lectura_ADC / 10) + '0');
		lectura_ADC %= 10;
		writeChar(lectura_ADC + '0');
		} else if (lectura_ADC >= 10) {
		writeChar((lectura_ADC / 10) + '0');
		lectura_ADC %= 10;
		writeChar(lectura_ADC + '0');
		} else {
		writeChar(lectura_ADC + '0');
	}
}

//************************************************************************************
// Interrupt subroutines
/*
ISR(USART_RX_vect){
	char temporal = UDR0;
	writeChar(temporal);
}
*/
/*

ISR(USART_RX_vect){
	char recibido = UDR0;
	char recibido_B = ((recibido &  0b11000000) >> 6) ;
	char recibido_D = (recibido << 2);
	PORTB = recibido_B;   // Show ASCII value in PORTB
	uint8_t temporal = PORTD & 0x03;
	PORTD = recibido_D | temporal;
}
*/

ISR(USART_RX_vect){
	char recibido = UDR0;
	if (estado == 0){
		if(recibido == '1'){
			cadena_texto("\n Valor potenciometro: ");
			enviar_numero(lectura_ADC);
			cadena_texto("\n");
			cadena_texto("\n");
			
			uint8_t lectura_ADC_B = ((lectura_ADC &  0b11000000) >> 6) ;
			uint8_t lectura_ADC_D = (lectura_ADC << 2);
			PORTB = lectura_ADC_B;   // Show ASCII value in PORTB
			uint8_t temporal_ADC = PORTD & 0x03;
			PORTD = lectura_ADC_D | temporal_ADC;
			
			mostrar_menu();
		} else if (recibido == '2'){
			cadena_texto("\n Ingrese caractér, finalize con #");
			estado = 1;
		} else {
			cadena_texto("\n Entrada no válida \n");
			cadena_texto("\n");
			mostrar_menu();
	}
		} else if (estado == 1){
		if (recibido == '#'){
			cadena_texto("\n Finalizando \n");
			cadena_texto("\n");
			estado = 0;
			mostrar_menu();
		} else {
			writeChar(recibido);
			char recibido_B = ((recibido &  0b11000000) >> 6) ;
			char recibido_D = (recibido << 2);
			PORTB = recibido_B;   // Show ASCII value in PORTB
			uint8_t temporal = PORTD & 0x03;
			PORTD = recibido_D | temporal;
		}
	}
}


ISR(ADC_vect)
{
	lectura_ADC = ADCH;
	ADCSRA	|= (1<< ADSC);		//Inicia una nueva lectura
}

