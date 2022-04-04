TITLE Chapter 13 Exercise 2                  (ch13_02.asm)

Comment !
Description: Modify the Readfile program in Section 13.3.4 so
that it can read a file of any size. Assuming that the buffer
is smaller than the input file, use a loop to read all data.
Display appropriate error messages if the Carry flag is set
after any INT 21h function calls.

This project is a little time-consuming because of the error
trapping and message displays.

Difficulty level: 2/5
Last update: 05/14/2002
!
INCLUDE Irvine16.inc
DisplayError PROTO msgPtr:PTR BYTE

.data
BufSize = 1000
infile    BYTE "infile.txt",0
outfile   BYTE "outfile.txt",0
inHandle  WORD ?
outHandle WORD ?
buffer    BYTE BufSize DUP(?)
bytesRead WORD ?
str1      BYTE "Cannot open input file. Halting program",0dh,0ah,0
str2      BYTE "Cannot create output file. Halting program",0dh,0ah,0
str3      BYTE "Error reading input file",0dh,0ah,0
str4      BYTE "Error writing to output file",0dh,0ah,0
str5      BYTE "infile.txt successfully copied to outfile.txt",0dh,0ah,0

.code
main PROC
    mov  ax,@data
    mov  ds,ax

; Open the input file
	mov ax,716Ch   	; extended create or open
	mov bx,0      	; mode = read-only
	mov cx,0	; normal attribute
	mov dx,1	; action: open
	mov si,OFFSET infile
	int 21h       	; call MS-DOS
	.IF Carry?
	  INVOKE DisplayError, ADDR str1
	  jmp quit
	.ELSE
	  mov inHandle,ax
	.ENDIF

; Create the output file
	mov ax,716Ch   	; extended create or open
	mov bx,1      	; mode = write-only
	mov cx,0	; normal attribute
	mov dx,12h	; action: create/truncate
	mov si,OFFSET outfile
	int 21h       	; call MS-DOS
	.IF Carry?
	  INVOKE DisplayError, ADDR str2
	  jmp quit
	.ELSE
	  mov outHandle,ax
	.ENDIF

Read_File_Into_Buffer:
	mov ah,3Fh	; read file or device
	mov bx,inHandle	; file handle
	mov cx,BufSize	; max bytes to read
	mov dx,OFFSET buffer	; buffer pointer
	int 21h
	.IF Carry?	; error when reading?
	  INVOKE DisplayError,	; yes: display error message
	    ADDR str3
	  jmp Close_Input_File	; and close the file
	.ELSE	; no:
	  mov bytesRead,ax	; save the buffer size
	.ENDIF

; Write buffer to new file
	mov ah,40h	; write file or device
	mov bx,outHandle	; output file handle
	mov cx,bytesRead	; number of bytes
	mov dx,OFFSET buffer	; buffer pointer
	int 21h
	.IF Carry?	; error when writing?
	  INVOKE DisplayError,	; yes: display error message
	    ADDR str4
	  jmp Close_Input_File	; and close the file
	.ENDIF

	cmp bytesRead,BufSize	; all data read yet?
	je  Read_File_Into_Buffer	; no: read more data
		; yes: close the files

Close_Input_File:
	mov  ah,3Eh    	; function: close file
	mov  bx,inHandle	; input file handle
	int  21h       	; call MS-DOS
	jc  quit	; quit if error

Close_Output_File:
	mov  ah,3Eh    	; function: close file
	mov  bx,outHandle	; output file handle
	int  21h       	; call MS-DOS

; Display success message
	mov   dx,OFFSET str5
	call  WriteString

quit:
	call Crlf
    exit
main ENDP

DisplayError PROC msgPtr:PTR BYTE
	movzx  edx,msgPtr
	call WriteString
	ret
DisplayError ENDP

END main