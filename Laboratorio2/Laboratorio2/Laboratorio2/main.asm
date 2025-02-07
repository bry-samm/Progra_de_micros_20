;
; Laboratorio2-Contadorxtiempo.asm
;
; Created: 07/02/2025
//Encabezado 
//Bryan Samuel Morales Paredes 23283
// Este código es un contador binario de 4 bits que aumenta cada 100ms
.include "M328PDEF.inc"
.cseg
.org 0x0000

/******************************************************************/
//Configuración de la pila 
/*****************************************************************/
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16		// SPL 
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16		// SPH 
//=================================================================================
//Configurar el microcontrolador (MCU)
SETUP:
