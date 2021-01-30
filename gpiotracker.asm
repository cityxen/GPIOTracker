//////////////////////////////////////////////////////////////////////////
// GPIO Tracker
//
// Machine: Commodore 64
// Version: 1
// Author: Deadline
//
// 2020-21 CityXen
//
// As seen on our youtube channel:
// https://www.youtube.com/CityXen
// 
// Assembly files are for use with KickAssembler
// http://theweb.dk/KickAssembler
//
// Notes: If you're going to attempt to compile this, you'll
// need the Macros and Constants from this repo:
// https://github.com/cityxen/Commodore64_Programming
//
// How To setup KickAssembler in Windows 10:
// https://www.youtube.com/watch?v=R9VE2U_p060
//
//////////////////////////////////////////////////////////////////////////

.segment Code []
.file [name="gpiotracker.prg",segments="Code,Main,Dorktronic"]
.disk [filename="gpiotracker.d64", name="GPIOTRACKER", id="CXN20" ]  {
        [name="GPIOTRACKER", type="prg",  segments="Code,Dorktronic,Main"],
        [name="I2C.ML", type="prg", segments="Dorktronic"]
}

#import "Constants.asm"
#import "Macros.asm"
#import "DrawPetMateScreen.asm"
#import "gpiotracker-vars.asm"
#import "i2c_symbols.asm"

*=$3000 "customfont"
#import "gpiotracker-charset.asm"
*=$3800 "screendata"
#import "gpiotracker-screen.asm"

*=$2000 "Cursor Sprite"
#import "sprite-cursor.asm"

.segment Dorktronic [outPrg="i2c.ml.prg"]
*=$2d00 "dorktronic i2c"
.import binary "i2c.ml"

.segment Main []

//////////////////////////////////////////////////////////
// START OF PROGRAM
*=$0801 "BASIC"
    BasicUpstart($080d)
*=$080d "Program"

//     jsr new_data

/*
    // Initialize the Dorktronic GPIO device
    // jsr I2C_INIT
    lda #$00 // IODIRA
    ldx #$40 // set port a-b
    ldy #$00 // output
    jsr I2C_I2C_OUT

    lda #$01 // IODIRB
    ldx #$40 // set port a-b
    ldy #$00 // output
    jsr I2C_I2C_OUT

    lda #$00 // IODIRA
    ldx #$42 // set port c-d
    ldy #$00 // output
    jsr I2C_I2C_OUT

    lda #$01 // IODIRB
    ldx #$42 // set port c-d
    ldy #$00 // output
    jsr I2C_I2C_OUT    
*/
    lda VIC_MEM_POINTERS // point to the new characters
    ora #$0c
    sta VIC_MEM_POINTERS
    jsr initialize
    jsr draw_screen    
    jsr sprite_init
    jmp mainloop

//////////////////////////////////////////////////////////
// START OF MAIN LOOP
mainloop:
    lda JOYSTICK_PORT_2
    jsr sub_read_joystick_2_fire // read joystick data
    jsr joystick_control_mode_check // Joystick Control Mode
    jsr playback // Playback if it is on
    jsr draw_playback_status // Draw Playback Status
    jsr sprite_cursor_blink

//////////////////////////////////////////////////////////
// Check Keyboard Input
    jsr KERNAL_GETIN // CHECK KEYBOARD FOR KEY HITS
//////////////////////////////////////////////////////////
// P (PLAY/PAUSE)
!check_key:
    cmp #KEY_P
    bne !check_key+
    clc
    lda playback_playing
    cmp #$01
    beq !check_key_inner+
    inc playback_playing
    jmp mainloop
!check_key_inner:
    lda #$00
    sta playback_playing
    jmp mainloop
//////////////////////////////////////////////////////////
// $ (Show Directory)
!check_key:
    cmp #KEY_DOLLAR_SIGN
    bne !check_key+
    jsr sprite_hide
    jsr show_directory
    jsr draw_screen
    jsr sprite_init
    jmp mainloop
//////////////////////////////////////////////////////////
// C (Change Command)
!check_key:
    cmp #KEY_C
    bne !check_key+
    jsr change_command
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// D (Change Drive)
!check_key:
    cmp #KEY_D
    bne !check_key+
    jsr change_drive
    jmp mainloop
//////////////////////////////////////////////////
// E (Erase File)
!check_key:
    cmp #KEY_E
    bne !check_key+
    jsr sprite_hide
    jsr erase_file_confirm
    jsr draw_screen
    jsr sprite_init
    jmp mainloop
//////////////////////////////////////////////////
// F (Change Filename)
!check_key:
    cmp #KEY_F
    bne !check_key+
    jsr change_filename
    jmp mainloop
//////////////////////////////////////////////////
// J (Toggle Joystick Control Mode)
!check_key:
    cmp #KEY_J
    bne !check_key+
    clc
    lda joystick_control_mode
    cmp #jcm_max_modes
    beq !check_key_inner+
    inc joystick_control_mode
    jmp !check_key_inner++
!check_key_inner:
    lda #$00
    sta joystick_control_mode
!check_key_inner:
    jsr draw_jcm
    jmp mainloop
//////////////////////////////////////////////////
// L (Load File)
!check_key:
    cmp #KEY_L
    bne !check_key+
    jsr sprite_hide
    jsr load_file
    jsr draw_screen
    jsr sprite_init
    jmp mainloop
//////////////////////////////////////////////////
// N (New Data)
!check_key:
    cmp #KEY_N
    bne !check_key+
    jsr sprite_hide
    jsr new_data_confirm
    jsr draw_screen
    jsr sprite_init
    jmp mainloop
//////////////////////////////////////////////////
// S (Save File)
!check_key:
    cmp #KEY_S
    bne !check_key+
    jsr sprite_hide
    jsr save_file
    jsr draw_screen
    jsr sprite_init
    jmp mainloop
//////////////////////////////////////////////////
// COLON (Change Pattern DOWN)
!check_key:
    cmp #KEY_COLON
    bne !check_key+
    ldx track_block_cursor
    lda track_block,x
    cmp #pattern_min
    beq !check_key_inner+
    dec track_block,x
!check_key_inner:
    jsr refresh_track_blocks
    jsr calculate_pattern_block
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// SEMICOLON (Change Pattern UP)
!check_key:
    cmp #KEY_SEMICOLON
    bne !check_key+
    ldx track_block_cursor
    lda track_block,x
    cmp #pattern_max
    beq !check_key_inner+
    inc track_block,x
