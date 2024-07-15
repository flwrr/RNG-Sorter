TITLE RNG Sorter

; Author:					Christian Ritchie
; Last Modified:			11-22-26
; Description:				Program generates and displays an array of random numbers, first as an unsorted list, 
;                           then a sorted list in ascending order by columns, then finds and displays the median,
;                           and finally counts the occurance of each possible value determined by the given range.
  
INCLUDE Irvine32.inc

ARRAYSIZE   =   200         ; Must be an integer above 0.             should be initially set to 200
LO          =   15          ; Must be an integer above 0 and <= HI.   should be initially set to 15
HI          =   50          ; Must be an integer above 0 and >= LO.   should be initially set to 50

.data
    ; messages
	intro1 			BYTE	10, 13, "RNG Sorter by Christian Ritchie", 10, 13, 10, 13, 0
    ; intro 2 uses placeholders which when the procedure 'displayList' encounters, will print the constant values:
    ; '#' will print ARRAYSIZE, '_' will print LO, '^' will print HI
    intro2          BYTE    "This program generates # random integers between _ and ^, inclusive.", 10, 13,
                            "It then displays the original list, sorts the list, displays the median value, ", 10, 13,
                            "displays the list sorted ascending, vertically by column, and finally displays the ", 10, 13,
                            "number of instances of each generated value, starting with the number of lowest.", 10, 13, 10, 13, 0
    intro2_count    DWORD   (LENGTHOF intro2)
	intro3   		BYTE	"Numbers are displayed ordered by column instead of by row.", 10, 13,
							"Numbers are generated directly to a file, then read the file into the array.", 10, 13, 0
    createFileError BYTE    10, 13, "INVALID_HANDLE_VALUE error occurred on CreateOutputFile.", 10, 13, 0
    ; print array titles
    titleRandom     BYTE    10, 13, "Unsorted Array of Random Numbers: ", 0
    titleSorted     BYTE    10, 13, "Sorted Array of Random Numbers: ", 0
    titleMedian     BYTE    10, 13, "The median value of the array: ", 0
    titleCount      BYTE    10, 13, "Count of Each Random Number's Appearance: ", 0
    ; arrays
    randArray       DWORD   ARRAYSIZE DUP(?)
    tempArray       DWORD   ARRAYSIZE DUP(?)    ; Temporary array used during sort procedure
    counts          DWORD   (HI-LO+1) DUP(0)    ; All counts initialized to 0
    countsLength    DWORD   LENGTHOF counts     ; number of values between LO and HI (inclusive)
    filename        BYTE    "randomArray.txt", 0
    buffer          DWORD   ?

.code
main PROC

    ; 1.    Introduce the program.
    PUSH    OFFSET intro3           ; [ebp+20]  =   address of 'intro3'
    PUSH    intro2_count            ; [ebp+16]  =   length of  'intro2'
    PUSH    OFFSET intro2           ; [ebp+12]  =   address of 'intro2'
    PUSH    OFFSET intro1           ; [ebp+8]   =   address of 'intro1'
    CALL    introduction

    ; 2.    Generate ARRAYSIZE random integers in the range from LO to HI (inclusive), 
    ;       storing them in consecutive elements of array randArray.
