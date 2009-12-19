#include <ruby.h>

/**
 * These two functions were lifted from this guy:
 * http://code.google.com/p/ruby-cpuid/
 * Who saved me the trouble of writing the inline assembly. However I changed
 * how he exposees them to Ruby and how he defines constants and so forth.
 * @michaeledgar
 */

static VALUE has_cpuid(VALUE self)
{
	long a, c;

    __asm__ __volatile__ (
		"pushf\n\t"
        "pop %0\n\t"
        "mov %0, %1\n\t"
        "xor $0x200000, %0\n\t"
        "push %0\n\t"
        "popf\n\t"
        "pushf\n\t"
        "pop %0\n\t"
        : "=a" (a), "=c" (c) : : "cc"
    );

	return a != c ? Qtrue : Qfalse;
}

static VALUE run_cpuid(VALUE self, VALUE ax)
{
	unsigned int op = NUM2UINT(ax);
	unsigned int regs[4];
	
    __asm__ __volatile__ (
	     "mov %%ebx, %%esi\n\t"
         "cpuid\n\t"
         "xchg %%ebx, %%esi"
         : "=a" (regs[0]), "=S" (regs[1]),
           "=c" (regs[2]), "=d" (regs[3])
         : "0" (op)
	);
	
	return rb_ary_new3(4, INT2NUM(regs[0]), INT2NUM(regs[1]), INT2NUM(regs[2]), INT2NUM(regs[3]));
}

/**
 * I wrote this stuff. @michaeledgar
 */
void Init_cpuid_ext()
{
    VALUE m_CPUID = rb_define_module("CPUID");
    rb_define_singleton_method(m_CPUID, "has_cpuid?", has_cpuid, 0);
    rb_define_singleton_method(m_CPUID, "run_cpuid", run_cpuid, 1);
}