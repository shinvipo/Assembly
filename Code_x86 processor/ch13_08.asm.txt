TITLE Chapter 13 Exercise 8                  (ch13_08.asm)

Comment !
Description: Write a program that counts the words in a text
file. Prompt the user for a file name, and display the word
count on the screen. The only procedure you may call from the
book's link library is WriteDec. All other input/output must
be performed using INT 21h.

Implementation notes:
 By convention, words are delimited by white space (space,
tab, end-of-line) characters.
 A finite-state machine is the ideal design tool for this
type of problem, because it handles repeated characters
and transitions between states.
 We borrowed all the file-handling code from the
Exercise 7 solution program.

Difficulty level: 3/5 (if code is borrowed from the Exercise 7 solution)
Last update: 05/14/2002
!
INCLUDE Irvine16.inc

ReadLine PROTO,
	bufPtr:PTR BYTE

ShowMessage PROTO,
	pString:PTR BYTE

BUFFER_SIZE = 10000

.data
inputFile  BYTE 60 DUP(0)
inHandle  WORD ?
wordCount DWORD ?
buffer    BYTE BUFFER_SIZE DUP(?)
bytesRead WORD ?
str1 BYTE "Counting the words in a text file",0dh,0ah,0dh,0ah
     BYTE "Enter the name of the input file: $"
str2 BYTE "Final word count: $"
str5 BYTE "Error: Cannot open input file.",0dh,0ah,"$"

.code
main PROC
	mov ax,@data
	mov ds,ax

; Try to open the input file
	call Open_Input_File
	.IF Carry?
	  INVOKE ShowMessage,ADDR str5
	  jmp Exit_prog
	.ENDIF

	call Read_File	; read file into buffer

; Count the words in the buffer
	mov wordCount,0
	mov si,0
; Use a finite-state machine to look for spaces and
; non-spaces in the input stream.

State_A:
	inc si
	.IF si == bytesRead	; end of file?
	  inc wordCount	; count current word
	  jmp Show_Count	; and exit
	.ENDIF
	mov al,buffer[si]	; get next byte
	cmp al,' '	; blank?
	je  State_B	; yes: goto state B
	cmp al,9	; tab character?
	je  State_B	; yes: goto state B
	cmp al,0Ah	; line feed? (end of line char)
	je  State_B	; yes: goto state B
	jmp State_A	; no: stay in this state

State_B:
	inc wordCount
State_B2:
	inc si
	.IF si == bytesRead
	  jmp Show_Count
	.ENDIF
	mov al,buffer[si]	; get next byte
	cmp al,' '	; blank?
	je  State_B2	; yes: stay in State B
	cmp al,0Dh	; carriage return?
	je  State_B2	; yes: stay in state B
	cmp al,0Ah	; line feed?
	je  State_B2	; yes: stay in state B
	cmp al,9	; tab character?
	je  State_B2	; yes: stay in state B
	jmp State_A	; otherwise, goto State A

Show_Count:
	INVOKE ShowMessage,ADDR str2
	mov  eax,wordCount
	call WriteDec
	call EndLine

Close_File:
	mov  ah,3Eh    	; function: close file
	mov  bx,inHandle	; input file handle
	int  21h       	; call MS-DOS

Exit_prog:
	exit
main ENDP

;--------------------------------------------------
Open_Input_File PROC
;
; Ask user for name of the input file and attempt
; to open the file.
; Receives: nothing
; Returns: CF=1 if the file could not be opened
;--------------------------------------------------
	pusha

; Ask user for name of input file
	INVOKE ShowMessage, ADDR str1
	INVOKE ReadLine,ADDR inputFile

; Attempt to open the input file
	mov ax,716Ch   	; extended create or open
	mov bx,0      	; mode = read-only
	mov cx,0	; normal attribute
	mov dx,1	; action: open
	mov si,OFFSET inputFile	; filename
	int 21h       	; call MS-DOS
	mov inHandle,ax	; save handle

	popa
	ret
Open_Input_File ENDP

;-----------------------------------------------------
Read_File PROC
;
; Read the input file into a buffer.
; Receives: nothing
; Returns: CF=1 if the buffer could not be read
;-----------------------------------------------------
	pusha

	mov  ah,3Fh	; read file or device
	mov  bx,inHandle	; file handle
	mov  cx,BUFFER_SIZE	; max bytes to read
	mov  dx,OFFSET buffer	; buffer pointer
	int  21h
	.IF Carry?
	  mov  bytesRead,0
	  jc   Exit_proc	; quit if error
	.ELSE
	  mov  bytesRead,ax
	.ENDIF

Exit_proc:
	popa
	ret
Read_File ENDP

;---------------------------------------------
EndLine PROC uses ax dx
;
; Display an end of line sequence
; Receives: nothing
; Returns:  nothing
;---------------------------------------------
.data
eolnStr BYTE 0dh,0ah,'$'
.code
	mov ah,9
	mov dx,OFFSET eolnStr
	int 21h

	ret
EndLine ENDP

;--------------------------------------------------------
ReadLine PROC uses ax si,
	bufPtr:PTR BYTE
;
; Reads a line of text from standard input until the
;   0Dh character is found. Inserts a null terminator
;   byte at the end of the string.
; Receives: pointer to input buffer
; Returns: nothing
;--------------------------------------------------------
	mov  si,bufPtr		; point to input buffer

L1:	mov  ah,1		; function: keyboard input
	int  21h		; AL = character
	cmp  al,0Dh		; end of line?
	je   Exit_proc		; yes: exit
	mov  [si],al		; no: store the character
	inc  si		; increment buffer pointer
	jmp  L1		; loop again

Exit_proc:
	mov  byte ptr [si],0		; insert null byte
	call EndLine
	ret
ReadLine ENDP

;-------------------------------------------
ShowMessage PROC uses ax dx,
	pString:PTR BYTE
;
; Display a string on the console, using
; INT 21h Function 9.
;-------------------------------------------
	mov  ah,9
	mov  dx,pString
	int  21h
	ret
ShowMessage ENDP

END main

