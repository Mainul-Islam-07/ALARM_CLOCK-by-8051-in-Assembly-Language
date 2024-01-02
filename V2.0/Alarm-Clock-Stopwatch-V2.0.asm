		ORG 00H            ; Origin set to 00H (start of code memory)
		LJMP MAIN
		ORG 0BH
		
                    	
MAIN:		MOV SP, #70H       ; Move stack pointer to 70H 
		MOV PSW, #00H      ; Initialize Program Status Word

		RS EQU P3.4        ; Define RS as the pin connected to P3.4
		RW EQU P3.5        ; Define RW as the pin connected to P3.5
		ENBL EQU P3.6      ; Define ENBL as the pin connected to P3.6

		MOV DPTR, #KCODE0  ; Set Data Pointer to the address of the starting of the lookup table
	
		BUZZ EQU P3.0      ; Define BUZZ as the pin connected to P3.0 (buzzer)
		SETB BUZZ           ; Set BUZZ pin (buzzer) to active low
		DISP EQU P0        ; Define DISP as the port for display
		DISP7 EQU P0.7     ; Define DISP7 as the pin connected to P0.7 (display busy checker D7)

		; CLOCK STARTING VALUES IN BANK-0 R1 to R7
		AMPM EQU R1        ; Define AMPM as Register R1
		CR0 EQU R2         ; Define CR0 as Register R2 (msb of hour)
		CR1 EQU R3         ; Define CR1 as Register R3 (lsb of hour)
		CR2 EQU R4         ; Define CR2 as Register R4 (msb of minute)
		CR3 EQU R5         ; Define CR3 as Register R5 (lsb of minute)
		CR4 EQU R6         ; Define CR4 as Register R6 (msb of second)
		CR5 EQU R7         ; Define CR5 as Register R7 (lsb of second)
		
		MOV 11H, #3        ; Initialize Register 11H with the number of snooze

		ALRM_DUR EQU 10    ; Define ALRM_DUR as the address for storing alarm duration (10th location in memory)
		
		AD EQU 15          ; Define AD as Register 15

		MOV ALRM_DUR, #AD  ; Store the value of Register AD in ALRM_DUR (seconds of alarm ring)
;;;;;;;;;;;;;;;;DISPLAY INITIALIZATION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		MOV A, #38H        ; Move the value 38H to accumulator A (Initialize display - 2 lines, 5x7 matrix)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

		MOV A, #0EH        ; Move the value 0EH to accumulator A (Display on, cursor on, blinking cursor off)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

		MOV A, #01         ; Move the value 01 to accumulator A (Clear display)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

		MOV A, #06H        ; Move the value 06H to accumulator A (Increment cursor, no display shift)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

		MOV A, #0CH        ; Move the value 0CH to accumulator A (Display on, cursor off, blinking cursor off)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
;;;;;;;;;;;;;;ADD ALARM?;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This part asks if we want to set an alarm or not.
; If we do, we have to take the alarm time as input.
; If not, the clock will act as a basic digital clock.
MODE:
		MOV A, #1H        ; Move the value 1H to accumulator A (Clearing the screen)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		
		MOV A, #80H       ; Move the value 80H to accumulator A (Set cursor at the beginning of the first line)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		MOV DPTR, #LRM    ; Set Data Pointer to the address of the message for setting the alarm
		LCALL PROMPT      ; Call subroutine PROMPT to display the message on the LCD
		
		MOV A, #0C0H      ; Move the value 0C0H to accumulator A (Move cursor to the beginning of the second line)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		MOV DPTR, #OPTION ; Set Data Pointer to the address of the options (Yes/No)
		LCALL PROMPT      ; Call subroutine PROMPT to display the options on the LCD
		
		LCALL KEYPAD      ; Call subroutine KEYPAD to get user input
		MOV R0, B         ; Move the user input to Register R0
		MOV A, #1         ; Move the value 1 to accumulator A
		XRL A, R0         ; XOR A with R0 to check if the input is 1
		JZ ER1            ; Jump to YEP if the input is 1 (user wants to set an alarm)
		MOV A, #2         ; Move the value 2 to accumulator A
		XRL A, R0         ; XOR A with R0 to check if the input is 2
		JZ STOPWATCH
		
		MOV A, #3         ; Move the value 3 to accumulator A
		XRL A, R0         ; XOR A with R0 to check if the input is 2
		JZ Timer
		MOV 30H, #0       ; Store invalid values in the alarm locations
		MOV 31H, #0       ; This prevents false alarms by making the alarm values different from the clock values
		MOV 32H, #0
		MOV 33H, #0
		MOV 34H, #0
		MOV 35H, #0
		MOV 36H, #0
		
		MOV 40H, #0       ; Backup memory locations for the alarm
		MOV 41H, #0
		MOV 42H, #0
		MOV 43H, #0
		MOV 44H, #0
		MOV 45H, #0
		MOV 46H, #0
		
		
		JZ SHAMNE         ; Jump to SHAMNE if A is 0 (user selected No, move to clock counter)
STOPWATCH: 	LJMP Stopwatch1
TIMER:  	LJMP TM1
SHAMNE:	LJMP AROSHAMNE     ; Jump to AROSHAMNE (address was out of range for JZ)
;;;;;;;;;;;;;;;;;;;;;;;;COLON;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This part clears the screen and adds two colons for separating hr, min, and sec

