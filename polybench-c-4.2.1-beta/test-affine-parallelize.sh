
#!/bin/bash

# For each test cases in PolyBench, first compile it into MLIR and then run
# affine-parallelize

set -o errexit
set -o pipefail
set -o nounset


BASE=$(pwd)

CGEIST=~/Polygeist/build/bin/cgeist
MLIR_OPT=~/mlir_supervec/build_debug/bin/mlir-opt
POLYGEIST_OPT=~/Polygeist/build/bin/polygeist-opt

UTILITY_INCLUDE=~/Polygeist-Script/polybench-c-4.2.1-beta/utilities
STD_INCLUDE=~/mlir_supervec/clang/lib/Headers


dirList="linear-algebra/blas
         linear-algebra/kernels
         linear-algebra/solvers
         datamining
         stencils
         medley"

CFLAGS="-march=native -I $UTILITY_INCLUDE -I $STD_INCLUDE -D LARGE_DATASET"


CGEIST_CMD="$CGEIST $CFLAGS -S --raise-scf-to-affine"
# We need --allow-unregistered-dialect as cgeist creates
# polygeist.pointer2memref, which is not registered to mlir-opt
MLIR_OPT_CMD="$MLIR_OPT --allow-unregistered-dialect --affine-parallelize"

for dir in $dirList; do
  cd "$BASE/$dir"
  for subDir in `ls`; do
    cd "$BASE/$dir/$subDir" 
    echo $(pwd)
    # run the base command for the .c file in the directory. Ignore .pluto.c and .plutopar.c.
    # Output should be in the form of <testcase>.mlir

    for c_file in *.c; do
      if [[ $c_file == *.pluto.c || $c_file == *.plutopar.c || $c_file == *.orig.c ]]; then
        continue
      fi
      # Convert to MLIR
      CMD="$CGEIST_CMD -o ${c_file%.c}.mlir $c_file"
      echo "Running: $CMD"
      $CMD
      echo "done"

      # Run affine-parallelize
      CMD="$MLIR_OPT_CMD ${c_file%.c}.mlir -o ${c_file%.c}.affine-parallelize.mlir"
      echo "Running: $CMD"
      $CMD
      echo "done"
    done

  done
done

