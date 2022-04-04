include irvine32.inc
include macros.inc

.data
pathFile	byte	"FileTracker32.dll",1000 dup(0)
buf			byte	1000 dup(0)
hFile		HANDLE	?
byteWritten dword	0
byteRead	dword	0
sum			DWORD	0

sectionName	byte	10 dup(0)
sectionNumber	dword	?

mDosHeader	byte	0,"e_magic",0,"e_cblp",0,"e_cp",0,"e_crlc",0,"e_cparhdr",0,"e_minalloc",0,"e_maxalloc",0,"e_ss",0,"e_sp",0,"e_csum",0,"e_ip",0,"e_cs",0,"e_lfarlc",0,"e_ovno",0,"e_res",0,"e_oemid",0,"e_oeminfo",0,"e_res2",0,"e_lfanew",0
szDosHeader	DWORD	18 dup(2),4
tmpStr1	byte	"e_res",0
tmpStr2 byte	"e_res2",0

startPeHeader	dword	?

mNTHeader		byte	0,"Signature",0
szNTHeader		dword	4

mFileHeader		byte	0,"Machine",0,"NumberOfSections",0,"TimeDataStamp",0,"PointerToSymbolTable",0,"NumberOfSymbols",0,"SizeOfOptionalHeader",0,"Characteristics",0
szFileHeader	dword	2,2,4,4,4,2,2

mOptionalHeader	   byte	0,"Magic"
				   byte 0,"MajorLinkerVersion"
				   byte 0,"MinorLinkerVersion"
				   byte 0,"SizeOfCode"
				   byte 0,"SizeOfInitializedData"
				   byte 0,"SizeOfUninitializedData"
				   byte 0,"AddressOfEntryPoint"
				   byte 0,"BaseOfCode"
				   byte 0,"BaseOfData"
				   byte 0,"ImageBase"
				   byte 0,"SectionAlignment"
				   byte 0,"FileAlignment"
				   byte 0,"MajorOperatingSystemVersion"
				   byte 0,"MinorOperatingSystemVersion"
				   byte 0,"MajorImageVersion"
				   byte 0,"MinorImageVersion"
				   byte 0,"MajorSubsystemVersion"
				   byte 0,"MinorSubsystemVersion"
				   byte 0,"Win32VersionValue"
				   byte 0,"SizeOfImage"
				   byte 0,"SizeOfHeaders"
				   byte 0,"CheckSum"
				   byte 0,"Subsystem"
				   byte 0,"DllCharacteristics"
				   byte 0,"SizeOfStackReserve"
				   byte 0,"SizeOfStackCommit"
				   byte 0,"SizeOfHeapReserve"
				   byte 0,"SizeOfHeapCommit"
				   byte 0,"LoaderFlags"
				   byte 0,"NumberOfRvaAndSizes"
				   byte 0
szOptionalHeader	dword	2,1,1, 9 dup (4), 6 dup(2), 4,4,4,4,2,2,4,4,4,4,4,4

mDataDirectories	byte 0,"Export Directory RVA"
					byte 0,"Export Directory Size"
					byte 0,"Import Directory RVA"
					byte 0,"Import Directory Size"
					byte 0,"Resource Directory RVA"
					byte 0,"Resource Directory Size"
					byte 0,"Exception Directory RVA"
					byte 0,"Exception Directory Size"
					byte 0,"Security Directory Offset"
					byte 0,"Security Directory Size"
					byte 0,"Relocation Directory RVA"
					byte 0,"Relocation Directory Size"
					byte 0,"Debug Directory RVA"
					byte 0,"Debug Directory Size"
					byte 0,"Architecture Directory RVA"
					byte 0,"Architecture Directory Size"
					byte 0,"Reserved"
					byte 0,"Reserved"
					byte 0,"TLS Directory RVA"
					byte 0,"TLS Directory Size"
					byte 0,"Load Config Directory RVA"
					byte 0,"Load Config Directory Size"
					byte 0,"Bound Import Directory RVA"
					byte 0,"Bound Import Directory Size"
					byte 0,"Import Address Table Directory RVA"
					byte 0,"Import Address Table Directory Size"
					byte 0,"Delay Import Directory RVA"
					byte 0,"Delay Import Directory Size"
					byte 0,".NET Directory RVA"
					byte 0,".NET Directory Size"
					byte 0
