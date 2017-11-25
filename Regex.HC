#ifndef REGEX_HC
#define REGEX_HC

// http://matt.might.net/articles/parsing-regex-with-recursive-descent/
//   <regex> ::= <term> '|' <regex>
//            |  <term>
//
//   <term> ::= { <factor> }
//
//   <factor> ::= <base> { '*' }
//
//   <base> ::= <char>
//           |  '\' <char>
//           |  '(' <regex> ')'

#include "String.HC"
#include "Util.HC"

#define REGEX_EMPTY   0
#define REGEX_EPSILON 1
#define REGEX_CHAR    2
#define REGEX_CONCAT  3
#define REGEX_OR      4
#define REGEX_AND     5
#define REGEX_STAR    6
#define REGEX_NOT     7

class Regex
{
  CHAR tag;
  CHAR c;   // optional (Char)
  Regex *s; // optional (Or, And, Concat, Star, Not)
  Regex *t; // optional (Or, Concat)
};

VOID RegexDelete(Regex *r)
{
  NullCheck(r, "regex");
  switch (r->tag) {
  case REGEX_EMPTY:
  case REGEX_EPSILON:
  case REGEX_CHAR:
    break;
  case REGEX_CONCAT:
  case REGEX_OR:
  case REGEX_AND:
    RegexDelete(r->t);
  case REGEX_STAR:
  case REGEX_NOT:
    RegexDelete(r->s);
    break;
  default:
    "unknown Regex tag %d\n", r->tag;
  };
  Free(r);
}

VOID RegexPrint(Regex *r, INT depth)
{
  INT i;
  for (i = 0; i < depth; ++i) " ";
  switch (r->tag) {
  case REGEX_EMPTY:
    "Empty\n";
    break;
  case REGEX_EPSILON:
    "Epsilon\n";
    break;
  case REGEX_CHAR:
    "Char(%c)\n", r->c;
    break;
  case REGEX_CONCAT:
    "Concat\n";
    RegexPrint(r->s, depth+1);
    RegexPrint(r->t, depth+1);
    break;
  case REGEX_OR:
    "Or\n";
    RegexPrint(r->s, depth+1);
    RegexPrint(r->t, depth+1);
    break;
  case REGEX_AND:
    "And\n";
    RegexPrint(r->s, depth+1);
    RegexPrint(r->t, depth+1);
    break;
  case REGEX_STAR:
    "Star\n";
    RegexPrint(r->s, depth+1);
    break;
  case REGEX_NOT:
    "Not\n";
    RegexPrint(r->s, depth+1);
    break;
  default:
    "unknown Regex tag %d\n", r->tag;
  };
}

String *RegexToString(Regex *r)
{
  String *s;
  switch (r->tag) {
  case REGEX_EMPTY:
    return StringMk("empty");
  case REGEX_EPSILON:
    return StringMk("eps");
  case REGEX_CHAR:
    s = StringEmpty;
    StringAppend(s, r->c);
    return s;
  case REGEX_CONCAT:
    s = StringEmpty;
    StringConcat(s, RegexToString(r->s));
    StringConcat(s, RegexToString(r->t));
    return s;
  case REGEX_OR:
    s = StringEmpty;
    StringConcat(s, RegexToString(r->s));
    StringAppend(s, '|');
    StringConcat(s, RegexToString(r->t));
    return s;
  case REGEX_AND:
    s = StringEmpty;
    StringConcat(s, RegexToString(r->s));
    StringAppend(s, '&');
    StringConcat(s, RegexToString(r->t));
    return s;
  case REGEX_STAR:
    s = StringEmpty;
    StringConcat(s, RegexToString(r->s));
    StringAppend(s, '*');
    return s;
  case REGEX_NOT:
    s = StringEmpty;
    StringAppend(s, '~');
    StringConcat(s, RegexToString(r->s));
    return s;
  default:
    return throws("unknown Regex tag");
  }
}

Regex *_mkInit()
{
  Regex *r = MAlloc(sizeof(Regex));
  r->tag = -1;
  r->c = 'a';
  r->s = NULL;
  r->t = NULL;
  return r;
}

Regex *_mkCopy(Regex *r)
{
  Regex *_r = _mkInit;
  _r->tag = r->tag;
  _r->c = r->c;
  if (r->s)
    _r->s = _mkCopy(r->s);
  if (r->t)
    _r->t = _mkCopy(r->t);
  return _r;
}

Regex *_mkEmpty()
{
  Regex *r = _mkInit;
  r->tag = REGEX_EMPTY;
  return r;
}

Regex *_mkEpsilon()
{
  Regex *r = _mkInit;
  r->tag = REGEX_EPSILON;
  return r;
}

Regex *_mkChar(CHAR c)
{
  Regex *r = _mkInit;
  r->tag = REGEX_CHAR;
  r->c = c;
  return r;
}

