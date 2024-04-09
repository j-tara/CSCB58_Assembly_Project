#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Tara Jorjani, 1007994529, jorjanit, tara.jorjani@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4 
# - Display width in pixels: 256 
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# - Milestone 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Double jump
# 2. Moving enemies
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################


.eqv BASE_ADDRESS 0x10008000
.eqv ENEMY_REGENERATION_TIME 60
.eqv red_value 0xff0000
.eqv green_value 0x00ff00
.eqv blue_value 0x0000ff
.eqv black_value 0x000000
.eqv white_value 0xffffff
.eqv yellow_value 0xffff99 		# Character colour
.eqv bright_yellow_value 0xffff00	# Face colour at end of game
.eqv purple_value 0x9900cc		# Enemy colour
.eqv cyan_value 0x00ffff		# Enemy colour
.eqv brown_value 0x996633

.eqv PLAYER_LOCATION 13824		# 8 pixels above platform
.eqv PURPLE_ENEMY_LOCATION 3880
.eqv CYAN_ENEMY_LOCATION 9676

load_graphics:

.text
# Global variables
li $s0, BASE_ADDRESS 			# $t0 stores the base address for display
li, $s1, PLAYER_LOCATION		# Stores the current player location (NOT ADDRESS) that gets updated with movement
li, $s2, 0				# Game state (0 -> game in progress, 1 -> game over)
li $s3, 0				# Number of jumps performed (before ground is reached) - does not allow more jumps if >= 2
li $s4, 0				# Number of hearts erased / number of hits with enemy  (min 0, max 3)
#li $s5, -1			 	# How many iterations of the loop to wait until enemies are recoloured
li $s5, ENEMY_REGENERATION_TIME
li $s6 PURPLE_ENEMY_LOCATION		# Current purple enemy location
li $s7 CYAN_ENEMY_LOCATION		# Current cyan enemy location
li $t7 0				# Purple enemy directions (0 = purple right, 1 = purple left)
li $t8 0				# Cyan enemy directions (0 = cyan left, 1 = cyan right)

# Reset screen to black
li $a0, 0
li $a1, 16384 
li $a2, black_value
jal FILL_PIXELS_LEFT_TO_RIGHT

# Painting all platforms red

# Top platform (19th - 20th rows)
li $a0, 4640
jal PAINT_ELEVATED_PLATFORM

# Middle platform (41st - 42nd rows)
li $a0, 10240
jal PAINT_ELEVATED_PLATFORM

# Bottom platform (63rd - 64th rows)
li $a0, 15872
li $a1, 16384 
li $a2, red_value
jal FILL_PIXELS_LEFT_TO_RIGHT

# Painting door (10 pixels tall, 6 pixels wide)
# Placed on the 9th level, and 57th step
li $a0, 2272
jal PAINT_DOOR

# Painting doorknob
li $a0, 3556
li $a1, 1
li $a2, 1
li $a3, bright_yellow_value
jal PAINT_RECTANGLE

# Painting first bar - left side below top platform
li $a0, 4608
jal PAINT_BAR

# Painting second bar - right side below middle platform
li $a0, 10464
jal PAINT_BAR

#Painting character - spawn point on the left part of the bottom platform
li $a0, PLAYER_LOCATION		# Starting location - this is the leftmost pixel of the 56th row				
jal PAINT_PLAYER	# Calling paint player function

#Painting enemy (height 3, width 3) - spawn on top floor
li $a0, PURPLE_ENEMY_LOCATION					
jal PAINT_ENEMY_1		# Calling paint player function

#Painting enemy (height 3, width 3) - spawn on middle floor
li $a0, CYAN_ENEMY_LOCATION					
jal PAINT_ENEMY_2		# Calling paint player function

# Draw left heart
li $a0, 464					
jal PAINT_HEART		# Calling paint heart function

# Draw middle heart
li $a0, 480					
jal PAINT_HEART		# Calling paint heart function

# Draw right heart
li $a0, 496					
jal PAINT_HEART		# Calling paint heart function



# MAIN LOOP - this is the program logic of the game

li $s2, 0 # This is the loop status (0 -> continue game, 1 -> end game)  
main_loop:

#Testing purposes
jal REMOVE_HEART

#Check for keypress
check_keypress:
li $t3, 0xffff0000
lw $t4, 0($t3)
beq $t4, 1, keypress_happened

after_keypress_check:
# Check for climbing
jal check_climbing
move, $t4, $v0			# Move 'check climbing' result in $t4 (0 -> no climbing, 1 -> climbing)
bnez $t5, after_player_movement			# If $t4 != 0, climbing occurs, so skip gravity