;       [ebp+20]  =   address of create file error message (reference, input)
;       [ebp+16]  =   address of buffer (reference, input/output)
;       [ebp+12]  =   address of fileName to read/write form (reference, input/output)
;       [ebp+8]   =   address of array to fill (reference, output)
    CALL    randomize               ; Generate random seed
    PUSH    OFFSET createFileError  ; [ebp+20]  =   address of file name error message
    PUSH    OFFSET buffer           ; [ebp+16]  =   address of buffer
    PUSH    OFFSET fileName         ; [ebp+12]  =   address of fileName to read/write to/from
    PUSH    OFFSET randArray        ; [ebp+8]   =   address of array to fill
    CALL    fillArray

    ; 3.    Display the list of integers before sorting, 
    ;       20 numbers per line with one space between each value.
    PUSH    ARRAYSIZE               ; [ebp+16]  =   Length of array
    PUSH    OFFSET randArray        ; [ebp+12]  =   Address of array
    PUSH    OFFSET titleRandom      ; [ebp+8]   =   Address of title
    CALL    displayList

    ; 4.    Sort the list in ascending order (i.e., smallest first).
    PUSH    OFFSET tempArray        ; [ebp+16]  =   address of 'tempArray'
    PUSH    OFFSET randArray        ; [ebp+12]  =   address of array to sort
    PUSH    ARRAYSIZE               ; [ebp+8]   =   length of array to sort in bytes
    CALL    sortList

    ; 5.    Calculate and display the median value of the sorted randArray, 
    ;       rounded to the nearest integer. (using Round Half Up)
    PUSH    OFFSET randArray        ; [ebp+12]  =   Array to count
    PUSH    OFFSET titleMedian      ; [ebp+8]   =   Title to print
    CALL    displayMedian

    ; 6.    Display the sorted randArray, 
    ;       20 numbers per line with one space between each value.
    PUSH    ARRAYSIZE               ; [ebp+16]  =   Length of array
    PUSH    OFFSET randArray        ; [ebp+12]  =   Address of array
    PUSH    OFFSET titleSorted      ; [ebp+8]   =   Address of title
    CALL    displayList

    ; 7.    Generate an array counts which holds the number of times each value in 
    ;       the range [LO, HI] ([15, 50] for default constant values) is seen in randArray.
    PUSH    OFFSET counts           ; [ebp+12]  =   Address of 'counts' array
    PUSH    OFFSET randArray        ; [ebp+8]   =   Address of array to count
    CALL    countList

    ; 8.    Display the array counts, 20 numbers per line with one space between each value.
    PUSH    countsLength            ; [ebp+16]  =   Length of array
    PUSH    OFFSET counts           ; [ebp+12]  =   Address of array
    PUSH    OFFSET titleCount       ; [ebp+8]   =   Address of title
    CALL    displayList

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; introduction {parameters: intro1 (reference, input), intro2 (reference, input), ...)
; ---------------------------------------------------------------------------------
; Name: introduction
; 
; Prints the program title and programmer's name, extra credit, and program description.
;
; Preconditions: None.
;
; Postconditions: None.
;
; Receives: 
;       [ebp+20]  =   address of 'intro3' (reference, input)
;       [ebp+16]  =   length of  'intro2' (reference, input)
;       [ebp+12]  =   address of 'intro2' (reference, input)
;       [ebp+8]   =   address of 'intro1' (reference, input)
;
; Returns: None.
;  ---------------------------------------------------------------------------------
introduction PROC
    ; Establish base pointer 
    PUSH    EBP                 
	MOV     EBP, ESP                    
    ; Preserve registers
    PUSH    ESI                 
    PUSH    EDX                 
    PUSH    ECX
    PUSH    EAX

    ; Write intro1 (Title and Author)
	MOV		EDX, [EBP+8]
	CALL	WriteString

    ; Write intro2 (Description), using placeholders to print constants.
    MOV     ECX, [EBP+16]
    MOV     ESI, [EBP+12]
_WriteIntro2:
    MOV     AL, [ESI]
    ; Check for character placeholders
    CMP     AL, '#'         
    JE      _WriteSize
    CMP     AL, '_'         
    JE      _WriteLow
    CMP     AL, '^'         
    JE      _WriteHigh
    ; Writes current char if not = to a placeholder
    CALL	WriteChar       
    JMP     _EndIteration

    ; Fill in constant values for placeholders
_WriteSize:
    MOV     EAX, ARRAYSIZE
    CALL    WriteDec
    JMP     _EndIteration
_WriteLow:
    MOV     EAX, LO
    CALL    WriteDec
    JMP     _EndIteration
_WriteHigh:
    MOV     EAX, HI
    CALL    WriteDec
    JMP     _EndIteration
_EndIteration:
    INC     ESI
    LOOP    _WriteIntro2

    ; Write intro3 (Extra Credit)
    MOV     EDX, [EBP+20]
    CALL	WriteString

    ; Restore registers           
    POP     EAX                 
    POP     ECX
    POP     EDX                 
    POP     ESI
    ; Restore base pointer
    POP     EBP
	RET     16
introduction ENDP


; fillArray {parameters: someArray (reference, output)}  
; NOTE: LO, HI, ARRAYSIZE will be used as globals within this procedure.
    ; Hint: Call Randomize once in main to generate a random seed. 
    ; Later, use RandomRange to generate each random number.
