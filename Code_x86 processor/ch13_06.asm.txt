TITLE Chapter 13 Exercise 6                  (ch13_06.asm)

Comment !
Description: Write a program that opens a text file containing
up to 60K bytes and performs a case-insensitive search for a string.
The string and the filename can be input by the user. Display each
line from the file on which the string appears and prefix each line
with a line number. Review the Str_find procedure from Section 9.7,
but note that your program must run in Real-address mode.

Difficulty level: 5/5
Last update: 05/14/2002
!
INCLUDE Irvine16.inc
Read_Line PROTO,
	pBuffer:PTR BYTE, 	; pointer to buffer
	bufSize:WORD	; buffer size

Str_find PROTO,
	pSource:PTR BYTE,
	pTarget:PTR BYTE

BUFFER_SIZE = 256

.data
infileName BYTE "infile.txt",0
inHandle  WORD ?	; input file handle
buffer    BYTE BUFFER_SIZE DUP(?)
bytesRead WORD ?	; number of bytes read
eof_flag  WORD 0	; end of file flag
lineNum   DWORD 0	; current line number
matches   DWORD 0	; number of matching lines
strSearch BYTE 80 DUP(?),0

str1 BYTE "Text Matching Program",0dh,0ah,0dh,0ah
     BYTE "Attempting to open input file: ",0
str2 BYTE "Input a string for which to search: ",0
str3 BYTE "Unable to open file. Halting program.",0
str4 BYTE ": ",0
str5 BYTE "No matching lines were found",0dh,0ah,0

.code
main PROC
	mov ax,@data
	mov ds,ax

; Display a greeting and show the input file name.
	mov  dx,OFFSET str1	; "opening input file"
	call WriteString
	mov  dx,OFFSET infileName
	call WriteString
	call Crlf

; Attempt to open the input file.
	mov ax,716Ch   	; extended create or open
	mov bx,0      	; mode = read-only
	mov cx,0	; normal attribute
	mov dx,1	; action: open
	mov si,OFFSET infileName	; file name
	int 21h       	; call MS-DOS
	jc  Error_Opening	; error? Display message
	mov inHandle,ax

; Ask user to input a string that will be used when
; searching the file.
	mov  dx,OFFSET str2
	call WriteString
	mov  dx,OFFSET strSearch
	mov  cx,SIZEOF strSearch - 1
	call ReadString
	call Crlf

Read_One_Line:
	INVOKE Read_Line, ADDR buffer, BUFFER_SIZE
	inc  lineNum	; next line number

; Search for strSearch inside buffer.
	INVOKE Str_find, ADDR strSearch, ADDR buffer
	jnz  Next_Line	; not found? read next line
	inc  matches	; increment matching line count

; The string was found in the current line. Display the
; line number and text line.
Display_line:
	mov  eax,lineNum	; display line number
	call WriteDec
	mov  dx,OFFSET str4	; ": "
	call WriteString
	mov  dx,OFFSET buffer	; display line of text
	call WriteString
	call Crlf

Next_Line:
	cmp  eof_flag,1	; end of file yet?
	jne  Read_One_Line	; no: read next line

; Close the input file.
	mov  ah,3Eh    	; function: close file
	mov  bx,inHandle	; input file handle
	int  21h       	; call MS-DOS

	.IF matches == 0	; match count = 0?
	  mov  dx,OFFSET str5	; "no matching lines found"
	  call WriteString
	.ENDIF
	jmp  Exit_prog	; normal exit

Error_Opening:
	mov  dx,OFFSET str3	; "cannot open file"
	call WriteString
	call Crlf

Exit_prog:
	call Crlf
	exit
main ENDP

;----------------------------------------------------------
Read_Line PROC USES ax bx cx dx si,
	pBuffer:PTR BYTE,
	bufSize:WORD
LOCAL counter:WORD
;
; Read a single line of text from the file, up to the
; next CR/LF. Place text in buffer.
; Receives: pointer to buffer, pointer to count
; Returns: text placed in buffer, count updated
; Note: this procedure is tricky to implement, because
; it must check for both end of file and end of line.
; In each case, the insertion of the null terminator
; is different.
;----------------------------------------------------------
EOLN = 0Ah	; end of line byte

	mov counter,0
	mov si,pBuffer	; points to buffer

L1:	mov ah,3Fh	; read file or device
	mov bx,inHandle	; file handle
	mov cx,1	; read one byte
	mov dx,si	; buffer position
	int 21h
	jc  Exit_proc	; exit if error (CF=1)
	.IF ax == 0	; if end of file,
	  mov eof_flag,1	; set a flag
	  mov BYTE PTR [si],0	; insert null terminator
	  jmp Exit_proc	; and exit
	.ENDIF
	inc counter	; no: count the bytes
	cmp BYTE PTR [si],EOLN	; EOLN byte found?
	je  Insert_Null	; yes: exit loop
	inc si	; next buffer position
	mov ax,bufSize	; no: continue
	cmp counter,ax	; counter < bufSize?
	jbe L1	; yes: repeat loop

Insert_Null:
	mov BYTE PTR [si-1],0	; null terminator replaces 0Dh

Exit_proc:
	ret
Read_Line ENDP

;----------------------------------------------------------
Str_find PROC USES bx cx dx si di,
	pSource:PTR BYTE,
	pTarget:PTR BYTE
;
; Searches for the first matching occurrence of a source string
; inside a target string and returns the matching position.
; Returns: If a match is found, the procedure sets the Zero
; flag and AX points to the matching position in the target
; string. Otherwise, the Zero flag is clear.
;-----------------------------------------------------------
	INVOKE Str_length, pSource
	mov dx,ax		; EDX = length of source string
	INVOKE Str_length, pTarget
	mov bx,ax		; EBX = length of target string

	cld		; direction = up
	mov si,pSource		; point to source
	mov di,pTarget		; point to target

; Scan the destination for the first character in the source string.

L1: cmp bx,dx		; destination shorter than source?
    jb  Exit_proc		; yes: exit with ZF = 0
    mov cx,bx		; get destination length
    mov al,[si]		; get first byte of source
    repne scasb		; was the character found?
    jz  L2		; yes: continue matching
    jmp Exit_proc		; no: quit with ZF = 0

; Try to match the rest of the source string.

L2: mov bx,cx		; save new destination length
    mov cx,dx		; get the source length
    dec cx		; and subtract 1 from it
    jz  L3		; exit if source is now empty
    cmp bx,cx		; destination shorter than source?
    jb  Exit_proc		; yes: exit with ZF = 0
    call compare		; source = destination?
    jz  L3		; yes: get ready to exit
    inc di		; no: move to next character
    jmp L1		; continue to scan destination

; A matching string was found. Set AX to matching position in target.

L3: pushf
	dec di		; back up the destination pointer
	mov ax,di		; set EAX to destination location
	popf
    jmp Exit_proc		; exit with ZF = 1

Exit_proc:
    ret
Str_find ENDP

;---------------------------------------------------------
compare PROC
;
; Compares two strings pointed to by ESI and EDI.
; Returns: ZF=1 if the two strings are equal; otherwise,
;   ZF=0
;---------------------------------------------------------
    push esi
    push edi
    inc  esi	; second character of source
    repe cmpsb	; compare remaining characters
    pop  edi
    pop  esi
    ret
compare ENDP

END main