# Check for gravity
jal check_gravity
move, $t5, $v0			# Move 'check gravity' result in $t5 (0 -> no gravity, 1 -> gravity)
bnez $t5, perform_gravity	# If $t5 != 0, perform gravity

after_player_movement:
# Check if enemies need to be regenerated
#jal REGENERATE_ENEMIES
beqz $s5, REGENERATE_ENEMIES
addi $s5, $s5, -1		# Update an iteration for the enemy regeneration counter

jal MOVE_PURPLE_ENEMY
jal MOVE_CYAN_ENEMY

after_enemy_movement:

wait:
li $v0, 32
li $a0, 40 			# Wait 40 miliseconds
syscall

beqz, $s2, main_loop # Check loop condition

end_program:

# Terminate the program
li $v0, 10
syscall


# POST GAME PAGES
YOU_WIN:
# Reset screen to black
li $a0, 0
li $a1, 16384 
li $a2, black_value
jal FILL_PIXELS_LEFT_TO_RIGHT

# Paint original hearts
li $a0, 464					
jal PAINT_HEART
li $a0, 480					
jal PAINT_HEART
li $a0, 496					
jal PAINT_HEART

# Update the hearts to what matches your score
jal REMOVE_HEART

# Display "YOU WON!"
jal PAINT_FACE_AND_EYES

li, $a0, 9532		# Store the a0 arg (start pixel) in $t0
li, $a1, 2		# Stores width
li, $a2, 6		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

li, $a0, 9588		# Store the a0 arg (start pixel) in $t0
li, $a1, 2		# Stores width
li, $a2, 6		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

li, $a0, 10564		# Store the a0 arg (start pixel) in $t0
li, $a1, 12		# Stores width
li, $a2, 2		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

li $a0, 9660	# Starting location - this is the leftmost pixel of the 56th row				
jal PAINT_PLAYER	# Calling paint player function


j end_program


YOU_LOSE:
# Reset screen to black
li $a0, 0
li $a1, 16384 
li $a2, black_value
jal FILL_PIXELS_LEFT_TO_RIGHT

# Draw left heart
li $a0, 464					
jal PAINT_LOST_HEART		# Calling paint heart function

# Draw middle heart
li $a0, 480					
jal PAINT_LOST_HEART	# Calling paint heart function

# Draw right heart
li $a0, 496					
jal PAINT_LOST_HEART		# Calling paint heart function

# Display "YOU LOST!"
jal PAINT_FACE_AND_EYES

li, $a0, 9532		# Store the a0 arg (start pixel) in $t0
li, $a1, 2		# Stores width
li, $a2, 6		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

li, $a0, 9588		# Store the a0 arg (start pixel) in $t0
li, $a1, 2		# Stores width
li, $a2, 6		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

# Paints frown
li, $a0, 9540		# Store the a0 arg (start pixel) in $t0
li, $a1, 12		# Stores width
li, $a2, 2		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

li $a0, 9648					
jal PAINT_ENEMY_1	

li $a0, 9680				
jal PAINT_ENEMY_2

j end_program


# ACTION LOGIC


# Implement gravity by moving down 2 pixels per main loop iteration
perform_gravity:

# Erasing character at previous position
move $a0, $s1
jal ERASE_PLAYER	# Calling erase player function

# Moving down 1 level
addi $s1, $s1, 256
move $a0, $s1					
jal PAINT_PLAYER	# Calling paint player function

j after_player_movement


# Move character right 
respond_to_d:

# Prevents player from moving right if they are on the right-most part of the screen
check_right_edge_of_screen:
move $t0, $s1 
li $t1, 256
div $t0, $t1	# If location % 256 == 244, player is on the right edge. Should not be allowed to move right
mfhi $t0
beq $t0, 244, after_keypress_check

# Prevents player from moving right if there is a non-black pixel on the right of any pixel right of the player
check_right_collision:
addi $t2, $s1, 12	# Topmost pixel directly to right of player (right of their hair)
addi $t3, $s1, 2060	# Lower-most pixel directly to the right of player (right of their shoes)

add $t2, $t2, $s0 		# Add $t2 to base address to get current address (in $t2)
add $t3, $t3, $s0 		# Add $t3 to base address to get current address (in $t3)

