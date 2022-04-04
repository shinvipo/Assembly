TITLE Chapter 11 Exercise 6                        (ch11_06.asm)

Comment !
Description: Write a program that creates a new text file.
Prompt the user for a student identification number, last name,
first name, and date of birth. Write this information to the file.
Input several more records in the same manner and close the file.

Difficulty level: 3/5
Last update: 05/23/2002
!
INCLUDE Irvine32.inc

AskInfo PROTO,
  messageSize:DWORD,
  messagePtr:PTR DWORD,
  bufferSize:DWORD,
  bufferPtr:PTR DWORD

.data
idStr        BYTE "Please enter your id number: "
lastNameStr  BYTE "Please enter your last name: "
firstNameStr BYTE "Please enter your first name: "
ageStr       BYTE "Please enter your date of birth: "

messagePtrs DWORD OFFSET idStr, SIZEOF idStr
	DWORD OFFSET lastNameStr, SIZEOF lastNameStr
	DWORD OFFSET firstNameStr, SIZEOF firstNameStr
	DWORD OFFSET ageStr, SIZEOF ageStr
Items = ($ - messagePtrs ) / ( TYPE messagePtrs * 2 )

EntrySize = 30	; bytes per item (including end of line)
userInfo BYTE Items * EntrySize DUP(0)

filename     BYTE "output.txt",0
fileHandle   DWORD ?	; handle to output file
stdOutHandle DWORD 0
bytesWritten DWORD 0
stdInHandle  DWORD 0
bytesRead    DWORD 0

.code
main PROC

	; Get handle to standard output
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov stdOutHandle, eax	; save console handle

	; Get handle to standard input
	INVOKE GetStdHandle, STD_INPUT_HANDLE
	mov stdInHandle, eax	; save standard input handle

	; Create file and get file handle
	INVOKE CreateFile,
	  ADDR filename, GENERIC_WRITE, DO_NOT_SHARE, NULL,
	  CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov fileHandle,eax	; save file handle

	mov ecx, 3	; number of records to read
L1:	push ecx	; save counter

	; Get info from user
	mov esi, OFFSET messagePtrs
	mov edi, OFFSET userInfo
	mov ecx, ITEMS	; counter

GET_INFO_LOOP:
	INVOKE AskInfo,	[esi + TYPE DWORD],	; message size
	  [esi],	; pointer to message
	  EntrySize,	; size of entry
	  edi	; pointer to item in userInfo Array

	add esi, 8	; two doublewords per item
	add edi, EntrySize	; next entry
	loop GET_INFO_LOOP

	call NewLine	; write a blank line
	pop ecx	; restore counter
	loop L1	; next student

	; close the file
	INVOKE CloseHandle, fileHandle

	INVOKE ExitProcess, 0	; exit the program
main ENDP

;-------------------------------------------------------
AskInfo PROC,
  messageSize:DWORD,
  messagePtr:PTR DWORD,
  bufferSize:DWORD,
  bufferPtr:PTR DWORD
;
; Writes a message asking the user for an item,
; reads a string from the user and writes it to a file
; Receives: size of message, pointer to message
;	size of buffer, pointer to buffer
; Returns: characters written to file
;-------------------------------------------------------

	pushad

	; Ask for the an item
	INVOKE WriteConsole,
	  stdOutHandle,
	  messagePtr,	; pointer to string
	  messageSize,	; length of string
	  ADDR bytesWritten,	; returns num bytes written
	  0	; not used

	; Get user input
	INVOKE ReadConsole,
	  stdInHandle,
	  bufferPtr,	; pointer to string buffer
	  bufferSize,	; chars to read
	  ADDR bytesRead,
	  0

	; Write info to the file
	INVOKE WriteFile,	; write text to file
	  fileHandle,	; file handle
	  bufferPtr,	; buffer pointer
	  bytesRead,	; number of bytes to write
	  ADDR bytesWritten,	; number of bytes written
	  0	; overlapped execution flag

	popad
	ret
AskInfo ENDP

;-------------------------------------------------------
NewLine PROC USES eax
;
; Calls WriteFile in the Win32 API
; and inserts a carriage return and a line feed
; Receives: nothing
; Returns: nothing
;-------------------------------------------------------
.data
	endl BYTE 0Dh,0Ah	; end of line sequence
.code

	INVOKE WriteFile,
	  fileHandle,	; output handle
	  ADDR endl,	; pointer to string
	  SIZEOF endl,	; length of string
	  ADDR bytesWritten,
	  0	; not used

	ret
NewLine ENDP
END main