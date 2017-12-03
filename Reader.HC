#ifndef READER_HC
#define READER_HC

#include "FastLexer.HC"
#include "MalNumber.HC"
#include "MalVector.HC"
#include "PArray.HC"
#include "String.HC"
#include "Types.HC"
#include "Util.HC"

class Reader
{
  PArray *_tokens;
  INT _pos;
  Env *_misc; // misc regexes
};

VOID _initReader(Reader *r)
{
  // misc regexes
  r->_misc = EnvEmpty(NULL);
  EnvSet(r->_misc, StringMk("digit"), RegexParseC(
"(-((0|1|2|3|4|5|6|7|8|9)+)|(0|1|2|3|4|5|6|7|8|9)+(\\.)(0|1|2|3|4|5|6|7|8|9)+)|((0|1|2|3|4|5|6|7|8|9)+)|(0|1|2|3|4|5|6|7|8|9)+(\\.)(0|1|2|3|4|5|6|7|8|9)+)"));
  EnvSet(r->_misc, StringMk("string"), RegexParseC("\".*\""));
  EnvSet(r->_misc, StringMk("symbol"), RegexParseC(".+")); // TODO
  EnvSet(r->_misc, StringMk("deref"), RegexParseC("@.+"));
}

Reader *ReaderMk()
{
  Reader *r = MAlloc(sizeof(Reader));
  r->_pos = 0;
  r->_tokens = NULL;
  _initReader(r);
  return r;
}

VOID ReaderDelete(Reader *r)
{
  NullCheck(r, "reader");
  INT i;
  if (r->_tokens) {
    for (i = 0; i < PArraySize(r->_tokens); ++i) {
      TokenDelete(PArrayGet(r->_tokens, i));
    }
  }
  PArray *regexes = EnvValues(r->_misc);
  for (i = 0; i < PArraySize(regexes); ++i) {
    RegexDelete(PArrayGet(regexes, i));
  }
  Free(r);
}

Token *ReaderPeek(Reader *r)
{
  NullCheck(r, "reader");
  if (r->_pos == PArraySize(r->_tokens)) return NULL;
  return PArrayGet(r->_tokens, r->_pos);
}

Token *ReaderNext(Reader *r)
{
  NullCheck(r, "reader");
  if (r->_pos == PArraySize(r->_tokens)) {
    throws("attempt to read past end of token stream");
  }
  return PArrayGet(r->_tokens, r->_pos++);
}

String *escapeString(String *s)
{
  INT i;
  /* CHAR c; */
  INT c; // suppress warning about 64-bit register
  String *escaped = StringEmpty;
  for (i = 0; i < StringLen(s); ++i) {
    c = StringGet(s, i);
    if (c == '\\' && i < StringLen(s)-1) {
      switch (StringGet(s, i+1)) {
      case '"':
	StringAppend(escaped, '"');
	++i;
	break;
      case 'n':
	StringAppend(escaped, '\n');
	++i;
	break;
      case '\\':
	StringAppend(escaped, '\\');
	++i;
	break;
      };
    }
    else {
      StringAppend(escaped, c);
    }
  }
  return escaped;
}

extern Malval *ReaderReadForm(Reader *r);

Malval *ReaderReadAtom(Reader *r)
{
  Token *t = ReaderNext(r);
  NullCheck(t, "token");
  /* CHAR c = StringGet(t->s, 0); */
  // suppress warning about 64-bit register
  INT c = StringGet(t->s, 0);
  Malval *result = NULL;
  String *s, *escaped;
  List *l;
  if (c == ':') {
    result = MalKeywordMk(StringSubstr(t->s, 0, -1));
  }
  else if (RegexMatch(EnvGetC(r->_misc, "digit"), t->s, 0)) {
    result = MalNumberMk(Atoi(t->s));
  }
  else if (RegexMatch(EnvGetC(r->_misc, "string"), t->s, 0)) {
    s = StringSubstr(t->s, 1, StringLen(t->s)-2);
    escaped = escapeString(s);
    result = MalStringMk(escaped);
  }
  else if (RegexMatch(EnvGetC(r->_misc, "deref"), t->s, 0)) {
    s = StringSubstr(t->s, 1, StringLen(t->s)-1);
    l = ListCons(MalSymbolMk(StringMk("deref")),
		 ListCons(MalSymbolMk(s), ListNil));
    result = MalListMk(l);
  }
  else if (StringEqC(t->s, "nil")) {
    result = MalNilMk;
  }
  else if (StringEqC(t->s, "false")) {
    result = MalFalseMk;
  }
  else if (StringEqC(t->s, "true")) {
    result = MalTrueMk;
  }
  else if (RegexMatch(EnvGetC(r->_misc, "symbol"), t->s, 0)) {
    result = MalSymbolMk(StringCopy(t->s));
  }
  if (result) {
    return result;
  }
  else {
    return throws("atom parse error");
  }
}