check_right_collision_loop:
	lw $t4, 0($t2)			# Store colour of right pixel in $t4	
	beq $t4, brown_value, YOU_WIN	# Player hit the door and they win
	beq $t4, cyan_value, TOUCHED_CYAN_ENEMY	
	beq $t4, purple_value, TOUCHED_PURPLE_ENEMY	
	bne, $t4, black_value, after_player_movement	# If pixel is not black (collision), ignore right action and continue to main loop
	
	addi $t2, $t2, 256		# Increment $t2 by 256 to get to the next right pixel (directly below previous one)
	blt $t2, $t3, check_right_collision_loop	# Iterate from top to bottom of direct right pixels of player (6 times)

# Erasing character at previous position
move $a0, $s1
jal ERASE_PLAYER	# Calling erase player function

# Moving to the right
addi $s1, $s1, 4
move $a0, $s1					
jal PAINT_PLAYER	# Calling paint player function

j after_keypress_check


# Move character left
respond_to_a:

# Prevents player from moving left if they are on the left-most part of the screen
check_left_edge_of_screen:
move $t0, $s1 
li $t1, 256
div $t0, $t1	# If location % 256 == 0, player is on the left edge. Should not be allowed to move left
mfhi $t0
beq $t0, 0, after_keypress_check

# Prevents player from moving left if there is a non-black pixel on the left of any pixel left of the player
check_left_collision:
addi $t2, $s1, -4	# Topmost pixel directly to left of player (left of their hair)
addi $t3, $s1, 2044	# Lower-most pixel directly to the left of player (left of their shoes)

add $t2, $t2, $s0 		# Add $t2 to base address to get current address (in $t2)
add $t3, $t3, $s0 		# Add $t3 to base address to get current address (in $t3)

check_left_collision_loop:
	lw $t4, 0($t2)			# Store colour of left pixel in $t4
	beq $t4, cyan_value, TOUCHED_CYAN_ENEMY	
	beq $t4, purple_value, TOUCHED_PURPLE_ENEMY	
	bne, $t4, black_value, after_player_movement	# If pixel is not black (collision), ignore left action and continue to main loop
	
	addi $t2, $t2, 256		# Increment $t2 by 256 to get to the next left pixel (directly below previous one)
	blt $t2, $t3, check_left_collision_loop	# Iterate from top to bottom of direct left pixels of player (6 times)


# Erasing character at previous position
move $a0, $s1
jal ERASE_PLAYER	# Calling erase player function

# Moving to the left
addi $s1, $s1, -4
move $a0, $s1					
jal PAINT_PLAYER	# Calling paint player function

j after_keypress_check


# Character jumps
respond_to_w:

	# If the character is climbing, do not update the midair jump counter
	# Move up by four pixels
	jal check_climbing
	move, $t4, $v0			# Move 'check climbing' result in $t4 (0 -> no climbing, 1 -> climbing)
	bnez $t5, perform_climbing	# If $t4 != 0, climbing occurs, so skip gravity


	perform_jumping:
	# Ensures triple jumps or further are not performed
	bge $s3, 2, after_keypress_check
	
	# This loop ensures that the character jumps max 8 pixels and does not continue jumping
	# when there is a collision above it (ie. non-black pixels immediately above player)
	li $t5, 0		# Initialize $t5 = i = 0
	
	# Check if the character cannot jump at all - if so, don't update the mid-air jump counter
	addi $t5, $t5, -256	# i = i - 256
	add $t2, $s0, $s1	# Obtains address of player
	# Checking if the three pixels directly above the player are black
	lw $t3, -256($t2)					# Store colour of up (left) pixel in $t3
	bne, $t3, black_value, after_keypress_check		# If up (left) pixel is not black, don't jump
	lw $t3, -252($t2)					# Store colour of up (middle) pixel in $t3
	bne, $t3, black_value, after_keypress_check		# If up (middle) pixel is not black, don't jump
	lw $t3, -248($t2)					# Store colour of up (left) pixel in $t3
	bne, $t3, black_value, after_keypress_check		# If up (left) pixel is not black, don't jump
	
	jump_loop:
	
		addi $t5, $t5, -256	# i = i - 256
		add $t2, $s0, $s1	# Obtains address of player
		
		# Checking if the two pixels directly above the player are black
		lw $t3, -256($t2)					# Store colour of up (left) pixel in $t3
		bne, $t3, black_value, jump_loop_exit		# If up (left) pixel is not black, don't jump
		lw $t3, -252($t2)					# Store colour of up (middle) pixel in $t3
		bne, $t3, black_value, after_keypress_check		# If up (middle) pixel is not black, don't jump
		lw $t3, -248($t2)					# Store colour of up (left) pixel in $t3
		bne, $t3, black_value, after_keypress_check		# If up (left) pixel is not black, don't jump
		
		# Jumping up by one level
		# Erasing character at previous position
		move $a0, $s1
		jal ERASE_PLAYER	# Calling erase player function
		# Jumping up 1 pixel
		addi $s1, $s1, -256
		move $a0, $s1					
		jal PAINT_PLAYER	# Calling paint player function
		
		bge $t5, -2048, jump_loop	# Max distance up for full jump is 8
	