ER1:		MOV A, #1H         ; Move the value 1H to accumulator A (Clearing the screen)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to clear the LCD screen
		LCALL DELAY        ; Call subroutine DELAY for a delay

		MOV DPTR, #KCODE0  ; Set Data Pointer to the address of the starting of the lookup table
		LCALL ADDCOLON     ; Call subroutine ADDCOLON to add colons to the display
;;;;;;;;;;;;;;;START TIME SELECTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Set the display to start time selection mode

		MOV A, #80H        ; Move the value 80H to accumulator A (Set cursor at the beginning of the first line)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

		MOV DPTR, #STARTTIME ; Set Data Pointer to the address of the prompt
		LCALL PROMPT       ; Call subroutine PROMPT to display the prompt on the LCD

		MOV A, #0C0H       ; Move the value 0C0H to accumulator A (Move cursor to the beginning of the second line)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

CLKHM:		LCALL KEYPAD       ; Call subroutine KEYPAD to input hours (MSB)
		CLR C
		MOV A, B
		CJNE A, #2, CHECKHM ; Check for invalid input
CHECKHM:	JC CHU_1            ; Jump if input is smaller than 2 (valid input)
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKHM          ; Go back to taking this input again
CHU_1:		MOV CR5, B         ; Store hours MSB

CLKHL:		LCALL KEYPAD       ; Call subroutine KEYPAD to input hours (LSB)
		MOV A, CR5
		CJNE A, #1, CHU2    ; Check for invalid input
		CLR C
		MOV A, B
		CJNE A, #3, CHECKHL ; Check for invalid input
CHECKHL:	JC CHU2_2           ; Jump if input is smaller than 3 (valid input)
AGHLLLL:	MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKHL          ; Go back to taking this input again
CHU2:		MOV A, B
		CJNE A, #10, YY     ; Check if input is 10
		SJMP AGHLLLL        ; Jump to AGHLLLL if input is not 10
YY:		JNC AGHLLLL        ; Jump to AGHLLLL if no carry (input is less than 10)
		XRL A, #0
		JZ AGHLLLL          ; Jump to AGHLLLL if A is zero
CHU2_2:		MOV CR4, B         ; Store hours LSB

		MOV A, #0C3H       ; Move the value 0C3H to accumulator A (Move cursor to the beginning of the third line)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

CLKMM:		LCALL KEYPAD       ; Call subroutine KEYPAD to input minutes (MSB)
		CLR C
		MOV A, B
		CJNE A, #6, CHECKMM ; Check for invalid input
CHECKMM:	JC CHU3              ; Jump if input is smaller than 6 (valid input)
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKMM          ; Go back to taking this input again
CHU3:		MOV CR3, B         ; Store minutes MSB

CLKML:		LCALL KEYPAD       ; Call subroutine KEYPAD to input minutes (LSB)
		MOV A, B
		CJNE A, #10, YY1    ; Check for invalid input
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKML          ; Go back to taking this input again
YY1:		JNC CLKML          ; Jump to CLKML if no carry (input is less than 10)
		MOV CR2, B         ; Store minutes LSB

		MOV A, #0C6H       ; Move the value 0C6H to accumulator A (Move cursor to the beginning of the sixth line)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay

CLKSM:		LCALL KEYPAD       ; Call subroutine KEYPAD to input seconds (MSB)
		CLR C
		MOV A, B
		CJNE A, #6D, CHECKSM ; Check for invalid input
CHECKSM:	JC CHU4              ; Jump if input is smaller than 6D (valid input)
AGHSSS:		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKSM          ; Go back to taking this input again
CHU4:		MOV CR1, B         ; Store seconds MSB

CLKSL:		LCALL KEYPAD       ; Call subroutine KEYPAD to input seconds (LSB)
		MOV A, B
		CJNE A, #10, YY3    ; Check for invalid input
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKSL          ; Go back to taking this input again
YY3:		JNC CLKSL          ; Jump to CLKSL if no carry (input is less than 10)
		MOV CR0, B         ; Store seconds LSB

CLKAP:		LCALL KEYPAD       ; Call subroutine KEYPAD to input AM/PM
		MOV A, B
		CJNE A, #10, APGAIN ; Check if input is 10
		SJMP OIJE           ; Jump to OIJE if input is not 10
APGAIN:		CJNE A, #11, AMAGAIN ; Check if input is 11
		SJMP OIJE           ; Jump to OIJE if input is not 11
AMAGAIN:	MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP CLKAP          ; Go back to taking this input again
OIJE:		MOV AMPM, B        ; Store AM/PM value

		MOV DPTR, #M_ADRS   ; Set Data Pointer to the address for showing 'M' for AM/PM
		MOV A, #0
		LCALL SHOW         ; Call subroutine SHOW to display 'M' for AM/PM

X:		LCALL KEYPAD       ; Call subroutine KEYPAD to check for ERASE or ENTER
		MOV A, #0DH
		CJNE A, B, XX       ; Check if ERASE is pressed, if yes, take input again
		LJMP ER1            ; Jump to ER1 to restart the input process
XX:		MOV A, #0CH         ; Move the value 0CH to accumulator A (Check if ENTER is pressed)
		CJNE A, B, X        ; Check if ENTER is pressed, if not, check again for ERASE/ENTER press
			                ; If ENTER is pressed, move forward
;
;;;;;;;;;;;;;;;ALARM TIME SELECTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Alarm values are stored in 30h-36h and 40h-46h backup

