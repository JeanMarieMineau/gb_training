;Source tuto pong 0.1
;Gameboy DMG WLA-DX
;CC furrtek.org 2011

.ROMDMG                         ;Pas de features CGB
.NAME "PONGDEMO"                ;Nom du ROM inscrit dans le header
.CARTRIDGETYPE 0                ;ROM only
.RAMSIZE 0
.COMPUTEGBCHECKSUM              ;WLA-DX �crira le checksum lui-m�me (n�cessaire sur une vraie GB)
.COMPUTEGBCOMPLEMENTCHECK       ;WLA-DX �crira le code de verif du header (n�cessaire sur une vraie GB)
.LICENSEECODENEW "00"           ;Code de license Nintendo, j'en ai pas donc...
.EMPTYFILL $00                  ;Padding avec des 0

.MEMORYMAP
SLOTSIZE $4000
DEFAULTSLOT 0
SLOT 0 $0000
SLOT 1 $4000
.ENDME

.ROMBANKSIZE $4000              ;Deux banks de 16Ko
.ROMBANKS 2

.BANK 0 SLOT 0

.ENUM $C000
RaquetteY  DB
Raquette2Y DB
BalleX     DB
BalleY     DB
VitX       DB
VitY       DB

.ENDE

.ORG $0040
call      VBlank                ;L'interruption VBlank tombe ici
reti

.ORG $0100
nop
jp    start                     ;Entry point

.ORG $0104
;Logo Nintendo, obligatoire
.db $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C
.db $00,$0D,$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6
.db $DD,$DD,$D9,$99,$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC
.db $99,$9F,$BB,$B9,$33,$3E

.org $0150
start:
  di                            ;Interruption d�sactiv�es
  ld     sp,$FFF4               ;D�but du stack � $FFF4 parce que Nintendo le veut

  xor a
  ldh    ($26),a                ;Coupe le circuit son

waitvbl:
  ldh    a,($44)                ;Attend le d�but d'un VBL (premi�re ligne hors de l'�cran, Y>144)
  cp     144
  jr     c, waitvbl

  ld     a,%00010001            ;�teins l'�cran
  ldh    ($40),a

  ;Charge 3 tiles
  ld     b,8*3*2                ;3*8 lignes 2BPP
  ld     de,tiles
  ld     hl,$8000
ldt:
  ld     a,(de)
  ldi    (hl),a
  inc    de
  dec    b
  jr     nz,ldt

  ld     de,32*32               ;Vide la map BKG
  ld     hl,$9800
clmap:
  xor    a
  ldi    (hl),a
  dec    de
  ld     a,e
  or     d
  jr     nz,clmap

  ld     hl,$FE00               ;Vide l'OAM
  ld     b,40*4
clspr:
  ld     (hl),$00
  inc    l                      ;Contournement bug hardware
  dec    b
  jr     nz,clspr

  xor    a
  ldh    ($42),a                ;Scroll Y
  ldh    ($43),a                ;Scroll X

  ld     hl,$FE00
  ld     b,4
  xor    a
ldspr:
  ld     (hl),a                 ;OAM raquette Y
  add    8                      ;Prochain Y ++8
  inc    l                      ;Pas de LDI ou de INC HL ici, bug hardware
  ld     (hl),$10               ;OAM raquette X
  inc    l
  ld     (hl),$01               ;OAM raquette tile
  inc    l
  ld     (hl),$00               ;OAM raquette attribut
  inc    l
  dec    b
  jr     nz,ldspr               ;fin de la boucle pour load les raquettes


;deuxi�me raquette


  ld     b,4
  xor    a