jump_loop_exit:
addi $s3, $s3, 1	# Update jump counter by 1 per jump (after entire loop was performed)
j after_keypress_check

perform_climbing:
# Climbing up by four levels
	# Erasing character at previous position
	move $a0, $s1
	jal ERASE_PLAYER	# Calling erase player function
	# Climbing up four levels
	addi $s1, $s1, -1024
	move $a0, $s1					
	jal PAINT_PLAYER	# Calling paint player function
j after_player_movement


# Character wants to move down
respond_to_s:
	# If the character is not climbing, do not move down
	# Move down by four pixels
	jal check_climbing
	move, $t4, $v0			# Move 'check climbing' result in $t4 (0 -> no climbing, 1 -> climbing)
	beqz $t5, after_keypress_check	# If $t4 == 0, climbing does not occurs, so don't move down
	
	# Climbing down by four levels
	# Erasing character at previous position
	move $a0, $s1
	jal ERASE_PLAYER	# Calling erase player function
	# Climbing down four levels
	addi $s1, $s1, 1024
	move $a0, $s1					
	jal PAINT_PLAYER	# Calling paint player function
	j after_player_movement
	


keypress_happened:
lw $t2, 4($t3) # this assumes $t3 is set to 0xfff0000 from before
beq $t2, 0x72, load_graphics # ASCII code of 'r' is 0x71 - reset game
beq $t2, 0x71, end_program # ASCII code of 'q' is 0x71 - quit game
beq $t2, 0x64, respond_to_d # ASCII code of 'd' is 0x64 - move right
beq $t2, 0x61, respond_to_a # ASCII code of 'a' is 0x61 - move left
beq $t2, 0x77, respond_to_w # ASCII code of 'w' is 0x77 - move up
beq $t2, 0x73, respond_to_s # ASCII code of 's' is 0x73 - move down
j after_keypress_check



# ACTION FUNCTIONS

# Returns 0 if there is no gravity, returns 1 if there is gravity
check_gravity:
add $t3, $s0, $s1		# Gets address of current player location
lw $t4, 2048($t3)			
bne $t4, black_value, no_gravity	# If pixel directly below player (on left) is not black, no gravity 

check_gravity_2:	# Case where middle bottom pixel is black, but we want to check right bottom pixel
lw $t4, 2052($t3)
bne, $t4, black_value, no_gravity	# If pixel directly below player (on right) is not black, check last pixel

check_gravity_3:	# Case where middle bottom pixel is black, but we want to check right bottom pixel
lw $t4, 2056($t3)
bne, $t4, black_value, no_gravity	# If pixel directly below player (on right) is not black, perform gravity
	
	gravity:
	li $v0, 1	# Function returns 1 (there is gravity)
	jr $ra
	
	no_gravity:
	li $s3, 0	# Reset number of jumps to 0 since character is on the ground
	li $v0, 0	# Function returns 0 (there is no gravity)
	jr $ra
	
# Returns 0 if there is no climbing, returns 1 if there is climbing	
check_climbing:
	li $t5, 16               # Number of repetitions for the loop = 19
	
	li $t1, 3080		# Start of high bar climbing region (top-left of it)
	li $t2, 8936		# Start of low bar climbing region (top-left of it)

	check_climbing_loop:
		
		move $t3, $t1
		move $t4, $t2
		
    		# Check for first bar if player is on horizontal area (4 pixels wide)
   		beq $s1, $t3, climbing
   		
   		addi $t3, $t3, 4
   		beq $s1, $t3, climbing
   		
   		addi $t3, $t3, 4
   		beq $s1, $t3, climbing
   		
   		addi $t3, $t3, 4
   		beq $s1, $t3, climbing
   		
   		# Check for second bar if player is on horizontal area (4 pixels wide)
   		beq $s1, $t4, climbing
   		
   		addi $t4, $t4, 4
   		beq $s1, $t4, climbing
   		
   		addi $t4, $t4, 4
   		beq $s1, $t4, climbing
   		
   		addi $t4, $t4, 4
   		beq $s1, $t4, climbing
   		
    		addi $t1, $t1, 256   # Check down
    		addi $t2, $t2, 256   # Check down
    
    		addi $t5, $t5, -1    # Decrement the counter
    		bnez $t5, check_climbing_loop  
    	
    	no_climbing:
    		li $v0, 0
    		jr $ra
    	 
	climbing:
		li $v0, 1
		jr $ra
		

