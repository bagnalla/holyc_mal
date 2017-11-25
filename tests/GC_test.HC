#include "Env.HC"
#include "GC.HC"
#include "PrimitiveTypes.HC"
#include "String.HC"
#include "Types.HC"

init_GC;

Env *env = EnvEmpty(NULL);
set_GC_root_env(env);
print_GC_status;

INT i;
CHAR buf[8];
String *s;
for (i = 0; i < 100; ++i) {
  StrPrint(buf, "%d", i);
  s = StringMk(buf);
  StringPrintLn(s);
  if (i % 2 == 0) {
    EnvSet(env, s, MalStringMk(s));
  }
  check_for_GC;
  /* print_GC_status; */
}

Malval *x = EnvGetC(env, "0");
"x: %d\n", x;

/* print_GC_status; */
cleanup_GC;
;