YEP:		MOV A, #1H        ; Move the value 1H to accumulator A (Clearing the screen)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		
		MOV DPTR, #KCODE0  ; Set Data Pointer to the address of the lookup table for adding colons
		LCALL ADDCOLON     ; Call subroutine ADDCOLON to add colons to the display
		
		MOV A, #80H       ; Move the value 80H to accumulator A (Set cursor at the beginning of the first line)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		MOV DPTR, #ALARMTIME ; Set Data Pointer to the address of the message for setting the alarm
		LCALL PROMPT      ; Call subroutine PROMPT to display the message on the LCD
		
		MOV A, #0C0H      ; Move the value 0C0H to accumulator A (Move cursor to the beginning of the second line)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		
AHM:		LCALL KEYPAD      ; Call subroutine KEYPAD to input alarm hours (MSB)
		CLR C
		MOV A, B
		CJNE A, #2, CHECKHM1 ; Check for invalid input
CHECKHM1:	JC CHU_11            ; Jump if input is smaller than 2 (valid input)
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP AHM            ; Go back to taking this input again
CHU_11:		MOV 30H, B         ; Store alarm hours MSB
		MOV 40H, B
		
AHL:		LCALL KEYPAD      ; Call subroutine KEYPAD to input alarm hours (LSB)
		MOV A, 30H
		CJNE A, #1, CHU22 ; Check for invalid input
		CLR C
		MOV A, B
		CJNE A, #3, CHECKHL1 ; Check for invalid input
CHECKHL1:	JC CHU22_2
AHLLL222:	MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP AHL
CHU22:		MOV A, B
		CJNE A, #10, YY4   ; Check for invalid input
		SJMP AHLLL222
YY4:		JNC AHLLL222
		XRL A, #0
		JZ AHLLL222
CHU22_2:	MOV 31H, B
		MOV 41H, B

	MOV A, #0C3H          ; Move the value 0C3H to accumulator A (Move cursor to the beginning of the third line)
		LCALL COMMAND       ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY         ; Call subroutine DELAY for a delay

AMM:		LCALL KEYPAD      ; Call subroutine KEYPAD to input alarm minutes (MSB)
		CLR C
		MOV A, B
		CJNE A, #6, CHECKMM1 ; Check for invalid input
CHECKMM1:	JC CHU33             ; Jump if input is smaller than 6 (valid input)
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP AMM             ; Go back to taking this input again
CHU33:		MOV 32H, B          ; Store alarm minutes MSB
		MOV 42H, B

AML:		LCALL KEYPAD      ; Call subroutine KEYPAD to input alarm minutes (LSB)
		MOV A, B
		CJNE A, #10, YY6   ; Check for invalid input
AMMM:		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP AML            ; Go back to taking this input again
YY6:		JNC AMMM
		MOV 33H, B          ; Store alarm minutes LSB
		MOV 43H, B

	MOV A, #0C6H          ; Move the value 0C6H to accumulator A (Move cursor to the beginning of the sixth line)
		LCALL COMMAND       ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY         ; Call subroutine DELAY for a delay

ASM:		LCALL KEYPAD      ; Call subroutine KEYPAD to input alarm seconds (MSB)
		CLR C
		MOV A, B
		CJNE A, #6D, CHECKSM1 ; Check for invalid input
CHECKSM1:	JC CHU44             ; Jump if input is smaller than 6D (valid input)
		MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP ASM             ; Go back to taking this input again
CHU44:		MOV 34H, B          ; Store alarm seconds MSB
		MOV 44H, B

ASL:		LCALL KEYPAD      ; Call subroutine KEYPAD to input alarm seconds (LSB)
		MOV A, B
		CJNE A, #10, YY7   ; Check for invalid input
ASLLA:	MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP ASL            ; Go back to taking this input again
YY7:		JNC ASLLA
		MOV 35H, B          ; Store alarm seconds LSB
		MOV 45H, B

AAP:		LCALL KEYPAD      ; Call subroutine KEYPAD to input AM/PM for alarm
		MOV A, B
		CJNE A, #10, APGAIN1 ; Check for invalid input
		SJMP OIJE1
APGAIN1:	CJNE A, #11, AMAGAIN1 ; Check for invalid input
		SJMP OIJE1
AMAGAIN1:	MOV A, #10H
		LCALL COMMAND
		LCALL DELAY
		SJMP AAP            ; Go back to taking this input again
OIJE1:	MOV 36H, B          ; Store AM/PM for alarm
		MOV 46H, B
		MOV DPTR, #M_ADRS   ; Set Data Pointer to the address for displaying 'M' (AM/PM)
		MOV A, #0
		LCALL SHOW          ; Call subroutine SHOW to display 'M' on the LCD

X2:		LCALL KEYPAD      ; Call subroutine KEYPAD to check if ERASE/ENTER is pressed
		MOV A, #0DH
		CJNE A, B, XX2      ; Check if ERASE is pressed, if yes, go back to the alarm input section
		LJMP YEP            ; Jump to YEP if ENTER is pressed (proceed to clock counter)
