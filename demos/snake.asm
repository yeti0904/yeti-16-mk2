; Snake for YETI-16
; Written by yeti0904
;
; Still WIP, currently isn't playable at all

; Consts
define paletteSize 48 ; 16 * 3
define keySpace    329
define keyUp       335
define keyDown     336
define keyLeft     337
define keyRight    338
define screenSize  800 ; 20*20*2
define snakeUp     0
define snakeDown   1
define snakeLeft   2
define snakeRight  3

; Initialise text mode
ldsi a 2 ; Graphics controller
ldsi b 0 ; Change graphics mode
out a b
ldsi b 0x13 ; 20x20 text mode
out a b
ldsi b 0x01 ; Load font
out a b

; Load palette
cpp sr bs
ldi a palette
addp sr a ; Pointer to palette now is in `sr`
lda ds 0x000404 ; Palette address
ldsi c paletteSize
load_palette_loop:
	rdb a sr
	wrb ds a
	incp sr
	incp ds
	dec c
	jnzb load_palette_loop

; Initialise keyboard
ldsi a 1    ; Keyboard
ldsi b 0x02 ; Enable keyboard events
out a b

; Render title screen
cpp sr bs
ldi a app_title
addp sr a
lda ds 3254
ldsi a 0x01
callb print_str ; Draw "S N A K E"
cpp sr bs
ldi a app_instructions
addp sr a
lda ds 3412
ldsi a 0x01
callb print_str ; Draw "Press space"

; Load graphics controller interrupt
cpp ds bs
ldi a title_screen
addp ds a ; Pointer to title_screen now in DS
lda sr 0x000084 ; Interrupt 0x20
ldsi a 1
wrb sr a ; Enable interrupt 0x20
incp sr
wra sr ds ; Write call address to interrupt
ldsi a 2 ; Graphics controller
ldsi b 0x03 ; Set draw interrupt
out a b
ldsi b 0x20
out a b
jmpb end

title_screen:
	; Check keyboard events
	ldsi a 1 ; Keyboard
	chk a
	jnzb .end

	in b a
	ldsi a 0x01 ; Key down
	cmp a b
	jnzb .ignore_event
	ldsi a 1
	in b a
	ldi a keySpace
	cmp a b ; Is key space?
	jnzb .end

	; Key is space, set draw interrupt to game
	cpp ds bs
	ldi a game
	addp ds a ; pointer to game in DS
	lda sr 0x000085 ; interrupt 0x20
	wra sr ds
	jmpb .end

	.ignore_event:
		in b a

	.end:
		ret

game:
	; Update ticks
	cpp ds bs
	ldi a ticks
	addp ds a
	rdb a ds
	inc a
	wrb ds a

	; Clear screen
	lda ds 0x000C34
	ldi c screenSize
	ldsi a 0

	.clear_loop:
		wrb ds a
		incp ds
		dec c
		jnzb .clear_loop

	; Update snake
	cpp ds bs
	ldi a ticks
	addp ds a
	rdb a ds
	ldsi b 15
	mod a b ; Should snake move in this frame?
	jnzb .input

	; Snake is moving in this frame
	cpp ds bs
	ldi a snake_dir
	addp ds a
	rdb a ds ; Snake direction in A

	ldsi b snakeUp
	cmp a b
	jzb .move_up

	ldsi b snakeDown
	cmp a b
	jzb .move_down

	ldsi b snakeLeft
	cmp a b
	jzb .move_left

	ldsi b snakeRight
	cmp a b
	jzb .move_right

	.move_up:
		cpp ds bs
		ldi a snake_y
		addp ds a
		rdb a ds
		dec a
		wrb ds a
		jmpb .input

	.move_down:
		cpp ds bs
		ldi a snake_y
		addp ds a
		rdb a ds
		inc a
		wrb ds a
		jmpb .input

	.move_left:
		cpp ds bs
		ldi a snake_x
		addp ds a
		rdb a ds
		dec a
		wrb ds a
		jmpb .input

	.move_right:
		cpp ds bs
		ldi a snake_x
		addp ds a
		rdb a ds
		inc a
		wrb ds a

	.input:
		ldsi a 1 ; Keyboard
		chk a
		jnzb .render_snake
		in b a
		ldsi c 0x01 ; Key down event
		cmp b c
		jnzb .ignore_key
		in b a ; Key code in B

		cpp ds bs
		ldi a snake_dir
		addp ds a

		ldi a keyUp
		cmp b a
		jzb .dir_up

		ldi a keyDown
		cmp b a
		jzb .dir_down

		ldi a keyLeft
		cmp b a
		jzb .dir_left

		ldi a keyRight
		cmp b a
		jzb .dir_right

	.dir_up:
		ldsi b snakeUp
		wrb ds b
		jmpb .render_snake

	.dir_down:
		ldsi b snakeDown
		wrb ds b
		jmpb .render_snake

	.dir_left:
		ldsi b snakeLeft
		wrb ds b
		jmpb .render_snake

	.dir_right:
		ldsi b snakeRight
		wrb ds b
		jmpb .render_snake

	.ignore_key:
		in b a

	.render_snake:
		cpp ds bs
		ldi a snake_x
		addp ds a
		rdb g ds ; Snake X in G
		cpp ds bs
		ldi a snake_y
		addp ds a
		rdb h ds ; Snake Y in H

		ldsi a 20
		mul h a
		add h g
		ldsi a 2
		mul h a ; Offset now in H
		lda ds 0x000C34 ; VRAM
		addp ds h
		ldsi a 0x02
		wrb ds a
		incp ds
		ldsi a 79 ; 'O'
		wrb ds a

	.end:
		ret

end:
	jmpb end

; Util functions
print_str:
	; Parameters
	; SR = string
	; DS = where to print
	; A  = attribute
	push b
.loop:
	rdb b sr
	jzb .end
	wrb ds a
	incp ds
	wrb ds b
	incp sr
	incp ds
	jmpb .loop
.end:
	pop b
	ret

; Palette
palette:
	; 0
	db 0x00 0x00 0x00 ; Background colour
	; 1
	db 0xFF 0xFF 0xFF ; Logo text colour
	; 2
	db 0x00 0xFF 0x00 ; Snake head
	; 3
	db 0x00 0x00 0x00
	; 4
	db 0x00 0x00 0x00
	; 5
	db 0x00 0x00 0x00
	; 6
	db 0x00 0x00 0x00
	; 7
	db 0x00 0x00 0x00
	; 8
	db 0x00 0x00 0x00
	; 9
	db 0x00 0x00 0x00
	; A
	db 0x00 0x00 0x00
	; B
	db 0x00 0x00 0x00
	; C
	db 0x00 0x00 0x00
	; D
	db 0x00 0x00 0x00
	; E
	db 0x00 0x00 0x00
	; F
	db 0x00 0x00 0x00

; Strings
app_title:
	db "S N A K E" 0
app_instructions:
	db "Press space" 0

; Variables
snake_x:
	db 0
snake_y:
	db 0
snake_dir:
	db snakeRight
ticks:
	db 0