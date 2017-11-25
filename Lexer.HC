#ifndef LEXER_HC
#define LEXER_HC

#include "Array.HC"
#include "PArray.HC"
#include "Regex.HC"
#include "String.HC"
#include "Util.HC"

class Lexer
{
  PArray *_regexes; // Array of pointers to Regex terms
  PArray *_aux_regexes; // Auxiliary regexes with '.*' appended to the end
};

class Token
{
  INT i;
  String *s;
};

Token *TokenMk(INT i, String *s)
{
  Token *t = MAlloc(sizeof(Token));
  t->i = i;
  t->s = s;
  return t;
}

VOID TokenDelete(Token *t)
{
  NullCheck(t, "token");
  Free(t);
}

VOID LexerDelete(Lexer *l)
{
  NullCheck(l, "lexer");
  NullCheck(l->_regexes, "lexer regexes");
  INT i;
  for (i = 0; i < PArraySize(l->_regexes); ++i) {
    RegexDelete(PArrayGet(l->_regexes, i));
  }
  Free(l);
}

Lexer *LexerEmpty()
{
  Lexer *l = MAlloc(sizeof(Lexer));
  l->_regexes = PArrayEmpty;
  l->_aux_regexes = PArrayEmpty;
  return l;
}

// expects [patterns] to be an PArray of Strings
Lexer *LexerMk(PArray *patterns)
{
  NullCheck(patterns, "regex patterns");
  INT i;
  Lexer *l = LexerEmpty;
  String *p;
  Regex *r;
  for (i = 0; i < PArraySize(patterns); ++i) {
    p = PArrayGet(patterns, i);
    r = RegexParse(p);
    PArrayPush(l->_regexes, r);
    PArrayPush(l->_aux_regexes, RegexMkPrefix(r));
  }
  return l;
}

// expects [patterns] to be an Array of c-strings
Lexer *LexerMkC(PArray *patterns)
{
  INT i;
  PArray *strings = PArrayEmpty;
  for (i = 0; i < PArraySize(patterns); ++i) {
    PArrayPush(strings, StringMk(PArrayGet(patterns, i)));
  }
  return LexerMk(strings);
}

INT _greedyMatch(Regex *r, String *s)
{
  INT i, match;
  INT max_i = 0;
  String *sub;
  for (i = 1; i <= StringLen(s); ++i) {
    sub = StringSubstr(s, 0, i);
    match = RegexMatch(r, sub, 0);
    if (match)
      max_i = i;
  }
  return max_i;
}

Token *LexerMatch(Lexer *l, String *s)
{
  NullCheck(l, "lexer");
  NullCheck(s, "input string");
  INT i, j;
  Regex *r, *r_aux;
  for (i = 0; i < PArraySize(l->_regexes); ++i) {
    r_aux = PArrayGet(l->_aux_regexes, i);
    if (RegexMatch(r_aux, s, 0)) {
      r = PArrayGet(l->_regexes, i);
      j = _greedyMatch(r, s);
      return TokenMk(i, StringSubstr(s, 0, j));
    }
  }
  return NULL;
}

PArray *LexerLex(Lexer *l, String *s)
{
  INT i = 0;
  NullCheck(l, "lexer");
  NullCheck(s, "input string");
  s = StringCopy(s);
  PArray *a = PArrayEmpty;
  Token *t;
  while (StringLen(s)) {
    t = LexerMatch(l, s);
    if (!t) {
      for (i = 0; i < PArraySize(a); ++i) {
	TokenDelete(PArrayGet(a, i));
      }
      return NULL;
    }
    PArrayPush(a, t);
    StringErase(s, 0, StringLen(t->s));
  }
  return a;
}

#endif