XX2:	MOV A, #0CH          ; Move the value 0CH to accumulator A (Check if ENTER is pressed)
		CJNE A, B, X2       ; Check if ENTER is pressed, if not, check again for ERASE/ENTER press
		                   ; If ENTER is pressed, go back to taking input again
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AROSHAMNE:	MOV A, #1H         ; Move the value 1H to accumulator A (Clearing the screen)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		MOV DPTR, #KCODE0 ; Set Data Pointer to the address of the lookup table for adding colons
		LCALL ADDCOLON    ; Call subroutine ADDCOLON to add colons to the display
		
		MOV A, #80H        ; Move the value 80H to accumulator A (Set cursor at the beginning of the first line)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		
		MOV A, #0          ; Move the value 0 to accumulator A
		MOV DPTR, #DIGI    ; Set Data Pointer to the address of the message for displaying digits
		LCALL PROMPT      ; Call subroutine PROMPT to display digits on the LCD
		
		MOV DPTR, #KCODE0  ; Set Data Pointer to the address of the lookup table for adding colons
		
		MOV A, #0C9H       ; Move the value 0C9H to accumulator A (Move cursor to the beginning of the ninth column)
		LCALL COMMAND     ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY       ; Call subroutine DELAY for a delay
		
		MOV DPTR, #M_ADRS  ; Set Data Pointer to the address for displaying 'M' (AM/PM)
		MOV A, #0          ; Move the value 0 to accumulator A
		LCALL SHOW         ; Call subroutine SHOW to display 'M' on the LCD
;;;;;;;;;;;;;;;;STOP and SNOOZE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		SETB P2.3      ; Set bit P2.3 (SNOOZE) - Activate the snooze function
		SETB P2.2      ; Set bit P2.2 (STOP) - Activate the stop function
		CLR P2.7      ; Clear bit P2.7 (OP) - Deactivate another function (OP)
;;;;;;;;;;;;;;;;;;;;TIME SHOWING;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Showing the current time

		MOV DPTR, #KCODE0  ; Set Data Pointer to the address of the lookup table for adding colons
		CLR A               ; Clear accumulator A

AGHM:		MOV A, #0C0H       ; Move the value 0C0H to accumulator A (Don't erase, set cursor to the beginning of the first line)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
		MOV A, CR5          ; Move the value of register CR5 to accumulator A (hour MSB)
		LCALL SHOW         ; Call subroutine SHOW to display the hour MSB

AGHL:		MOV A, #0C1H       ; Move the value 0C1H to accumulator A (Don't erase, set cursor to the next position)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
		MOV A, CR4          ; Move the value of register CR4 to accumulator A (hour LSB)
		LCALL SHOW         ; Call subroutine SHOW to display the hour LSB
	                     ; Colon will be displayed after this position

AGMM:		MOV A, #0C3H       ; Move the value 0C3H to accumulator A (Don't erase, set cursor to the next position)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
		MOV A, CR3          ; Move the value of register CR3 to accumulator A (minute MSB)
		LCALL SHOW         ; Call subroutine SHOW to display the minute MSB

AGML:		MOV A, #0C4H       ; Move the value 0C4H to accumulator A (Don't erase, set cursor to the next position)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
		MOV A, CR2          ; Move the value of register CR2 to accumulator A (minute LSB)
		LCALL SHOW         ; Call subroutine SHOW to display the minute LSB
	                     ; Colon will be displayed after this position

AGSM:		MOV A, #0C6H       ; Move the value 0C6H to accumulator A (Don't erase, set cursor to the next position)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
		MOV A, CR1          ; Move the value of register CR1 to accumulator A (second MSB)
		LCALL SHOW         ; Call subroutine SHOW to display the second MSB

AGSL:		MOV A, #0C7H       ; Move the value 0C7H to accumulator A (Don't erase, set cursor to the next position)
		LCALL COMMAND      ; Call subroutine COMMAND to send the command to the LCD
		LCALL DELAY        ; Call subroutine DELAY for a delay
		MOV A, CR0          ; Move the value of register CR0 to accumulator A (second LSB)
		LCALL SHOW         ; Call subroutine SHOW to display the second LSB

AGAP:		MOV A, AMPM        ; Move the value of AMPM to accumulator A
		LCALL SHOW         ; Call subroutine SHOW to display AM/PM
;;;;;;;;;;;;;;;;;;;;CLOCK OPERATION;;;;;;;;;;;;;;;;;;;;;;;;;;;

		LCALL DELAYG     ; Call subroutine DELAYG for a 1-second delay (optimized for hardware)

CONT:		MOV B,30H        ; Move the value of register 30H to register B (original hour MSB)
		MOV A,CR5         ; Move the value of register CR5 to accumulator A (current hour MSB)
		CJNE A,B, JAH     ; Compare current hour MSB with original hour MSB, jump to JAH if not equal

		MOV B,31H        ; Move the value of register 31H to register B (original hour LSB)
		MOV A,CR4         ; Move the value of register CR4 to accumulator A (current hour LSB)
		CJNE A,B, JAH     ; Compare current hour LSB with original hour LSB, jump to JAH if not equal

		MOV B,32H        ; Move the value of register 32H to register B (original minute MSB)
		MOV A,CR3         ; Move the value of register CR3 to accumulator A (current minute MSB)
		CJNE A,B, JAH     ; Compare current minute MSB with original minute MSB, jump to JAH if not equal

		MOV B,33H        ; Move the value of register 33H to register B (original minute LSB)
		MOV A,CR2         ; Move the value of register CR2 to accumulator A (current minute LSB)
		CJNE A,B, JAH     ; Compare current minute LSB with original minute LSB, jump to JAH if not equal

		MOV B,34H        ; Move the value of register 34H to register B (original second MSB)
		MOV A,CR1         ; Move the value of register CR1 to accumulator A (current second MSB)
		CJNE A,B, JAH     ; Compare current second MSB with original second MSB, jump to JAH if not equal

		MOV B,35H        ; Move the value of register 35H to register B (original second LSB)
		MOV A,CR0         ; Move the value of register CR0 to accumulator A (current second LSB)
		CJNE A,B, JAH     ; Compare current second LSB with original second LSB, jump to JAH if not equal

		MOV B,36H        ; Move the value of register 36H to register B (original AM/PM)
		MOV A,AMPM        ; Move the value of register AMPM to accumulator A (current AM/PM)
		CJNE A,B, JAH     ; Compare current AM/PM with original AM/PM, jump to JAH if not equal

		CLR BUZZ          ; Clear the BUZZ bit

		INC R0            ; Increment register R0