ldspr2:
  ld     (hl),a                 ;OAM raquette2 Y
  add    8                      ;Prochain Y ++8
  inc    l                      ;Pas de LDI ou de INC HL ici, bug hardware
  ld     (hl),$8C               ;OAM raquette2 X
  inc    l
  ld     (hl),$01               ;OAM raquette2 tile
  inc    l
  ld     (hl),$00               ;OAM raquett2e attribut
  inc    l
  dec    b
  
  jr     nz,ldspr2               ;fin de la boucle pour load les raquettes
  
  ld     (hl),$80               ;OAM balle Y
  inc    l
  ld     (hl),$80               ;OAM balle X
  inc    l
  ld     (hl),$02               ;OAM balle tile
  inc    l
  ld     (hl),0                 ;OAM balle attribut

  ld     a,$20
  ld     (RaquetteY),a
  ld     a,$20
  ld     (Raquette2Y),a            ;Inits variables
  ld     a,$80
  ld     (BalleX),a
  ld     (BalleY),a
  ld     a,2
  ld     (VitX),a
  ld     (VitY),a


  ld     a,%11100100            ;Palette BG
  ldh    ($47),a
  ldh    ($48),a                ;Palette sprite 0
  ldh    ($49),a                ;Palette sprite 1 (sert pas)
  ld     a,%10010011            ;Allume l'�cran, BG on, tiles � $8000
  ldh    ($40),a

  ld     a,%00010000            ;Interruptions VBlank activ�es
  ldh    ($41),a
  ld     a,%00000001            ;Interruptions VBlank activ�e (double activation � la con)
  ldh    ($FF),a

  ei

loop:
  jr     loop



VBlank:
  push   af
  push   hl

  ld     a,%00100000            ;Selection touches de direction
  ldh    ($00),a
  
  ldh    a,($00)
  ld     b,a

  bit    $1,b                   ;Gauche
  jr     nz,nod
  ld     a,(RaquetteY)
  inc    a
  inc    a
  ld     (RaquetteY),a
  cp     144+16-32              ;Bordure �cran bas
  jr     c,nod
  ld     a,144+16-32
  ld     (RaquetteY),a
nod:

  bit    $2,b                   ;Haut
  jr     nz,nou
  ld     a,(RaquetteY)
  dec    a
  dec    a
  ld     (RaquetteY),a
  cp     16                     ;Bordure �cran haut
  jr     nc,nou
  ld     a,16
  ld     (RaquetteY),a
nou:

;on refait comme en haut mais avec gauche et droite pour faire bouger la deuxi�me raquette
  bit    $3,b                   ;bas
  jr     nz,nod2
  ld     a,(Raquette2Y)
  inc    a
  inc    a
  ld     (Raquette2Y),a
  cp     144+16-32              ;Bordure �cran bas
  jr     c,nod2
  ld     a,144+16-32
  ld     (Raquette2Y),a
nod2:

  bit    $0,b                   ;Droite
  jr     nz,nou2
  ld     a,(Raquette2Y)
  dec    a
  dec    a
  ld     (Raquette2Y),a
  cp     16                     ;Bordure �cran haut
  jr     nc,nou2
  ld     a,16
  ld     (Raquette2Y),a
nou2:

  ld     hl,$FE00
  ld     a,(RaquetteY)
  ld     (hl),a                 ;OAM raquette 0 Y
  ld     hl,$FE04
  add    $8
  ld     (hl),a                 ;OAM raquette 1 Y
  ld     hl,$FE08
  add    $8
  ld     (hl),a                 ;OAM raquette 2 Y
  ld     hl,$FE0C
  add    $8
  ld     (hl),a                 ;OAM raquette 3 Y
  
  
  
  ;Raquette2
  ld     hl,$FE10
  ld     a,(Raquette2Y)
  ld     (hl),a                 ;OAM raquette 0 Y
  ld     hl,$FE14
  add    $8
  ld     (hl),a                 ;OAM raquette 1 Y
  ld     hl,$FE18
  add    $8
  ld     (hl),a                 ;OAM raquette 2 Y
  ld     hl,$FE1C
  add    $8
  ld     (hl),a                 ;OAM raquette 3 Y
  


  ld     hl,BalleX
  ld     a,(VitX)
  add    (hl)

  cp     160                    ;BalleX < 160: pas de collision mur droit
  jr     c,nocxr
  call   lowbeep
  ;rajout de la fonctionnalit� de score
  ;ld     a,(ScoreD)
  ;add 1
  ;ld (ScoreD),a




  ld     a,$FE                  ;-2
  ld     (VitX),a
  ld     a,160                  ;Limite � 160
