#include "PrimitiveTypes.HC"
#include "String.HC"
#include "Types.HC" // For Util

// provide a dummy implementation of mal_alloc
CHAR *mal_alloc(INT size)
{
  return MAlloc(size);
}

String *s = StringEmpty;
StringAppend(s, 'a');
StringAppend(s, '\n');
StringPrintLn(s);
;
