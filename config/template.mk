# DFToy build config template.
#
# Copy this file to config/<name>.mk, fill it in, then run:
#
#   make CONFIG=<name>
#
# Use 'make CONFIG=<name> showconfig' to check the resulting flags.
#
# Project flags such as -std=c99 and -Iinclude come from the root Makefile, so
# only system-specific settings belong here. WITH_OPENMP, WITH_SCALAPACK,
# WITH_ELPA and DEBUG are already set when this file is read, so they can be
# tested here, for example to pick threaded libraries:
#
#   ifneq ($(call enabled,$(WITH_OPENMP)),)
#   LAPACK_LIBS = <threaded libraries>
#   else
#   LAPACK_LIBS = <serial libraries>
#   endif
#
# If the system uses environment modules, list the ones to load here. Modules
# often set CPATH without setting a library search path, in which case the -L
# paths still need to be given below.

# ----------------------------------------------------------------------------
# Compiler (required)
# ----------------------------------------------------------------------------
# MPI C compiler wrapper, e.g. mpicc, mpiicx, cc.
MPICC =

# Target architecture flags, e.g. -march=native (GNU, Clang) or -xHost (Intel).
# Leave empty for a binary that can move between machines.
ARCHFLAGS =

# Used for normal builds, and for DEBUG=1 builds.
OPTFLAGS = -O2 -g
DEBUGFLAGS = -O0 -g

# Passed when building with WITH_OPENMP=1, e.g. -fopenmp (GNU, Clang) or
# -qopenmp (Intel). OPENMP_LIBS is added to the link line for those builds; Clang
# needs -latomic for the OpenMP reductions on complex values.
OPENMP_FLAGS =
OPENMP_LIBS =

# ----------------------------------------------------------------------------
# LAPACK + BLAS (required)
# ----------------------------------------------------------------------------
# The sources include <lapacke.h> and <cblas.h>, so both must be on the include
# path, and the libraries must provide the LAPACKE interface.
#
# Examples of LAPACK_LIBS:
#   Netlib:   -llapacke -llapack -lblas
#   OpenBLAS: -lopenblas
LAPACK_CPPFLAGS =
LAPACK_LDFLAGS =
LAPACK_LIBS =

# ----------------------------------------------------------------------------
# FFTW (required)
# ----------------------------------------------------------------------------
# The sources include <fftw3-mpi.h>. FFTW must be built against the same MPI as
# MPICC, as its MPI library is not compatible with other MPI implementations.
#
# If the library isn't on the default runtime search path, either add
# -Wl,-rpath,<dir> to FFTW_LDFLAGS or set LD_LIBRARY_PATH when running.
FFTW_CPPFLAGS =
FFTW_LDFLAGS =
FFTW_LIBS = -lfftw3_mpi -lfftw3

# ----------------------------------------------------------------------------
# MPI launcher (optional, only used by 'make run')
# ----------------------------------------------------------------------------
# MPIEXEC is called as: $(MPIEXEC) -n $(NTASKS) $(MPIEXEC_FLAGS) build/<name>/dftoy
# For OpenMPI, MPIEXEC_FLAGS = --oversubscribe allows more tasks than cores.
MPIEXEC = mpiexec
MPIEXEC_FLAGS =

# ----------------------------------------------------------------------------
# ScaLAPACK (optional, used with WITH_SCALAPACK=1)
# ----------------------------------------------------------------------------
# Example for Intel MPI + MKL:
#   SCALAPACK_LIBS = -lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64
SCALAPACK_CPPFLAGS =
SCALAPACK_LDFLAGS =
SCALAPACK_LIBS =

# ----------------------------------------------------------------------------
# ELPA (optional, used with WITH_ELPA=1, which implies WITH_SCALAPACK=1)
# ----------------------------------------------------------------------------
# The sources include <elpa/elpa.h>. Example:
#   ELPA_CPPFLAGS = -isystem/usr/include/elpa
#   ELPA_LIBS = -lelpa
ELPA_CPPFLAGS =
ELPA_LDFLAGS =
ELPA_LIBS =
