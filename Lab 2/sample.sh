#!/bin/bash

greet() {
	sum=`expr "$1" + "$2"`
	echo $sum
	sum2=`expr "$3" + "$4"`
	echo $sum2
}

greet 1 2 3 4

