TITLE Chapter 11 Exercise 2                       (ch11_02.asm)

Comment !
Description: Write a program that inputs the following information from
the user, using the Win32 ReadConsole function: First name, last name,
age, phone number. Redisplay the same information with labels and
attractive formatting, using the Win32 WriteConsole function. Do not
use any procedures from the Irvine32 library.

Difficulty level: 3/5
Last update: 05/23/2002

!
INCLUDE Irvine32.inc

AskInfo PROTO,
  messageSize:DWORD,
  messagePtr:PTR DWORD,
  bufferSize:DWORD,
  bufferPtr:PTR DWORD

DisplayInfo PROTO,
  labelSize:DWORD,
  labelPtr:PTR DWORD,
  infoSize:DWORD,
  infoPtr:PTR DWORD

Screen_Cols = 80

.data
firstNameStr BYTE "Please enter your first name: "
lastNameStr  BYTE "Please enter your last name: "
ageStr       BYTE "Please enter your age: "
phoneStr     BYTE "Please enter your phone number: "

messagePtrs  DWORD OFFSET firstNameStr, SIZEOF firstNameStr
	DWORD OFFSET lastNameStr, SIZEOF lastNameStr
	DWORD OFFSET ageStr, SIZEOF ageStr
	DWORD OFFSET phoneStr, SIZEOF phoneStr
Items = ($ - messagePtrs ) / ( TYPE messagePtrs * 2 )

firstNameLabel BYTE "First name: "
lastNameLabel  BYTE "Last Name: "
ageLabel       BYTE "Age: "
phoneLabel     BYTE "Phone: "

labelPtrs DWORD OFFSET firstNameLabel, SIZEOF firstNameLabel
	DWORD OFFSET lastNameLabel, SIZEOF lastNameLabel
	DWORD OFFSET ageLabel, SIZEOF ageLabel
	DWORD OFFSET phoneLabel, SIZEOF phoneLabel

EntrySize = 30	; bytes per item (including end of line)
userInfo BYTE Items * EntrySize DUP(0)

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

	; Get info from user
	mov esi, OFFSET messagePtrs
	mov edi, OFFSET userInfo
	mov ecx, ITEMS	; counter

GET_INFO_LOOP:
	INVOKE AskInfo,[esi + TYPE DWORD],			; message size
	  [esi],				; pointer to message
	  EntrySize,	; size of entry
	  edi	; pointer to item in userInfo Array

	add esi, 8	; two double words per item
	add edi, EntrySize	; next entry
	loop GET_INFO_LOOP

	call NewLine	; carriage return and line feed

	; Display info
	mov esi, OFFSET labelPtrs
	mov edi, OFFSET userInfo
	mov ecx, ITEMS	; counter

DISPLAY_INFO_LOOP:
	INVOKE DisplayInfo,[esi + TYPE DWORD],		; label size
	  [esi],					; pointer to label
	  EntrySize,	; size of entry
	  edi	; pointer to item in userInfo Array

	add esi, 8	; two double words per item
	add edi, EntrySize	; next entry
	loop DISPLAY_INFO_LOOP

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
; and reads a string from the user
; Receives: size of message, pointer to message
;	size of buffer, pointer to buffer
; Returns: string read in memory pointed by bufferPtr
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
	  bufferSize, 	; number of chars to read
	  ADDR bytesRead,
	  0

	popad
	ret
AskInfo ENDP

;-------------------------------------------------------
DisplayInfo PROC,
  labelSize:DWORD,
  labelPtr:PTR DWORD,
  infoSize:DWORD,
  infoPtr:PTR DWORD
;
; Displays a message with a label
; Receives: size of label, pointer to label
;	size of message, pointer to message
; Returns: nothing
;-------------------------------------------------------

	pushad

	; Center the message
	mov eax, Screen_Cols
	sub eax, labelSize
	sub eax, infoSize
	sub eax, Screen_Cols / 6	; center
	mov dl, al	; column for first character
	call Goto_X	; locate cursor

	; Display the label
	INVOKE WriteConsole,
	  stdOutHandle,
	  labelPtr,	; pointer to string
	  labelSize,	; length of string
	  ADDR bytesWritten,	; returns number of bytes written
	  0	; not used

	; Display the message
	INVOKE WriteConsole,
	  stdOutHandle,
	  infoPtr,	; pointer to string
	  infoSize,	; length of string
	  ADDR bytesWritten,	; returns number of bytes written
	  0	; not used

	call NewLine	; carriage return and line feed

	popad
	ret
DisplayInfo ENDP

;-------------------------------------------------------
NewLine PROC USES eax
;
; Calls WriteConsole in the Win32 API
; and inserts a carriage return and a line feed
; Receives: nothing
; Returns: nothing
;-------------------------------------------------------
.data
	endl BYTE 0Dh,0Ah	; end of line sequence
.code

	INVOKE WriteConsole,
	  stdOutHandle,	; output handle
	  ADDR endl,	; pointer to string
	  SIZEOF endl,	; length of string
	  ADDR bytesWritten,
	  0	; not used

	ret
NewLine ENDP

;--------------------------------------------------
Goto_X PROC
;
; Move the cursor to a column in the screen
; Receives: DL = screen column
; Returns: nothing
;-----------------------------------------------------
.data
	cursor_Position COORD <>
	cursor_Info CONSOLE_SCREEN_BUFFER_INFO <>
.code
	pushad

	movzx ax, dl		; x coordinate ( column )
	mov cursor_Position.X, ax

	; Read cursor information
	INVOKE GetConsoleScreenBufferInfo,
	  stdOutHandle,		; screen handle
	  ADDR cursor_Info		; structure to store cursor info

	mov ax, cursor_Info.dwCursorPos.Y	; get current row
	mov cursor_Position.Y, ax

	INVOKE SetConsoleCursorPosition,
	  stdOutHandle,
	  cursor_Position

	popad
	ret
Goto_X ENDP
END main