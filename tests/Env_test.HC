#include "Env.HC"
#include "PrimitiveTypes.HC"
#include "String.HC" // for Util
#include "Types.HC" // For Util

// provide a dummy implementation of mal_alloc
CHAR *mal_alloc(INT size)
{
  return MAlloc(size);
}

PArray *env = EnvEmpty(NULL);
EnvSet(env, StringMk("asdf"), MalNilMk);
EnvSet(env, StringMk("dfgh"), MalNilMk);

Malval *x = EnvGetC(env, "iojdfg");
Malval *y = EnvGetC(env, "asdfg");
Malval *z = EnvGetC(env, "1a2a3a4a5a");

"x: %d\n", x;
"y: %d\n", y;
"z: %d\n", z;
;
