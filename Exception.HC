#ifndef EXCEPTION_H
#define EXCEPTION_H

#include "PrimitiveTypes.HC"

#define EXCEPTION_CSTRING 0
#define EXCEPTION_MALVAL  1

// Forward declarations
extern class Malval;
extern class String;
extern Malval *MalStringMk(String *s);
extern String *StringMk(CHAR *c);
extern String *PrintMalval(Malval *m, BOOL print_readably, BOOL print_quotes);

// Exceptions are not garbage-collected even though they may contain
// Malvals which *are* GCed. So, the inner Malval isn't considered
// reachable by the GC and would be collected if the GC were to run
// during the lifetime of the exception, but I don't think it's possible
// for that to happen. The GC should never run while an exception is
// being propagated, and we shouldn't depend on the existence of the
// exception after catching it and continuing with evaluation.

class Exception
{
  Malval *_malval;
};

Exception *GetException()
{
  return Fs->except_ch;
}

VOID CatchException()
{
  Fs->catch_except = TRUE;
}

VOID RethrowException()
{
  Fs->catch_except = FALSE;
}

String *ExceptionString(Exception *e)
{
  return PrintMalval(e->_malval, TRUE, FALSE);
}

Malval *ExceptionMalval(Exception *e)
{
  return e->_malval;
}

Exception *ExceptionCStringMk(CHAR *c)
{
  Exception *e = MAlloc(sizeof(Exception));
  e->_malval = MalStringMk(StringMk(c));
  return e;
}

Exception *ExceptionMalvalMk(Malval *v)
{
  Exception *e = MAlloc(sizeof(Exception));
  e->_malval = v;
  return e;
}

CHAR *throws(CHAR *str)
{
  Exception *e = ExceptionCStringMk(str);
  throw(e);
  return 0; // make compiler stfu
}

CHAR *throwval(Malval *val)
{
  Exception *e = ExceptionMalvalMk(val);
  throw(e);
  return 0; // make compiler stfu
}

VOID ExceptionDelete(Exception *e)
{
  Free(e);
}

#endif
