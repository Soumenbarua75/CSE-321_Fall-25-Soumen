// user/ps.c
#include "kernel/types.h"
#include "user/user.h"
int
main(void)
{
ps(); // call the ps system call
exit(0);
}