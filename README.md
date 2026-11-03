# DFToy

3D DFT toy code.

Performs exact and/or iterative calculation of the Eigenstates of a simple
system, representative of a simple DFT calculation.

# Requirements
 - GNU Make
 - C compiler with an MPI wrapper (MPI is currently mandatory)
 - LAPACK with the LAPACKE interface (`lapacke.h`), and BLAS (`cblas.h`)
 - FFTW with MPI support, built against the same MPI as the compiler wrapper
 - ScaLAPACK (optional) - build with `WITH_SCALAPACK=1`
 - ELPA (optional) - build with `WITH_ELPA=1` (implies `WITH_SCALAPACK=1`)

# Building

Compiler and library settings are kept in `config/`, with one file per setup.
Select one with `CONFIG`:

`make CONFIG=<name>`

`CONFIG` can also be set in your environment. The binary is built as
`build/<config>/dftoy`. Run `make help` to list the available configs, options
and targets.

## Adding a config

To build on a new system, duplicated the template and fill it in:

`cp config/template.mk config/<name>.mk`

Then run `make CONFIG=<name> showconfig` to check the flags it will use.

## Build options

 - `WITH_OPENMP=1` - enable OpenMP (off by default)
 - `DEBUG=1` - build with `DEBUGFLAGS` instead of `OPTFLAGS`

# Running

For a basic run with default parameters:

`mpirun -np <num_procs> build/<config>/dftoy`

Run `dftoy --usage` for an overview of the available configuration parameters.

## Running larger simulations

The time (and memory) required to solve the eigenstate problem in 3D by exact
diagonalisation increases _very rapidly_ with the number of wavevectors. It is
recommended to only run the iterative solver (`dftoy --iterative`) for larger
problems.

