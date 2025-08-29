# CSCB58 Assembly Project (Winter 2024)

## About:
2D platform game written entirely in MIPS assembly (32 bits).

## Objective:
Navigate through the platforms to reach the door. Along the way, you will need to avoid moving enemies. You are given three lives.

## Setup:
1. Open the MARS Assembly Simulator (download from here https://computerscience.missouristate.edu/mars-mips-simulator.htm)
2. Open `game.asm` in MARS Simulator
3. Under "Tools", select "Keyboard and Display MMIO Simulator". Click "Connect to MIPS" on the new window
5. Under "Tools" again, select "Bitmap Display"
6. Use the following configurations:

    - Unit Width in Pixels: 4
    - Unit Height in Pixels: 4
    - Display Width in Pixels: 256
    - Display Height in Pixels: 256
    - Base address for display: 0x10008000 ($gp)
   
    Click "Connect to MIPS" when done.
  
8. Under "Run", click "Assemble", then click "Go"
9. The game has started. Ensure that all keyboard input gets typed in the "Keyboard and Display MMIO Simulator" window

## Keyboard inputs:
- w: jump
- a: navigate left
- s: climb down
- d: navigate right
- r: restart the game
- q: quit

## Features:
- Double jump
- Moving enemies
