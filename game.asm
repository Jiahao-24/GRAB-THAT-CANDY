#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Martin Ni, Student Number: 1007250895, UTorID: nijiahao, official email: martin.ni@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1
# - Milestone 2
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health/score 
#       - Health is shown at the top right of the screen through out the game.
#       - Score is shown at the bottom right of the screen through out the game and on the "game over" screen.
# 2. Fail condition
#       - Fail if the player health dropping to zero, or falling into the river at the bottom.
#       - If the player hit the fire at the top, the health will drop.
# 3. Win condition
#       - Win if the player score hits 3.
#       - If the player reach the candy at the top, the score will go up.
# 4. Moving platforms
#       - Except the brown wood(safe area) on the river, all the other platforms starts moving to the 
#         left constantly once the game hits LEVEL 2 and gets regenerate at the bottom right 
#         if it hits certain height.
# 5. Different levels
#       - The game has three different difficulty levels
#       - LEVEL 1 - platforms are not moving
#       - LEVEL 2 - platforms moving to the left at speed 1 unit per SLEEP_TIME
#       - LEVEL 3 - platforms moving to the left at speed 2 units per SLEEP_TIME
#       - The level gets adjusted base on the curren player score:
#           - if the score is 0, the game is at LEVEL 1
#           - if the score is 1 or 2, the game is at LEVEL 2
#           - if the score is above 2, the game is at LEVEL 3
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - YES
#
# Any additional information that the TA needs to know:
# - At the chech point session, 
#   I lost one mark for letting the player pass the right edge of the screen,
#   that have been fixed it by now ^_^
# - Also I forgot to mention in the video that the player turns green if reaches the candy.
# - Hope you will have some fun playing my game!
#
#####################################################################

# Defined CONSTANTS
.eqv    BASE_ADDRESS            0x10008000
.eqv    LAST_ADDRESS            0x1000BFFC
.eqv    CHAR_ADDRESS            0x10008008
.eqv    RIVER_ADDRESS           0x1000BD00
.eqv    CANDY_ADDRESS           0x10008088
.eqv    FIRE_ADDRESS            0x1000825C
.eqv    HEALTH_ADDRESS          0x100081F4
.eqv    SCORE_ADDRESS           0x1000B7EC
.eqv    SAFE_LAND_ADDRESS       0x1000B874
.eqv    NUMofPLATFORMS          4
.eqv    SPACEofPLATFORMS        16
.eqv    TOTAL_HEALTH            3
.eqv    SLEEP_TIME              40
# Colour codes
.eqv    BACKGROUND              0x0002233f                   
.eqv    ARMOR                   0x009e0912
.eqv    PLATFORM_COLOR          0x00c1c4ce
.eqv    BODY                    0x00ffdab2
.eqv    RIVER                   0x0061efce
.eqv    CANDY_RED               0x00e31999
.eqv    CANDY_GREEN             0x0000d200
.eqv    FIRE_ORANGE             0x00ef6d00
.eqv    FIRE_RED                0x00ff0010
.eqv    FIRE_YELLOW             0x00fdec00
.eqv    HEALTH_RED              0x00d30912
.eqv	SCORE_COLOR		        0x00f3ce10

.data
P:   .space              SPACEofPLATFORMS                  # array of platforms

.text
.globl main

main:
    # clear the screen
    li      $a0, BASE_ADDRESS
    li      $a1, LAST_ADDRESS
    jal     clear_screen

    # initialize the state of the game
    # $s0 - old address of character
    # $s1 - updated address of character
    # $s2 - base address of array P
    # $s3 - 1 if falling, 0 if standing on a platform
    # $s4 - 1 if eating, 0 if not
    # $s5 - 1 if hurting, 0 if not
    # $s6 - total health = 3
    # $s7 - score = 0
    # initialize character
    li      $s0, CHAR_ADDRESS           # address of the character
    li      $s1, CHAR_ADDRESS
    li      $s3, 1
    li      $s4, 0
    li      $s5, 0
    li      $s6, 3
    li      $s7, 0
    move    $a0, $s0
    jal     draw_character
    # initialize all platforms
    la      $s2, P
    li      $t0, 0x1000A200
    sw      $t0, 0($s2)
    li      $t0, 0x10009540
    sw      $t0, 4($s2)
    li      $t0, 0x1000A878
    sw      $t0, 8($s2)
    li      $t0, 0x10009BBC
    sw      $t0, 12($s2)
    jal     generate_platform
    jal     draw_river
    jal     draw_candy
    jal     draw_fire
    jal     draw_health_bar
    jal     draw_score
    jal     draw_safe_land


    #li      $v0, 32
    #li      $a0, 1000
    #syscall

