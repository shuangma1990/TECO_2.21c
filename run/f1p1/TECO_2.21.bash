#!/bin/bash
#PBS -l walltime=00:15:00
#PBS -N f1p1
#PBS -o /scratch_lg/cardamom/shuangma/TECO/TECO_2.21/run/f1p1/output/out.o
#PBS -e /scratch_lg/cardamom/shuangma/TECO/TECO_2.21/run/f1p1/output/error.err
#PBS -l mem=200mb
#PBS -q array
#PBS -J 1-1000

### Load modules into your environment
module load intel/compiler/64
module load intel/mkl/64
cd /scratch_lg/cardamom/shuangma/TECO/TECO_2.21/run/f1p1
./TECO_2.21