Regex *_mkConcat(Regex *s, Regex *t)
{
  Regex *r = _mkInit;
  r->tag = REGEX_CONCAT;
  r->s = s;
  r->t = t;
  return r;
}

Regex *_mkOr(Regex *s, Regex *t)
{
  Regex *r = _mkInit;
  r->tag = REGEX_OR;
  r->s = s;
  r->t = t;
  return r;
}

Regex *_mkAnd(Regex *s, Regex *t)
{
  Regex *r = _mkInit;
  r->tag = REGEX_AND;
  r->s = s;
  r->t = t;
  return r;
}

Regex *_mkStar(Regex *s)
{
  Regex *r = _mkInit;
  r->tag = REGEX_STAR;
  r->s = s;
  return r;
}

Regex *_mkNot(Regex *s)
{
  Regex *r = _mkInit;
  r->tag = REGEX_NOT;
  r->s = s;
  return r;
}

Regex *_mkAny()
{
  INT i;
  Regex *r = _mkEmpty;
  for (i = 0; i < ToI64(Pow(2.0, 8.0)); ++i) {
    r = _mkOr(r, _mkChar(i));
  }
  return r;
}

BOOL _regexEq(Regex *r1, Regex *r2)
{
  if (r1->tag != r2->tag) return 0;
  switch (r1->tag) {
  case REGEX_CHAR:
    return r1->c == r2->c;
  case REGEX_CONCAT:
  case REGEX_OR:
  case REGEX_AND:
    if (_regexEq(r1->s, r2->s))
      return _regexEq(r1->t, r2->t);
    else return FALSE;
  case REGEX_STAR:
  case REGEX_NOT:
    return _regexEq(r1->s, r2->s);
  };
  return 1;
}

/* Recursive descent parsing internals. */

// state of the parser
CHAR *_parser_input;
INT _parser_cur;

CHAR _peek()
{
  return _parser_input[_parser_cur];
}

VOID _eat(CHAR c)
{
  if (_peek != c) {
    "expected %c", c;
    return;
  }
  ++_parser_cur;
}

CHAR _next()
{
  return _parser_input[_parser_cur++];
}

INT _more()
{
  return _parser_cur < StrLen(_parser_input);
}

Regex *_extractLeft(Regex *r)
{
  Regex *s = _mkCopy(r->s);
  RegexDelete(r);
  return s;
}

Regex *_extractRight(Regex *r)
{
  Regex *t = _mkCopy(r->t);
  RegexDelete(r);
  return t;
}

extern Regex *_reduce(Regex *r);

Regex *_reduceConcat(Regex *r)
{
  r->s = _reduce(r->s);
  r->t = _reduce(r->t);
  if (!r->s->tag || !r->t->tag) {
    RegexDelete(r);
    return _mkEmpty;
  }
  else {
    if (r->s->tag == 1)
      return _extractRight(r);
    else if (r->t->tag == 1)
      return _extractLeft(r);
  }
  return r;
}

Regex *_reduceOr(Regex *r)
{
  r->s = _reduce(r->s);
  r->t = _reduce(r->t);
  if (_regexEq(r->s, r->t)) {
    return _extractLeft(r);
  }
  else {
    if (!r->s->tag)
      return _extractRight(r);
    else if (!r->t->tag)
      return _extractLeft(r);
  }
  return r;
}

Regex *_reduceAnd(Regex *r)
{
  r->s = _reduce(r->s);
  r->t = _reduce(r->t);
  if (_regexEq(r->s, r->t)) {
    return _extractLeft(r);
  }
  else {
    if (!r->s->tag || !r->t->tag) {
      RegexDelete(r);
      return _mkEmpty;
    }
  }
  return r;
}

Regex *_reduceStar(Regex *r)
{
  r->s = _reduce(r->s);
  if (!r->s->tag) {
    RegexDelete(r);
    return _mkEmpty;
  }
  if (r->s->tag == 1) {
    RegexDelete(r);
    return _mkEpsilon;
  }
  return r;
}

Regex *_reduceNot(Regex *r)
{
  r->s = _reduce(r->s);
  // ?
  return r;
}

Regex *_reduce(Regex *r)
{
  Regex *red = NULL;
  switch (r->tag) {
  case REGEX_CONCAT:
    red = _reduceConcat(r);
    break;
  case REGEX_OR:
    red = _reduceOr(r);
    break;
  case REGEX_AND:
    red = _reduceAnd(r);
    break;
  case REGEX_STAR:
    red = _reduceStar(r);
    break;
  case REGEX_NOT:
    red = _reduceNot(r);
    break;
  default:
    red = r;
  };
  return red;
}

/* Regular expression term types. */

extern Regex *_regex();
extern Regex *_term();
extern Regex *_factor();
extern Regex *_base();

// The main parsing function. Initializes the parser state and kicks off
// the recursive descent parsing procedure.
Regex *RegexParseC(CHAR *s)
{
  _parser_input = s;
  _parser_cur = 0;
  return _reduce(_regex);
}