# Function to update the hearts based on $s4 value
REMOVE_HEART:

addi $sp, $sp, -4	
sw $ra, 0($sp)

beq $s4, 3, remove_third_heart
beq $s4, 2, remove_second_heart
beq $s4, 1, remove_first_heart
jr $ra

remove_third_heart:
li $a0, 464					
jal PAINT_LOST_HEART
j YOU_LOSE		# Go to lost game screen	

remove_second_heart:
li $a0, 480					
jal PAINT_LOST_HEART

remove_first_heart:
li $a0, 496					
jal PAINT_LOST_HEART

lw $ra, 0($sp)
addi $sp, $sp, 4	

jr $ra	


TOUCHED_PURPLE_ENEMY:

addi $sp, $sp, -4	
sw $ra, 0($sp)

move $a0, $s6	
addi $s4, $s4, 1				
jal PAINT_HARMLESS_ENEMY_1
jal REMOVE_HEART

lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra

TOUCHED_CYAN_ENEMY:

addi $sp, $sp, -4	
sw $ra, 0($sp)

move $a0, $s7		
addi $s4, $s4, 1			
jal PAINT_HARMLESS_ENEMY_2
jal REMOVE_HEART

lw $ra, 0($sp)
addi $sp, $sp, 4
	
jr $ra

REGENERATE_ENEMIES:

# If $s5 == -1, don't regenerate enemies and don't count down
#bne $s5, -1, check_regenerate_enemies
#jr $ra

# If $s5 == 0, regenerate enemies. If not, count down $s5 by 1
check_regenerate_enemies:
#beqz $s5, regenerate_enemies
#addi $s5, $s5, -1
#jr $ra

regenerate_enemies:

addi $sp, $sp, -4	
sw $ra, 0($sp)

#Painting enemy (height 3, width 3) - spawn on top floor
move $a0, $s6					
jal PAINT_ENEMY_1		# Calling paint player function

#Painting enemy (height 3, width 3) - spawn on middle floor
move $a0, $s7					
jal PAINT_ENEMY_2		# Calling paint player function

lw $ra, 0($sp)
addi $sp, $sp, 4

li $s5, ENEMY_REGENERATION_TIME			# Start regnerate enemy counter
jr $ra


MOVE_PURPLE_ENEMY:

addi $sp, $sp, -4	
sw $ra, 0($sp)

# If $s5 != -1, freeze the harmless enemy
# $s5, -1, move_purple_enemy
#lw $ra, 0($sp)
#addi $sp, $sp, 4
#jr $ra

move_purple_enemy:

beq $s6, 4012, move_purple_left
beq $s6, 3880, move_purple_right

beq $t7, 0, move_purple_right 
beq $t7, 1, move_purple_left

move_purple_left:

li $t7, 1

# Case where purple enemy is touching something - don't make it go through object
add $t2, $s0, $s6
lw $t3, -256($t2)
bne, $t3, black_value, dont_move_purple
lw $t3, -4($t2)
bne, $t3, black_value, dont_move_purple
lw $t3, 248($t2)
bne, $t3, black_value, dont_move_purple

move $a0, $s6					
jal ERASE_ENEMY_1	# Calling erase enemy function

addi $s6, $s6, -4
move $a0, $s6					
jal PAINT_ENEMY_1	# Calling paint enemy function

lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra

move_purple_right:

li $t7, 0

# Case where purple enemy is touching something - don't make it go through object
add $t2, $s0, $s6
lw $t3, -248($t2)
bne, $t3, black_value, dont_move_purple
lw $t3, 12($t2)
bne, $t3, black_value, dont_move_purple
lw $t3, 272($t2)
bne, $t3, black_value, dont_move_purple

move $a0, $s6					
jal ERASE_ENEMY_1	# Calling erase enemy function

addi $s6, $s6, 4
move $a0, $s6					
jal PAINT_ENEMY_1	# Calling paint enemy function

lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra

dont_move_purple:
lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra


MOVE_CYAN_ENEMY:

addi $sp, $sp, -4	
sw $ra, 0($sp)

# If $s5 != -1, freeze the harmless enemy
#beq $s5, -1, move_cyan_enemy
#lw $ra, 0($sp)
#addi $sp, $sp, 4
#jr $ra

