#ifndef UTIL_HC
#define UTIL_HC

// Utility functions.

#include "Exception.HC"

extern class String;
extern VOID StringConcatC(String *s, CHAR *c);
extern class Malval;
extern Malval *MalStringMk(String *s);

VOID NullCheck(CHAR *x, CHAR *xname)
{
  String *s;
  if (!x) {
    s = StringMk("NullCheck failed for ");
    StringConcatC(s, xname);
    throwval(MalStringMk(s));
  }
}

VOID NullThrow(CHAR *s)
{
  throws(s);
}

// assert x >= y
VOID LtCheck(INT x, INT y, CHAR *xname)
{
  if (x < y) {
    "%s is less than %ld.\n", xname, y;
    throws("");
  }
}

// assert x > y
VOID LeCheck(INT x, INT y, CHAR *xname)
{
  if (x <= y) {
    "%s is not greater than %ld.\n", xname, y;
    throws("");
  }
}

// assert x <= y
VOID GtCheck(INT x, INT y, CHAR *xname)
{
  if (x > y) {
    "%s is greater than than %ld.\n", xname, y;
    throws("");
  }
}

// assert x < y
VOID GeCheck(INT x, INT y, CHAR *xname)
{
  if (x >= y) {
    "%s is not less than %ld.\n", xname, y;
    throws("");
  }
}

// assert y <= x <= z
VOID BoundsCheck(INT x, INT y, INT z, CHAR *xname)
{
  if (x < y) {
    "%s is less than %ld.\n", xname, y;
    throws("");
  }
  if (z < x) {
    "%s is greater than %ld", xname, z;
    throws("");
  }
}

// Return the least power of 2 that is greater than or equal to n
INT NextPowerOf2(INT n)
{
  INT i = 1;
  while (i < n) {
    i = i << 1;
  }
  return i;
}

BOOL IsDigit(CHAR c)
{
  return 48 <= c < 58;
}

VOID PrintError(CHAR *c)
{
  "%s\n", c;
}

#endif
