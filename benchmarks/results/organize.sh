#!/bin/sh

cd results

for test in *
do
  cd $test
  
  for provider in *
  do
    cd $provider
    
    for result in *
    do
      mv $result/*/*/result.json ./$result.json
    done

    cd ..
  done

  cd ..
done