move_cyan_enemy:

beq $s7, 9520, move_cyan_right
beq $s7, 9676, move_cyan_left

beq $t8, 0, move_cyan_left 
beq $t8, 1, move_cyan_right

move_cyan_right:

li $t8, 1

# Case where cyan enemy is touching something - don't make it go through object
add $t2, $s0, $s7
lw $t3, 508($t2)
bne, $t3, black_value, dont_move_cyan
lw $t3, 524($t2)
bne, $t3, black_value, dont_move_cyan

move $a0, $s7					
jal ERASE_ENEMY_2	# Calling erase enemy function

addi $s7, $s7, 4
move $a0, $s7					
jal PAINT_ENEMY_2	# Calling paint enemy function

lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra

move_cyan_left:

li $t8, 0

# Case where cyan enemy is touching something - don't make it go through object
add $t2, $s0, $s7
lw $t3, -4($t2)
bne, $t3, black_value, dont_move_cyan
lw $t3, 12($t2)
bne, $t3, black_value, dont_move_cyan

move $a0, $s7					
jal ERASE_ENEMY_2	# Calling erase enemy function

addi $s7, $s7, -4
move $a0, $s7					
jal PAINT_ENEMY_2	# Calling paint enemy function

lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra

dont_move_cyan:
lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra	

# GRAPHICS FUNCTIONS

# Fills any specified pixels from a start range $a0 (inclusive) to end range $a1 (non-inclusive)
# Fills pixels with colour stored in $a2 argument
FILL_PIXELS_LEFT_TO_RIGHT:

move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
move, $t2, $a1		# Store the a1 arg (end pixel) in $t2
move, $t3, $a2		# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel
add $t2, $t2, $t0       # Add base address to get the actual address - end pixel

fill_pixels_left_to_right_loop:
    sw $t3, 0($t1)      # Fill the pixel with the color in $t3
    addi $t1, $t1, 4    # Move to the next pixel address by updating $a0 by 4s
    blt $t1, $t2, fill_pixels_left_to_right_loop # Repeat until the ending address is reached

jr $ra


PAINT_ELEVATED_PLATFORM:
move, $t0, $a0		# Store the a0 arg (start pixel) in $t0
addi, $t1, $t0, 768	# Specified the platform is 3 pixels tall

addi $sp, $sp, -4	
sw $ra, 0($sp)		# Store $ra on stack - since we will call functions inside this function

paint_elevated_platform_loop:
	# Push $t0, then $t1 in the stack
	# so they don't get overwritten in fill pixel function call
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	
	addi $a0, $t0, 0
	addi $a1, $t0, 224		# 224/4=56 specifies platform to paint is 56 pixels wide
	li $a2, red_value
	
	jal FILL_PIXELS_LEFT_TO_RIGHT
	
	# Pop $t1, then $t0 from the stack after fill pixel function call
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	# Loop increment
	addi $t0, $t0, 256
	
	# Loop condition
	blt $t0, $t1, paint_elevated_platform_loop

lw $ra, 0($sp)
addi $sp, $sp, 4	# Pop $ra

jr $ra


# Paints the player from the starting pixel (upper-left corner)
# The player is 6 pixels tall and 2 pixels wide
PAINT_PLAYER:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t2, brown_value	
li, $t3, yellow_value
li, $t4, blue_value

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t2, 0($t1)      	# Fill the player's hair brown
sw $t2, 4($t1)
sw $t2, 8($t1)

sw $t3, 256($t1)      	# Fill the player's face yellow
sw $t3, 260($t1)
sw $t3, 264($t1)
sw $t3, 512($t1)    	  	
sw $t3, 516($t1)
sw $t3, 520($t1)

sw $t4, 768($t1)	# Fills the player's clothes blue
sw $t4, 772($t1)
sw $t4, 776($t1)
sw $t4, 1024($t1)
sw $t4, 1028($t1)
sw $t4, 1032($t1)
sw $t4, 1280($t1)
sw $t4, 1284($t1)
sw $t4, 1288($t1)
sw $t4, 1536($t1)
sw $t4, 1540($t1)
sw $t4, 1544($t1)
sw $t4, 1792($t1)
sw $t4, 1796($t1)
sw $t4, 1800($t1)

jr $ra


# Paints the player from the starting pixel (upper-left corner)
# The player is 6 pixels tall and 2 pixels wide
ERASE_PLAYER:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t2, black_value	

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t2, 0($t1)      	# Erase player's hair 
sw $t2, 4($t1)
sw $t2, 8($t1)

