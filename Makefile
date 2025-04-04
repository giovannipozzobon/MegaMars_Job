# -----------------------------------------------------------------------------

megabuild		= 0
attachdebugger	= 0

# -----------------------------------------------------------------------------

MAKE			= make
CP				= cp
MV				= mv
RM				= rm -f
CAT				= cat

SRC_DIR			= ./src
EXE_DIR			= ./exe
BIN_DIR			= ./bin

CC1541			= cc1541
MC				= MegaConvert
MEGAADDRESS		= megatool -a
MEGACRUNCH		= megatool -c
MEGAIFFL		= megatool -i
EL				= etherload
XMEGA65			= D:\PCTOOLS\xemu\xmega65.exe
MEGAFTP			= mega65_ftp -e

.SUFFIXES: .o .s .out .bin .pu .b2 .a

default: all

VPATH = src

# Common source files
ASM_SRCS = decruncher.s iffl.s irqload.s irq_fastload.s irq_main.s startup.s program_asm.s
C_SRCS = keyboard.c main.c dma.c modplay.c dmajobs.c program.c

OBJS = $(ASM_SRCS:%.s=$(EXE_DIR)/%.o) $(C_SRCS:%.c=$(EXE_DIR)/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=$(EXE_DIR)/%-debug.o) $(C_SRCS:%.c=$(EXE_DIR)/%-debug.o)

BINFILES  = $(BIN_DIR)/gfx_chars0.bin
BINFILES += $(BIN_DIR)/mapcol_pal0.bin
BINFILES += $(BIN_DIR)/maphgt_chars0.bin
BINFILES += $(BIN_DIR)/mapcol_chars0.bin
BINFILES += $(BIN_DIR)/song.mod

BINFILESMC  = $(BIN_DIR)/gfx_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/mapcol_pal0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/maphgt_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/mapcol_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/song.mod.addr.mc

# -----------------------------------------------------------------------------

# character mode = 1 = SuperExtendedAttributeMode
# direction      = 3 = CharTopBottomLeftRight
$(BIN_DIR)/gfx_chars0.bin: $(BIN_DIR)/gfx.bin
	$(MC) $< cm1:1 d1:3 cl1:18000 rc1:0

# character mode = 1 = SuperExtendedAttributeMode
# direction      = 2 = PixelLeftRightTopBottom
$(BIN_DIR)/maphgt_chars0.bin: $(BIN_DIR)/maphgt.bin
	$(MC) $< cm1:1 d1:2 cl1:20000 rc1:0

# character mode = 1 = SuperExtendedAttributeMode
# direction      = 2 = PixelLeftRightTopBottom
$(BIN_DIR)/mapcol_pal0.bin: $(BIN_DIR)/mapcol.bin
	$(MC) $< cm1:1 d1:2 cl1:30000 rc1:0

$(BIN_DIR)/alldata.bin: $(BINFILES)
	$(MEGAADDRESS) $(BIN_DIR)/gfx_chars0.bin      00018000
	$(MEGAADDRESS) $(BIN_DIR)/mapcol_pal0.bin     0000c000
	$(MEGAADDRESS) $(BIN_DIR)/maphgt_chars0.bin   00020000
	$(MEGAADDRESS) $(BIN_DIR)/mapcol_chars0.bin   00030000
	$(MEGAADDRESS) $(BIN_DIR)/song.mod            08000000
	$(MEGACRUNCH) $(BIN_DIR)/gfx_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/mapcol_pal0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/maphgt_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/mapcol_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/song.mod.addr
	$(MEGAIFFL) $(BINFILESMC) $(BIN_DIR)/alldata.bin

$(EXE_DIR)/%.o: %.s
	as6502 --target=mega65 --list-file=$(@:%.o=%.lst) -o $@ $<

$(EXE_DIR)/%.o: %.c
	cc6502 --target=mega65 --code-model=plain -O2 --list-file=$(@:%.o=%.lst) -o $@ $<

$(EXE_DIR)/%-debug.o: %.s
	as6502 --target=mega65 --debug --list-file=$(@:%.o=%.lst) -o $@ $<

$(EXE_DIR)/%-debug.o: %.c
	cc6502 --target=mega65 --debug --list-file=$(@:%.o=%.lst) -o $@ $<

# there are multiple places that need to be changed for the start address:
# ln6502 command line option --load-address 0x1001
# megacrunch start address -f 100e
# scm file   address (#x1001) section (programStart #x1001)

$(EXE_DIR)/megamars.prg: $(OBJS)
	ln6502 --target=mega65 mega65-custom.scm -o $@ $^ --load-address 0x1200 --raw-multiple-memories --cstartup=mystartup --rtattr printf=nofloat --rtattr exit=simplified --output-format=prg --list-file=$(EXE_DIR)/cprog.lst

$(EXE_DIR)/megamars.prg.mc: $(EXE_DIR)/megamars.prg
	$(MEGACRUNCH) -f 1200 $(EXE_DIR)/megamars.prg

# -----------------------------------------------------------------------------

$(EXE_DIR)/megamars.d81: $(EXE_DIR)/megamars.prg.mc  $(BIN_DIR)/alldata.bin
	$(RM) $@
	$(CC1541) -n "megamars" -i " 2025" -d 19 -v\
	 \
	 -f "megamars" -w $(EXE_DIR)/megamars.prg.mc \
	 -f "megamars.data" -w $(BIN_DIR)/alldata.bin \
	$@

# -----------------------------------------------------------------------------

run: $(EXE_DIR)/megamars.d81

ifeq ($(megabuild), 1)
	$(MEGAFTP) -c "put .\exe\megamars.d81 megamars.d81" -c "quit"
	$(EL) -m MEGAMARS.D81 -r $(EXE_DIR)/megamars.prg.mc
ifeq ($(attachdebugger), 1)
	m65dbg --device /dev/ttyS2
endif
else
ifeq ($(attachdebugger), 1)
	cmd.exe /c "$(XMEGA65) -uartmon :4510 -autoload -8 $(EXE_DIR)/megamars.d81" & m65dbg -l tcp 4510
else
	cmd.exe /c "$(XMEGA65) -autoload -8 $(EXE_DIR)/megamars.d81"
endif
endif

clean:
	-rm -f $(OBJS) $(OBJS:%.o=%.clst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.clst) $(BIN_DIR)/*_*.bin
	-rm -f $(EXE_DIR)/megamars.d81 $(EXE_DIR)/megamars.elf $(EXE_DIR)/megamars.prg $(EXE_DIR)/megamars.prg.mc $(EXE_DIR)/megamars.lst $(EXE_DIR)/megamars-debug.lst