main_LOOP:
    # Check for keyboard input
    li      $a0, 0xffff0000
    lw      $t8, 0($a0)
    beq     $t8, 1, keypress_happened
    j update_character_position

keypress_happened:
    jal     handel_keypress

update_character_position:
    beq     $s0, $s1, update_draw_character

update_clear_character:
    # clear the character at the old address
    move    $a0, $s0
    jal     clear_character
    
update_draw_character:
    # draw the character at the updated address
    move    $a0, $s1
    beq     $s4, 1, update_draw_eating_character
    beq     $s5, 1, update_draw_hurting_characer
    jal     draw_character
    j       updated_old_character
update_draw_eating_character:
    jal     draw_eating_character
    j       updated_old_character
update_draw_hurting_characer:
    jal     draw_hurting_character
updated_old_character: 
    # updated the old address
    move    $s0, $s1

update_score:
    beq     $s4, 1, add_one_point
    j       update_health
add_one_point:
    addi    $s7, $s7, 1
    jal     clear_score
    jal     draw_score
update_health:
    beq     $s5, 1, lose_one_health
    j       update_everything_else
lose_one_health:
    addi    $s6, $s6, -1
    ble     $s6, $zero, FAIL_GAME
    jal     clear_health_bar
    jal     draw_health_bar

update_everything_else:
    jal     generate_platform
    jal     draw_river

    blt     $s7, 1, level_one      
    jal     shift_platform
level_one:  
    jal     draw_candy
    jal     draw_fire
    jal     draw_safe_land


collision_update:
    jal     if_standing
    lw      $s3, 0($sp)
    addi    $sp, $sp, 4

    beq     $s3, 0, falling
    j       eating_check
falling: 
    addi    $s1, $s1, 256

eating_check:
    jal     if_eating

hurting_check:
    jal     if_hurting

river_check:
    li      $t0, RIVER_ADDRESS
    blt     $s1, $t0, score_check
    j       FAIL_GAME

score_check:
    blt    $s7, 5, sleep
    j       WIN_GAME

health_check:
    bltz    $s6, FAIL_GAME

sleep:
    li      $v0, 32
    li      $a0, SLEEP_TIME
    syscall
    j       main_LOOP

WIN_GAME:
    # clear the screen
    li      $a0, BASE_ADDRESS
    li      $a1, LAST_ADDRESS
    jal     clear_screen
    jal     draw_win
    j       AFTER_THE_GAME

FAIL_GAME: 
    # clear the screen
    li      $a0, BASE_ADDRESS
    li      $a1, LAST_ADDRESS
    jal     clear_screen
    jal     draw_fail

 AFTER_THE_GAME:
    # give user two second to consider if they want to restart
    li      $v0, 32
    li      $a0, 2000
    syscall

    # See if user want to restart
    li      $a0, 0xffff0000
    lw      $t8, 0($a0)
    beq     $t8, 1, keypress_happened_after_game
keypress_happened_after_game:
    lw      $t9, 4($a0)
    beq	    $t9, 0x70, restart_the_game
    j       END_THE_GAME
restart_the_game:
    j       main

END_THE_GAME:
    li      $v0, 10                  # terminate the program gracefully syscall
    syscall


#****************************************************************
clear_screen: # clear_screen (starting_addr, ending_addr):
#**************
# clear screen from starting_addr($a0) to ending_addr($a1)
#
# $a0 - first param (starting_addr)
# $a1 - second param (ending_addr)
# 
# $t1 - background colour code
# $t2 - starting address
# $t3 - ending address
#**************
    li      $t1, BACKGROUND                     # $t1 stores the background colour
    move    $t2, $a0                            # $t2 stores the starting address
    move    $t3, $a1                            # $t3 stores the ending address
clear_screen_LOOP:
    sw      $t1, 0($t2)                         # clear screen at the current address
    addi    $t2, $t2, 4                         # increment $t2 by 4
    ble     $t2, $t3, clear_screen_LOOP         # loop until we pass $t3
    jr      $ra
#****************************************************************


#****************************************************************
clear_character: # clear_character (given_address):
#*****************
# $a0 - param (given_address):
# $t1 - background colour code
#*****************
    li      $t1, BACKGROUND
    #clearing
    sw      $t1, 0($a0)                     # first row center
    sw      $t1, 248($a0)                   # second row two unit to the left
    sw      $t1, 252($a0)                   # second row one unit to the left
    sw      $t1, 256($a0)                   # second row center
    sw      $t1, 260($a0)                   # second row one unit to the right
    sw      $t1, 264($a0)                   # second row two unit to the right
    sw      $t1, 508($a0)                   # third row one unit to the left
    sw      $t1, 512($a0)                   # third row center
    sw      $t1, 516($a0)                   # third row one unit to the right
    sw      $t1, 768($a0)                   # fourth row center
    sw      $t1, 1020($a0)                  # fifth row one unit to the left
    sw      $t1, 1028($a0)                  # fifth row one unit to the right
    sw      $t1, 1276($a0)                  # sixth row one unit to the left
    sw      $t1, 1284($a0)                  # sixth row one unit to the right
    jr      $ra
