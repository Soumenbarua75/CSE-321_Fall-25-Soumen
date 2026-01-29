#include "kernel/types.h" 
#include "user/user.h" 

int main(int argc, char *argv[]){

    if(argc < 3){
        printf("Less args given _______");
    }

    else if(argc==3){
        int a=atoi(argv[1]);
        int b=atoi(argv[2]);
        printf("a+b : %d\n", a+b);
        
    }

    else{
        printf("More arg given_______");
    }


    return 0;
}