!check_key_inner:
    jsr refresh_track_blocks
    jsr calculate_pattern_block
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// MINUS (Turn OFF all relays)
!check_key:
    cmp #KEY_MINUS
    bne !check_key+
    jsr all_relay_off
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// PLUS (Turn ON all relays)
!check_key:
    cmp #KEY_PLUS
    bne !check_key+
    jsr all_relay_on
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// EQUAL (Change Command Value DOWN)
!check_key:
    cmp #KEY_EQUAL
    bne !check_key+
    jsr change_command_data_down
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// ASTERISK (Change Command Value UP)
!check_key:
    cmp #KEY_ASTERISK
    bne !check_key+
    jsr change_command_data_up
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// F1 (Move Track Position UP)
!check_key:
    cmp #KEY_F1
    bne !check_key+
    lda track_block_cursor
    cmp #$00
    beq !check_key_inner+
    dec track_block_cursor
    jsr refresh_track_blocks
    jsr calculate_pattern_block
    jsr refresh_pattern
!check_key_inner:
    jmp mainloop
//////////////////////////////////////////////////
// F2 (Track Length DOWN)
!check_key:
    cmp #KEY_F2
    bne !check_key+
    lda track_block_length
    cmp #$00
    beq !check_key_inner+
    dec track_block_length
    lda track_block_length
    sta track_block_cursor
!check_key_inner:
    lda #$00
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_track_blocks
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// F3 (Move Track Position DOWN)
!check_key:
    cmp #KEY_F3
    bne !check_key+
    lda track_block_cursor
    cmp track_block_length
    beq !check_key_inner+
    inc track_block_cursor
    jsr refresh_track_blocks
    jsr calculate_pattern_block
    jsr refresh_pattern
!check_key_inner:
    jmp mainloop
//////////////////////////////////////////////////
// F4 (Track Length UP)
!check_key:
    cmp #KEY_F4
    bne !check_key+
    lda track_block_length
    cmp #$ff
    beq !check_key_inner+
    inc track_block_length
    lda track_block_length
    sta track_block_cursor
!check_key_inner:
    lda #$00
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_track_blocks
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// F5 (Page UP in current Pattern)
!check_key:
    cmp #KEY_F5
    bne !check_key+
    clc
    lda pattern_cursor
    sbc #$05
    bcs !check_key_inner+
    lda #$00
!check_key_inner:
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// F6
!check_key:
    cmp #KEY_F6
    bne !check_key+
    jmp mainloop
//////////////////////////////////////////////////
// F7 (Page DOWN in current Pattern)
!check_key:
    cmp #KEY_F7
    bne !check_key+
    clc
    lda pattern_cursor
    adc #$05
    bcc !check_key_inner+
    lda #$ff
!check_key_inner:
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// F8
!check_key:
    cmp #KEY_F8
    bne !check_key+
    jmp mainloop
//////////////////////////////////////////////////
// SPACE (Toggle GPIO under sprite cursor)
!check_key:
    cmp #KEY_SPACE
    bne !check_key+
    jsr toggle_gpio_pin_under_cursor
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// Cursor LEFT (Move sprite cursor left)
!check_key:
    cmp #KEY_CURSOR_LEFT
    bne !check_key+
    dec sprite_cursor
    lda sprite_cursor
    cmp #$ff
    bne !check_key_inner+
    lda #$1f
    sta sprite_cursor
!check_key_inner:
    jsr sprite_cursor_move
    jmp mainloop
//////////////////////////////////////////////////
// Cursor RIGHT (Move sprite cursor right)
!check_key:
    cmp #KEY_CURSOR_RIGHT
    bne !check_key+
    inc sprite_cursor
    lda sprite_cursor
    cmp #$20
    bne !check_key_inner+
    lda #$00
    sta sprite_cursor
!check_key_inner:
    jsr sprite_cursor_move
    jmp mainloop
//////////////////////////////////////////////////
// Cursor DOWN (Move down one position in current pattern)
!check_key:
    cmp #KEY_CURSOR_DOWN
    bne !check_key+
    lda pattern_cursor
    cmp #$ff
    beq !check_key_inner+
    inc pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
!check_key_inner:
    jmp mainloop
//////////////////////////////////////////////////
// Cursor UP (Move up one position in current pattern)
!check_key:
    cmp #KEY_CURSOR_UP
    bne !check_key+
    lda pattern_cursor
    cmp #$00
    beq !check_key_inner+
    dec pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
!check_key_inner:
    jmp mainloop
//////////////////////////////////////////////////
// HOME (Move to top position in current pattern)
!check_key:
    cmp #KEY_HOME
    bne !check_key+
    lda #$00
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
    jmp mainloop
//////////////////////////////////////////////////
// CLEAR (Move to end position in current pattern)
!check_key:
    cmp #KEY_CLEAR
    bne !check_key+
    lda #$ff
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
//////////////////////////////////////////////////
// END Check Keys
!check_key:
    jmp mainloop
// END OF MAIN LOOP
////////////////////////////////////////////////////

////////////////////////////////////////////////////
// Joystick Control Mode
joystick_control_mode_check:
    clc
    lda joystick_control_mode
    beq jcm_out
    cmp #$01
    bne !jcm_mode_check+

jcm_1: // MODE 1: PLAY (Playback occurs while fire button is pressed)
    lda jcm_fire_pressed
	beq jcm_1_off
    lda #$01
    sta playback_playing
    rts
jcm_1_off:
    lda #$00
    sta playback_playing
    jmp jcm_out

!jcm_mode_check:
    cmp #$02
    bne jcm_out

jcm_2: // MODE 2: SS (Fire button toggles playback)
    lda jcm_fire_pressed
    bne jcm_out
    lda jcm_fire_released
    bne jcm_out
    lda #$00
    sta jcm_fire_released
    inc playback_playing
    lda playback_playing
    and #$01
    sta playback_playing
    
jcm_out:
    rts

////////////////////////////////////////////////////
// Joystick read data
sub_read_joystick_2_fire:
	lda JOYSTICK_PORT_2
	lsr; lsr; lsr; lsr; lsr
	bcc read_joystick_2_fire
    lda jcm_fire_pressed
    bne !rj2f+
    lda #$01
    sta jcm_fire_released
!rj2f:
    lda #$00
    sta jcm_fire_pressed
	rts
read_joystick_2_fire:
    lda #$00
    sta jcm_fire_released
    lda #$01
    sta jcm_fire_pressed
	rts

////////////////////////////////////////////////////
// Change Command value UP
change_command_data_up:
    jsr calculate_pattern_block
    ldx #$00
    lda (zp_block_cmd,x)
    and #$c0
    sta zp_temp
    lda (zp_block_cmd,x)
    clc
    and #$3f
    sta zp_temp2
    inc zp_temp2
    lda zp_temp2
    clc
    cmp #$40
    bcs !ccdu_j+
    ora zp_temp
    sta (zp_block_cmd,x)
    rts
