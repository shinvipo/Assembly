TITLE Chapter 10 Exercise 7                           (ch10_07.asm)

Comment !
Description:
16-bit Real-address mode program. Requires reading Section 15.3.3.5.

Create a macro named mScroll that displays a color rectangle on the
screen. Include the following parameters in the macro definition:

	ULrow Upper-left window row
	ULcol Upper-left window column
	LRrow Lower-right window row
	LRcol Lower-right window column
	attrib Color of scrolled lines

If attrib is blank, assume a color of light gray characters on a
black background.

Difficulty level: 1/5
Last update: 05/05/2002
!
INCLUDE Irvine16.inc

mScroll MACRO ULrow,ULcol,LRrow,LRcol,attrib
	pusha
	mov ax,0600h		;; scroll window
	mov ch,ULrow
	mov cl,ULcol
	mov dh,LRrow
	mov dl,LRcol

	IFNB <attrib>		;; is the attribute blank?
	  mov bh,attrib		;; user-specified attribute
	ELSE
	  mov bh,lightGray		;; default attribute
	ENDIF
	int 10h
	popa
ENDM

.data


.code
main PROC
	call Clrscr

	mScroll  0, 0, 5,20, (lightBlue * 16)
	mScroll  0,30, 5,50, (lightRed * 16)
	mScroll 10, 0,15,20, (lightCyan * 16)
	mScroll 10,30,15,50, (lightMagenta * 16)

	mov dh,24
	mov dl,0
	call Gotoxy

	exit
main ENDP
END main