; ---------------------------------------------------------------------------------
; Name: fillArray
; 
; Generates ARRAYSIZE random integers in the range from LO to HI (inclusive), 
; storing them in consecutive elements of array randArray. 
; (e.g. for LO = 20 and HI = 30, generate values from the set [20, 21, ... 30]) 
;
; Preconditions: None.
;
; Postconditions: Array passed to procedure will be filled with random integers.
;                 A text file will be generated and filled with data.
;
; Receives: 
;       [ebp+20]  =   address of create file error message (reference, input)
;       [ebp+16]  =   address of buffer (reference, input/output)
;       [ebp+12]  =   address of fileName to read/write form (reference, input/output)
;       [ebp+8]   =   address of array to fill (reference, output)
;
; Returns: None.
;  ---------------------------------------------------------------------------------
fillArray PROC
    ; Establish base pointer 
    PUSH    EBP                 
	MOV     EBP, ESP             
    ; Preserve registers
    PUSHAD

    ; --------------------- Normal Storage (NON-EXTRA-CREDIT) ----------------------

    COMMENT !
    ; Load parameters
    MOV     ESI, [EBP+8]        ; Address of array to store random ints to
    MOV     ECX, ARRAYSIZE      ; Constant - Size of array
_FillLoop:
    ; Generate random int
    MOV     EAX, HI             ; RandomRange precondition: EAX - upper limit
    ADD     EAX, 1              ; RandomRange is exclusive; upper limit += 1
    SUB     EAX, LO             ; upper limit initialized to HI - LO for gen
    CALL    RandomRange
    ADD     EAX, LO             ; add lower limit back into random int (0 -> LO)
    ; Store random int
    MOV     [ESI], EAX
    ADD     ESI, 4              ; Increment ESI to the next item's address
    LOOP    _FillLoop
    !

    ; -------------- **EC: GENERATE FILE AND WRITE/READ TO/FROM IT -----------------

    ; Create file

    MOV     EDX, [EBP+12]       ; Precondition: EDX - address of fileName
    CALL    CreateOutputFile    ; Postconiditon: EAX - file handle
    CMP     EAX, INVALID_HANDLE_VALUE
    JE      _CreateOutputError

    ; Write to file

    MOV     EDI, EAX            ; EDI - file handle
    MOV     ESI, ARRAYSIZE      ; ESI - counter
_WriteLoop:
    ; Generate random int
    MOV     EAX, HI             ; RandomRange precondition: EAX - upper limit
    ADD     EAX, 1              ; RandomRange is exclusive; upper limit += 1
    SUB     EAX, LO             ; upper limit initialized to HI - LO for gen
    CALL    RandomRange
    ADD     EAX, LO             ; add lower limit back into random int (0 -> LO)
    ; store value in buffer
    MOV     EBX, [EBP+16]
    MOV     [EBX], EAX       
    ; Write to file
    MOV     EAX, EDI            ; WriteToFile precondition: EAX - file handle
    MOV     EDX, [EBP+16]       ; WriteToFile precondition: EDX - address of buffer
    MOV     ECX, 4              ; WriteToFile precondtiion: ECX - buffer size
    call    WriteToFile
    ; Test loop counter
    DEC     ESI
    CMP     ESI, 0
    JA      _WriteLoop
    ; Close file
    MOV     EAX, EDI            ; CloseFile precondition: EAX - file handle
    CALL    CloseFile

    ; Read from file and store in array

    ; Open file
    MOV     EDX, [EBP+12]       ; OpenInputFile precondition: EDX - address of filename
    CALL    OpenInputFile       ; OpenInputFile postcondition: EAX - file handle
    CMP     EAX, INVALID_HANDLE_VALUE
    JE      _CreateOutputError

    ; Read file
    MOV     EDI, EAX            ; EDI - file handle
    ; Calculate bytes to read
    MOV     ECX, ARRAYSIZE
    MOV     EAX, 4
    MUL     ECX
    ; Preconditions
    MOV     ECX, EAX            ; ReadFromFile precondition: bytes to read
    MOV     EAX, EDI            ; ReadFromFile precondition: EAX - file handle
    MOV     EDX, [EBP+8]        ; ReadFromFile precondition: buffer address
    CALL    ReadFromFile

    ; Close file
    MOV     EAX, EDI            ; CloseFile precondition: EAX - file handle
    CALL    CloseFile
    JMP     _End

_CreateOutputError:
    MOV     EDX, [EBP+20]
    CALL    WriteString

    ; ---------------------- END OF **EC STORAGE VERSION ---------------------------

_End:
    ; Restore registers
    POPAD
    ; Restore EBP registers
    POP     EBP                 
	RET     16
fillArray ENDP