sw $t2, 256($t1)      	# Erase player's face
sw $t2, 260($t1)
sw $t2, 264($t1)
sw $t2, 512($t1)    	  	
sw $t2, 516($t1)
sw $t2, 520($t1)

sw $t2, 768($t1)	# Erase player's clothes
sw $t2, 772($t1)
sw $t2, 776($t1)
sw $t2, 1024($t1)
sw $t2, 1028($t1)
sw $t2, 1032($t1)
sw $t2, 1280($t1)
sw $t2, 1284($t1)
sw $t2, 1288($t1)
sw $t2, 1536($t1)
sw $t2, 1540($t1)
sw $t2, 1544($t1)
sw $t2, 1792($t1)
sw $t2, 1796($t1)
sw $t2, 1800($t1)

jr $ra

PAINT_ENEMY_1:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, purple_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill the first enemy row
sw $t3, 4($t1)	    	
sw $t3, 8($t1)
sw $t3, -252($t1)	# Fill top spike

sw $t3, 252($t1)	# Fill the second enemy row
sw $t3, 256($t1)    	
sw $t3, 260($t1)	
sw $t3, 264($t1)
sw $t3, 268($t1)

sw $t3, 512($t1)    	# Fill the third enemy row	
sw $t3, 520($t1)

jr $ra

PAINT_HARMLESS_ENEMY_1:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, white_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill the first enemy row
sw $t3, 4($t1)	    	
sw $t3, 8($t1)
sw $t3, -252($t1)	# Fill top spike

sw $t3, 252($t1)	# Fill the second enemy row
sw $t3, 256($t1)    	
sw $t3, 260($t1)	
sw $t3, 264($t1)
sw $t3, 268($t1)

sw $t3, 512($t1)    	# Fill the third enemy row	
sw $t3, 520($t1)

jr $ra

ERASE_ENEMY_1:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, black_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill the first enemy row
sw $t3, 4($t1)	    	
sw $t3, 8($t1)
sw $t3, -252($t1)	# Fill top spike

sw $t3, 252($t1)	# Fill the second enemy row
sw $t3, 256($t1)    	
sw $t3, 260($t1)	
sw $t3, 264($t1)
sw $t3, 268($t1)

sw $t3, 512($t1)    	# Fill the third enemy row	
sw $t3, 520($t1)

jr $ra

PAINT_ENEMY_2:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, cyan_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill the first enemy row   	
sw $t3, 8($t1)

sw $t3, 260($t1)    	# Fill the second enemy row	

sw $t3, 512($t1)	# Fill enemy feet
sw $t3, 520($t1)

jr $ra

PAINT_HARMLESS_ENEMY_2:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, white_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill the first enemy row   	
sw $t3, 8($t1)

sw $t3, 260($t1)    	# Fill the second enemy row	

sw $t3, 512($t1)	# Fill enemy feet
sw $t3, 520($t1)

jr $ra

ERASE_ENEMY_2:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, black_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill the first enemy row   	
sw $t3, 8($t1)

sw $t3, 260($t1)    	# Fill the second enemy row	

sw $t3, 512($t1)	# Fill enemy feet
sw $t3, 520($t1)

jr $ra


# Paints the door on the right side of the top platform
PAINT_DOOR:
move, $t0, $a0		# Store the a0 arg (start pixel) in $t0
addi, $t1, $t0, 2560	# Specified the door is 10 pixels tall

addi $sp, $sp, -4	
sw $ra, 0($sp)		# Store $ra on stack - since we will call functions inside this function

paint_door_loop:
	# Push $t0, then $t1 in the stack
	# so they don't get overwritten in fill pixel function call
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	
	addi $a0, $t0, 0
	addi $a1, $t0, 24		# 24/4=6 specifies character to paint is 6 pixels wide
	li $a2, brown_value
	
	jal FILL_PIXELS_LEFT_TO_RIGHT
	
	# Pop $t1, then $t0 from the stack after fill pixel function call
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	# Loop increment
	addi $t0, $t0, 256
	
	# Loop condition
	blt $t0, $t1, paint_door_loop

lw $ra, 0($sp)
addi $sp, $sp, 4	# Pop $ra

jr $ra


# Paints a bar - they are used for climbing to the platforms
PAINT_BAR:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, green_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0        # Left vertical bar start pixel
addi $t2, $t1, 28        # Right vertical bar start pixel

addi $t5, $t1, 4	   # Left spokes of the bar
addi $t6, $t1, 24	   # Right spokes of the bar

