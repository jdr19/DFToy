# DFToy build system. Requires GNU Make.
#
#   make CONFIG=<name> [WITH_OPENMP=1] [DEBUG=1]
#   make help
#
# Toolchain and library settings live in config/<name>.mk and nothing in this
# file should be specific to a vendor. To support a new system, copy
# config/template.mk rather than editing this file.

.DEFAULT_GOAL := all

TARGET := dftoy

# Goals that can run without a config and goals that don't need a compiler.
NO_CONFIG_GOALS := help cleanall
NO_TOOLCHAIN_GOALS := $(NO_CONFIG_GOALS) clean showconfig
GOALS := $(or $(MAKECMDGOALS),$(.DEFAULT_GOAL))

# TODO: use global config variable to simplify changes and allow user to set a custom directory

AVAILABLE_CONFIGS := $(filter-out template,$(basename $(notdir $(wildcard config/*.mk))))

# ----------------------------------------------------------------------------
# Feature flags. These are resolved before the config is included so that a
# config can use them, e.g. to pick threaded libraries when WITH_OPENMP is on.
# ----------------------------------------------------------------------------

# Helper to handle disabling a flag. (0, no, false, off, and an empty value) indicate disabled; anything else enables it.
enabled = $(filter-out 0 no false off,$(1))

WITH_OPENMP ?= 0
DEBUG ?= 0

# ELPA requires ScaLAPACK.
ifneq ($(call enabled,$(WITH_ELPA)),)
override WITH_SCALAPACK := 1
endif

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------
ifneq ($(filter-out $(NO_CONFIG_GOALS),$(GOALS)),)
ifeq ($(strip $(CONFIG)),)
$(error No config selected. Use 'make CONFIG=<name>' or set CONFIG in the environment. Available: $(AVAILABLE_CONFIGS). For a new system, copy config/template.mk)
endif
ifeq ($(wildcard config/$(CONFIG).mk),)
$(error Unknown config '$(CONFIG)'. Available: $(AVAILABLE_CONFIGS). For a new system, copy config/template.mk)
endif
include config/$(CONFIG).mk
endif

# TODO: flag defaults set arbitrarily - duplicated inside template.mk so changes should be replectated there or removed
OPTFLAGS ?= -O2 -g
DEBUGFLAGS ?= -O0 -g
MPIEXEC ?= mpiexec

# MPI is mandatory for now: the sources include mpi.h unconditionally.
ifneq ($(origin WITH_MPI),undefined)
ifneq ($(WITH_MPI),1)
$(error MPI cannot be disabled: DFToy currently always builds with MPI. Unset WITH_MPI)
endif
endif

# ----------------------------------------------------------------------------
# Checks. Skipped for goals that don't compile anything.
# ----------------------------------------------------------------------------
ifneq ($(filter-out $(NO_TOOLCHAIN_GOALS),$(GOALS)),)
REQUIRED_VARS := MPICC FFTW_LIBS LAPACK_LIBS
ifneq ($(call enabled,$(WITH_OPENMP)),)
REQUIRED_VARS += OPENMP_FLAGS
endif
$(foreach var,$(REQUIRED_VARS),$(if $(strip $($(var))),,$(error $(var) is not set in config/$(CONFIG).mk)))

ifeq ($(shell command -v $(firstword $(MPICC)) 2>/dev/null),)
$(error MPI compiler '$(firstword $(MPICC))' not found. Is the right module loaded, or MPICC set correctly in config/$(CONFIG).mk?)
endif
endif

# ----------------------------------------------------------------------------
# Flags
# ----------------------------------------------------------------------------
DFTOY_CPPFLAGS := -Iinclude -D_POSIX_C_SOURCE=200809L
DFTOY_CFLAGS := -std=c99 $(ARCHFLAGS)
DFTOY_LDFLAGS :=
DFTOY_LIBS :=

ifneq ($(call enabled,$(DEBUG)),)
DFTOY_CFLAGS += $(DEBUGFLAGS)
else
DFTOY_CFLAGS += $(OPTFLAGS)
endif

ifneq ($(call enabled,$(WITH_OPENMP)),)
DFTOY_CFLAGS += $(OPENMP_FLAGS)
DFTOY_LDFLAGS += $(OPENMP_FLAGS)
endif

ifneq ($(call enabled,$(WITH_ELPA)),)
DFTOY_CPPFLAGS += -DDFTOY_USE_ELPA $(ELPA_CPPFLAGS)
DFTOY_LDFLAGS += $(ELPA_LDFLAGS)
DFTOY_LIBS += $(ELPA_LIBS)
endif

ifneq ($(call enabled,$(WITH_SCALAPACK)),)
DFTOY_CPPFLAGS += -DDFTOY_USE_SCALAPACK $(SCALAPACK_CPPFLAGS)
DFTOY_LDFLAGS += $(SCALAPACK_LDFLAGS)
DFTOY_LIBS += $(SCALAPACK_LIBS)
endif

DFTOY_CPPFLAGS += $(LAPACK_CPPFLAGS) $(FFTW_CPPFLAGS)
DFTOY_LDFLAGS += $(LAPACK_LDFLAGS) $(FFTW_LDFLAGS)

# Listed so that each library comes before the ones it depends on.
DFTOY_LIBS += $(LAPACK_LIBS) $(FFTW_LIBS)
ifneq ($(call enabled,$(WITH_OPENMP)),)
DFTOY_LIBS += $(OPENMP_LIBS)
endif
DFTOY_LIBS += -lm


ALL_CPPFLAGS = $(DFTOY_CPPFLAGS) $(CPPFLAGS)
ALL_CFLAGS = $(DFTOY_CFLAGS) $(CFLAGS)
ALL_LDFLAGS = $(DFTOY_LDFLAGS) $(LDFLAGS)
ALL_LIBS = $(DFTOY_LIBS) $(LDLIBS)

# ----------------------------------------------------------------------------
# Sources and outputs
# ----------------------------------------------------------------------------
SRC_DIRS := src src/solvers
SRC := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))

BUILD_DIR := build/$(CONFIG)
OBJ := $(SRC:%.c=$(BUILD_DIR)/obj/%.o)
DEP := $(OBJ:.o=.d)
BIN := $(BUILD_DIR)/$(TARGET)

# ----------------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------------
NTASKS ?= 1
TOYCODE_DIAG ?= ZHEEVD

.PHONY: all clean cleanall run help showconfig FORCE
.DELETE_ON_ERROR:

all: $(BIN)

$(BIN): $(OBJ)
	$(MPICC) $(ALL_CFLAGS) -o $@ $(OBJ) $(ALL_LDFLAGS) $(ALL_LIBS)

$(BUILD_DIR)/obj/%.o: %.c
	@mkdir -p $(@D)
	$(MPICC) $(ALL_CPPFLAGS) $(ALL_CFLAGS) -MMD -MP -c $< -o $@

FORCE:

run: all
	$(MPIEXEC) -n $(NTASKS) $(MPIEXEC_FLAGS) ./$(BIN) -x $(TOYCODE_DIAG)

clean:
	rm -rf $(BUILD_DIR)

cleanall:
	rm -rf build

showconfig:
	@echo "CONFIG         = $(CONFIG)"
	@echo "MPICC          = $(MPICC)"
	@echo "WITH_OPENMP    = $(WITH_OPENMP)"
	@echo "WITH_SCALAPACK = $(WITH_SCALAPACK)"
	@echo "WITH_ELPA      = $(WITH_ELPA)"
	@echo "DEBUG          = $(DEBUG)"
	@echo "CPPFLAGS       = $(ALL_CPPFLAGS)"
	@echo "CFLAGS         = $(ALL_CFLAGS)"
	@echo "LDFLAGS        = $(ALL_LDFLAGS)"
	@echo "LIBS           = $(ALL_LIBS)"
	@echo "MPIEXEC        = $(MPIEXEC) -n $(NTASKS) $(MPIEXEC_FLAGS)"

help:
	@echo "Usage: make CONFIG=<name> [options] [target]"
	@echo ""
	@echo "Available configs: $(AVAILABLE_CONFIGS)"
	@echo "For a new system, copy config/template.mk to config/<name>.mk"
	@echo ""
	@echo "Options:"
	@echo "  WITH_OPENMP=1      Enable OpenMP (off by default)"
	@echo "  DEBUG=1            Build with DEBUGFLAGS instead of OPTFLAGS"
	@echo "  WITH_SCALAPACK=1   Enable ScaLAPACK solvers"
	@echo "  WITH_ELPA=1        Enable the ELPA solver (implies WITH_SCALAPACK)"
	@echo ""
	@echo "Targets:"
	@echo "  all          Build ./$(TARGET) (default)"
	@echo "  run          Build and run, using NTASKS and TOYCODE_DIAG"
	@echo "  showconfig   Print the settings a build would use"
	@echo "  clean        Remove the build for the selected config"
	@echo "  cleanall     Remove the builds for all configs"
	@echo "  help         Show this message"

-include $(DEP)
