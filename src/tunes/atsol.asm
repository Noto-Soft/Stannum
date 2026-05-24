include '../inc/notes.inc'

SONG_TIME = BASE_TIME / 7 * 4

dw TIME
dd SONG_TIME

; cataclysm wave

dw Gs4, G4, C4, As4, G4, C4, Gs4, G4, C4, C5, G4, C4, As4, C4, Ds5, C4
dw D5, Ds5, D5, As4, F4, As4, Gs4, G4, F4, G4, F4, Ds4, D4, Ds4, D4, As3
dw Gs3, As3, Ds4, G4, Gs3, Ds4, G4, As4, Ds4, As4, Ds5, G5, As4, D5, F5, As5
dw D5, F5, As5, C6, F5, As5, C6, D6, F6, Ds6, D6, C6, As5, C6, D6, F6
dw Ds6, F6, Ds6, C6, G5, C6, D6, Ds6, D6, As5, F5, As5
dw C6, D6, C6, Gs5, Ds5, Gs5, As5, C6, As5, G5, D5, G5
dw Gs5, G5, F5, Ds5, G5, F5, Ds5, D5
dw Gs5, Gs4, Ds4, C6, Gs4, Ds4, As5, Gs4, Ds4, C6, Gs4, Ds4
dw As5, D5, As4, D6, D5, As4, Ds6, D5, As4, F6, D5, As4
dw F4, As4, D5, F5, As5, D6, F6, As6

; transition from cata to bloodbath

dw G5, Ds5, C5, Ds5, G4, C5, Ds4, G4, C4, G4, Ds4, G4, C5, G5, F5, Ds5
dw G5, Ds5, C5, Ds5, G4, C5, Ds4, G4, C4, G4, Ds4, G4, C5, G5, F5, Ds5
dw Fs5, Cs5, C5, Cs5, As4, Cs5, Fs4, Cs5, Cs4, Cs5, C5, As4, Fs4, As4, Cs5, F5
dw Fs5, Cs5, C5, Cs5, Fs4, Cs5, Cs4, Cs5, Fs4, Cs5, C5, Cs5, Fs5, As5, C6, Cs6
dw G5, Ds5, C5, Ds5, G4, C5, Ds4, G4, C4, G4, Ds4, G4, C5, G5, F5, Ds5
dw G5, Ds5, C5, Ds5, G4, C5, Ds4, G4, C4, G4, Ds4, G4, C5, G5, F5, Ds5

dw TIME
dd SONG_TIME * 32 ; multiply by 32 to save on 31 CONT words (62 wasted bytes)

dw Fs5

; bloodbath first and second ship, first ball

dw TIME
dd SONG_TIME

dw C6, Gs5, F5, C5, F4, G4, Gs4, C5, C6, Gs5, F5, C5, F4, G4, Gs4, C5
dw F4, G4, Gs4, C5, G4, Gs4, C5, F5, Gs4, C5, F5, Gs5, C5, F5, Gs5, As5
dw C6, Gs5, F5, Gs5, Cs5, F5, Gs4, Cs5, F4, Gs4, Cs4, F4, Gs3, Cs4, F4, G4
dw Gs5, G5, F5, Cs5, F5, G5, Gs5, Cs6, F6, Ds6, Cs6, Gs5, Cs6, Ds6, F6, Gs6
dw C6, Gs5, F5, C5, F4, G4, Gs4, C5, C6, Gs5, F5, C5, F4, G4, Gs4, C5
dw F4, G4, Gs4, C5, G4, Gs4, C5, F5, Gs4, C5, F5, Gs5, C5, F5, Gs5, As5
dw C6, Gs5, F5, Gs5, Cs5, F5, Gs4, Cs5, F4, Gs4, Cs4, F4, Gs3, Cs4, F4, G4
dw Gs5, G5, F5, Cs5, F5, G5, Gs5, Cs6, F6, Ds6, Cs6, Gs5, Cs6, Ds6, F6, Gs6

; bloodbath second ball

dw G5, C5, D5, Ds5, D5, C5, Gs5, C5, D5, Ds5, D5, C5
dw G5, C5, D5, Ds5, D5, C5, As5, C5, D5, Ds5, D5, C5
dw Gs5, C5, D5, Ds5, G5, Ds5, D5, C5
dw Gs5, Gs4, C5, Ds5, C5, Gs4, Ds6, Gs4, C5, Ds5, C5, Gs4
dw D6, Gs4, C5, Ds5, C5, Gs4, As5, Gs4, C5, Ds5, C5, Gs4
dw D6, Gs4, C5, Ds5, Ds6, Ds5, C5, Gs4
dw As5, G4, As4, Ds5, As4, G4, Gs5, G4, As4, Ds5, As4, G4
dw G5, G4, As4, Ds5, As4, G4, Gs5, G4, As4, Ds5, As4, G4
dw G5, G4, As4, G4, Ds5, G4, As4, G4
dw G4, Ds4, G4, D4, B4, G4, D5, B4, D5, B4, F5, D5, F5, D5
dw G5, F5, G5, F5, B5, G5, B5, G5, D6, B5, G6, F6, Ds6, D6, F6, Ds6, D6, Ds6

dw TIME
dd SONG_TIME * 16 ; multiply by 32 to save on 15 CONT words (31 wasted bytes)

dw C6, ENDS