szDataDirectories	dword	30 dup (4)

mSectionTable 		byte 0,"VirtualSize"
					byte 0,"VirtualAddress"
					byte 0,"SizeOfRawData"
					byte 0,"PointerToRawData"
					byte 0,"PointerToRelocations"
					byte 0,"PointerToLinenumbers"
					byte 0,"NumberOfRelocations"
					byte 0,"NumberOfLinenumbers"
					byte 0,"Characteristics"
					byte 0
szSectionTable		dword 6 dup (4),2,2,4

mExportTable	byte 0,"Characteristics",0,"TimeDateStamp",0,"MajorVersion",0,"MinorVersion",0,"Name",0,"Base",0,"NumberOfFuntions",0,"NumberOfName",0,"AddressOfFuntions",0,"AddressOfNames",0,"AddressOfNameOrdinals",0
szExportTable	dword 4,4,2,2, 7 dup(4)

idataVA			dword	0
idataRawData	dword	0
importTableRVA	dword	0

edataVA			dword	0
edataRawData	dword	0
exportTableRVA	dword	0

importNameRVA dword 0 
exportNameRVA dword 0 

sectionTableOffset	dword	0
imageBase	dword	0
OFTs dword 0 ; oft = originalFistThunk point to a array of module name rva



.code
main proc
	
	mWrite "Enter FilePath : "
	mov edx , offset pathFile
	mov ecx , sizeof pathFile
	call ReadString
	call crlf
	mWrite<"File Name: ">
	mov edx , offset pathFile
	call OpenInputFile
	mov hFile, eax

	cmp eax, INVALID_HANDLE_VALUE
	jne file_oke
	mWrite<"Cannot open file",10,0>
	jmp returnn

file_oke:
	mov edx, offset pathFile
	mov ecx, lengthof pathFile
	call writestring 
	call crlf

	push 4
	push 03ch
	call getBuf

	call crlf
	call showDosHeader
	call showPEHeader
	call showSectionTable
	call importDirec
	call exportDirec

returnn:
	call Crlf
	call WaitMsg
	exit
main endp

getBuf proc StartOffset: DWORD , NumbertoRead: DWORD
	pushad
	pushad
	invoke SetFilePointer, hFile, StartOffset, NULL, FILE_BEGIN
	invoke ReadFile, hFile, addr buf,NumbertoRead, offset byteRead, null
	popad
	popad
	ret
getbuf endp

writeSpace proc uses ecx, numberDot: DWORD
	mov ecx, numberDot
	loop1:
		mov al, ' '
		call writechar
		loop loop1
	ret
writeSpace endp

write_Eax_Hex proc uses ebx ecx edi, sz: DWORD, addrBuf: DWORD
;;;;;;;;;;;;;;;;;;;; print value Buffer
	xor eax, eax
	mov ecx, 0
	mov ebx, sz
	mov edi, addrBuf

	loop1:
		inc ecx
		mov al, [edi]
		cmp ecx, ebx
		jz con1
		shl eax, 8
		inc edi
		jmp loop1
	con1:
		cmp ebx, 2
		jz con3
		cmp ebx, 4
		jz con2
		jmp quit
		
	con2:
		mov ecx, 4
		mov ebx, addrBuf
		mov edi, 3
		loop2:
			shl eax, 8
			mov al,[edi+ebx]
			dec edi
			loop loop2
		jmp quit
	con3:
		rol ax,8

	quit:
		call writehexb
		ret
write_Eax_Hex endp

str_cmp	proc uses ebx ecx edx esi edi , str1: ptr byte, str2: ptr byte	
local len1: dword

	push str1
	call str_length
	mov len1, eax

	push str2
	call str_length
	
	cmp len1, eax
	jz cmpCon1
	mov eax, 0
	jmp cmpQuit

	cmpCon1:
		mov edi, str1
		mov esi, str2

		cmpLoop:
			mov al, [esi]
			mov dl, [edi]

			cmp al, 0
			jz equal
			cmp al, dl
			jz cL1
			mov eax , 0
			jmp cmpQuit

			cL1:
				inc edi
				inc esi
			jmp cmpLoop
	equal:
		mov eax, 1
		jmp cmpQuit
	cmpQuit:
	ret
