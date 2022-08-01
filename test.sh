#!/bin/bash

for i in `grep '.md' SUMMARY.md | awk -F '(' '{print $2}'| awk -F ')' '{print $1}' `
do
 echo 
 line=`grep $i SUMMARY-GitBook-auto-summary.md`
 echo $line | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'

done 
