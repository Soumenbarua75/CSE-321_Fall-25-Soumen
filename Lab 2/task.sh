#echo "Hello"

# variable

#mark=86

#name=Kamrul

#echo "My name is $name"

#system defined variable 

#echo '$PWD'
#echo '$HOME'


#if condition
#then

#if ((mark > 85))
#then 
 #   echo "A-"
#else 
  #  echo "not bad"
    
#fi

echo "Hello"

#variable


echo "My name is #name"

vehicle=car

case $vehicle in
     "car" )
          echo "it's a car" ;;
     "Truck" )
          echo "It's a Truck" ;;
     "Bus" )
          echo "It's a Bus" ;; 

esac

touch samiul.txt
if [ -f samiul.txt ]
then 
    echo "This is a file"
else 
    echo "This is not a file"
    
fi


#variable

#for i in {1..100..2}
for ((i=0 ; i<30 ; i++))
do  
  echo "Title is CSE321 Lab and the i is $i"
done


echo -n "Enter your name
read name
echo "My name is $name"



#command line argument

echo "first argument is $1 and second argument is $2





function printDetails(){
  echo "Hello I'm a function"
}

printDetails