str_cmp endp

check_eres	proc uses eax srcOff: DWORD 
; if src equal "e_eres" => ecx = 4
;		 equal "e_eres2" => ecx = 10
		push offset tmpStr1
		push srcOff
		call str_cmp

		cmp eax, 1
		jz Conn1

		push offset tmpStr2
		push srcOff
		call str_cmp

		cmp eax, 1
		jz Conn2
		ret

	Conn1:
		mov ecx, 4
		ret
	Conn2:
		mov ecx, 10
		ret

	ret
check_eres endp

showInfo proc uses eax ebx ecx edx, startOffset: DWORD, addrMemHeader: DWORD, addrSzHeader: DWORD, numMem: DWORD
local addres: DWORD 
local tmp: dword 	
	; eax = start offset of DosHeader
	xor eax, eax
	mov eax, startOffset
	mov tmp,eax
	mov esi,  addrSzHeader
	mov edi,  addrMemHeader
	xor ecx, ecx
	loop1:
		mWrite<9>
		cmp ecx, numMem
		jz quit

		push ecx

		mov ecx, 1000
		cld
		mov eax , 0
		repne scasb
		mov edx, edi
		call writestring 
		push edx
		call str_length
		mov ebx, 38
		sub ebx, eax
		push ebx
		call writeSpace 

		;;;;;;;;;;;;;;;;;;; write address
		mov eax, tmp
		mov addres, eax
		mWrite "0x"
		call writehex
		add eax,dword ptr [esi]
		mov tmp, eax

		;;;;;;;;;;;;;;;;;;; write size
		mWrite <9>
		mov eax, [esi]
		call writedec
		add esi, 4

		;;;;;;;;;;;;;;;;;;; write value
		mov ecx, 1

		push edi
		call check_eres

		loopPrint:
			mWrite <9>
			mWrite "0x"

			push eax
			push addres
			call getBuf

			push eax

			push offset buf
			push eax
			call write_eax_hex
			
			mov startPeHeader, eax
			pop eax
			mov ebx, addres
			add ebx, eax
			mov addres, ebx
			mov tmp, ebx
			loop loopPrint

		;;;;;;;;;;;;;;;;;;;
		call crlf
		pop ecx
		inc ecx
		jmp loop1
	quit:
	ret
showInfo endp

showDosHeader proc uses ecx

	mWrite<"DosHeader:",10>
	push lengthof szDosHeader
	push offset szDosHeader
	push offset mDosHeader
	push 0
	call showInfo
	
	quit:
		ret
showDosHeader endp

showPEHeader proc uses eax ebx edx
	
	mWrite<10,"NTHeader:",10>

	mov eax,startPeHeader
	add eax, szNTHeader

	mov ebx, eax
	add ebx, 2

	push 2
	push ebx
	call getbuf
	xor ebx, ebx
	mov bx, word ptr [buf]
	mov sectionNumber, ebx

	push lengthof szNTHeader
	push offset szNTHeader
	push offset mNTHeader
	push startPeHeader
	call showInfo

	mWrite<10,"File Header:",10>
	push lengthof szFileHeader
	push offset szFileHeader
	push offset mFileHeader
	push eax
	call showInfo

	push lengthof szFileHeader
	push offset szFileHeader
	call arr_sum
	add eax, sum

	mWrite<10,"Optional Header:",10>
	push lengthof szOptionalHeader
	push offset szOptionalHeader
	push offset mOptionalHeader
	push eax
	call showInfo

	mov edx, eax
	add edx, 28

	push 4
	push edx
	call getbuf

	mov edx, dword ptr[buf]
	mov imageBase, edx

	push lengthof szOptionalHeader
	push offset szOptionalHeader
	call arr_sum
	add eax, sum

	mov edx , eax

	push 20
	push edx
	call getBuf
	mov ebx, dword ptr [buf+8]
	mov importTableRVA, ebx

	mov ebx, dword ptr [buf]
	mov exportTableRVA, ebx

	mWrite<10,"Data Directories:",10>
	push lengthof szDataDirectories
	push offset szDataDirectories
	push offset mDataDirectories
	push eax
	call showInfo

	push lengthof szDataDirectories
	push offset szDataDirectories
	call arr_sum
	add eax, sum
	add eax, 8
	mov startPeHeader, eax

	ret