#****************************************************************


#****************************************************************
clear_platform: # clear_platform (given_address):
#****************
# $a0 - param (given_address):
# $t1 - background colour code
#****************
    li      $t1, BACKGROUND
    #clearing
    sw      $t1, 0($a0)
    sw      $t1, 4($a0)
    sw      $t1, 8($a0)
    sw      $t1, 12($a0)
    sw      $t1, 16($a0)
    sw      $t1, 20($a0)
    sw      $t1, 24($a0)
    sw      $t1, 28($a0)
    sw      $t1, 32($a0)
    sw      $t1, 36($a0)
    jr      $ra
#****************************************************************


#****************************************************************
handel_keypress: # handel_keypress (address 0xffff0000)
#*****************
# $a0 - param (address 0xffff0000)
#
# $t0 - ASII value of the pressed key
# $t8 - temp
# $t9 - temp
#*****************

    lw      $t0, 4($a0)
    beq	    $t0, 0x77, respond_to_w
    beq     $t0, 0x61, respond_to_a
    beq     $t0, 0x64, respond_to_d
    beq	    $t0, 0x70, respond_to_p

respond_to_w: # jump
    # check if character reaches the top edge
    li      $t9, BASE_ADDRESS
    addi    $t9, $t9, 1024
    blt     $s1, $t9, END_handel_keypress                       # at the top edge, skil to the end
    beq     $s3, 0, WEAK_JUMP
    addi    $s1, $s0, -4352
    j       END_handel_keypress
WEAK_JUMP:
    #addi    $s1, $s0, -768
    j       END_handel_keypress

respond_to_a: # move left
    # check if character reaches the left most edge
    addi    $t8, $s0, -8                                        # character left shoulder address
    andi    $t9, $t8, 255
    beq     $t9, $zero, END_handel_keypress                     # at the left edge, skip to the end
    addi    $s1, $s0, -16
    j       END_handel_keypress

respond_to_d: # move right
    # check if character reaches the right most edge
    #li      $t9, 256
    #div     $s0, $t9
    #mfhi    $t9                                                # t9 is the remainder of $s0/256
    #li      $t8, 244
    #beq     $t9, $t8, END_handel_keypress                      # at the right edge, skil to the end
    addi    $t8, $s0, 8                                         # character right shoulder address
    addi    $t8, $t8, 16
    andi    $t9, $t8, 255
    beq     $t9, $zero, END_handel_keypress                     # at the right edge, skip to the end
    addi    $s1, $s0, 16
    j       END_handel_keypress

respond_to_p: # reset
    la      $ra, main
    j       END_handel_keypress

END_handel_keypress:
    jr      $ra

#****************************************************************


#****************************************************************
if_standing: # if_standing():
#********************
# $t0 - return value(0 if not standing, 1 if standing)
# $t1 - i
# $t9 - temp
#********************
    li      $t1, 0                          # i = 0
if_standing_plat_LOOP:
    beq     $t1, NUMofPLATFORMS, END_if_standing_plat
    sll     $t9, $t1, 2                     # $t9 = i * 4 = offset
    add     $t9, $t9, $s2                   # $t9 = addr(P[i])
    lw      $t9, 0($t9)                     # $t9 = P[i]

    addi    $t7, $t9, -268                  # above left edge of the current platform
    addi    $t8, $t7, 52                    # above right edge of the current platform
	
    addi    $t6, $s1, 1280
    blt     $t6, $t7, NOT_standing_plat
    bgt     $t6, $t8, NOT_standing_plat
    li      $t0, 1
    j       END_if_standing_plat

NOT_standing_plat:
    li      $t0, 0
    addi    $t1, $t1, 1                     # i++
    j       if_standing_plat_LOOP

END_if_standing_plat:
    beqz    $t0, if_on_safe_land
    j       END_if_standing

if_on_safe_land:
    li      $t7, SAFE_LAND_ADDRESS
    addi    $t7, $t7, -256
    addi    $t8, $t7, 20

    addi    $t6, $s1, 1280
    blt     $t6, $t7, NOT_standing_land
    bgt     $t6, $t8, NOT_standing_land
    li      $t0, 1
    j       END_if_standing

NOT_standing_land:
    li      $t0, 0

