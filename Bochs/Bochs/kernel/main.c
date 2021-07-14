#include "print.h"
#include "init.h"
#include "debug.h"
#include "memory.h"

int main(void) {
//int _start(void) {
	//put_char('k');
	//put_char('e');
	//put_char('r');
	//put_char('n');
	//put_char('e');
	//put_char('l');
	//put_char('\n');
	//put_char('1');
	//put_char('2');
	//put_char('\b');
	//put_char('3');
	put_str("I am kernel\n");
	//put_int(0);
	//put_char('\n');
	//put_int(9);
	//put_char('\n');
	//put_int(0x00021a3f);
	//put_char('\n');
	//put_int(0x12345678);
	//put_char('\n');
	//put_int(0x00000000);
	init_all();
	//asm volatile("sti");	//为演示中断处理，在此临时开中断
	//ASSERT(1==2);
	void* addr = get_kernel_pages(3);
	put_str("\n get_kernel_page start vaddr is ");
	put_int((uint32_t)addr);
	put_char('\n');

	while(1);
	return 0;
}