; sortList {parameters: someArray (reference, input/output)} 
; NOTE: ARRAYSIZE will be used as a global within this procedure.
; ---------------------------------------------------------------------------------
; Name: sortList
; 
; Uses mergesort to sort an array of integer values.
;
; Preconditions: None.
;
; Postconditions: Array passed to procedure will be sorted in ascending order.
;
; Receives: 
;       [ebp+16]  =   address of 'tempArray' (reference, input/output)
;       [ebp+12]  =   address of array to sort (reference, input/output)
;       [ebp+8]   =   length of array to sort in bytes (value, input)
;
; Returns: None.
;  ---------------------------------------------------------------------------------
    
sortList PROC
    ; Establish base pointer and preserve registers
    PUSH    EBP                 
	MOV     EBP, ESP                    
    PUSHAD
    ; ------------------------------- MERGE SORT -----------------------------------
    ; Test if array is size 1
    MOV     EAX, [EBP+8]
    CMP     EAX, 1
    JBE      _ExitProcedure

    ; --------------------- 1. RECURSIVELY DIVIDE ARRAY ---------------------------- 
    ; Find mid by dividing length by 2
    MOV     EDX, 0          ; DIV precondition: EDX:EAX - Dividend
    MOV     ESI, 2
    DIV     ESI             ; DIV 32bit Postcondition: EAX - Quotient, EDX - Remainder

    ; Call sortList on LEFT half
    PUSH    [EBP+16]        ; 1st parameter - address within 'tempArray'
    PUSH    [EBP+12]        ; 2nd parameter - address within array to sort
    PUSH    EAX             ; 3rd parameter - LEFT length
    CALL    sortList

    ; Call sortList on RIGHT half
    ; Find offset of RIGHT half array's first element
    MOV     EBX, EAX        ; Preserve LEFT length for 3rd parameter calculation
    MOV     ESI, 4
    MUL     ESI             ; MUL 32bit Postcondition: EAX:EDX - Product
    ; Find offset for RIGHT half TEMP array
    MOV     ESI, [EBP+16]
    ADD     ESI, EAX
    PUSH    ESI             ; 1st parameter - new address within 'tempArray'
    ; Find offset for RIGHT half array to sort
    MOV     ESI, [EBP+12]
    ADD     ESI, EAX        
    PUSH    ESI             ; 2nd parameter - new address within array to sort
    ; Find length of RIGHT half array
    MOV     EDX, [EBP+8]    ; Store CURRENT array length
    SUB     EDX, EBX        ; Subtract CURRENT array length by LEFT length to obtain RIGHT length
    PUSH    EDX             ; 3rd parameter - RIGHT length
    CALL    sortList

    ; ------------------- 2. PRE-SORT: ESTABLISH VARIABLES ------------------------- 
    ; Copy current array segment to tempArray
    MOV     ECX, [EBP+8]    ; Store CURRENT length
    MOV     ESI, [EBP+12]   ; Store base address of source (array to sort)
    MOV     EDI, [EBP+16]   ; Store base address of destination (TEMP)
_CopyArrayLoop:
    MOV     EAX, [ESI]
    MOV     [EDI], EAX
    ADD     ESI, 4
    ADD     EDI, 4
    LOOP    _CopyArrayLoop

    ; Sort; Merge LEFT and RIGHT into CURRENT by value size
    MOV     ECX, [EBP+8]    ; Store CURRENT length
    MOV     EDI, [EBP+12]   ; Store address of CURRENT
    MOV     ESI, [EBP+16]   ; Store address of TEMP

    ; Calculate and store 'STOP' address of LEFT (TEMP array)
    MOV     EAX, 4
    MUL     EBX
    ADD     EAX, ESI
    MOV     EBX, EAX

    ; Calculate and store 'STOP' address of RIGHT (TEMP array)
    MOV     EAX, 4
    MUL     ECX
    ADD     EAX, ESI
    MOV     EDX, EAX

    ; Store remaining variables
    MOV     EAX, [EBP+16]
    MOV     ECX, EBX        
    MOV     EDI, [EBP+12]

    ; ----------------------------- 3. MERGE SORT ----------------------------------
    ; Variables:
    ;   EAX - LEFT address (Same as TEMP array address)
    ;   EBX - RIGHT address (Same as LEFT 'STOP') 
    ;   ECX - lEFT 'STOP' (address past final LEFT address) 
    ;   EDX - RIGHT 'STOP' (address past final RIGHT address)
    ;   ESI - General Purpose
    ;   EDI - Destination address (array to be sorted)