!ccdu_j:
    lda zp_temp
    sta (zp_block_cmd,x)
    rts

////////////////////////////////////////////////////
// Change Command value DOWN
change_command_data_down:
    jsr calculate_pattern_block
    ldx #$00
    lda (zp_block_cmd,x)
    and #$c0
    sta zp_temp
    lda (zp_block_cmd,x)
    clc
    and #$3f
    sta zp_temp2
    dec zp_temp2
    lda zp_temp2
    clc
    cmp #$ff
    bcs !ccdd_j+
    ora zp_temp
    sta (zp_block_cmd,x)
    rts
!ccdd_j:
    lda zp_temp
    ora #$3F
    sta (zp_block_cmd,x)
    rts

////////////////////////////////////////////////////
// Change Command
change_command:
    jsr calculate_pattern_block
    lda (zp_block_cmd,x)
    clc
    adc #$40
    bcc cc_2
    lda (zp_block_cmd,x)
    and #$3f
cc_2:
    sta (zp_block_cmd,x)
    ldx #$00
    lda (zp_block_cmd,x)
    and #$c0
    cmp #$40
    bne cc_not_speed
    lda (zp_block_cmd,x)
    ora #playback_default_speed
    sta (zp_block_cmd,x)
    rts
cc_not_speed:
    lda (zp_block_cmd,x)
    and #$c0
    sta (zp_block_cmd,x)
    rts

////////////////////////////////////////////////////
// Playback
playback:
    clc
    lda playback_playing
    and #$01
    bne playing
    rts
playing:
    // process command
    jsr calculate_pattern_block
    ldx #$00
    lda (zp_block_cmd,x)
    tax
    and #$c0
    clc
    ror; ror; ror; ror; ror; ror
    cmp #$01
    bne pb_pc_2
    // speed
    txa
    and #$3f
    sta playback_speed
    jmp pb_pc_end
pb_pc_2:
    cmp #$02
    bne pb_pc_3
    // stop
    lda #$00
    sta playback_playing
    jmp pb_pc_end
pb_pc_3:
pb_pc_end:
    
pb_speed_chk:
    inc playback_speed_counter
    clc
    lda playback_speed
    rol
    rol
    cmp playback_speed_counter
    bcc pb_speed_chk3
    rts

pb_speed_chk3:
    lda #$00
    sta playback_speed_counter
    sta playback_speed_counter2    
    clc
    lda playback_pos_pattern_c
    cmp #$ff
    bne pb_ppc_out
    clc
    lda playback_pos_track
    cmp track_block_length
    bne pb_ppt_out
    lda #$ff
    sta playback_pos_track
pb_ppt_out:
    inc playback_pos_track
pb_ppc_out:
    inc playback_pos_pattern_c
    lda playback_pos_track
    sta track_block_cursor
    tax
    lda track_block,x
    sta playback_pos_pattern
    lda playback_pos_pattern_c
    sta pattern_cursor
    jsr calculate_pattern_block
    jsr refresh_pattern
    jsr refresh_track_blocks
    rts

////////////////////////////////////////////////////
// Initialize
initialize:  
    lda #08     // Set drive
    sta drive   //           to 8
    lda #$ff    // Set all DATA Direction
    sta USER_PORT_DATA_DIR // on user port
    ldx #00     // Store initial_filename in filename_buffer
init_fn_loop:
    lda initial_filename,x
    sta filename_buffer,x
    inx
    cpx #$10
    bne init_fn_loop
    jsr convert_filename
    ldx filename_length
    stx filename_cursor
    lda #track_block_cursor_init // Set Track block cursor to 0
    sta track_block_cursor
    lda #pattern_cursor_init    // Set Pattern cursor to 0
    sta pattern_cursor
    lda #$00
    sta track_block_length
    jsr calculate_pattern_block
    lda #$00
    sta joystick_control_mode
    sta playback_pos_track
    sta playback_pos_pattern
    sta playback_pos_pattern_c
    sta playback_playing
    lda #playback_default_speed
    sta playback_speed
    lda #$00
    sta playback_speed_counter
    ldx #$00
    ldy #$00
!fill_data:
    lda initial_gpio_settings,x
    sta $4200,y
    inx
    lda initial_gpio_settings,x
    sta $4300,y
    inx
    lda initial_gpio_settings,x
    sta $4400,y
    inx
    lda initial_gpio_settings,x
    sta $4500,y
    inx
    lda initial_gpio_settings,x
    sta $4600,y
    iny
    inx
    cpy #$0a
    bne !fill_data-

    rts

initial_filename:
.text "filename.gtd"
.byte 0,0,0,0

initial_gpio_settings:
.byte %00000000,%00000000,%00000000,%00000000,%01000111
.byte %00000000,%00000000,%00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000,%00000000,%00000000
.byte %00111100,%01100110,%01000100,%00011000,%00000000
.byte %01100110,%01100110,%01100110,%00011000,%00000000
.byte %01100000,%00111100,%01110110,%00011000,%00000000
.byte %01100000,%00011000,%01101110,%00011000,%00000000
.byte %01100000,%00111100,%01100110,%00011000,%00000000
.byte %01100110,%01100110,%01100110,%00000000,%00000000
.byte %00111100,%01100110,%01100110,%00011000,%00000000
.byte %00000000,%00000000,%00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000,%00000000,%00000000

////////////////////////////////////////////////////
// New Data
new_data_confirm:
    jsr draw_confirm_question
ndc_loop2:
    jsr KERNAL_GETIN
    cmp #$00
    beq ndc_loop2
ndc_check_y_hit: // Y (Yes New Memory)
    cmp #$59
    beq new_data
    jsr draw_screen
    rts
new_data:
    pha
    lda #$00
    sta zp_block1_lo
    lda #tracker_data_start_hi
    sta zp_block1_hi
    ldx #$00
clrloop:
    txa
    pha
    ldx #$00
    ldy #$00
    lda zp_block1_hi
    sta BACKGROUND_COLOR
    jsr print_hex
    ldx #$00
    ldy #$00
    lda zp_block1_lo
    sta BORDER_COLOR
    jsr print_hex    
    pla
    tax
    lda #$00
    sta (zp_block1,x)
    inc zp_block1_lo
    lda zp_block1_lo
    cmp #$00
    bne clrloop
    inc zp_block1_hi
    lda zp_block1_hi
    cmp #tracker_data_end_hi
    bne clrloop
    pla
    rts