END_if_standing:
    addi $sp, $sp, -4                       # push return value onto the stack
    sw $t0, 0($sp)
    jr $ra
#****************************************************************


#****************************************************************
if_eating:  # if_eating():
    li      $t1, CANDY_ADDRESS
    #addi    $t2, $t1, 764
    addi    $t3, $t1, 1024
    #addi    $t4, $t1, 1276
    #beq     $s1, $t2, IS_EATING
    beq     $s1, $t3, IS_EATING
    #beq     $s1, $t4, IS_EATING
    li      $s4, 0
    j       END_if_eating
IS_EATING:
    li      $s4, 1
END_if_eating:
    jr      $ra
#****************************************************************


#****************************************************************
if_hurting:  # if_hurting():
    li      $t1, FIRE_ADDRESS
    #addi    $t2, $t1, 252
    addi    $t3, $t1, 508
    #addi    $t4, $t1, 764
    #beq     $s1, $t2, IS_HURTING
    beq     $s1, $t3, IS_HURTING
    #beq     $s1, $t4, IS_HURTING
    li      $s5, 0
    j       END_if_hurting
IS_HURTING:
    li      $s5, 1
END_if_hurting:
    jr      $ra
#****************************************************************


#****************************************************************
generate_platform: # generate_platform():
#*******************
# Generates all the platforms
# 
# $t0 - i
# $t9 - temp
#*******************
    li      $t0, 0                          # i = 0
generate_platform_LOOP:
    beq     $t0, NUMofPLATFORMS, END_generate_platform
    sll     $t9, $t0, 2                     # $t9 = i * 4 = offset
    add     $t9, $t9, $s2                   # $t9 = addr(P[i])
    lw      $t9, 0($t9)                     # $t9 = P[i]

    # push $ra onto the stack
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    # call draw_platform
    move    $a0, $t9
    jal     draw_platform

    # restore $ra
    lw      $ra, 0($sp)
    addi    $sp, $sp, 4

    addi    $t0, $t0, 1                     # i++
    j       generate_platform_LOOP
END_generate_platform:
    jr      $ra
#****************************************************************


