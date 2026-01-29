#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
int
main(int argc, char *argv[])
{
int n;
if(argc != 2){
fprintf(2, "Usage: sleep ticks\n");
exit(1);
}
n = atoi(argv[1]);
if(n < 0){
fprintf(2, "sleep: negative value not allowed\n");
exit(1);
}
if(sleep(n) < 0){
fprintf(2, "sleep: failed\n");
exit(1);
}
exit(0);
}