Regex *RegexParse(String *s)
{
  CHAR *c = StringCString(s);
  Regex *r = RegexParseC(c);
  Free(c);
  return r;
}

Regex *_regex()
{
  Regex *term = _term;
  Regex *regex;
  if (_more) {
    if (_peek == '|') {
      _eat('|');
      regex = _regex;
      return _mkOr(term, regex);
    }
    else if (_peek == '&') {
      _eat('&');
      regex = _regex;
      return _mkAnd(term, regex);
    }
  }
  return term;
}

Regex *_term()
{
  Regex *factor = _mkEpsilon;
  Regex *nextFactor;
  while (_more) {
    if (_peek == ')' || _peek == '|' || _peek == '&')
      break;
    nextFactor = _factor;
    factor = _mkConcat(factor, nextFactor);
  }
  return factor;
}

Regex *_factor()
{
  Regex *base = _base;
  if (_more) {
    if (_peek == '*') {
      _eat('*');
      base = _mkStar(base);
    }
    // desugar '+' to Concat and Star
    else if (_peek == '+') {
      _eat('+');
      base = _mkConcat(_mkCopy(base), _mkStar(base));
    }
  }
  return base;
}

Regex *_base()
{
  CHAR esc;
  Regex *r;
  switch (_peek) {
  case '(': {
    _eat('(');
    r = _regex;
    _eat(')');
    return r;
  }
  case '\\':
    _eat('\\');
    esc = _next;
    return _mkChar(esc);
  case '^':
    _eat('^');
    r = _regex;
    return _mkNot(r);
  case '.':
    _eat('.');
    return _mkAny;
  };
  return _mkChar(_next);
}

// derivatives

BOOL _nullable(Regex *r)
{
  switch (r->tag) {
  case REGEX_EMPTY:
  case REGEX_CHAR:
    return FALSE;
  case REGEX_EPSILON:
  case REGEX_STAR:
    return TRUE;
  case REGEX_CONCAT:
  case REGEX_AND:
    if (_nullable(r->s))
      return _nullable(r->t);
    else
      return FALSE;
  case REGEX_OR:
    if (_nullable(r->s))
      return TRUE;
    else
      return _nullable(r->t);
  case REGEX_NOT:
    return !_nullable(r->s);
  default:
    "unknown Regex tag %d\n", r->tag;
    return FALSE;
  };
}

Regex *_deriv(Regex *r, CHAR c)
{
  Regex *_r;
  switch (r->tag) {
  case REGEX_EMPTY:
  case REGEX_EPSILON:
    return _mkEmpty;
  case REGEX_CHAR:
    if (r->c == c)
      return _mkEpsilon;
    else
      return _mkEmpty;
  case REGEX_CONCAT: {
    _r = NULL;
    if (_nullable(r->s)) {
      _r = _mkEpsilon;
    }
    else {
      _r = _mkEmpty;
    }
    return _mkOr(_mkConcat(_deriv(r->s, c), _mkCopy(r->t)),
		 _mkConcat(_r, _deriv(r->t, c)));
  }
  case REGEX_OR:
    return _mkOr(_deriv(r->s, c), _deriv(r->t, c));
  case REGEX_AND:
    return _mkAnd(_deriv(r->s, c), _deriv(r->t, c));
  case REGEX_STAR:
    return _mkConcat(_deriv(r->s, c), _mkCopy(r));
  case REGEX_NOT:
    return _mkNot(_deriv(r->s, c));
  default:
    "unknown Regex tag %d\n", r->tag;
  };
  return NULL;
}

BOOL RegexMatch(Regex *r, String *s, INT cur)
{
  BOOL matches;
  Regex *deriv;
  if (StringLen(s) <= cur) {
    return _nullable(r);
  }
  else {
    deriv = _deriv(r, StringGet(s, cur));
    deriv = _reduce(deriv);
    matches = RegexMatch(deriv, s, ++cur);
    RegexDelete(deriv);
    return matches;
  }
}

BOOL RegexMatchC(Regex *r, CHAR *s, INT cur)
{
  String *_s = StringMk(s);
  BOOL matches = RegexMatch(r, _s, cur);
  return matches;
}

BOOL RegexParseMatch(String *pattern, String *s)
{
  Regex *r = RegexParse(pattern);
  BOOL matches = RegexMatch(r, s, 0);
  RegexDelete(r);
  return matches;
}

BOOL RegexParseMatchC(CHAR *pattern, CHAR *s)
{
  String *_pattern = StringMk(pattern);
  String *_s = StringMk(s);
  BOOL matches = RegexParseMatch(_pattern, _s);
  return matches;
}

Regex *RegexMkPrefix(Regex *r)
{
  return _mkConcat(r, _mkStar(_mkAny));
}

#endif
