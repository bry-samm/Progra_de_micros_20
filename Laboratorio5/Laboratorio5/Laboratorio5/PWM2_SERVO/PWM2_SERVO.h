/*
 * PWM2_SERVO.h
 *
 * Created: 7/04/2025 16:45:11
 *  Author: bsmor
 */ 


#ifndef PWM2_SERVO_H_
#define PWM2_SERVO_H_

//Servo limit 2
#define SERVO_MIN_2  9   // OCR0A for 0° (1ms of pulse)
#define SERVO_MAX_2  36

void initPWM2();

#endif /* PWM2_SERVO_H_ */