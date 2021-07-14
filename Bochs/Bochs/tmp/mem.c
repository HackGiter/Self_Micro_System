#include <stdio.h>
void main(void) {
	int in_a = 1, in_b = 2;
	printf("in_b is %d\n", in_b);
	asm("movb %b0, %1;"::"a"(in_a), "m"(in_b));		//a:表示address，m:表示memory，%1:序号占位符
	printf("in_b now is %d\n", in_b);
}
