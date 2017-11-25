#ifndef PRINTER_HC
#define PRINTER_HC

#include "MalListVector.HC"
#include "String.HC"
#include "Types.HC"

String *unescapeString(String *s)
{
  INT i;
  CHAR c;
  String *unescaped = StringEmpty;
  for (i = 0; i < StringLen(s); ++i) {
    c = StringGet(s, i);
    switch (c) {
    case '"':
      StringAppend(unescaped, '\\');
      StringAppend(unescaped, '"');
      break;
    case '\n':
      StringAppend(unescaped, '\\');
      StringAppend(unescaped, 'n');
      break;
    case '\\':
      StringAppend(unescaped, '\\');
      StringAppend(unescaped, '\\');
      break;
    default:
      StringAppend(unescaped, c);
    };
  }
  return unescaped;
}

String *PrintAtom(Atom *a, BOOL print_readably, BOOL print_quotes)
{
  CHAR buf[32];
  String *s, *unescaped;
  NullCheck(a, "atom");
  switch (a->_tag) {
  case ATOM_NIL:
    return StringMk("nil");
  case ATOM_FALSE:
    return StringMk("false");
  case ATOM_TRUE:
    return StringMk("true");
  case ATOM_SYMBOL:
  case ATOM_KEYWORD:
    return StringCopy(a->_str);
  case ATOM_STRING:
    if (print_quotes) s = StringMk("\"");
    else s = StringEmpty;
    if (print_readably) {
      unescaped = unescapeString(a->_str);
      StringConcat(s, unescaped);
    }
    else {
      StringConcat(s, a->_str);
    }
    if (print_quotes) StringAppend(s, '"');
    return s;
  case ATOM_NUMBER:
    StrPrint(buf, "%ld", a->_num);
    return StringMk(buf);
  default:
    PrintError("unknown atom tag");
    return NULL;
  };
}

String *PrintFun(Fun *f)
{
  return StringMk("#<function>");
}

String *PrintRef(Malval *m, BOOL print_readably)
{
  String *s = StringMk("(atom ");
  String *_s = PrintMalval(m->_ref, print_readably, TRUE);
  StringConcat(s, _s);
  StringAppend(s, ')');
  return s;
}

VOID _printSeqAux(Malval *seq, String *str, BOOL print_readably)
{
  INT i;
  Malval *_m;
  String *_s;
  for (i = 0; i < MalSize(seq); ++i) {
    _m = MalNth(seq, i);
    // this is on purpose (passing print_readably for print_quotes)
    _s = PrintMalval(_m, print_readably, print_readably);
    StringConcat(str, _s);
    if (i < MalSize(seq) - 1)
      StringAppend(str, ' ');
  }
}

String *PrintMalval(Malval *m, BOOL print_readably=TRUE, BOOL print_quotes=TRUE)
{
  NullCheck(m, "malval");
  String *s;
  INT i;
  Hashmap *tab;
  PArray *keys;
  Malval *key, *val;
  switch (m->_tag) {
  case ATOM:
    return PrintAtom(m->_atom, print_readably, print_quotes);
  case LIST:
    s = StringMk("(");
    _printSeqAux(m, s, print_readably);
    StringAppend(s, ')');
    return s;
  case VEC:
    s = StringMk("[");
    _printSeqAux(m, s, print_readably);
    StringAppend(s, ']');
    return s;
  case FUN:
    return PrintFun(m->_fun);
  case HASH:
    s = StringMk("{");
    tab = HashmapOfMalval(m);
    keys = RemoveDuplicateMalvals(HashmapKeys(tab));
    for (i = 0; i < PArraySize(keys); ++i) {
      key = PArrayGet(keys, i);
      val = HashmapGet(tab, key);
      StringConcat(s, PrintMalval(key, print_readably, print_readably));
      StringConcatC(s, " ");
      StringConcat(s, PrintMalval(val, print_readably, print_readably));
      if (i < PArraySize(keys) - 1)
	StringAppend(s, ' ');
    }
    StringAppend(s, '}');
    return s;
  case REF:
    return PrintRef(m, print_readably);
  default:
  "unknown malval tag: %d\n", m->_tag;
    return throws("print malval error");
  }
}

VOID PrintfMalval(Malval *m, BOOL print_readably, BOOL print_quotes)
{
  String *s = PrintMalval(m, print_readably, print_quotes);
  CHAR *c = StringCString(s);
  "%s\n", c;
  Free(c);
}

#endif