JAH:		JB BUZZ, MOVE     ; Jump to MOVE if the BUZZ bit is set (indicating buzzer activation)
		JNB P2.2, STOPBUZZ ; Jump to STOPBUZZ if the STOP button is pressed (P2.2 is low)

		MOV A, #0H        ; Move the value 0H to accumulator A
		CJNE A, 11H, OKAY ; Compare accumulator A with the value in register 11H, jump to OKAY if not equal
		SJMP STOPBUZZ     ; Jump to STOPBUZZ if accumulator A is not equal to 11H

OKAY:		JB P2.3, LAAF      ; Jump to LAAF if the SNOOZE button is pressed (P2.3 is low)
		LCALL SNOOZE       ; Call subroutine SNOOZE
LAAF:		DJNZ ALRM_DUR, MOVE ; Decrement ALRM_DUR and jump to MOVE if not zero
		LCALL SNOOZE       ; Call subroutine SNOOZE
		SJMP MOVE           ; Jump to MOVE

STOPBUZZ:	SETB BUZZ          ; Set the BUZZ bit

	; When the STOP button is pressed, reset the alarm registers to the original alarm time, erasing snooze times
		MOV 30H, 40H
		MOV 31H, 41H
		MOV 32H, 42H
		MOV 33H, 43H
		MOV 34H, 44H
		MOV 35H, 45H
		MOV 36H, 46H

; Next portion basically does the 6-digit clock counter

MOVE:		CJNE CR0, #9, NEXT  ; Compare CR0 with 9, jump to NEXT if not equal
		CJNE CR1, #5, NEXT2 ; Compare CR1 with 5, jump to NEXT2 if not equal
		CJNE CR2, #9, NEXT3 ; Compare CR2 with 9, jump to NEXT3 if not equal
		CJNE CR3, #5, NEXT4 ; Compare CR3 with 5, jump to NEXT4 if not equal
		CJNE CR5, #1, NEXT5 ; Compare CR5 with 1, jump to NEXT5 if not equal
		CJNE CR4, #1, BOOM   ; Compare CR4 with 1, jump to BOOM if not equal

		MOV A, AMPM          ; Move the value of AMPM to accumulator A
		XRL A, #00000001B   ; XOR accumulator A with binary 00000001
		MOV AMPM, A         ; Move the result back to AMPM

BOOM:		CJNE CR4, #2, NEXTX  ; Compare CR4 with 2, jump to NEXTX if not equal

BHAG:		MOV CR0, #0H        ; Set CR0 to 0 for second LSB
		MOV CR1, #0H        ; Set CR1 to 0 for second MSB
		MOV CR2, #0H        ; Set CR2 to 0 for minute LSB
		MOV CR3, #0H        ; Set CR3 to 0 for minute MSB
		MOV CR4, #1H        ; Set CR4 to 1 for hour LSB
		MOV CR5, #0H        ; Set CR5 to 0 for hour MSB

		LJMP AGHM           ; Jump to AGHM

NEXT:		INC CR0             ; Increment CR0
		LJMP AGSL           ; Jump to AGSL

NEXT2: 		INC CR1             ; Increment CR1
		MOV CR0, #0         ; Set CR0 to 0
		LJMP AGSM           ; Jump to AGSM

NEXT3:		INC CR2             ; Increment CR2
		MOV CR1, #0         ; Set CR1 to 0
		MOV CR0, #0         ; Set CR0 to 0
		LJMP AGML           ; Jump to AGML

NEXT4:		INC CR3             ; Increment CR3
		MOV CR2, #0         ; Set CR2 to 0
		MOV CR1, #0         ; Set CR1 to 0
		MOV CR0, #0         ; Set CR0 to 0
		LJMP AGMM           ; Jump to AGMM

NEXT5:		CJNE CR4, #9, NEXTX ; Compare CR4 with 9, jump to NEXTX if not equal
		INC CR5             ; Increment CR5
		MOV CR4, #0         ; Set CR4 to 0
		MOV CR3, #0         ; Set CR3 to 0
		MOV CR2, #0         ; Set CR2 to 0
		MOV CR1, #0         ; Set CR1 to 0
		MOV CR0, #0         ; Set CR0 to 0

		LJMP AGHM           ; Jump to AGHM

NEXTX:		INC CR4             ; Increment CR4
		MOV CR3, #0         ; Set CR3 to 0
		MOV CR2, #0         ; Set CR2 to 0
		MOV CR1, #0         ; Set CR1 to 0
		MOV CR0, #0         ; Set CR0 to 0

		LJMP AGHL           ; Jump to AGHL
