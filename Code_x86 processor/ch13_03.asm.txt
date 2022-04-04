TITLE Chapter 13 Exercise 3                  (ch13_03.asm)

Comment !
Description: Write a program that displays the current date
and prompts the user for a new date. If a nonblank date is
entered, use it to update the system date.

Implementation note: This program requires very little time
to complete because it builds on the DateTime.asm program
shown in Section 13.2.4.1.

Difficulty level: 2/5
Last update: 05/14/2002
!
INCLUDE Irvine16.inc

Write PROTO char:BYTE

.data
; Use signed variables, in case the user decides
; to enter negative values for month/day/year.
month SBYTE ?
day   SBYTE ?
year  SWORD ?

str1 BYTE "The current date is: ",0
str2 BYTE "Enter new month: ",0
str3 BYTE "Enter new day:   ",0
str4 BYTE "Enter new year:  ",0
str5 BYTE "Date out of range. No action taken",0dh,0ah,0

.code
main PROC
	mov  ax,@data
	mov  ds,ax
	call DisplayDate
	call Crlf

; Prompt the user for a new date
	mov  dx,OFFSET str2	; input month
	call WriteString
	call ReadInt
	mov  month,al
	call Crlf

	mov  dx,OFFSET str3	; input day
	call WriteString
	call ReadInt
	mov  day,al
	call Crlf

	mov  dx,OFFSET str4	; input year
	call WriteString
	call ReadInt
	mov  year,ax
	call Crlf

	; Following will be a signed comparison:
	.IF (month < 1) || (day < 1) || (year < 1)
	  mov  dx,OFFSET str5	; date out of range
	  call WriteString
	  jmp Exit_prog
	.ENDIF

; Set the new system date (requires Power User
; access under Windows NT/2000/XP
	mov  ah,2Bh	; set date
	mov  dh,month
	mov  dl,day
	mov  cx,year
	int  21h
	call Crlf
	call DisplayDate

Exit_prog:
	call Crlf
	exit
main ENDP

;--------------------------------------------
DisplayDate PROC
;
; Display the system date.
; Recevies: nothing
; Returns:  nothing
;--------------------------------------------
	pushad

	mov   dx,OFFSET str1
	call  WriteString
	mov   ah,2Ah	; get system date
	int   21h
	movzx eax,dh	; month
	call  WriteDec
	INVOKE Write,'-'
	movzx eax,dl	; day
	call  WriteDec
	INVOKE Write,'-'
	movzx eax,cx	; year
	call  WriteDec
	call  Crlf

	popad
	ret
DisplayDate ENDP


;---------------------------------------------
Write PROC char:BYTE
; Display a single character.
;---------------------------------------------
	push eax
	push edx
	mov  ah,2
	mov  dl,char
	int  21h
	pop  edx
	pop  eax
	ret
Write ENDP

;---------------------------------------------
WritePaddedDec PROC
; Display unsigned integer in EAX, padding
; to two digit positions with a leading zero.
;---------------------------------------------
	.IF eax < 10
	   push eax
	   push edx
	   mov  ah,2
	   mov  dl,'0'
	   int  21h
	   pop  edx
	   pop  eax
	.ENDIF

	call WriteDec
	ret
WritePaddedDec ENDP

END main