////////////////////////////////////////////////////
// Draw Confirm Question
draw_confirm_question:
    ldy #$02
    ldx #$00
ndc_loop:
    lda confirm_text,x
    sta SCREEN_RAM+12+11*40,x
    tya
    sta COLOR_RAM+12+11*40,x
    lda confirm_text+15,x
    sta SCREEN_RAM+12+12*40,x
    tya
    sta COLOR_RAM+12+12*40,x
    lda confirm_text+30,x
    sta SCREEN_RAM+12+13*40,x
    tya
    sta COLOR_RAM+12+13*40,x
    inx
    cpx #15
    bne ndc_loop
    rts

confirm_text:
.byte 079,119,119,119,119,119,119,119,119,119,119,119,119,119,080
.byte 101,001,018,005,032,025,015,021,032,019,021,018,005,063,103
.byte 076,111,111,111,111,111,111,111,111,111,111,111,111,111,122

////////////////////////////////////////////////////
// Draw Playback Status
draw_playback_status:
    ldx playback_playing
    lda playback_text,x
    sta SCREEN_RAM+23+1*40 // draw playback_playing
    ldx #24
    ldy #01
    lda playback_pos_track
    jsr print_hex // draw track pos
    ldx #26
    ldy #01    
    lda playback_pos_pattern
    jsr print_hex // draw pattern pos
    ldx #28
    ldy #01
    lda playback_pos_pattern_c
    jsr print_hex // draw pattern cursor
    ldx #32
    ldy #01
    lda playback_speed
    jsr print_hex // draw playback speed    
    rts

playback_text:
.byte 05,16

////////////////////////////////////////////////////
// Draw Screen
draw_screen:
    DrawPetMateScreen(screen_gpio_tracker)
    ldx #$00    // Draw the filename onto the screen
ds_fn_loop:
    lda filename_buffer,x
    cmp #$00
    bne ds_fn_2
    lda #$20
ds_fn_2:
    sta filename,x
    lda #$01
    sta filename_color,x
    inx
    cpx #$10
    bne ds_fn_loop
    jsr show_drive  // Draw the drive onto the screen
    jsr refresh_track_blocks // Update track blocks
    jsr calculate_pattern_block
    jsr refresh_pattern // Update pattern
    jsr draw_jcm

    rts

////////////////////////////////////////////////////
// Draw Relays Macro
drawgpio:
    stx zp_temp
    sty zp_temp2
    jsr calculate_screen_pos // zp_ptr_screen // screen location
    ldx zp_temp
    ldy zp_temp2
    jsr calculate_color_pos // zp_ptr_color // screen location
    //////////////////////////////////////////////////
    // BLOCK 1 (First 8 bits)
    ldx #$00; lda (zp_block1,x) // get first block of gpio data
    jsr drawgpio_block
    //////////////////////////////////////////////////
    // BLOCK 2 (Next 8 bits)
    ldx #$00; lda (zp_block2,x) // get next block of gpio data
    jsr drawgpio_block 
    //////////////////////////////////////////////////
    // BLOCK 3 (Next 8 bits)
    ldx #$00; lda (zp_block3,x) // get next block of gpio data
    jsr drawgpio_block
    //////////////////////////////////////////////////
    // BLOCK 4 (Next 8 bits)
    ldx #$00; lda (zp_block4,x) // get next block of gpio data
    jsr drawgpio_block
    rts

drawgpio_block:
    sta zp_temp
    ldy #$08
!dgpb:
    lda zp_temp
    clc
    asl
    sta zp_temp
    bcs !dgpb+
    lda #gpio_off
    ldx #$00
    sta (zp_ptr_screen,x)
    lda #gpio_off_color
    ldx #$00
    sta (zp_ptr_color,x)
    jmp !dgpb++
!dgpb:
    lda #gpio_on
    ldx #$00
    sta (zp_ptr_screen,x)
    lda #gpio_on_color
    ldx #$00
    sta (zp_ptr_color,x)
!dgpb:
    jsr increment_screen_pos
    jsr increment_color_pos
    dey
    bne !dgpb---
    rts

////////////////////////////////////////////////////
// Refresh Joystick Control Mode
refresh_jcm:
draw_jcm:
    // 0 = OFF: off
    // 1 = PLAY MODE: Playback occurs while fire button pressed
    // 2 = SS MODE: Playback toggled with fire button
    // 2 = FREESTYLE MODE: Joystick directions toggle relays 1-4 directions + button toggle relays 5-8
    // 3 = TRACKER MODE: Joystick UP and DOWN control play of tracker
    // 4 = EDIT
    clc
    lda joystick_control_mode
    cmp #$00
    beq jcm_is_zero
    lda joystick_control_mode
    clc
    rol
    rol
jcm_is_zero:
    tax
    lda jcm_modes_text,x
    sta SCREEN_RAM+36+1*40
    inx
    lda jcm_modes_text,x
    sta SCREEN_RAM+1+36+1*40
    inx
    lda jcm_modes_text,x
    sta SCREEN_RAM+2+36+1*40
    inx
    lda jcm_modes_text,x
    sta SCREEN_RAM+3+36+1*40
    rts

jcm_modes_text:
.text "off "
.text "play"
.text "ss  "
.text "trak"
.text "edit"

////////////////////////////////////////////////////
// Clear Pattern Line Macro line stored in y
clear_pattern_line:
    ldx #$00
    jsr calculate_screen_pos
    lda #$20
    ldx #$00
    ldy #$00
!cpl_loop:
    sta (zp_ptr_screen_lo,x)
    inc zp_ptr_screen_lo
    bne !cpl_loop+
    inc zp_ptr_screen_hi
!cpl_loop:
    iny
    cpy #$28
    bne !cpl_loop--
    rts

////////////////////////////////////////////////////
// Draw Command Macro

drawcommand: // x=xpos, y=ypos
    jsr calculate_screen_pos    
    ldx #$00
    lda (zp_block_cmd,x)
    and #%11000000
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    tax
    lda command,x
    ldx #$00
    sta (zp_ptr_screen,x)
    ldx #$00
    inc zp_ptr_screen_lo
    lda (zp_block_cmd,x)
    and #%00111111
    jsr print_hex_no_calc
    rts

command: // none
.text "-"
command_speed:
.text "s"
command_stop:
.byte $4e
command_future:
.text "f"

////////////////////////////////////////////////////
// Set the GPIO pins according to pattern cursor
dorktronic_set_gpio:
    // TODO: Set GPIO
    // jsr I2C_I2C_OUT

    //       A = I2C REGISTER NUMBER
    //       X = I2C DEVICE NUMBER.  FOR C=GPIO USE $40 FOR PORTA-B, $42 FOR PORTC-D
    //       Y = DATA BYTE TO SEND




