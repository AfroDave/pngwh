ASM=nasm
LD=ld

ASMFLAGS=-f elf64
LDFLAGS=

SRCDIR=src
OBJDIR=build
BINDIR=bin

TARGET=pngwh
SRCS=$(wildcard $(SRCDIR)/*.asm)
OBJS=$(SRCS:$(SRCDIR)/%.asm=$(OBJDIR)/%.o)

all: init $(BINDIR)/$(TARGET)

$(BINDIR)/$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $< -o $@

$(OBJS): $(SRCS)
	$(ASM) $(ASMFLAGS) $< -o $@

init:
	mkdir -p $(BINDIR) $(OBJDIR)

clean:
	rm -f $(OBJS)

distclean: clean
	rm -f $(BINDIR)/$(TARGET)
