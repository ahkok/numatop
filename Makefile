PREFIX := /usr/local
BINDIR := /bin
MANDIR := /share/man/man8
PROG = numatop
CC := gcc
LD := gcc
CFLAGS := -g -Wall -O2
TEST_CFLAGS = -g -Wall -O0
LDFLAGS := -g
LDLIBS = -lncurses -lpthread -lnuma

NUMATOP_OBJS = numatop.o

COMMON_OBJS = cmd.o disp.o lwp.o page.o perf.o proc.o reg.o util.o \
	win.o ui_perf_map.o

OS_OBJS = os_cmd.o os_perf.o os_win.o node.o map.o os_util.o plat.o \
	pfwrapper.o sym.o os_page.o

TEST_PATH = ./test/mgen

ARCH := $(shell uname -m)

ifneq (,$(filter $(ARCH),ppc64le ppc64))
ARCH_PATH = ./powerpc
ARCH_OBJS = $(ARCH_PATH)/power8.o $(ARCH_PATH)/power9.o $(ARCH_PATH)/plat.o \
	$(ARCH_PATH)/util.o $(ARCH_PATH)/ui_perf_map.o

TEST_ARCH_PATH = $(TEST_PATH)/powerpc
else
ARCH_PATH = ./intel
ARCH_OBJS = $(ARCH_PATH)/wsm.o $(ARCH_PATH)/snb.o $(ARCH_PATH)/nhm.o \
	$(ARCH_PATH)/bdw.o $(ARCH_PATH)/skl.o $(ARCH_PATH)/plat.o \
	$(ARCH_PATH)/util.o $(ARCH_PATH)/ui_perf_map.o

TEST_ARCH_PATH = $(TEST_PATH)/intel
endif

TEST_PROG = $(TEST_PATH)/mgen
TEST_OBJS = $(TEST_PATH)/mgen.o
TEST_ARCH_OBJS = $(TEST_ARCH_PATH)/util.o

DEP := $(wildcard ./common/include/*.h) $(wildcard ./common/include/os/*.h) \
	$(wildcard $(ARCH_PATH)/include/*.h) $(wildcard $(TEST_PATH)/include/*.h)

%.o: ./common/%.c $(DEP)
	$(CC) $(CFLAGS) -o $@ -c $<

%.o: ./common/os/%.c $(DEP)
	$(CC) $(CFLAGS) -o $@ -c $<

$(ARCH_PATH)/%.o: $(ARCH_PATH)/%.c $(DEP)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TEST_PATH)/%.o: $(TEST_PATH)/%.c $(DEP)
	$(CC) $(TEST_CFLAGS) -o $@ -c $<

$(TEST_ARCH_PATH)/%o: $(TEST_ARCH_PATH)/%.c $(DEP)
	$(CC) $(TEST_CFLAGS) -o $@ -c $<

all: $(PROG) test

# build numatop tool
$(PROG): $(NUMATOP_OBJS) $(COMMON_OBJS) $(OS_OBJS) $(ARCH_OBJS)
	$(LD) $(LDFLAGS) -o $@ $(NUMATOP_OBJS) $(COMMON_OBJS) $(OS_OBJS) \
	$(ARCH_OBJS) $(LDLIBS)

# build mgen selftest
test: $(TEST_PROG)

$(TEST_PROG): $(TEST_OBJS) $(COMMON_OBJS) $(OS_OBJS) $(ARCH_OBJS) $(TEST_ARCH_OBJS)
	$(LD) $(LDFLAGS) -o $@ $(TEST_OBJS) $(COMMON_OBJS) $(OS_OBJS) \
	$(ARCH_OBJS) $(TEST_ARCH_OBJS) $(LDLIBS)

install: $(PROG)
	install -m 0755 -D $(PROG) $(DESTDIR)$(PREFIX)$(BINDIR)/$(PROG)
	gzip -c numatop.8 > numatop.8.gz
	install -m 0755 -D numatop.8.gz $(DESTDIR)$(PREFIX)$(MANDIR)/numatop.8.gz

clean:
	rm -rf *.o $(ARCH_PATH)/*.o $(TEST_PATH)/*.o $(TEST_ARCH_PATH)/*.o \
	$(PROG) $(TEST_PROG)