rts

////////////////////////////////////////////////////
// Refresh Pattern
refresh_pattern:
    jsr dorktronic_set_gpio
    jsr calculate_pattern_block
rp_v1:    
    lda pattern_cursor
    clv
    sec
    sbc #$06
    bcs rp_v1_2
    ldy #11
    jsr clear_pattern_line
    jmp rp_v2
rp_v1_2:
    ldx #00
    ldy #11
    jsr print_hex
    lda pattern_cursor
    clv
    sec
    sbc #$06
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #11
    jsr drawgpio
    ldx #36
    ldy #11
    jsr drawcommand
    
rp_v2:
    lda pattern_cursor
    clv
    sec
    sbc #$05
    bcs rp_v2_2
    ldy #12
    jsr clear_pattern_line
    jmp rp_v3
rp_v2_2:
    ldx #00
    ldy #12
    jsr print_hex
    lda pattern_cursor
    clv
    sec
    sbc #$05
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #12
    jsr drawgpio
    ldx #36
    ldy #12
    jsr drawcommand

rp_v3:
    lda pattern_cursor
    clv
    sec
    sbc #$04
    bcs rp_v3_2
    ldy #13
    jsr clear_pattern_line
    jmp rp_v4
rp_v3_2:
    ldx #00
    ldy #13
    jsr print_hex
    lda pattern_cursor
    clv
    sec
    sbc #$04
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #13
    jsr drawgpio
    ldx #36
    ldy #13
    jsr drawcommand

rp_v4:
    lda pattern_cursor
    clv
    sec
    sbc #$03
    bcs rp_v4_2
    ldy #14
    jsr clear_pattern_line
    jmp rp_v5
rp_v4_2:
    ldx #00
    ldy #14
    jsr print_hex
    lda pattern_cursor
    clv
    sec
    sbc #$03
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #14
    jsr drawgpio
    ldx #36
    ldy #14
    jsr drawcommand

rp_v5:
    lda pattern_cursor
    clv
    sec
    sbc #$02
    bcs rp_v5_2
    ldy #15
    jsr clear_pattern_line
    jmp rp_v6
rp_v5_2:
    ldx #00
    ldy #15
    jsr print_hex
    lda pattern_cursor
    clv
    sec
    sbc #$02
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #15
    jsr drawgpio
    ldx #36
    ldy #15
    jsr drawcommand

rp_v6:
    lda pattern_cursor
    clv
    sec
    sbc #$01
    bcs rp_v6_2
    ldx #$00
    ldy #16
    jsr clear_pattern_line
    jmp rp_v7
rp_v6_2:
    ldx #00
    ldy #16
    jsr print_hex
    lda pattern_cursor
    clv
    sec
    sbc #$01
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #16
    jsr drawgpio
    ldx #36
    ldy #16
    jsr drawcommand

rp_v7:
    lda pattern_cursor
    ldx #00
    ldy #17
    jsr print_hex
    lda pattern_cursor
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #17
    jsr drawgpio
    lda pattern_cursor
    jsr set_pattern_block_zptrs
    ldx #36
    ldy #17
    jsr drawcommand
rp_v8:
    lda pattern_cursor
    clc
    adc #$01
    bcc rp_v8_2
    ldy #18
    jsr clear_pattern_line
    jmp rp_v9
rp_v8_2:
    ldx #00
    ldy #18
    jsr print_hex
    lda pattern_cursor
    clc
    adc #$01
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #18
    jsr drawgpio
    ldx #36
    ldy #18
    jsr drawcommand

rp_v9:
    lda pattern_cursor
    clc
    adc #$02
    bcc rp_v9_2
    ldy #19
    jsr clear_pattern_line
    jmp rp_v10
rp_v9_2:
    ldx #00
    ldy #19
    jsr print_hex
    lda pattern_cursor
    clc
    adc #$02
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #19
    jsr drawgpio
    ldx #36
    ldy #19
    jsr drawcommand

rp_v10:
    lda pattern_cursor
    clc
    adc #$03
    bcc rp_v10_2
    ldy #20
    jsr clear_pattern_line
    jmp rp_v11
rp_v10_2:
    ldx #00
    ldy #20
    jsr print_hex
    lda pattern_cursor
    clc
    adc #$03
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #20
    jsr drawgpio
    ldx #36
    ldy #20
    jsr drawcommand

rp_v11:
    lda pattern_cursor
    clc
    adc #$04
    bcc rp_v11_2
    ldy #21
    jsr clear_pattern_line
    jmp rp_v12
rp_v11_2:
    ldx #00
    ldy #21
    jsr print_hex
    lda pattern_cursor
    clc
    adc #$04
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #21
    jsr drawgpio
    ldx #36
    ldy #21
    jsr drawcommand

rp_v12:
    lda pattern_cursor
    clc
    adc #$05
    bcc rp_v12_2
    ldy #22
    jsr clear_pattern_line
    jmp rp_v13
rp_v12_2:
    ldx #00
    ldy #22
    jsr print_hex
    lda pattern_cursor
    clc
    adc #$05
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #22
    jsr drawgpio
    ldx #36
    ldy #22
    jsr drawcommand

rp_v13:
    lda pattern_cursor
    clc
    adc #$06
    bcc rp_v13_2
    ldy #23
    jsr clear_pattern_line
    jmp rp_v14
rp_v13_2:
    ldx #00
    ldy #23
    jsr print_hex
    lda pattern_cursor
    clc
    adc #$06
    jsr set_pattern_block_zptrs
    ldx #03
    ldy #23
    jsr drawgpio
    ldx #36
    ldy #23
    jsr drawcommand
rp_v14:
    rts

////////////////////////////////////////////////////
// Refresh Track Blocks
refresh_track_blocks:
    lda #$20 // Clear Track Blocks Area
    ldx #$00
rtb_loop1:
    sta SCREEN_RAM+3*40,x
    sta SCREEN_RAM+4*40,x
    sta SCREEN_RAM+5*40,x
    inx
    cpx #$07
    bne rtb_loop1
    // Done clearing track blocks area
// track -1
    ldx track_block_cursor
    dex
    cpx #$ff
    beq rtb_skip_top
    lda #58 // put :
    sta SCREEN_RAM+3+3*40
    txa
    ldx #01
    ldy #03
    jsr print_hex // print track -1
    ldx track_block_cursor
    dex
    lda track_block,x
    ldx #04
    ldy #03
    jsr print_hex // print pattern of track -1
