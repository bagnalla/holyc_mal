#ifndef STRING_HC
#define STRING_HC

#include "Array.HC"
#include "GCCommon.HC"
#include "PArray.HC"
#include "Util.HC"

class String
{
  BOOL _reachable; // for GC
  CHAR _gc_tag;
  Array *_arr;
};

VOID StringGCMark(CHAR *str)
{
  String *s = str(String*);
  if (!s->_reachable) {
    s->_reachable = TRUE;
  }
}

String *StringEmpty()
{
  String *s = mal_alloc(sizeof(String));
  s->_arr = ArrayMk(1, 64);
  s->_gc_tag = GC_STRING;
  return s;
}

String *StringMk(CHAR *c)
{
  String *s = StringEmpty;
  INT len = StrLen(c);
  ArrayReserve(s->_arr, len);
  MemCpy(s->_arr->_data, c, len);
  s->_arr->_size = len;
  return s;
}

String *StringCopy(String *s)
{
  NullCheck(s, "string");
  String *_s = StringEmpty;
  ArrayDelete(_s->_arr);
  _s->_arr = ArrayCopy(s->_arr);
  return _s;
}

VOID StringDelete(String *s)
{
  NullCheck(s, "string");
  ArrayDelete(s->_arr);
  Free(s);
}

INT StringLen(String *s)
{
  NullCheck(s, "string");
  return ArraySize(s->_arr);
}

CHAR StringGet(String *s, INT i)
{
  NullCheck(s, "string");
  return *ArrayGet(s->_arr, i);
}

VOID StringSet(String *s, INT i, CHAR c)
{
  NullCheck(s, "string");
  ArraySet(s->_arr, i, &c);
}

BOOL StringIsEmpty(String *s)
{
  NullCheck(s, "string");
  return ArrayIsEmpty(s->_arr);
}

VOID StringErase(String *s, INT i, INT j)
{
  NullCheck(s, "string");
  ArrayErase(s->_arr, i, j);
}

VOID StringClear(String *s)
{
  NullCheck(s, "string");
  ArrayClear(s->_arr);
}

VOID StringAppend(String *s, CHAR c)
{
  NullCheck(s, "string");
  ArrayPush(s->_arr, &c);
}

VOID StringInsert(String *s, INT i, CHAR c)
{
  NullCheck(s, "string");
  ArrayInsert(s->_arr, i, &c);
}

CHAR StringFront(String *s)
{
  NullCheck(s, "string");
  if (!StringLen(s)) {
    PrintError("can't take front of empty string");
    throws("can't take front of empty string");
  }
  return StringGet(s, 0);
}

CHAR StringBack(String *s)
{
  NullCheck(s, "string");
  if (!StringLen(s)) {
    PrintError("can't take back of empty string");
    throws("can't take front of empty string");
  }
  return StringGet(s, StringLen(s)-1);
}

// modify s1 by appending s2 at the end, s2 is unchanged
VOID StringConcat(String *s1, String *s2)
{
  NullCheck(s1, "string 1");
  NullCheck(s2, "string 2");
  INT i;
  for (i = 0; i < StringLen(s2); ++i) {
    StringAppend(s1, StringGet(s2, i));
  }
}

VOID StringConcatC(String *s, CHAR *c)
{
  NullCheck(s, "String");
  NullCheck(c, "c-string");
  String *s2 = StringMk(c);
  StringConcat(s, s2);
}

// Check if a CHAR exists in a String
BOOL StringExists(String *s, CHAR c)
{
  NullCheck(s, "string");
  return ArrayExists(s->_arr, &c);
}

CHAR *StringCString(String *s)
{
  NullCheck(s, "string");
  INT sz = ArraySize(s->_arr);
  CHAR *c = MAlloc(sz + 1);
  MemCpy(c, s->_arr->_data, sz);
  c[sz] = '\0';
  return c;
}

// Substring of length l starting at index i 
String *StringSubstr(String *s, INT i, INT l)
{
  NullCheck(s, "string");
  Array *a = ArraySubarray(s->_arr, i, l);
  NullCheck(a, "subarray");
  String *sub = StringEmpty;
  ArrayDelete(sub->_arr);
  sub->_arr = a;
  return sub;
}

VOID StringPrint(String *s)
{
  CHAR *c = StringCString(s);
  "%s", c;
  Free(c);
}

VOID StringPrintLn(String *s)
{
  CHAR *c = StringCString(s);
  "%s\n", c;
  Free(c);
}

// TODO: figure out how to do this in TempleOS
INT StringReadLn(String *s)
{
  NullCheck(s, "string");
  StringClear(s);
  INT c = GetChar;
  while (c != EOF && c != '\n') {
    StringAppend(s, c);
    c = GetChar;
  }
  return c;
}

BOOL StringEq(String *s1, String *s2)
{
  NullCheck(s1, "string 1");
  NullCheck(s2, "string 2");
  if (StringLen(s1) != StringLen(s2)) return FALSE;
  INT i;
  for (i = 0; i < StringLen(s1); ++i) {
    if (StringGet(s1, i) != StringGet(s2, i))
      return FALSE;
  }
  return TRUE;
}

BOOL StringEqC(String *s1, CHAR *s2)
{
  NullCheck(s1, "string 1");
  NullCheck(s2, "string 2");
  String *_s2 = StringMk(s2);
  BOOL eq = StringEq(s1, _s2);
  return eq;
}

// TODO: figure this out for TempleOS
INT Atoi(String *s)
{
  CHAR *c = StringCString(s);
  INT n = Str2I64(c);
  Free(c);
  return n;
  return 0;
}

String *StringAddQuotes(String *s)
{
  String *_s = StringMk("\"");
  StringConcat(_s, s);
  StringAppend(_s, '"');
  return _s;
}

String *StringTrimQuotes(String *s)
{
  NullCheck(s, "string");
  if (StringLen(s) < 2)
    return s;
  else if (StringFront(s) != '"' || StringBack(s) != '"')
    return s;
  else return StringSubstr(s, 1, StringLen(s) - 2);
}

// Doesn't make copies
PArray *RemoveDuplicateStrings(PArray *pa)
{
  NullCheck(pa, "PArray of strings");
  PArray *strings = PArrayEmpty;
  INT i, j;
  String *s1, *s2;
  for (i = PArraySize(pa)-1; i >= 0; --i) {
    s1 = PArrayGet(pa, i);
    for (j = 0; j < PArraySize(strings); ++j) {
      s2 = PArrayGet(strings, j);
      if (StringEq(s1, s2)) goto END_OUTER;
    }
    PArrayPush(strings, s1);
  END_OUTER:;
  }
  return strings;
}

#endif