;;;;;;;;;;;;;;;;;;;;;SUB ROUTINES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Set to 10 seconds for code demonstration

	
SNOOZE:	SETB BUZZ        ; Set BUZZ bit to clear buzzer when snooze is pressed
	CLR PSW.3          ; Clear the PSW.3 flag
	MOV A, CR0
	MOV 35H, A
	MOV A, CR1
	MOV 34H, A
	MOV A, CR2
	ADD A, #5
	         ; Move the value of register CR1 to accumulator A
        CJNE A, #9, PERANAI ; Compare accumulator A with 5, jump to PERANAI if not equal
PERANAI: JNC PERA
	 MOV A, CR2         ; Move the value of register CR2 to accumulator A
	 ADD A, #5               ; Increment current time's MSB by 1
	 MOV 33H, A         ; Move the result to register 33H
	 SJMP ACTION 
PERA: MOV A, CR2
      ADD A, #5
      SUBB A, #10D
      MOV 33H, A
      MOV A, 32H
      INC A
      CJNE A,#6, UPDATEMIN
      MOV A,#0
      MOV 32H, A
      
      
      MOV A, 30H
      CJNE A, #1, KOMPERA
      MOV A, 31H
      CJNE A, #1, AGAINNOPERA2
      MOV A, #2
      MOV 31H, A
      MOV A, #1
      MOV 30H, A
      MOV A, 36H          ; Move the value of AMPM to accumulator A
      XRL A, #00000001B   ; XOR accumulator A with binary 00000001
      MOV 36H, A
      SJMP ACTION
      
AGAINNOPERA2: 
               MOV A, 31H
               INC A
               MOV 31H, A
               SJMP ACTION      
      
      
KOMPERA: MOV A, 31H
	 CJNE A, #9, AGAINNOPERA
	 MOV A, #0
	 MOV 31H, A
	 MOV A, 30H
	 INC A
	 MOV 30H, A
	 SJMP ACTION
	 
	 
      
AGAINNOPERA: INC A
           MOV 31H, A
           SJMP ACTION      
      
      
      
      
UPDATEMIN:  
	MOV 32H,A
	SJMP ACTION   		 
	

ACTION:	MOV ALRM_DUR, #AD  ; Set ALRM_DUR to SECONDS OF ALARM RING
	DEC 11H            ; Decrement register 11H
	RET

;;;;;;;;Stopwatch;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
STOPWATCH1:
;;;;;;;;;;;;;;;Start Stopwatch;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set the display to 00:00:00
SETB P1.7
CLR P2.7 ; Clear bit P2.7 (OP) - Deactivate another function (OP)

MOV A, #80H ; Move the value 80H to accumulator A (Set cursor at the beginning of the first line)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, #1H ; Move the value 1H to accumulator A (Clearing the screen)
LCALL COMMAND ; Call subroutine COMMAND to send the command to clear the LCD screen
LCALL DELAY ; Call subroutine DELAY for a delay

MOV DPTR, #KCODE0 ; Set Data Pointer to the address of the starting of the lookup table
LCALL ADDCOLON ; Call subroutine ADDCOLON to add colons to the display

MOV CR5, #0H
MOV CR4, #0H
MOV CR3, #0H
MOV CR2, #0H
MOV CR1, #0H
MOV CR0, #0H

MOV DPTR, #KCODE0 ; Set Data Pointer to the address of the lookup table for adding colons
CLR A ; Clear accumulator A

SWHM:	MOV A, #0C0H ; Move the value 0C0H to accumulator A (Don't erase, set cursor to the beginning of the first line)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, CR5 ; Move the value of register CR5 to accumulator A (hour MSB)
LCALL SHOW ; Call subroutine SHOW to display the hour MSB

SWHL:	MOV A, #0C1H ; Move the value 0C1H to accumulator A (Don't erase, set cursor to the next position)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, CR4 ; Move the value of register CR4 to accumulator A (hour LSB)
LCALL SHOW ; Call subroutine SHOW to display the hour LSB

SWMM:	MOV A, #0C3H ; Move the value 0C3H to accumulator A (Don't erase, set cursor to the next position)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, CR3 ; Move the value of register CR3 to accumulator A (minute MSB)
LCALL SHOW ; Call subroutine SHOW to display the minute MSB

SWML:	MOV A, #0C4H ; Move the value 0C4H to accumulator A (Don't erase, set cursor to the next position)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, CR2 ; Move the value of register CR2 to accumulator A (minute LSB)
LCALL SHOW ; Call subroutine SHOW to display the minute LSB

SWSM:	MOV A, #0C6H ; Move the value 0C6H to accumulator A (Don't erase, set cursor to the next position)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, CR1 ; Move the value of register CR1 to accumulator A (second MSB)
LCALL SHOW ; Call subroutine SHOW to display the second MSB

SWSL:	MOV A, #0C7H ; Move the value 0C7H to accumulator A (Don't erase, set cursor to the next position)
LCALL COMMAND ; Call subroutine COMMAND to send the command to the LCD
LCALL DELAY ; Call subroutine DELAY for a delay
MOV A, CR0 ; Move the value of register CR0 to accumulator A (second LSB)
LCALL SHOW ; Call subroutine SHOW to display the second LSB

;operation
LCALL DELAYG ; Call subroutine DELAYG for a 1-second delay (optimized for hardware)

JNB P1.7, STOP_STOPWATCH ; Jump to STOP_STOPWATCH if button is pressed
SJMP STOP_BUZZ_SW ; Jump to STOP_BUZZ_SW to continue stopwatch operation