li $t4, 12               # Number of repetitions for each pixel = 12

paint_bar_sides_loop:
    # Filling left vertical line
    sw $t3, 0($t1)       # Fill the pixel with the color in $t3 for the left bar
    addi $t1, $t1, 256   # Move to the next pixel address for the left bar

    # Filling right vertical line
    sw $t3, 0($t2)       # Fill the pixel with the color in $t3 for the right bar
    addi $t2, $t2, 256   # Move to the next pixel address for the right bar
    
    addi $t4, $t4, -1    # Decrement the counter
    bnez $t4, paint_bar_sides_loop  
    
# Add left and right spokes of the ladder
li $t4, 5 # number of reptitions for each pixel = 5
addi $t5, $t5, 512	# Shifting down initial spoke (left) 2 levels down
addi $t6, $t6, 512	# Shifting down initial spoke (right) 2 levels down
paint_bar_spokes_loop:
    # Filling left spokes of the bar
    sw $t3, 0($t5)       # Fill the pixel with the color in $t3 for the left spokes
    addi $t5, $t5, 512   # Move to the next pixel address for the left spokes
    
    # Filling right spokes of the bar
    sw $t3, 0($t6)       # Fill the pixel with the color in $t3 for the right spokes
    addi $t6, $t6, 512   # Move to the next pixel address for the right spokes
    
    addi $t4, $t4, -1    # Decrement the counter
    bnez $t4, paint_bar_spokes_loop  

jr $ra


# Function to paint a heart
PAINT_HEART:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, red_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill top heart row
sw $t3, 8($t1)	    	
sw $t3, 256($t1)    	# Fill middle of heart	
sw $t3, 260($t1)
sw $t3, 264($t1)	
sw $t3, 516($t1)	# Fill bottom of heart

jr $ra

# Function to draw a lost heart
PAINT_LOST_HEART:
move, $t0, $s0		# Storing $s0's value (BASE_ADDRESS) in a temporary register
move, $t1, $a0		# Store the a0 arg (start pixel) in $t1
li, $t3, white_value	# Store the a2 arg (colour) in $t3

add $t1, $t1, $t0       # Add base address to get the actual address - start pixel

sw $t3, 0($t1)      	# Fill top heart row
sw $t3, 8($t1)	    	
sw $t3, 256($t1)    	# Fill middle of heart	
sw $t3, 260($t1)
sw $t3, 264($t1)	
sw $t3, 516($t1)	# Fill bottom of heart

jr $ra

# Function to draw a face at the end of the game
PAINT_RECTANGLE:

addi $sp, $sp, -4	
sw $ra, 0($sp)		# Store $ra on stack - since we will call functions inside this function

move, $t0, $a0		# Store the a0 arg (start pixel) in $t0
move, $t3, $a1		# Stores width
move, $t1, $a2		# Stores height
move $t4, $a3		# stores colour

li $t5, 4
mult $t3, $t5
mflo $t5 

paint_rectangle_loop:
	# Push $t0, then $t1 in the stack
	# so they don't get overwritten in fill pixel function call
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	
	addi $a0, $t0, 0
	add $a1, $t0, $t5
	move $a2, $t4
	jal FILL_PIXELS_LEFT_TO_RIGHT
	
	# Pop $t1, then $t0 from the stack after fill pixel function call
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	# Loop increment
	addi $t0, $t0, 256
	
	addi $t1, $t1 -1
	
	# Loop condition
	bnez $t1, paint_rectangle_loop
	
lw $ra, 0($sp)
addi $sp, $sp, 4	# Pop $ra

jr $ra


# Function to draw a face at the end of the game
PAINT_FACE_AND_EYES:

addi $sp, $sp, -4	
sw $ra, 0($sp)		# Store $ra on stack - since we will call functions inside this function

# Paints face
li, $a0, 5152		# Store the a0 arg (start pixel) in $t0
li, $a1, 30		# Stores width
li, $a2, 30		# Stores height
li $a3, bright_yellow_value		# stores colour
jal PAINT_RECTANGLE

# Painrs left eye
li, $a0, 6712		# Store the a0 arg (start pixel) in $t0
li, $a1, 5		# Stores width
li, $a2, 5		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

# Paints right eye
li, $a0, 6764		# Store the a0 arg (start pixel) in $t0
li, $a1, 5		# Stores width
li, $a2, 5		# Stores height
li $a3, black_value		# stores colour
jal PAINT_RECTANGLE

lw $ra, 0($sp)
addi $sp, $sp, 4	# Pop $ra

jr $ra