PArray *ReaderReadSeq(Reader *r, CHAR rightClose)
{
  ReaderNext(r); // eat '(' or '['
  PArray *seq = PArrayEmpty;
  Token *t = ReaderPeek(r);
  Malval *val;
  NullCheck(t, "token");
  // Until rightClose
  while (!(t->i == SPECIAL_ONE && StringGet(t->s, 0) == rightClose)) {
    val = ReaderReadForm(r);
    PArrayPush(seq, val);
    t = ReaderPeek(r);
    if (!t) throws("expected a ')'");
  }
  ReaderNext(r); // eat ')'
  return seq;
}

Malval *ReaderReadList(Reader *r)
{
  return MalListMk(ListFromPArray(ReaderReadSeq(r, ')')));
}

Malval *ReaderReadVec(Reader *r)
{
  return MalVectorMk(ReaderReadSeq(r, ']'));
}

Malval *ReaderReadHash(Reader *r)
{
  PArray *seq = ReaderReadSeq(r, '}');
  Hashmap *s = HashmapFromSequence(seq);
  return MalHashMk(s);
}

Malval *ReaderReadForm(Reader *r)
{
  Token *t = ReaderPeek(r);
  try {
    NullCheck(t, "token");
  }
  catch {
    /* throws("parse error: expected token"); */
    "parse error: expected token\n";
    RethrowException; // just to be explicit
  }
  CHAR c;
  Malval *m = NULL;
  Malval *v, *meta;
  List *l;
  switch (t->i) {
  case SPECIAL_ONE: { // If left paren, parse list
    c = StringGet(t->s, 0);
    if (c == '(')
      m = ReaderReadList(r);
    else if (c == '[')
      m = ReaderReadVec(r);
    else if (c == '{')
      m = ReaderReadHash(r);
    else if (c == '\'') {
      ReaderNext(r);
      l = ListCons(MalSymbolMk(StringMk("quote")),
		   ListCons(ReaderReadForm(r), ListNil));
      m = MalListMk(l);
    }
    else if (c == '`') {
      ReaderNext(r);
      l = ListCons(MalSymbolMk(StringMk("quasiquote")),
		   ListCons(ReaderReadForm(r), ListNil));
      m = MalListMk(l);
    }
    else if (c == '~') {
      ReaderNext(r);
      l = ListCons(MalSymbolMk(StringMk("unquote")),
		   ListCons(ReaderReadForm(r), ListNil));
      m = MalListMk(l);
    }
    else if (c == '^') {
      ReaderNext(r);
      v = ReaderReadForm(r);
      meta = ReaderReadForm(r);
      l = ListCons(MalSymbolMk(StringMk("with-meta")),
		   ListCons(meta, ListCons(v, ListNil)));
      m = MalListMk(l);
      return m;
    }
    else {
      throws("unexpected special character");
    }
    break;
  }

  case SPECIAL_TWO:
    if (StringEqC(t->s, "~@")) {
      ReaderNext(r);
      l = ListCons(MalSymbolMk(StringMk("splice-unquote")),
			 ListCons(ReaderReadForm(r), ListNil));
      m = MalListMk(l);
    }
    else {
      throws("unexpected special character");
    }
    break;

  default: // Else parse atom
    m = ReaderReadAtom(r);
  };

  return m;
}

VOID _printTokens(PArray *tokens)
{
  INT i;
  CHAR *c;
  Token *t;
  for (i = 0; i < PArraySize(tokens); ++i) {
    t = PArrayGet(tokens, i);
    c = StringCString(t->s);
    "token %ld: %s\n", t->i, c;
    Free(c);
  }
}

Malval *ReaderReadString(Reader *r, String *s)
{
  NullCheck(r, "reader");
  NullCheck(s, "input string");
  StringAppend(s, '\n');
  PArray *tokens = FastTokenize(s);
  INT i;
  Token *t;
  // If lexing succeeded
  if (tokens) {
    // remove whitespace and comment tokens
    for (i = 0; i < PArraySize(tokens);) {
      t = PArrayGet(tokens, i);
      if (t->i == WHITESPACE || t->i == COMMENT) {
  	TokenDelete(PArrayGet(tokens, i));
  	PArrayErase(tokens, i, i+1);
      }
      else ++i;
    }
    r->_tokens = tokens;
    return ReaderReadForm(r);
  }
  // Else lexing failed
  else {
    return throws("lexer failed");
  }
}

#endif
