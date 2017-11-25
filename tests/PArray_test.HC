#include "PArray.HC"
#include "PrimitiveTypes.HC"
#include "String.HC" // for Util
#include "Types.HC" // For Util

// provide a dummy implementation of mal_alloc so the PArrayEmpty will work;
CHAR *mal_alloc(INT size)
{
  return MAlloc(size);
}

PArray *pa = PArrayEmpty;
PArrayPush(pa, 25);
PArrayPush(pa, 1);
PArrayPush(pa, 2);
PArrayPush(pa, 3);
PArrayPush(pa, 123456789);

"parray size: %d\n", PArraySize(pa);
"parray[0]: %d\n", PArrayGet(pa, 0);
"parray[1]: %d\n", PArrayGet(pa, 1);
"parray[4]: %d\n", PArrayGet(pa, 4);
;