_MergeLoop:
    ; Check if 'STOP' has been reached for LEFT or RIGHT
    CMP     EBX, EDX                
    JAE     _AddRemainingLeft
    CMP     EAX, ECX                
    JAE     _AddRemainingRight

    ; Compare and add lesser value
    MOV     ESI, [EBX]
    CMP     [EAX], ESI
    JBE      _AddLeft
_AddRight:
    MOV     ESI, [EBX]
    MOV     [EDI], ESI
    ADD     EBX, 4
    ADD     EDI, 4
    JMP     _MergeLoop
_AddLeft:
    MOV     ESI, [EAX]
    MOV     [EDI], ESI
    ADD     EAX, 4
    ADD     EDI, 4
    JMP     _MergeLoop

    ; Add remaining values
_AddRemainingRight:
    CMP     EBX, EDX
    JAE     _AddRemainingLeft
    MOV     ESI, [EBX]
    MOV     [EDI], ESI
    ADD     EBX, 4
    ADD     EDI, 4
    JMP     _AddRemainingRight
_AddRemainingLeft:
    CMP     EAX, ECX                
    JAE     _ExitProcedure
    MOV     ESI, [EAX]
    MOV     [EDI], ESI
    ADD     EAX, 4
    ADD     EDI, 4
    JMP     _AddRemainingLeft

_ExitProcedure:
    ; Restore Registers and base pointer
    POPAD
    POP     EBP
	RET     12
sortList ENDP


; displayMedian {parameters: someTitle (reference, input), someArray (reference, input)} 
; NOTE: ARRAYSIZE will likely be used as a global within this procedure.
; ---------------------------------------------------------------------------------
; Name: displayMedian
; 
; Calculates and displays the median value of an array. For an array with an odd 
; number of elements, it displays the middle element. For an array with an even 
; number of elements, it calculates the average of the two middle elements, rounding 
; up if there is a remainder.
;
; Preconditions: Input array must be sorted.
;
; Postconditions: None.
;
; Receives: 
;       [ebp+12]  =   address of the array to find the median of (reference, input)
;       [ebp+8]   =   address of the title to print (reference, input)
;
; Returns: None.
;  ---------------------------------------------------------------------------------
displayMedian PROC
    ; Establish base pointer and preserve registers
    PUSH    EBP                 
	MOV     EBP, ESP                    
    PUSHAD

    ; Print title
    MOV     EDX, [EBP+8]
    CALL    WriteString

    ; ----------------------- FIND FIRST MIDDLE ELEMENT ----------------------------

    ; Initialize array and size
    MOV     EAX, ARRAYSIZE
    MOV     ESI, [EBP+12]

    ; Calculation; Divide arraysize by 2
    MOV     EBX, 2
    MOV     EDX, 0      ; DIV 32bit preconditions:  EDX:EAX - dividend. reg32/mem32 - divisor
	DIV		EBX			; DIV 32bit postconditions: EAX - quotient. EDX - remainder
    MOV     ECX, EDX    ; Store remainder

    ; Calculate offset from array address of first middle element
    MOV     EBX, 4
    MUL     EBX         ; EAX - ARRAYSIZE//2 = Median Index for odd array >
    ADD     ESI, EAX    ; Store first middle element address

    ; Determine if ARRAYSIZE is even or odd
	cmp		ECX, 0		
    JE      _EvenArray

    ; ------------------- ODD ARRAY: FIRST MIDDLE == MEDIAN -----------------------

_OddArray:
    MOV     EAX, [ESI]
    CALL    WriteDec
    JMP     _End

    ; --------------------- EVEN ARRAY: FIND SECOND MIDDLE ------------------------

_EvenArray:
    ; Check if arraysize is equal to 2
    CMP     ESI, [EBP+12]
    JNE     _ArraySizeGreaterThanTwo
    ; If array size == 2; add array[0] to array[1]
    MOV     EAX, [ESI]
    ADD     EAX, [ESI + 4]
    JMP     _DivideSumOfMiddles

    ; Add first middle element to second middle element
_ArraySizeGreaterThanTwo:
    MOV     EAX, [ESI]
    ADD     EAX, [ESI - 4]
    ; Divide sum by 2 to calculate median
