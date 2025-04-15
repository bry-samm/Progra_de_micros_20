/*
 * PWM_SERVO.h
 *
 * Created: 5/04/2025 10:58:07
 *  Author: bsmor
 */ 


#ifndef PWM_SERVO_H_
#define PWM_SERVO_H_

//Servo limit 1
#define SERVO_MIN  9   // OCR0A for 0° (1ms of pulse)
#define SERVO_MAX  36   // OCR0A for 180° (2ms of pulse)

void initPWM();
void initADC();


#endif /* PWM_SERVO_H_ */