
i=1
while [ $i -le 6 ]
do
   j=1
   while [ $j -le 1 ]
   do
      if [ -f f${j}p${i}_MCMC_CS162/active_case ];then
         cd f${j}p${i}_MCMC_CS162
         echo run $PWD/TECO_2.21
	 qsub TECO_2.21.bash
         cd ..
      fi
      j=`expr $j + 1`
   done
   i=`expr $i + 1`
done