#****************************************************************
draw_platform: # draw_platform (given_address)
#***************
# draw platform at the given address($a0)
# 
# $a0 - param (given_address)
# $t1 - platform colour code
#***************
    li      $t1, PLATFORM_COLOR                         # $t1 stores the platorm colour
    #drawing
    sw      $t1, 0($a0)
    sw      $t1, 4($a0)
    sw      $t1, 8($a0)
    sw      $t1, 12($a0)
    sw      $t1, 16($a0)
    sw      $t1, 20($a0)
    sw      $t1, 24($a0)
    sw      $t1, 28($a0)
    sw      $t1, 32($a0)
    sw      $t1, 36($a0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_character: # draw_character (given_address)
#****************
# draw character at the given address9($ao)
#
# $a0 - param (given_address)
# $t0 - armor colour code
# $t1 - body colour code
#****************
    li      $t0, ARMOR
    li      $t1, BODY
    #drawing
    sw      $t1, 0($a0)                     # first row center
    sw      $t0, 248($a0)                   # second row two unit to the left
    sw      $t0, 252($a0)                   # second row one unit to the left
    sw      $t0, 256($a0)                   # second row center
    sw      $t0, 260($a0)                   # second row one unit to the right
    sw      $t0, 264($a0)                   # second row two unit to the right
    sw      $t1, 508($a0)                   # third row one unit to the left
    sw      $t0, 512($a0)                   # third row center
    sw      $t1, 516($a0)                   # third row one unit to the right
    sw      $t0, 768($a0)                   # fourth row center
    sw      $t0, 1020($a0)                  # fifth row one unit to the left
    sw      $t0, 1028($a0)                  # fifth row one unit to the right
    sw      $t1, 1276($a0)                  # sixth row one unit to the left
    sw      $t1, 1284($a0)                  # sixth row one unit to the right
    jr      $ra
#****************************************************************


#****************************************************************
draw_eating_character: # draw_eating_character (given_address)
#****************
# draw character at the given address9($ao)
#
# $a0 - param (given_address)
# $t0 - bright green
#****************
    li      $t0, 0x0000ff00
    #drawing
    sw      $t0, 0($a0)                     # first row center
    sw      $t0, 248($a0)                   # second row two unit to the left
    sw      $t0, 252($a0)                   # second row one unit to the left
    sw      $t0, 256($a0)                   # second row center
    sw      $t0, 260($a0)                   # second row one unit to the right
    sw      $t0, 264($a0)                   # second row two unit to the right
    sw      $t0, 508($a0)                   # third row one unit to the left
    sw      $t0, 512($a0)                   # third row center
    sw      $t0, 516($a0)                   # third row one unit to the right
    sw      $t0, 768($a0)                   # fourth row center
    sw      $t0, 1020($a0)                  # fifth row one unit to the left
    sw      $t0, 1028($a0)                  # fifth row one unit to the right
    sw      $t0, 1276($a0)                  # sixth row one unit to the left
    sw      $t0, 1284($a0)                  # sixth row one unit to the right
    jr      $ra
#****************************************************************


#****************************************************************
draw_hurting_character: # draw_hurting_character (given_address)
#****************
# draw character at the given address9($ao)
#
# $a0 - param (given_address)
# $t0 - bright green
#****************
    li      $t0, 0x00d80095
    #drawing
    sw      $t0, 0($a0)                     # first row center
    sw      $t0, 248($a0)                   # second row two unit to the left
    sw      $t0, 252($a0)                   # second row one unit to the left
    sw      $t0, 256($a0)                   # second row center
    sw      $t0, 260($a0)                   # second row one unit to the right
    sw      $t0, 264($a0)                   # second row two unit to the right
    sw      $t0, 508($a0)                   # third row one unit to the left
    sw      $t0, 512($a0)                   # third row center
    sw      $t0, 516($a0)                   # third row one unit to the right
    sw      $t0, 768($a0)                   # fourth row center
    sw      $t0, 1020($a0)                  # fifth row one unit to the left
    sw      $t0, 1028($a0)                  # fifth row one unit to the right
    sw      $t0, 1276($a0)                  # sixth row one unit to the left
    sw      $t0, 1284($a0)                  # sixth row one unit to the right
    jr      $ra
#****************************************************************


#****************************************************************
draw_river: # draw_river()
#************
# draw river at the last two row
#************
    li      $t0, LAST_ADDRESS
    li      $t1, RIVER_ADDRESS
    li      $t2, RIVER
draw_river_LOOP:
    bgt     $t1, $t0, draw_river_END
    sw      $t2, 0($t1)
    addi    $t1, $t1, 4
    j       draw_river_LOOP
draw_river_END:
    jr      $ra
#****************************************************************


#****************************************************************
draw_candy: # draw_candy()
#************
# draw candy at the middle of the first row
#************
    li      $t0, CANDY_ADDRESS
    li      $t1, CANDY_GREEN
    li      $t2, CANDY_RED
    #drawing
    sw      $t1, 0($t0)
    sw      $t1, 256($t0)
    sw      $t1, 512($t0)
    sw      $t1, 764($t0)
    sw      $t1, 768($t0)
    sw      $t1, 772($t0)
    sw      $t1, 1020($t0)
    sw      $t2, 1024($t0)
    sw      $t1, 1028($t0)
    sw      $t1, 1276($t0)
    sw      $t1, 1280($t0)
    sw      $t1, 1284($t0)
    #sw      $t2, 1532($t0)
    #sw      $t2, 1536($t0)
    #sw      $t2, 1540($t0)
    #sw      $t2, 1788($t0)
    #sw      $t2, 1792($t0)
    #sw      $t2, 1796($t0)
    jr  $ra
    
#****************************************************************


#****************************************************************
draw_fire:  # draw_fire()
#************
# draw fire
#************
    li     $t0, FIRE_ADDRESS
    li     $t1, FIRE_ORANGE
    li     $t2, FIRE_RED
    li     $t3, FIRE_YELLOW
    #drawing
    sw     $t2, 0($t0)
    sw     $t2, 252($t0)
    sw     $t1, 256($t0)
    sw     $t2, 260($t0)
    sw     $t2, 508($t0)
    sw     $t3, 512($t0)
    sw     $t2, 516($t0) 
    sw     $t2, 764($t0)
    sw     $t2, 768($t0)
    sw     $t2, 772($t0)

    jr $ra     
#****************************************************************


#****************************************************************
draw_fail: # draw_fail()
#****************
# draw 
#****************
    li      $t0, 0x10009838
    li      $t1, PLATFORM_COLOR
    li      $t2, HEALTH_RED
    addi    $t3, $t0, 3072
    li      $t4, 36

    # draw red lines
draw_red_line_loop:
    beqz    $t4, draw_letters
    sw      $t2, 0($t3)
    addi    $t3, $t3, 4
    addi    $t4, $t4, -1
    j       draw_red_line_loop

draw_letters:
    # draw F
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    sw      $t1, 256($t0)
    sw      $t1, 260($t0)
    sw      $t1, 264($t0)
    sw      $t1, 268($t0)
    sw      $t1, 272($t0)
    sw      $t1, 276($t0)
    sw      $t1, 280($t0)
    sw      $t1, 284($t0)
    sw      $t1, 512($t0)               # 1
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)               # 2
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)              # 3
    sw      $t1, 1028($t0)
    sw      $t1, 1032($t0)
    sw      $t1, 1036($t0)
    sw      $t1, 1040($t0)
    sw      $t1, 1044($t0)
    sw      $t1, 1280($t0)              # 4
    sw      $t1, 1284($t0)
    sw      $t1, 1288($t0)
    sw      $t1, 1292($t0)
    sw      $t1, 1296($t0)
    sw      $t1, 1300($t0)
    sw      $t1, 1536($t0)              # 5
    sw      $t1, 1540($t0)
    sw      $t1, 1792($t0)              # 6
    sw      $t1, 1796($t0)      
    sw      $t1, 2048($t0)              # 7
    sw      $t1, 2052($t0)
    sw      $t1, 2304($t0)              # 8
    sw      $t1, 2308($t0)

    # draw A
    addi    $t0, $t0, 40
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    sw      $t1, 264($t0)
    sw      $t1, 268($t0)
    sw      $t1, 272($t0)
    sw      $t1, 276($t0)
    sw      $t1, 512($t0)               # 1
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)               # 2
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)              # 3
    sw      $t1, 1028($t0)
    sw      $t1, 1032($t0)
    sw      $t1, 1036($t0)
    sw      $t1, 1040($t0)
    sw      $t1, 1044($t0)
    sw      $t1, 1280($t0)              # 4
    sw      $t1, 1284($t0)
    sw      $t1, 1288($t0)
    sw      $t1, 1292($t0)
    sw      $t1, 1296($t0)
    sw      $t1, 1300($t0)
    sw      $t1, 1536($t0)              # 5
    sw      $t1, 1540($t0)
    sw      $t1, 1792($t0)              # 6
    sw      $t1, 1796($t0)      
    sw      $t1, 2048($t0)              # 7
    sw      $t1, 2052($t0)
    sw      $t1, 2304($t0)              # 8
    sw      $t1, 2308($t0)
    
    addi    $t0, $t0, 24
    sw      $t1, 512($t0)               # 1
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)               # 2
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)              # 3
    sw      $t1, 1028($t0)
    sw      $t1, 1280($t0)              # 4
    sw      $t1, 1284($t0)
    sw      $t1, 1536($t0)              # 5
    sw      $t1, 1540($t0)
    sw      $t1, 1792($t0)              # 6
    sw      $t1, 1796($t0)      
    sw      $t1, 2048($t0)              # 7
    sw      $t1, 2052($t0)
    sw      $t1, 2304($t0)              # 8
    sw      $t1, 2308($t0)

    # draw I
    addi    $t0, $t0, 16
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    sw      $t1, 256($t0)
    sw      $t1, 260($t0)
    sw      $t1, 264($t0)
    sw      $t1, 268($t0)
    sw      $t1, 272($t0)
    sw      $t1, 276($t0)
    addi    $t0, $t0, 8
    sw      $t1, 512($t0)               # 1
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)               # 2
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)              # 3
    sw      $t1, 1028($t0)
    sw      $t1, 1280($t0)              # 4
    sw      $t1, 1284($t0)
    sw      $t1, 1536($t0)              # 5
    sw      $t1, 1540($t0)
    sw      $t1, 1792($t0)              # 6
    sw      $t1, 1796($t0)
    sw      $t1, 2040($t0)              # 7 left
    sw      $t1, 2044($t0)    
    sw      $t1, 2048($t0)              # 7
    sw      $t1, 2052($t0)
    sw      $t1, 2056($t0)              # 7 right
    sw      $t1, 2060($t0)
    sw      $t1, 2296($t0)              # 8 left
    sw      $t1, 2300($t0)
    sw      $t1, 2304($t0)              # 8
    sw      $t1, 2308($t0)
    sw      $t1, 2312($t0)              # 8 right
    sw      $t1, 2316($t0)

    # draw L
    addi    $t0, $t0, 24
    sw      $t1, 0($t0)                 # 1
    sw      $t1, 4($t0)
    sw      $t1, 256($t0)               # 2
    sw      $t1, 260($t0)
    sw      $t1, 512($t0)               # 3
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)               # 4
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)              # 5
    sw      $t1, 1028($t0)
    sw      $t1, 1280($t0)              # 6
    sw      $t1, 1284($t0)
    sw      $t1, 1536($t0)              # 7
    sw      $t1, 1540($t0)
    sw      $t1, 1792($t0)              # 8
    sw      $t1, 1796($t0)      
    sw      $t1, 2048($t0)              # 9
    sw      $t1, 2052($t0)
    sw      $t1, 2056($t0)
    sw      $t1, 2060($t0)
    sw      $t1, 2064($t0)
    sw      $t1, 2068($t0)
    sw      $t1, 2072($t0)
    sw      $t1, 2076($t0)
    sw      $t1, 2304($t0)              # 10
    sw      $t1, 2308($t0)
    sw      $t1, 2312($t0)
    sw      $t1, 2316($t0)
    sw      $t1, 2320($t0)
    sw      $t1, 2324($t0)
    sw      $t1, 2328($t0)
    sw      $t1, 2332($t0)

    # show the score
    move    $a3, $ra
    jal     draw_score
    move    $ra, $a3

    jr      $ra
