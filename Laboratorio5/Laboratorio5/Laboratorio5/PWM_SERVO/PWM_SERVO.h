/*
 * PWM_SERVO.h
 *
 * Created: 5/04/2025 10:58:07
 *  Author: bsmor
 */ 


#ifndef PWM_SERVO_H_
#define PWM_SERVO_H_

// Servo limit 
#define SERVO_MIN  9   // OCR0A for 0° (1ms of pulse)
#define SERVO_MAX  35   // OCR0A for 180° (2ms of pulse)

//************************************************************************************
// Function prototypes
void initPWM();
void initADC();


#endif /* PWM_SERVO_H_ */