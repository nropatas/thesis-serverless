#!/bin/sh

set -e

cd results

for test in *
do
  cd $test
  
  for provider in *
  do
    cd $provider
    
    for result in *
    do
      echo "$test/$provider/$result"
      mv $result/*/*/result.json ./$result.json
    done

    cd ..
  done

  cd ..
done