#****************************************************************


#****************************************************************
draw_win: # draw_win()
#****************
# draw 
#****************
    li      $t0, 0x10009838
    li      $t1, PLATFORM_COLOR
    li      $t2, CANDY_GREEN
    addi    $t3, $t0, 3072
    li      $t4, 36

    # draw green lines
draw_green_line_loop:
    beqz    $t4, draw_win_letters
    sw      $t2, 0($t3)
    addi    $t3, $t3, 4
    addi    $t4, $t4, -1
    j       draw_green_line_loop

draw_win_letters:
    # draw W
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 256($t0)
    sw      $t1, 260($t0)
    sw      $t1, 512($t0)               # 1
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)               # 2
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)              # 3
    sw      $t1, 1028($t0)
    sw      $t1, 1040($t0)
    sw      $t1, 1044($t0)
    sw      $t1, 1280($t0)              # 4
    sw      $t1, 1284($t0)
    sw      $t1, 1296($t0)
    sw      $t1, 1300($t0)
    sw      $t1, 1536($t0)              # 5
    sw      $t1, 1540($t0)
    sw      $t1, 1544($t0)
    sw      $t1, 1548($t0)
    sw      $t1, 1560($t0)
    sw      $t1, 1564($t0)
    sw      $t1, 1792($t0)              # 6
    sw      $t1, 1796($t0)
    sw      $t1, 1800($t0) 
    sw      $t1, 1804($t0) 
    sw      $t1, 1816($t0)
    sw      $t1, 1820($t0)
    sw      $t1, 2048($t0)              # 7
    sw      $t1, 2052($t0)
    sw      $t1, 2304($t0)              # 8
    sw      $t1, 2308($t0)
    addi    $t0, $t0, 32
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 256($t0)
    sw      $t1, 260($t0)
    sw      $t1, 512($t0)
    sw      $t1, 516($t0)
    sw      $t1, 768($t0)
    sw      $t1, 772($t0)
    sw      $t1, 1024($t0)
    sw      $t1, 1028($t0)
    sw      $t1, 1280($t0)
    sw      $t1, 1284($t0)
    sw      $t1, 1536($t0)
    sw      $t1, 1540($t0)
    sw      $t1, 1792($t0)
    sw      $t1, 1796($t0)
    sw      $t1, 2048($t0)
    sw      $t1, 2052($t0)
    sw      $t1, 2304($t0)
    sw      $t1, 2308($t0)

    # draw O
    addi    $t0, $t0, 16
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    addi    $t0, $t0, 256
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    addi    $t0, $t0, 256
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    addi    $t0, $t0, -2304

    # draw N
    addi    $t0, $t0, 40
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 16($t0)
    sw      $t1, 20($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 24($t0)
    sw      $t1, 28($t0)
    addi    $t0, $t0, -2304

    # draw !
    addi    $t0, $t0, 48
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    addi    $t0, $t0, 256
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)

    # show the score
    move    $a3, $ra
    jal     draw_number_five
    move    $ra, $a3
    jr      $ra