STOP_STOPWATCH:
    SETB BUZZ ; Stop the buzzer (you might need to adjust this based on your hardware)
    SJMP STOP_STOPWATCH ; Optional: Use an infinite loop to effectively halt further execution

STOP_BUZZ_SW:
    LJMP STOP_BUZZ_SW ; Continue the stopwatch operation

; ... (existing code)

SNEXT:	INC CR0             ; Increment CR0
	LJMP SWSL           ; Jump to AGSL

SNEXT2: INC CR1             ; Increment CR1
	MOV CR0, #0         ; Set CR0 to 0
	LJMP SWSM           ; Jump to AGSM

SNEXT3:	INC CR2             ; Increment CR2
	MOV CR1, #0         ; Set CR1 to 0
	MOV CR0, #0         ; Set CR0 to 0
	LJMP SWML           ; Jump to AGML

SNEXT4:	INC CR3             ; Increment CR3
	MOV CR2, #0         ; Set CR2 to 0
	MOV CR1, #0         ; Set CR1 to 0
	MOV CR0, #0         ; Set CR0 to 0
	LJMP SWMM           ; Jump to AGMM

SNEXT5:	CJNE CR4, #9, SNEXTX ; Compare CR4 with 9, jump to NEXTX if not equal
	INC CR5             ; Increment CR5
	MOV CR4, #0         ; Set CR4 to 0
	MOV CR3, #0         ; Set CR3 to 0
	MOV CR2, #0         ; Set CR2 to 0
	MOV CR1, #0         ; Set CR1 to 0
	MOV CR0, #0         ; Set CR0 to 0
	LJMP SWHL           ; Jump to AGHM

SNEXTX:	INC CR4             ; Increment CR4
	MOV CR3, #0         ; Set CR3 to 0
	MOV CR2, #0         ; Set CR2 to 0
	MOV CR1, #0         ; Set CR1 to 0
	MOV CR0, #0         ; Set CR0 to 0
	LJMP SWHL           ; Jump to AGHL

STOPBUZZSW2:	LJMP MAIN




		
		
;;;;;;;;Timer;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TM1:
        SJMP $           

; ...............................................................

SHOW:   MOVC A, @A+DPTR   ; Move code byte from code memory to accumulator A
	LCALL DISPLAY      ; Call subroutine DISPLAY to show the value on the LCD
	LCALL DELAY        ; Call subroutine DELAY for a delay
	RET

; ...............................................................

; Modified to keep the number value of input in register B
KEYPAD: SETB PSW.4        ; Set PSW.4 for register bank 1
	SETB P2.0         ; Set P2.0 for keypad column 0
	SETB P2.1         ; Set P2.1 for keypad column 1
	SETB P2.2         ; Set P2.2 for keypad column 2
	SETB P2.3         ; Set P2.3 for keypad column 3

K1: CLR P2.4          ; Clear P2.4 for keypad row 0
	CLR P2.5          ; Clear P2.5 for keypad row 1
	CLR P2.6          ; Clear P2.6 for keypad row 2
	CLR P2.7          ; Clear P2.7 for keypad row 3

	MOV A, P2          ; Read all columns, ensure all keys are open
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, K1 ; Check until all keys are released

K2: ACALL DELAY         ; Call 20ms delay
	MOV A, P2          ; See if any key is pressed
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, OVER ; Key pressed, await closure
	SJMP K2             ; Check if key is pressed

OVER: ACALL DELAY       ; Wait for 20ms debounce time
	MOV A, P2          ; Check key closure
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, OVER1 ; Key pressed, find row
	SJMP K2             ; If none, keep polling

OVER1: CLR P2.4         ; Clear P2.4 for keypad row 0
	SETB P2.5         ; Set P2.5 for keypad row 1
	SETB P2.6         ; Set P2.6 for keypad row 2
	SETB P2.7         ; Set P2.7 for keypad row 3

	MOV A, P2          ; Read all columns
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, ROW_0 ; Key in row 0, find the column

	SETB P2.4         ; Set P2.4 for keypad row 1
	CLR P2.5         ; Clear P2.5 for keypad row 1
	SETB P2.6         ; Set P2.6 for keypad row 2
	SETB P2.7         ; Set P2.7 for keypad row 3

	MOV A, P2          ; Read all columns
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, ROW_1 ; Key in row 1, find the column

	SETB P2.4         ; Set P2.4 for keypad row 2
	SETB P2.5         ; Set P2.5 for keypad row 2
	CLR P2.6         ; Clear P2.6 for keypad row 2
	SETB P2.7         ; Set P2.7 for keypad row 3

	MOV A, P2          ; Read all columns
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, ROW_2 ; Key in row 2, find the column

	SETB P2.4         ; Set P2.4 for keypad row 3
	SETB P2.5         ; Set P2.5 for keypad row 3
	SETB P2.6         ; Set P2.6 for keypad row 3
	CLR P2.7         ; Clear P2.7 for keypad row 3

	MOV A, P2          ; Read all columns
	ANL A, #00001111B  ; Mask unused bits
	CJNE A, #00001111B, ROW_3 ; Key in row 3, find the column

	LJMP K2             ; If none, false input, repeat

ROW_0: MOV DPTR, #KCODE0 ; Set DPTR=start of row 0
	MOV R7, #0
	SJMP FIND          ; Find column key belongs to

ROW_1: MOV DPTR, #KCODE1 ; Set DPTR=start of row 1
	MOV R7, #4
	SJMP FIND          ; Find column key belongs to

