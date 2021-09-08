#	Makefile
.PHONY := kbuild all clean stat include_build

srctree := $(shell pwd)
include tools/Kbuild.include

# Check if V options is set by user, if V=1, debug mode is set
# e.g. make V=1 produces all the commands being executed through
# the building process
ifeq ("$(origin V)", "command line")
	KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
	KBUILD_VERBOSE = 0
endif
ifeq ($(KBUILD_VERBOSE),1)
	Q =
else
	MAKEFLAGS += --no-print-directory -s
	Q = @
endif

export TEXT_OFFSET := 2048

export COMMON_FLAGS := -DTEXT_OFFSET=$(TEXT_OFFSET) -D_DEBUG
export JOS_FLAGS := -D__wramp__
export CFLAGS := $(JOS_FLAGS) $(COMMON_FLAGS)

export CURRENT_TIME := $(shell date +%s)
export INCLUDE_PATH := -I./include/posix_include/ -I./include/
export includes := $(shell find include -name "*.h")
export KBUILD_VERBOSE
export srctree \\
export Q
export SREC_INCLUDE := include/srec/

# List of user libraries used by the kernel
ALLDIR			= jOS lib init user kernel fs driver
ALLDIR_CLEAN	= jOS lib init user kernel fs driver include

DISK			= include/disk.c
FS_DEPEND		= fs/*.c fs/system/*.c fs/makefs_only/*.c

KERNEL_O		= jOS/*.o kernel/system/*.o kernel/*.o fs/*.o fs/system/*.o driver/*.o include/*.o
KLIB_O			= lib/syscall/wramp_syscall.o lib/ipc.o lib/ansi/string.o lib/util/util.o lib/gen/ucontext.o \
				  	lib/stdlib/atoi.o lib/syscall/debug.o lib/posix/_sigset.o lib/ansi/rand.o
L_HEAD			= jOS/limits/limits_head.o
L_TAIL			= jOS/limits/limits_tail.o

SREC			= $(shell find $(SREC_INCLUDE) -name "*.srec")
STARTTIME_FILE	= include/startup_time.c

all:| makedisk kbuild $(DISK) include_build
	$(Q)wlink $(LDFLAGS) -Ttext 1024 -v -o winix.srec \
	$(L_HEAD) $(KERNEL_O) $(KLIB_O) $(L_TAIL) > $(SREC_INCLUDE)/winix.verbose
ifeq ($(KBUILD_VERBOSE),0)
	@echo "LD \t winix.srec"
endif

clean:
	$(Q)rm -f makedisk
	$(Q)$(MAKE) $(cleanall)='$(ALLDIR_CLEAN)'

$(DISK):	$(SREC)
	$(Q)./makedisk -t $(TEXT_OFFSET) -o $(DISK) -s $(SREC_INCLUDE) -u $(CURRENT_TIME)
	ifeq ($(KBUILD_VERBOSE), 0)
		@echo "LD \t disk.c"
	endif

include_build:
	$(Q)echo "unsigned int start_time=$(CURRENT_TIME);\n" > $(STARTTIME_FILE)
	$(Q)$(MAKE) $(build)=include/

kbuild:		$(ALLDIR)
	$(ALLDIR):	FORCE
	$(Q)$(MAKE) $(build)=$@

makedisk: $(FS_DEPEND)
	$(Q)gcc -g -D MAKEFS_STANDALONE $(COMMON_CFLAGS) -w -I./include/fs_include/ -I./include/ $^ -o makedisk

stat:
	@echo "C Lines: "
	@find . -type d -name "include" -prune -o -name "*.c"  -exec cat {} \; | wc -l
	@echo "Header LoC: "
	@find . -name "*.h" -exec cat {} \; | wc -l
	@echo "Assembly LoC: "
	@find . -name "*.s" -exec cat {} \; | wc -l

FORCE:
# DO NOT DELETE

