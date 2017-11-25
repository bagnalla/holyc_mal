#include "List.HC"
#include "PrimitiveTypes.HC"
#include "String.HC" // for Util
#include "Types.HC" // For Util

// provide a dummy implementation of mal_alloc so the PArrayEmpty will work;
CHAR *mal_alloc(INT size)
{
  return MAlloc(size);
}

List *l = ListCons(1, ListCons(2, ListCons(123456789, ListNil)));

INT x = ListHead(l);
INT y = ListHead(ListTail(l));
INT z = ListNth(l, 2);

"x: %d\n", x;
"y: %d\n", y;
"z: %d\n", z;

INT i;
for (i = 0; i < 2000; ++i) {
  l = ListCons(i+1, l);
}

"list size: %d\n", ListSize(l);
;
