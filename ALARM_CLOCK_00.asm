ORG 00H
	
	MOV SP, #70H ; initiation in stack pointer
	MOV PSW, #00H ; initiation in 0 reg bank 0
	
	ALAR EQU 67H
	STOPWH EQU 68H ; for stopwatch hour for calculation
	STOR_S EQU 69H ; store stopwatch second
 	STOR_M EQU 6AH ; store stopwatch minute
	STOR_H EQU 6BH ; store stopwatch hour
	
	;FOR CLOCK
	MOV R0, 0H ; to go from 0 to 14 and make reset
	MOV R1, 0H ; from one to 60 seconds
	MOV R2, 0H ; From one to 60 minutes
	MOV R3, 0H ; from one to 24 hours 
	
	;FOR ALARM
	MOV R4, 0H ; for minute input for alarm
	MOV R5, 0H ; for hour input for alarm
	
	;FOR STOPWATCH suppose a pin calls then it runs the loop like P3.1 gets low for example
	MOV R6, 0H ; for stopwatch second
	MOV R7, 0H ; for stopwatch minute
	MOV STOPWH, #0H ; for stopwatch hour
	
	CLR A; first time clear A
	 
;----------------------------MANUAL CLOCK-----------------------------;---------------------CLOCK (1ST PART)
START:
	MOV TMOD, #00000001 ; Timer 0 as timer 
	MOV TCON, #00H 
	INC R0 ; increment R0 upto 14 then reset to 0 ... 16bit*14 times= 1 second
ONE_SEC_DIV14:
	MOV TL0, #00H ; 16 bit timer low byte to 0
	MOV TH0, #00H ; 16 bit timer high byte to 0
	SETB TR0; Start timer
INTO_14:
	JNB TF0,INTO_14 ; if timer flag 0 go to into_14 again
	CLR TF0 ; timer flag clear
	CLR TR0 ; timer off
	
	CJNE R0,#0EH, ONE_SEC_DIV14   ;  if 1 second take down
	MOV R0, 0H ; clear timer
	INC R1 ; one second increase
	
	;ALARM CONDITION CHECK;----------------------------------------------------------------ALARM
	MOV A, ALAR
	CJNE A,01H, HERE ; if alar is 01h then alarm is on
	
	MOV A, R4
	CJNE A, 02H, HERE ;minute matches
	
	MOV A, R5
	CJNE A, 03H, HERE ;hour matches
	
	SETB P3.1 ; alarm on (connect alarm to P3.1)
	
	;ALARM TURNING OFF;--------------------------------------------------
	MOV A, ALAR
	CJNE A,00H , HERE ; 
	CLR P3.1 ; alarm stopped

HERE:	
	;STOPWATCH CONDITION CHECK----------------------------------------------------------STOPWATCH
	JNB P3.1, ST_ON ; if bit high reset all variables of stopwatch
	;------------------------store--------------------------------------
	MOV STOR_S , R6 ; store stopwatch second
	MOV STOR_M , R7 ; store stopwatch minute
	MOV STOR_H , STOPWH ; store stopwatch hour
	;-----------------------clear---------------------------------------
	MOV R6, 0H ; clear stopwatch second 
	MOV R7, 0H ; clear stopwatch minute
	CLR STOPWH ; clear stopwatch hour
	  
ST_ON:	JB P3.1 , HERE1 ; if pin gets low stopwatch stars 
	;R6 R7 STOPWH
	INC R6 ;one second increase when clock inreases one second ------------ STOPWATCH SECOND COUNT
	
	MOV A, R6 ;-----------------STOPWATCH MINUTE CHECK------------------
	CJNE A,#3CH,HERE ; whether stopwatch reaches 60 seconds
	INC R7; increase minute of stopwatch by one-----------------------------STOPWATCH MINUTE COUNT
	MOV R6, 0H; clear stopwatch second to 0
	
HERE1:	MOV A, R1;-------------------------------------------------------------------------CLOCK (REST PART)
	CJNE A,#3CH, ONE_SEC_DIV14  ; if 60 seconds take down (clock)
	MOV R1, 0H
	INC R2 ; one minute increase
	
	
	MOV A , R7;----------------STOPWATCH HOUR CHECK--------------------
	CJNE A,#3CH,GO ; check stopwatch minute if reaches 60
	INC STOPWH ; incease stopwatch hour by one----------------------------STOPWATCH HOUR COUNT
	MOV R7, 0H; clear stopwatch minute to 0
	
	
GO:	MOV A, R2 ;-------------------------------------------------------
	CJNE A,#3CH, ONE_SEC_DIV14  ;  if 60 minutes take down (clock)
	
	MOV R2, 0H
	INC R3 ; one hour increases
	
	MOV A, R3;-------------------------------------------------------
	CJNE A, #18H, ONE_SEC_DIV14 ; if 24 hours take down (clock)
	
	MOV R3, 0H 
	LJMP ONE_SEC_DIV14
	
END
	
	
	
	

	