nocxr:

  cp     2
  jr     nc,nocxl               ;BalleX > 2: pas de collision mur gauche
  call   lowbeep
   ;rajout de la fonctionnalit� de score

  ld     a,2
  ld     (VitX),a
  ld     a,8
nocxl:
  ld     (hl),a
  


  ld     hl,BalleY
  ld     a,(VitY)
  add    (hl)

  cp     144+8
  jr     c,nocyr                ;Collision bas
  call   lowbeep
  ld     a,$FE
  ld     (VitY),a
  ld     a,144+8                ;Limite
nocyr:
  cp     8+8
  jr     nc,nocyl               ;Collision haut
  call   lowbeep
  ld     a,2
  ld     (VitY),a
  ld     a,8+8                  ;Limite
nocyl:
  ld     (hl),a
  
  ;collison raquette 1

  ld     a,(BalleX)
  cp     8+16
  jr     nc,nopaddle            ;BalleX > 8+16: pas de collision raquette
  cp     8+10
  jr     c,nopaddle             ;BalleX < 8+10: pas de collision raquette
  ld     a,(VitX)
  cp     2
  jr     z,nopaddle             ;Vitesse positive: pas de collision raquette

  ld     a,(BalleY)
  add    8
  ld     b,a
  ld     a,(RaquetteY)
  cp     b
  jr     nc,nopaddle            ;PaddleY > BalleY+8: pas de collision raquette haute

  ld     hl,BalleY
  ld     a,(RaquetteY)
  add    32
  cp     (hl)
  jr     c,nopaddle             ;PaddleY+32 < BalleY: pas de collision raquette basse


  call   hibeep                 ;Rebond raquette
  ld     a,2
  ld     (VitX),a

nopaddle:

   ;collisions raquette 2
  ld     a,(BalleX)
  cp     138
  jr     c,nopaddle2             ;BalleX < 8+144: pas de collision raquette 2
  cp     144
  jr     nc,nopaddle2            ;BalleX > 8+150: pas de collision raquette2
  ld     a,(VitX)
  cp     2
  jr     nz,nopaddle2             ;Vitesse negative: pas de collision raquette2

  ld     a,(BalleY)
  add    8
  ld     b,a
  ld     a,(Raquette2Y)
  cp     b
  jr     nc,nopaddle2            ;PaddleY > BalleY+8: pas de collision raquette haute

  ld     hl,BalleY
  ld     a,(Raquette2Y)
  add    32
  cp     (hl)
  jr     c,nopaddle2             ;PaddleY+32 < BalleY: pas de collision raquette basse

  call   hibeep                 ;Rebond raquette
  ld     a,$FE
  ld     (VitX),a

  nopaddle2:
  ld     hl,$FE20
  ld     a,(BalleY)
  ld     (hl),a                 ;OAM balle Y
  inc    l
  ld     a,(BalleX)
  ld     (hl),a                 ;OAM balle X
  
                                ;OAM score
  
  


  pop    hl
  pop    af
  ret



lowbeep:
  call   setsnd
  ld     a,%00000000
  ldh    ($13),a
  ld     a,%11000111
  ldh    ($14),a
  ret

  
hibeep:
  call   setsnd
  ld     a,%11000000
  ldh    ($13),a
  ld     a,%11000111
  ldh    ($14),a
  ret


setsnd:
  ld     a,%10000000
  ldh    ($26),a

  ld     a,%01110111
  ldh    ($24),a
  ld     a,%00010001
  ldh    ($25),a

  ld     a,%10111000
  ldh    ($11),a
  ld     a,%11110000
  ldh    ($12),a
  ret

  .ORG   $0800
tiles:
  .INCBIN "tiles.bin"
