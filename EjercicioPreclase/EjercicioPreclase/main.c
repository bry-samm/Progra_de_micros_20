/*
 * EjercicioPreclase.c
 * 
 * Created: 25/04/2025 21:23:16
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
void mostrar_menu();

uint8_t estado_led = 0;
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
	
	//Leds configuration, PORTD as output
	DDRD |= (1 << PORTD2) | (1 << PORTD3); 
	PORTD = 0x00;
	//Pushbutton configuration
	DDRB &= ~(1 << PORTB2);
	PORTB |= (1 << PORTB2); //Activate pull up
	
	// Enable interruption in PB2 (PCI0)
	PCICR |= (1 << PCIE0);               // Enable interruption in PORTB
	PCMSK0 |= (1 << PCINT2);  // PB2
	
	initUART();
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

void writeChar(char caracter){
	
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter;
}

void cadena_texto(char* texto) {
	while (*texto != '\0') {
		writeChar(*texto);
		texto++;
	}
}

void mostrar_menu(){
	writeChar(' ');
	cadena_texto("\n Ingrese ON/OFF para encender o apagar la led");
	cadena_texto("\n 1. ON (encender)");
	cadena_texto("\n 2. OFF (apagar)");
}
//************************************************************************************
// Interrupt subroutines
ISR(PCINT0_vect){
	if (!(PINB & (1 << PORTB2))){
		//Hacer una compuerta lógica XOR para cambiar el estado 
		estado_led ^= 1; // Hace el toggle
		/*
		*También puede realizarse con un not
		
		estado_led = !estado_led;
		
		*o bien estableciendo el valor en el if 
		if (estado_led == 1);
		estado_led = 0;
		programa...
		else if (estado_led == 0);
		estado_led = 1;
		programa...
		*/
		
		if (estado_led){
			PORTD |= (1 << PORTD3);    // enciende PD3
		}else{
			PORTD &= ~(1 << PORTD3); // Apaga led
		}
	}
}


ISR(USART_RX_vect){
	char recibido = UDR0;
	// Ignorar salto de línea y carriage return
	if (recibido == '\n' || recibido == '\r') return;
	
	if (recibido == '1'){
		PORTD |= (1 << PORTD2);
		cadena_texto("LED encendida (ON) ");
		mostrar_menu();
	}
	else if (recibido == '2'){
		PORTD &= ~(1 << PORTD2);
		cadena_texto("LED apagada (OFF) ");
		//mostrar_menu();
	}
	else{
		writeChar(' ');
		cadena_texto("\ Valor no valido ");
		mostrar_menu();
	}

}