_DivideSumOfMiddles:
    MOV     EBX, 2
    MOV     EDX, 0      ; DIV 32bit preconditions:  EDX:EAX - dividend. reg32/mem32 - divisor
	DIV		EBX			; DIV 32bit postconditions: EAX - quotient. EDX - remainder
    ; Check for rounding: Check if there remainer is == 0
    CMP     EDX, 0
    JE      _NoRounding

_RoundingUp:
    INC     EAX
_NoRounding:
    ; Print Median
    CALL    WriteDec

_End:
    CALL    Crlf
    ; Restore Registers and base pointer
    POPAD
    POP     EBP     
	RET     8
displayMedian ENDP


; displayList {parameters: someTitle (reference, input), 
; someArray (reference, input), arrayLength (value, input)}
; ---------------------------------------------------------------------------------
; Name: displayList
; 
; Displays a title and the contents of an array in a formatted manner.
;
; Preconditions: 
;       The length parameter [ebp+16] should match the number of elements in the array.
;   
; Postconditions: None.
;
; Receives: 
;       [ebp+16]  =   length of array  (value, input)
;       [ebp+12]  =   address of array (reference, input)
;       [ebp+8]   =   address of title (reference, input)
;
; Returns: None.
;  ---------------------------------------------------------------------------------
displayList PROC
    ; Establish base pointer and preserve registers
    PUSH    EBP                 
	MOV     EBP, ESP            
    PUSHAD

    ; -------------------- NORMAL PRINT (NON-EXTRA-CREDIT) ------------------------

    COMMENT ! 
    ; Print title
    MOV     EDX, [EBP+8]
    CALL    WriteString
    ; Print array
    MOV     ECX, [EBP+16]
    MOV     ESI, [EBP+12]
_NewLine:
    MOV     EDX, 0              ; Count of numbers per line
    CALL    Crlf