rtb_skip_top:
// track 0
    lda #58 // put :
    sta SCREEN_RAM+3+4*40
    lda track_block_cursor
    ldx #01
    ldy #04
    jsr print_hex // print track
    ldx track_block_cursor
    lda track_block,x
    sta zp_temp
    ldx #04
    ldy #04
    jsr print_hex // print pattern in track area
    lda zp_temp
    ldx #16
    ldy #03
    jsr print_hex // print pattern in pattern area
// track +1
    ldx track_block_cursor
    cpx track_block_length
    beq rtb_skip_bot
    lda #58 // put :
    sta SCREEN_RAM+3+5*40
    ldx track_block_cursor
    inx
    txa
    ldx #01
    ldy #05
    jsr print_hex // print track +1
    ldx track_block_cursor
    inx
    lda track_block,x
    ldx #04
    ldy #05
    jsr print_hex // print pattern of track +1
rtb_skip_bot:
    clc
    ldx #$00 // reverse the track cursor location
rtb_rev:
    lda SCREEN_RAM+4*40,x
    adc #$80
    sta SCREEN_RAM+4*40,x
    lda #$01 // and color
    sta COLOR_RAM+4*40,x // it white
    inx
    cpx #$07 // only do 7 characters
    bne rtb_rev
    rts

////////////////////////////////////////////////////
// Change Filename
change_filename:
    ldx #$00 // Reverse the editing area
fn_reverse:
    lda filename,x
    ora #$80
    sta filename,x
    lda #$01
    sta filename_color,x
    inx
    cpx #$10
    bne fn_reverse
fn_kb_chk: // Check Keyboard loop
    clc
    lda $a2
    cmp #$10
    bcc fn_kb_chk_no_crs
    ldx filename_cursor
    lda filename,x
    cmp #$80
    bcs fn_kb_chk_crs_not_revd
    ora #$80
    sta filename,x
    jmp fn_kb_chk_no_crs
fn_kb_chk_crs_not_revd:
    and #$7f
    sta filename,x
fn_kb_chk_no_crs: // End of flash cursor stuff
    ldx filename_cursor
    cpx #$10
    bne fn_kb_not_too_long
    ldx #$0f
    stx filename_cursor
fn_kb_not_too_long:
    jsr KERNAL_GETIN
    cmp #$00
    beq fn_kb_chk
    cmp #13
    beq fn_kb_chk_end
    cmp #20
    bne fn_kb_chk_not_del
    ldx filename_cursor
    cpx #$00
    beq fn_kb_chk_del_first_pos
    lda #$a0
    ldx filename_cursor
    sta filename,x
    dec filename_cursor
    jmp fn_kb_chk
fn_kb_chk_del_first_pos:
    lda #$a0
    sta filename
    jmp fn_kb_chk
fn_kb_chk_not_del:
    cmp #64
    bcc fn_kb_num
    sbc #64
fn_kb_num:
    ora #$80
    ldx filename_cursor
    sta filename,x
    inc filename_cursor
    jmp fn_kb_chk
fn_kb_chk_end:
    ldx #00
fn_rereverse:   // Done editing, re-reverse all the characters
    lda filename,x
    and #$7f
    sta filename,x
    sta filename_buffer,x
    inx
    cpx #$10
    bne fn_rereverse
    ldx #$00
    ldx #$0f // fill in spaces on end with 0 (start at end and work backward)
fn_trim:
    lda filename_buffer,x
    cmp #$20
    bne fn_out
    lda #00
    sta filename_buffer,x
    dex
    jmp fn_trim
fn_out:
    rts

////////////////////////////////////////////////////
// Change Drive
change_drive:
    inc drive
show_drive:
    lda drive
    cmp #08
    bne cd_2
    lda #48
    sta $491
    lda #56
    sta $492
    rts
cd_2:
    cmp #09
    bne cd_3
    lda #48
    sta $491
    lda #57
    sta $492
    rts
cd_3:
    cmp #10
    bne cd_4
    lda #49
    sta $491
    lda #48
    sta $492
    rts
cd_4:
    cmp #11
    bne cd_5
    lda #49
    sta $491
    lda #49
    sta $492
    rts
cd_5:
    lda #07
    sta drive
    jmp change_drive

////////////////////////////////////////////////////
// Show Disk Directory
show_directory:
    ClearScreen(BLACK)
    lda #dirname_end-dirname
    ldx #<dirname
    ldy #>dirname
    jsr $ffbd      // call setnam
    lda #$02       // filenumber 2
    ldx drive       // default to device number 8
    ldy #$00      // secondary address 0 (required for dir reading!)
    jsr $ffba      // call setlfs
    jsr $ffc0      // call open (open the directory)      
    bcs error     // quit if open failed
    ldx #$02       // filenumber 2
    jsr $ffc6      // call chkin
    ldy #$04       // skip 4 bytes on the first dir line
    bne skip2
next:
    ldy #$02       // skip 2 bytes on all other lines
skip2:  
    jsr getbyte    // get a byte from dir and ignore it
    dey
    bne skip2

    jsr getbyte    // get low byte of basic line number
    tay
    jsr getbyte    // get high byte of basic line number
    pha
    tya            // transfer y to x without changing akku
    tax
    pla
    jsr $bdcd      // print basic line number
    lda #$20       // print a space first
char:
    jsr $ffd2      // call chrout (print character)
    jsr getbyte
    bne char      // continue until end of line

    lda #$0d
    jsr $ffd2      // print return
    jsr $ffe1      // run/stop pressed?
    bne next      // no run/stop -> continue
error:
    // akkumulator contains basic error code
    // most likely error:
    // a = $05 (device not present)
exit:
    lda #$02       // filenumber 2
    jsr $ffc3      // call close
    jsr $ffcc     // call clrchn

    lda #$0d
    jsr KERNAL_CHROUT

    jsr show_drive_status

    ldx #$00
labl22:
    lda dir_presskey,x
    beq sdlabl4
    jsr KERNAL_CHROUT
    inx
    jmp labl22

sdlabl4:
    jsr KERNAL_WAIT_KEY
    beq sdlabl4
    rts

getbyte:
    jsr $ffb7      // call readst (read status byte)
    bne end       // read error or end of file
    jmp $ffcf      // call chrin (read byte from directory)
end:
    pla            // don't return to dir reading loop
    pla
    jmp exit

dirname:
.text "$"
dirname_end:
dir_presskey:
.encoding "screencode_mixed"
.byte 13
.text "PRESS ANY KEY"
.byte 0

////////////////////////////////////////////////////
// Convert Filename for Disk I/O
convert_filename:
    ldx #$00