ROW_2: MOV DPTR, #KCODE2 ; Set DPTR=start of row 2
	MOV R7, #8
	SJMP FIND          ; Find column key belongs to

ROW_3: MOV DPTR, #KCODE3 ; Set DPTR=start of row 3
	MOV R7, #0CH
FIND: RRC A               ; See if any CY bit is low
	JNC MATCH           ; If zero, get the ASCII code
	INC R7
	INC DPTR            ; Point to the next column address
	SJMP FIND           ; Keep searching

MATCH: CLR A             ; Set A=0 (match found)
	MOVC A, @A+DPTR     ; Get ASCII code from table
	ACALL DISPLAY       ; Call display subroutine
	ACALL DELAY         ; Give LCD some time
	MOV B, R7
	CLR PSW.4
	RET
; ........................................................................................
; For showing message prompts
PROMPT: CLR A
        MOVC A, @A+DPTR   ; Move the content of the address pointed by A+DPTR to A
        JZ NEXT1           ; Jump to FINISH if the content of A=0, end of string
        LCALL DISPLAY      ; Display subroutine
        LCALL DELAY        ; Delay
        INC DPTR           ; Increase DPTR to show the next character
        LJMP PROMPT        ; Repeat
NEXT1: RET

; ..........................................................................................
COMMAND: LCALL READY        ; Call subroutine READY
        MOV DISP, A        ; Move A to DISP
        CLR RS             ; Clear RS
        CLR RW             ; Clear RW
        SETB ENBL          ; Set ENBL
        LCALL DELAY        ; Delay
        CLR ENBL           ; Clear ENBL
        RET

; ...........................................................................................
DISPLAY: LCALL READY        ; Call subroutine READY
         MOV DISP, A       ; Move A to DISP
         SETB RS           ; Set RS
         CLR RW            ; Clear RW
         SETB ENBL         ; Set ENBL
         LCALL DELAY       ; Delay
         CLR ENBL          ; Clear ENBL
         RET

; ..........................................................................................
READY: SETB DISP7          ; Set DISP7
       CLR RS             ; Clear RS
       SETB RW            ; Set RW

WAIT: CLR ENBL             ; Clear ENBL
      ACALL DELAY         ; Call DELAY subroutine
      SETB ENBL           ; Set ENBL
      JB DISP7, WAIT      ; Jump to WAIT if DISP7 is set
      RET

; ............................................................................................
DELAY: SETB PSW.3          ; Set PSW.3
       MOV R3, #25        ; Set R3 to 25
AGAIN_2: MOV R4, #25        ; Set R4 to 25
AGAIN: DJNZ R4, AGAIN      ; Decrement R4, repeat until it becomes 0
       DJNZ R3, AGAIN_2    ; Decrement R3, repeat until it becomes 0
       CLR PSW.3          ; Clear PSW.3
       RET

; This is the one-second delay
DELAYG: MOV R0, #20         ; Set loop count to 20
        MOV TMOD, #00000001B ; Set timer mode
loop: CLR TR0               ; Start each loop with the timer stopped
      CLR TF0               ; Clear the overflow flag
      MOV TH0, #4Fh         ; Set timer 0 to overflow in 50 ms
      MOV TL0, #00h         ; Set timer 0 low byte
      SETB TR0              ; Start the timer
      JNB TF0, $            ; Wait for overflow
      DJNZ R0, loop         ; Repeat until the loop count is exhausted
       RET

; Delay for keypad
DELAYK: SETB PSW.3          ; Set PSW.3
        MOV R3, #50         ; Set R3 to 50 or higher for fast CPUs
HERE2:  MOV R4, #255        ; Set R4 to 255
HERE:   DJNZ R4, HERE       ; Stay until R4 becomes 0
        DJNZ R3, HERE2      ; Repeat until R3 becomes 0
        CLR PSW.3          ; Clear PSW.3
        RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Adds colon for separation of hr, min, and sec
ADDCOLON: MOV A, #0C2H      ; Move constant 0C2H to A
          LCALL COMMAND    ; Call COMMAND subroutine
          LCALL DELAY      ; Delay
          MOV A, #16D       ; Move constant 16D to A
          MOVC A, @A+DPTR   ; Move the content of the address pointed by A+DPTR to A
          LCALL DISPLAY    ; Call DISPLAY subroutine
          LCALL DELAY      ; Delay
          MOV A, #0C5H      ; Move constant 0C5H to A
          LCALL COMMAND    ; Call COMMAND subroutine
          LCALL DELAY      ; Delay
          MOV A, #16D       ; Move constant 16D to A
          MOVC A, @A+DPTR   ; Move the content of the address pointed by A+DPTR to A
          LCALL DISPLAY    ; Call DISPLAY subroutine
          LCALL DELAY      ; Delay
          RET

; ******************************************************************************
; Lookup table
KCODE0: DB "0"
        DB "1"
        DB "2"
        DB "3"
KCODE1: DB "4"
        DB "5"
        DB "6"
        DB "7"
KCODE2: DB "8"
        DB "9"
        DB "A"
        DB "P"
KCODE3: DB "."
        DB "Y"
        DB "E"
        DB "F"
; ----------------
        DB ":"
M_ADRS: DB "M"
STARTTIME: DB "ENTER START TIME:", 0
ALARMTIME: DB "SET ALARM TIME:", 0
LRM: DB "Select MODE?", 0
OPTION: DB "1.A 2.S 3.T", 0
DIGI: DB "Digital Clock", 0
END