#****************************************************************


#****************************************************************
draw_health_bar: # draw_health_bar()
    move    $t0, $s6
    li      $a0, HEALTH_ADDRESS
    move    $a1, $ra
draw_health_bar_LOOP:
    beq     $t0, $zero, draw_health_bar_END
    jal     draw_health_H
    addi    $a0, $a0, 1024
    addi    $t0, $t0, -1
    j       draw_health_bar_LOOP
draw_health_bar_END:
    move    $ra, $a1
    jr      $ra
#****************************************************************


#****************************************************************
draw_health_H:
    li  $t9, HEALTH_RED
    # drawing
    sw  $t9, 0($a0)
    sw  $t9, 8($a0)
    sw  $t9, 256($a0)
    sw  $t9, 260($a0)
    sw  $t9, 264($a0)
    sw  $t9, 512($a0)
    sw  $t9, 520($a0)
    jr  $ra
#****************************************************************


#****************************************************************
clear_health_bar:
    li      $t0, 3
    li      $a0, HEALTH_ADDRESS
    move    $a1, $ra
clear_health_bar_LOOP:
    beq     $t0, $zero, clear_health_bar_END
    jal     clear_health_H
    addi    $a0, $a0, 1024
    addi    $t0, $t0, -1
    j       clear_health_bar_LOOP