cfn_labl0:
    lda #$00
    sta filename_save,x
    inx
    cpx #$10
    bne cfn_labl0
cfn_labl2:
    ldx #$00
cfn_labl4:
    lda filename_buffer,x
    cmp #$00
    beq cfn_labl5
    cmp #27
    bcs cfn_dont_add
    adc #$40
cfn_dont_add:
    sta filename_save,x
    inx
    jmp cfn_labl4
cfn_labl5:
    stx filename_length
    rts


////////////////////////////////////////////////////
// Save File
save_file_are_you_sure:
    // Add are you sure prompt here

save_file:
    ClearScreen(BLACK)
    ldx #$00
sv_labl1:
    lda save_saving,x
    beq sv_labl2
    sta SCREEN_RAM,x
    inx
    jmp sv_labl1
sv_labl2:
    jsr convert_filename
  ldx #$00
sv_labl3:
    lda filename_buffer,x
    beq sv_labl4
    sta SCREEN_RAM+7,x
    inx
    cpx #$10
    bne sv_labl3
sv_labl4:
    lda #$0f
    ldx drive
    ldy #$ff
    jsr KERNAL_SETLFS
    lda filename_length
    ldx #<filename_save
    ldy #>filename_save
    jsr KERNAL_SETNAM
    lda #<tracker_data_start // Set Start Address
    sta zp_block1_lo
    lda #>tracker_data_start
    sta zp_block1_hi
    ldx #<tracker_data_end // Set End Address
    ldy #>tracker_data_end
    lda #<zp_block1_lo
    jsr KERNAL_SAVE
    lda #13
    jsr KERNAL_CHROUT
    jsr KERNAL_CHROUT
    jsr show_drive_status
    ldx #$00
sv_labl22:
    lda dir_presskey,x
    beq sv_out
    jsr KERNAL_CHROUT
    inx
    jmp sv_labl22
sv_out:
    jsr KERNAL_WAIT_KEY
    beq sv_out
    rts

save_saving:
.encoding "screencode_mixed"
.text "saving "
.byte 0

////////////////////////////////////////////////////
// Load File
load_file:
    ClearScreen(BLACK)
    ldx #$00
ld_labl1:
    lda load_loading,x
    beq ld_labl2
    sta SCREEN_RAM,x
    inx
    jmp ld_labl1
ld_labl2:
    jsr convert_filename
    ldx #$00
ld_labl3:
    lda filename_buffer,x
    beq ld_labl4
    sta SCREEN_RAM+8,x
    inx
    cpx #$10
    bne ld_labl3
ld_labl4:
    lda #$0f
    ldx drive
    ldy #$ff
    jsr KERNAL_SETLFS
    lda filename_length //#$10
    ldx #<filename_save
    ldy #>filename_save
    jsr KERNAL_SETNAM
    ldx #<tracker_data_start // Set Load Address
    ldy #>tracker_data_start
    lda #00
    jsr KERNAL_LOAD
    lda #13
    jsr KERNAL_CHROUT
    jsr KERNAL_CHROUT
    jsr show_drive_status
    ldx #$00
ld_labl22:
    lda dir_presskey,x
    beq ld_out
    jsr KERNAL_CHROUT
    inx
    jmp ld_labl22
ld_out:
    jsr KERNAL_WAIT_KEY
    beq ld_out
    clc
    rts

load_loading:
.encoding "screencode_mixed"
.text "loading "
.byte 0

////////////////////////////////////////////////////
// Erase File
erase_file_confirm:
    jsr draw_confirm_question
efc_loop2:
    jsr KERNAL_GETIN
    cmp #$00
    beq efc_loop2
efc_check_y_hit: // Y (Yes New Memory)
    cmp #$59
    beq erase_file
    rts
    // Yes hit... erase the file
erase_file:
    jsr convert_filename
    ldx #$00
ef_cpfn:
    lda filename_save,x
    sta ef_cmd+3,x
    inx
    cpx filename_length
    bne ef_cpfn
    inx
    inx
    inx
    stx zp_temp
    ClearScreen(BLACK)
    ldx #$00
efw_print1:
    lda ef_text,x
    jsr KERNAL_CHROUT
    inx
    cpx #$08
    bne efw_print1
    ldx#$00
efw_print2:
    lda ef_cmd,x
    jsr KERNAL_CHROUT
    inx
    stx zp_temp2
    lda zp_temp
    cmp zp_temp2
    bne efw_print2
    lda #$0d
    jsr KERNAL_CHROUT
    jsr KERNAL_CHROUT
    lda zp_temp
    ldx #<ef_cmd
    ldy #>ef_cmd
    jsr $FFBD     // call SETNAM
    lda #$0F      // file number 15 
    ldx $BA       // last used device number 
    bne ef2skip 
    ldx drive     // default to device 8 
ef2skip:
    ldy #$0F      // secondary address 15 
    jsr $FFBA     // call SETLFS 
    jsr $FFC0     // call OPEN
    jsr show_drive_status
    bcc ef2_noerror     // if carry set, the file could not be opened 
    // Accumulator contains BASIC error code 
    // most likely errors: 
    // A = $05 (DEVICE NOT PRESENT) 
    // ... error handling for open errors ... 
ef2_noerror:
    lda #$0F      // filenumber 15 
    jsr $FFC3     // call CLOSE 
    jsr $FFCC     // call CLRCHN
ef_out:
    jsr KERNAL_WAIT_KEY
    beq ef_out
    rts

ef_text:
.encoding "screencode_mixed"
.text "ERASING "
ef_text_end:
ef_cmd:
.text "S0:" // command string
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
ef_cmd_end:

////////////////////////////////////////////////////
// Show Drive Status
show_drive_status:
    lda #$00
    sta $90       // clear status flags
    lda drive     // device number
    jsr $ffb1     // call listen
    lda #$6f      // secondary address 15 (command channel)
    jsr $ff93     // call seclsn (second)
    jsr $ffae     // call unlsn
    lda $90       // get status flags
    bne sds_devnp // device not present
    lda drive     // device number
    jsr $ffb4     // call talk
    lda #$6f      // secondary address 15 (error channel)
    jsr $ff96     // call sectlk (tksa)
sds_loop:
    lda $90       // get status flags
    bne sds_eof   // either eof or error
    jsr $ffa5     // call iecin (get byte from iec bus)
    jsr KERNAL_CHROUT     // call chrout (print byte to screen)
    jmp sds_loop  // next byte
sds_eof:
    jsr $ffab     // call untlk
    rts
sds_devnp:
    //  ... device not present handling ...
    rts