showPEHeader endp

showSectionTable proc 
	pushad
	mWrite<10,"Section Table: Have ">
	mov eax, sectionNumber
	call writedec 
	mwrite<" Section...",10>
	call crlf
	mov eax, startPeHeader
	mov sectionTableOffset, eax
	xor ecx, ecx
	printLoop:
		cmp ecx, sectionNumber
		jz quit
		inc ecx
		push 8
		push eax
		call getbuf

		add eax,8
		mov edx, offset buf
		call writestring

		push lengthof szSectionTable
		push offset szSectionTable
		push offset mSectionTable
		push eax
		call showInfo
		mWrite <10>

		push lengthof szSectionTable
		push offset szSectionTable
		call arr_sum
		add eax, sum

		jmp printLoop
	quit:
	popad
	ret
showSectionTable endp

arr_sum proc uses eax ecx ebx edi, lpArr: DWORD, lenArr: DWORD
	mov edi, lpArr
	mov ecx, lenArr
	xor eax, eax
	mov sum, eax
	loopSum:
		add eax, [edi]
		add edi, 4
		loop loopSum
	mov sum, eax
	ret
arr_sum endp

importDirec proc
	pushad
	
	mWrite<10,"ImportDirectory:",10>

	mov ebx, sectionTableOffset
	xor ecx, ecx

	idataHeader_Find:
		cmp ecx , sectionNumber
		jz quit1
		push 20
		push ebx
		call getBuf
		
		push importTableRVA
		push dword ptr [buf + 8]
		push dword ptr [buf + 12]
		call check_Directory
		cmp eax, 1

		jz getInfo
		conFind:
		add ebx, 8
		add ebx, 20h
		inc ecx
		jmp idataHeader_Find

	getInfo:
		add ebx, 12
		push 4
		push ebx
		call getBuf
		mov eax, dword ptr[buf]
		mov idataVA, eax

		add ebx, 8
		push 4
		push ebx
		call getBuf
		mov eax, dword ptr[buf]
		mov idataRawData, eax

		push importTableRVA
		call calRawOffset		; cal RawOffset of IMAGE_IMPORT_DESCRIPTOR struct
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
		
		getResult:
			push eax

			push 4
			push eax
			call getBuf

			cmp dword ptr [buf],0
			jz quit

			mov ebx, dword ptr [buf]
			mov OFTs, ebx
			
			add eax , 12
			push 4
			push eax
			call getBuf

			mov ebx, dword ptr[buf]
			mov importNameRVA, ebx

			push importNameRVA
			call calRawOffset

			push 100
			push eax
			call getBuf

			mov edx, offset buf
			call writestring
			call crlf
			mWrite<9,"Hint",9,"Name",10>

			push OFTs
			call calRawOffset

			printModuleName:
				push eax

				push 4
				push eax
				call getBuf
				
				mov edx,dword ptr [buf]
				cmp edx, 0
				jz continueeeee

				push dword ptr[buf]
				call calRawOffset

				mWrite<9>
				push 50
				push eax
				call getBuf

				push offset buf
				push 2
				call write_eax_hex

				mwrite<9>
				mov edx, offset buf
				add edx, 2
				call writestring
				call crlf
				pop eax
				add eax, 4
				jmp printModuleName
			continueeeee:
			pop eax
			pop eax
			add eax, 20
			jmp getResult
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	quit:
	pop eax
	quit1:
	popad
	ret 
importDirec endp