_PrintArrayLoop:
    ; Check if new line needs to be printed
    CMP     EDX, 20
    JE      _NewLine
    ; Print current number
    MOV     EAX, [ESI]
    CALL    WriteDec
    MOV     AL, 32              ; Print space; '32' in Ascii
    CALL    WriteChar
    ADD     ESI, 4              ; Increment ESI to the next item's address
    INC     EDX                 ; Increment count of numbers on current line
    LOOP    _PrintArrayLoop
    CALL    Crlf
    !

    ; --------------------------- **EC PRINT STYLE --------------------------------

    ; **EC: Display the numbers ordered by column instead of by row. 
    ; These numbers should still be printed 20-per-row, filling the
    ; first row before printing the second row. (1pt)

    ; Print title
    MOV     EDX, [EBP+8]
    CALL    WriteString
    CALL    Crlf
    
    ; ------------------------------- VARIABLES -----------------------------------
    
    ; Find number of rows (length of array // 20)
    MOV     EAX, [EBP+16]       ; length of array
    MOV     EBX, 20             ; row size
    MOV     EDX, 0              ; DIV precondition: EDX:EAX - Dividend
    DIV     EBX                 ; DIV 32bit Postcondition: EAX - Quotient, EDX - Remainder

    ; Increment row size and remainder if there is a remainder
    CMP     EDX, 0
    JE      _VariablesSetup
    INC     EAX
    INC     EDX

    ; If remainder (+1) == row size, bypass special print logic by setting remainder to 0
    CMP     EDX, EBX
    JNE     _VariablesSetup
    MOV     EDX, 0

_VariablesSetup:
    ; Stack variables:
    PUSH    EDX                 ; [ESP+12] number of elements in final row + 1
    PUSH    EAX                 ; [ESP+8]  number of rows / prev column length
    PUSH    0                   ; [ESP+4]  row count
    PUSH    0                   ; [ESP]    column count
    ; Register variables:
    MOV     ECX, [EBP+16]       ; ECX - length of array
    MOV     ESI, [EBP+12]       ; ESI - address of array

    ; ------------------------------- PRINTING ------------------------------------

_PrintLoop:
    ; Check if end of row has been reached
    MOV     EAX, [ESP]
    CMP     EAX, 20
    JB      _CheckColumnLength
    CALL    Crlf
    ; reset column count
    MOV     EAX, 0
    MOV     [ESP], EAX    
    ; Increment row count
    MOV     EAX, [ESP+4]
    INC     EAX
    MOV     [ESP+4], EAX 
    ; Set index to row count
    MOV     EAX, [ESP+4]
    MOV     EBX, 4
    MUL     EBX
    MOV     ESI, [EBP+12]       ; reset index pointer to 0
    ADD     ESI, EAX            ; add row count * 4 to index 0
    ; Increment rows
    MOV     EAX, [ESP+12]
    CMP     EAX, 0
    JE      _CheckColumnLength
    MOV     EAX, [ESP+8]
    INC     EAX
    MOV     [ESP+8], EAX

_CheckColumnLength:
    ; Check if previous two columns were different lengths
    MOV     EAX, [ESP+12]
    CMP     EAX, 0              ; Skip check if no remainder / remainder+1 == 20
    JE      _FindIndex
    MOV     EAX, [ESP]
    CMP     EAX, [ESP+12]       ; Check if prev 2 columns were different lengths
    JNE     _FindIndex
    MOV     EAX, [ESP+8]
    DEC     EAX
    MOV     [ESP+8], EAX

_FindIndex:
    MOV     EAX, [ESP]
    CMP     EAX, 0             ; If index > 0, add rows to index
    JE      _Print
    MOV     EAX, [ESP+8]
    MOV     EBX, 4
    MUL     EBX
    ADD     ESI, EAX

_Print:
    MOV     EAX, [ESI]
    CALL    WriteDec
    MOV     AL, 32              ; Print space
    CALL    WriteChar
    MOV     EAX, [ESP]
    INC     EAX
    MOV     [ESP], EAX          ; Increment column counter

    ; Check if all elements have been printed
    DEC     ECX
    CMP     ECX, 0
    JA     _PrintLoop
    CALL    Crlf

    ; Remove last four pushed DWORDS from stack
    ADD     ESP, 16           

    ; ------------------------- END OF EC PRINT STYLE ------------------------------
  
    ; Restore base pointer and restore registers
    POPAD
    POP     EBP                 
	RET     12
displayList ENDP


; countList {parameters: someArray1 (reference, input), someArray2 (reference, output)} 
; NOTE: LO, HI, and ARRAYSIZE will be used as globals within this procedure.
; ---------------------------------------------------------------------------------
; Name: countList
; 
; Counts the occurrences of each integer within a specified range (from LO to HI) 
; in the array to count then stores these counts in another array. 
; Each index in the 'counts' array corresponds to an integer in the range.
;
; Preconditions: 'array to count' must be sorted in ascending order.
;
; Postconditions: The 'counts' array now contains the frequency of each integer 
;                 in the 'array to count' within the range from LO to HI.
;
; Receives: 
;       [ebp+12]  =   address of 'counts' array (reference, output)
;       [ebp+8]   =   address of array to count (reference, input)
;
; Returns: None.
;  ---------------------------------------------------------------------------------
countList PROC
    ; Establish base pointer 
    PUSH    EBP                 
	MOV     EBP, ESP            
    ; Preserve registers
    PUSH    ESI                 
    PUSH    EDI
    PUSH    EDX
    PUSH    ECX
    PUSH    EBX
    PUSH    EAX

    ; Calculate array to count's 'STOP' address (address after final array element's address)
    MOV     ESI, [EBP+8]
    MOV     EDX, ARRAYSIZE
    MOV     EAX, 4
    MUL     EDX
    ADD     EAX, ESI

    ; Initialize variables
    MOV     EDX, EAX        ; 'STOP' address of array to count
    MOV     EDI, [EBP+12]   ; Current 'counts' array element address
    MOV     ESI, [EBP+8]    ; Current array element's effective address
    MOV     EBX, LO         ; Current value to count (runs from LO to HI)
    MOV     ECX, 0          ; Count of current value

_CountLoop:
    ; Check if end of array has been reached
    CMP     ESI, EDX
    JAE     _AddValue
    ; Check for a matching value
    CMP     [ESI], EBX
    JNE     _AddValue
    ; Add to count (match found)
    INC     ECX
    ADD     ESI, 4
    JMP     _CountLoop

_AddValue:
    ; Store and reset count
    MOV     [EDI], ECX
    MOV     ECX, 0
    ADD     EDI, 4
    ; Set EBX to next value to count
    INC     EBX
    ; Check if final value has been counted (HI)
    CMP     EBX, HI
    JA      _End
    JMP     _CountLoop

_End:
    ; Restore registers
    POP     EAX
    POP     EBX
    POP     ECX
    POP     EDX
    POP     EDI
    POP     ESI
    ; Restore base pointer
    POP     EBP                 
	RET     8
countList ENDP


END main