toggle_gpio_pin_under_cursor:
    jsr calculate_pattern_block

    lda sprite_cursor
    clc
    cmp #$08
    bcs !tgpuc+
    // in first block
    ldx sprite_cursor
    inx
    lda #%00000000
    sec
!tgpuc_i:
    ror
    dex
    bne !tgpuc_i-
    ldx #$00
    eor (zp_block1,x)
    sta (zp_block1,x)
    rts

!tgpuc:
    cmp #$10
    bcs !tgpuc+
    // in second block
    lda sprite_cursor
    sec
    sbc #$08
    tax
    inx
    lda #%00000000
    sec
!tgpuc_i:
    ror
    dex
    bne !tgpuc_i-
    ldx #$00
    eor (zp_block2,x)
    sta (zp_block2,x)
    rts

!tgpuc:
    cmp #$18
    bcs !tgpuc+
    // in third block
    lda sprite_cursor
    sec
    sbc #$10
    tax
    inx
    lda #%00000000
    sec
!tgpuc_i:
    ror
    dex
    bne !tgpuc_i-
    ldx #$00
    eor (zp_block3,x)
    sta (zp_block3,x)
    rts

!tgpuc:
    // in fourth block
    lda sprite_cursor
    sec
    sbc #$18
    tax
    inx
    lda #%00000000
    sec
!tgpuc_i:
    ror
    dex
    bne !tgpuc_i-
    ldx #$00
    eor (zp_block4,x)
    sta (zp_block4,x)

tgpuc_out:
    rts

////////////////////////////////////////////////////
// all relays off
all_relay_off:
    jsr calculate_pattern_block
    lda #$00
    ldx #$00
    sta (zp_block1,x)
    sta (zp_block2,x)
    sta (zp_block3,x)
    sta (zp_block4,x)
    rts

////////////////////////////////////////////////////
// all relays on
all_relay_on:
    jsr calculate_pattern_block
    lda #$ff
    ldx #$00
    sta (zp_block1,x)
    sta (zp_block2,x)
    sta (zp_block3,x)
    sta (zp_block4,x)
    rts

set_pattern_block_zptrs:
    sta zp_block1_lo
    sta zp_block2_lo
    sta zp_block3_lo
    sta zp_block4_lo
    sta zp_block_cmd_lo
    rts

inc_pattern_block_zptrs:
    inc zp_block1_lo
    inc zp_block2_lo
    inc zp_block3_lo
    inc zp_block4_lo
    inc zp_block_cmd_lo
    rts
    
dec_pattern_block_zptrs:
    inc zp_block1_lo
    inc zp_block2_lo
    inc zp_block3_lo
    inc zp_block4_lo
    inc zp_block_cmd_lo
    rts
    
///////////////////////////////////////////////////
// Calculate pattern block
calculate_pattern_block:
    lda pattern_cursor
    sta playback_pos_pattern_c

    // sta zp_pointer_lo
    sta zp_block1_lo
    sta zp_block2_lo
    sta zp_block3_lo
    sta zp_block4_lo
    sta zp_block_cmd_lo

    lda #> pattern_block_start

    clc
    sta zp_block1_hi
    adc #$01
    sta zp_block2_hi
    adc #$01
    sta zp_block3_hi
    adc #$01
    sta zp_block4_hi
    adc #$01
    sta zp_block_cmd_hi 

    ldx track_block_cursor
    stx playback_pos_track
    lda track_block,x
    sta playback_pos_pattern
    tax
    cpx #$00
    beq cpb_2
cpb_1:
    lda zp_block1_hi
    adc #$04
    sta zp_block1_hi
    adc #$01
    sta zp_block2_hi
    adc #$01
    sta zp_block3_hi
    adc #$01
    sta zp_block4_hi    
    adc #$01
    sta zp_block_cmd_hi
    dex
    cpx #$00
    beq cpb_2
    jmp cpb_1
cpb_2:

    lda zp_block1_hi
    ldx #05
    ldy #10
    jsr print_hex
    lda zp_block1_lo
    ldx #07
    ldy #10
    jsr print_hex // draw memory locations

    lda zp_block2_hi
    ldx #13
    ldy #10
    jsr print_hex
    lda zp_block2_lo
    ldx #15
    ldy #10
    jsr print_hex // draw memory locations

    lda zp_block3_hi
    ldx #21
    ldy #10
    jsr print_hex
    lda zp_block3_lo
    ldx #23
    ldy #10
    jsr print_hex // draw memory location
    
    lda zp_block4_hi
    ldx #29
    ldy #10
    jsr print_hex
    lda zp_block4_lo
    ldx #31
    ldy #10
    jsr print_hex // draw memory locations

    lda zp_block_cmd_hi
    ldx #35
    ldy #10
    jsr print_hex
    lda zp_block_cmd_lo
    ldx #37
    ldy #10
    jsr print_hex // draw memory locations    

    rts

sprite_cursor_move:
    clc
    lda sprite_cursor
    adc #$03
    tax
    ldy #17
    lda #$18
    sta zp_temp
    lda #$31
    sta zp_temp2
    lda #$00
    sta zp_temp3
    cpx #$00
!scm_x:
    beq !scm_y+
    clc
    lda zp_temp
    adc #$08
    sta zp_temp
    bcc !scm_x2+
    inc zp_temp3
!scm_x2:
    dex
    jmp !scm_x-
!scm_y:
    cpy #$00
!scm_y:
    beq !scm_out+
    clc
    lda zp_temp2
    adc #$08
    sta zp_temp2
    dey
    jmp !scm_y-
!scm_out:
    lda zp_temp
    sta SPRITE_0_X
    lda zp_temp2
    sta SPRITE_0_Y
    lda zp_temp3
    sta SPRITE_LOCATIONS_MSB
!scm_x:
    rts

sprite_cursor_blink:
    jsr KERNAL_RDTIM
    and #$1F
    lsr
    lsr
    lsr
    lsr
    sta SPRITE_ENABLE
    rts

sprite_hide:
    lda #$00
    sta SPRITE_ENABLE
    rts

sprite_init:
    // Initialize sprite stuff
    lda #$01
    sta SPRITE_ENABLE
    lda #$00
    sta SPRITE_MULTICOLOR
    lda #LIGHT_GRAY
    sta SPRITE_0_COLOR
    lda #$00
    sta SPRITE_MSB_X
    lda #$80
    sta SPRITE_0_POINTER
    lda #$00
    sta sprite_cursor
    jsr sprite_cursor_move
    rts

// END OF PROGRAM
///////////////////////////////////////////////////

#import "PrintSubRoutines.asm"