clear_health_bar_END:
    move    $ra, $a1
    jr      $ra
#****************************************************************


#****************************************************************
clear_health_H:
    li  $t9, BACKGROUND
    # clearing
    sw  $t9, 0($a0)
    sw  $t9, 8($a0)
    sw  $t9, 256($a0)
    sw  $t9, 260($a0)
    sw  $t9, 264($a0)
    sw  $t9, 512($a0)
    sw  $t9, 520($a0)
    jr  $ra
#****************************************************************


#****************************************************************
shift_platform: # shift_platform()
#****************
# shift all the platforms one unit to the left
# $s2 - base address of array P
#****************
    move    $t0, $s2
    addi    $t1, $t0, SPACEofPLATFORMS
    li      $t3, BASE_ADDRESS
    addi    $t3, $t3, 5120
    #addi    $t4, $t4, 4868
    #addi    $t5, $t5, 4616

shift_platform_loop:
    beq     $t0, $t1, shift_platform_END
    lw      $t9, 0($t0)
    ble     $t9, $t3, generate_one_new

    move    $a3, $ra
    move    $a2, $t1
    move    $a0, $t9
    jal     clear_platform
    bge     $s7, 3, shift_to_left_by_8
    addi    $t9, $t9, -4
    j shift_platform_redraw
shift_to_left_by_8:
    addi    $t9, $t9, -8
    j shift_platform_redraw

shift_platform_redraw:
    move    $a0, $t9
    jal     draw_platform
    move    $t1, $a2
    move    $ra, $a3

    sw      $t9, 0($t0)

    addi    $t0, $t0, 4
    j       shift_platform_loop

generate_one_new:
    #li      $v0, 42
    #li      $a0, 0
    #li      $a1, 20
    #syscall

    move    $a1, $ra
    move    $a2, $t1
    move    $a0, $t9
    jal     clear_platform

    li      $t8, LAST_ADDRESS
    addi    $t8, $t8, -3072
    addi    $t8, $t8, -36
    move    $a0, $t8
    jal     draw_platform
    move    $t1, $a2
    move    $ra, $a1

    sw      $t8, 0($t0)
    
    addi    $t0, $t0, 4
    j       shift_platform_loop

shift_platform_END:
    jr  $ra
#****************************************************************


#****************************************************************
draw_safe_land:
    li  $t0, SAFE_LAND_ADDRESS
    li  $t1, 0x00965910

    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    sw      $t1, 16($t0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_score:
    move    $a2, $ra
    beq     $s7, 0, draw_score_zero
    beq     $s7, 1, draw_score_one
    beq     $s7, 2, draw_score_two
    beq     $s7, 3, draw_score_three
    beq     $s7, 4, draw_score_four
    beq     $s7, 5, draw_score_five

draw_score_zero:
    jal     draw_number_zero
    j       draw_score_END
draw_score_one:
    jal     draw_number_one
    j       draw_score_END
draw_score_two:
    jal     draw_number_two
    j       draw_score_END
draw_score_three:
    jal     draw_number_three
    j       draw_score_END
draw_score_four:
    jal     draw_number_four
    j       draw_score_END
draw_score_five:
    jal     draw_number_five
    j       draw_score_END
draw_score_END:
    move    $ra, $a2
    jr      $ra
#****************************************************************


#****************************************************************
draw_number_zero:
    li      $t0, SCORE_ADDRESS
    li      $t1, SCORE_COLOR

    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_number_one:
    li      $t0, SCORE_ADDRESS
    li      $t1, SCORE_COLOR

    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_number_two:
    li      $t0, SCORE_ADDRESS
    li      $t1, SCORE_COLOR

    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 4($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_number_three:
    li      $t0, SCORE_ADDRESS
    li      $t1, SCORE_COLOR

    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_number_four:
    li      $t0, SCORE_ADDRESS
    li      $t1, SCORE_COLOR

    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 8($t0)
    jr      $ra
#****************************************************************


#****************************************************************
draw_number_five:
    li      $t0, SCORE_ADDRESS
    li      $t1, SCORE_COLOR

    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    addi    $t0, $t0, 256
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    jr      $ra
#****************************************************************


#****************************************************************
clear_score:
    li      $t0, SCORE_ADDRESS
    li      $t1, BACKGROUND

    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    addi    $t0, $t0, 256
    sw      $t1, 0($t0)
    sw      $t1, 4($t0)
    sw      $t1, 8($t0)
    sw      $t1, 12($t0)
    jr      $ra
#****************************************************************