exportDirec proc
local exportTableOffset: dword
local numberName: DWORD 
	pushad
	mWrite<10,"ExportDirectory:",10>

	mov ebx, sectionTableOffset
	xor ecx, ecx

	edataHeader_Find:
		cmp ecx , sectionNumber
		jz quit1
		push 20
		push ebx
		call getBuf
		
		push exportTableRVA
		push dword ptr [buf + 8]
		push dword ptr [buf + 12]
		call check_Directory
		cmp eax, 1

		jz getInfo
		conFind:
		add ebx, 8
		add ebx, 20h
		inc ecx
		jmp edataHeader_Find

	getInfo:
		add ebx, 12
		push 4
		push ebx
		call getBuf
		mov eax, dword ptr[buf]
		mov edataVA, eax

		add ebx, 8
		push 4
		push ebx
		call getBuf
		mov eax, dword ptr[buf]
		mov edataRawData, eax

		push exportTableRVA
		call calRawOffsetExD		; cal RawOffset of IMAGE_EXPORT_DESCRIPTOR struct

		mov exportTableOffset, eax

		push lengthof szExportTable
		push offset szExportTable
		push offset mExportTable
		push eax
		call showInfo

		call crlf

		add eax, 24
		push 100
		push eax
		call getBuf
		
		mov ebx, dword ptr [buf+8]
		mov exportNameRVA, ebx

		mov ebx,  dword ptr[buf]
		mov numberName,ebx

		mov ebx, dword ptr[buf+12]
		;mov nameOrdinalRVA, ebx

		push ebx
		call calRawOffsetExD

		mov ebx, eax

		push exportNameRVA
		call calRawOffsetExD

		mwrite <9,"ExportedByNameFuntion:",10>
		mwrite <9,9,"NameOrdinal",9,"Name",10>
		xor ecx, ecx

		showExFuntion:
			push eax
			cmp ecx, numberName
			jz quit
			mwrite <9,9>

			call showOrdinal
			mWrite<9,9>
			call showName

			pop eax
			add eax, 4
			add ebx, 2
			inc ecx
			jmp showExFuntion
	quit:
	pop eax
	quit1:
	popad
	ret
exportDirec endp

showName proc
	pushad
			push 4
			push eax
			call getBuf

			push dword ptr[buf]
			call calRawOffsetExD

			push 100
			push eax
			call getBuf

			mov edx, offset buf
			call writestring
			call crlf
	popad
	ret
showName endp

showOrdinal proc
	pushad
			push 4
			push ebx
			call getBuf

			push dword ptr[buf]
			call calRawOffsetExD

			push 100
			push ebx
			call getBuf

			push offset buf
			push 2
			call write_eax_hex
			
	popad
	ret
showOrdinal endp

calRawOffset proc uses ebx VA_YouHave: DWORD	
;;;;;;;;;; Raw Offset = RVA_YouHave - ImageBase - VirtualOffsetOfSection + RawOffsetOfSection

	;; RVA_UHave - VirtualOffsetOfSection ====> offset trên file của biến cần tính so với start offset của Section chứa nó
	mov ebx , idataVA
	sub ebx , idataRawData

	mov eax , VA_YouHave
	sub eax , ebx

	;add eax, imageBase
	ret
calRawOffset endp

calRawOffsetExD proc uses ebx VA_YouHave: DWORD	
;;;;;;;;;; Raw Offset = VA_YouHave - VirtualOffsetOfSection + RawOffsetOfSection
	
	mov ebx , edataVA
	sub ebx , edataRawData

	mov eax , VA_YouHave
	sub eax , ebx

	;add eax, imageBase
	ret
calRawOffsetExD endp

check_Directory	proc  VASection: DWORD , szSection : DWORD , direcRVA: DWORD
local upperBound: DWORD 
	
	mov eax, szSection		;; Virtural Size Section
	add eax, VASection
	mov upperBound, eax

	mov eax,direcRVA
	
	cmp eax,VASection
	jb no

	cmp eax, upperBound
	jg no

	jmp yes

	no:
		mov eax, 0
		jmp quit
	yes:
		mov eax, 1
		jmp quit
	quit:
	ret
check_Directory	endp

end main