#ifndef FAST_LEXER_HC
#define FAST_LEXER_HC

// Hand-rolled lexer written specifically for Mal. Should be much faster
// than the general lexer that uses greedy matching of regexes in a dumb
// way.

// Token indices
#define WHITESPACE   0
#define SPECIAL_TWO  1
#define SPECIAL_ONE  2
#define QUOTE_STRING 3
#define COMMENT      4
#define OTHER        5

#include "PArray.HC"
#include "String.HC"
#include "Lexer.HC"

Token *_matchWhitespace(String *s, INT *cur)
{
  CHAR c = StringGet(s, *cur);
  String *_s;
  switch (c) {
  case ' ':
  case ',':
  case '\t':
  case '\n':
  case 31: // shift+space dot thing
    _s = StringEmpty;
    StringAppend(_s, c);
    // careful with the syntax below.
    // ++*cur and *cur++ don't appear to work in HolyC as they do in C
    *cur = *cur + 1;
    return TokenMk(WHITESPACE, _s);
  default:
    return NULL;
  }
}

Token *_matchSpecialTwo(String *s, INT *cur)
{
  String *sub = StringSubstr(s, *cur, 2);
  if (StringEqC(sub, "~@")) {
    *cur = *cur + 2;
    return TokenMk(SPECIAL_TWO, StringMk("~@"));
  }
  else
    return NULL;
}

Token *_matchSpecialOne(String *s, INT *cur)
{
  CHAR c = StringGet(s, *cur);
  String *_s;
  switch (c) {
  case '[': case ']': case '{': case '}': case '(':
  case ')': case '\'': case '`': case '~': case '^':
    _s = StringEmpty;
    StringAppend(_s, c);
    *cur = *cur + 1;
    return TokenMk(SPECIAL_ONE, _s);
  default:
    return NULL;
  }
}

Token *_matchQuote(String *s, INT *cur)
{
  INT local_cur = *cur;
  CHAR c = StringGet(s, local_cur++);
  String *acc = StringMk("\"");
  if (c == '"') {
    while (local_cur < StringLen(s)) {
      c = StringGet(s, local_cur++);
      if (c == '\\') {
	c = StringGet(s, local_cur++);
	if (c == '"') {
	  StringAppend(acc, '"');
	}
	else {
	  StringAppend(acc, '\\');
	  StringAppend(acc, c);
	}
      }
      else {
	if (c == '"') {
	  *cur = local_cur;
	  StringAppend(acc, '"');
	  return TokenMk(QUOTE_STRING, acc);
	}
	else {
	  StringAppend(acc, c);
	}
      }
    }
    return NULL;
  }
  else
    return NULL;
}

BOOL isOtherChar(CHAR c)
{
  switch (c) {
  case 'a'...'z': case 'A'...'Z': case '0'...'9':
  case '=': case '+': case '!': case '#': case '$$':
  case '%': case '&': case '*': case '_': case '-':
  case '<': case '>': case '.': case '?': case '/':
  case '"': case '\'': case ':': case '@':
    return TRUE;
  default:
    return FALSE;
  }
}

Token *_matchComment(String *s, INT *cur)
{
  INT local_cur = *cur;
  CHAR c = StringGet(s, local_cur++);
  String *acc = StringEmpty;
  if (c == ';') {
    while (local_cur < StringLen(s)) {
      c = StringGet(s, local_cur++);
      if (c == '\n') break;
      else StringAppend(acc, c);
    }
    *cur = local_cur;
    return TokenMk(COMMENT, acc);
  }
  else {
    return NULL;
  }
}

Token *_matchOther(String *s, INT *cur)
{
  INT local_cur = *cur;
  CHAR c = StringGet(s, local_cur++);
  String *acc = StringEmpty;
  if (isOtherChar(c)) {
    StringAppend(acc, c);
    while (local_cur < StringLen(s)) {
      c = StringGet(s, local_cur++);
      if (isOtherChar(c)) {
	StringAppend(acc, c);
      }
      else break;
    }
    *cur = local_cur - 1;
    return TokenMk(OTHER, acc);
  }
  else {
    return NULL;
  }
}

// Tokenize an input string.
PArray *FastTokenize(String *s)
{
  INT cur = 0;
  PArray *tokens = PArrayEmpty;
  Token *t;
  while (cur < StringLen(s)) {
    t = _matchWhitespace(s, &cur);
    if (t) {
      PArrayPush(tokens, t);
      goto FAST_TOKENIZE_LOOP_END;
    }
    t = _matchSpecialTwo(s, &cur);
    if (t) {
      PArrayPush(tokens, t);
      goto FAST_TOKENIZE_LOOP_END;
    }
    t = _matchSpecialOne(s, &cur);
    if (t) {
      PArrayPush(tokens, t);
      goto FAST_TOKENIZE_LOOP_END;
    }
    t = _matchQuote(s, &cur);
    if (t) {
      PArrayPush(tokens, t);
      goto FAST_TOKENIZE_LOOP_END;
    }
    t = _matchComment(s, &cur);
    if (t) {
      PArrayPush(tokens, t);
      goto FAST_TOKENIZE_LOOP_END;
    }
    t = _matchOther(s, &cur);
    if (t) {
      PArrayPush(tokens, t);
      goto FAST_TOKENIZE_LOOP_END;
    }

    /* Fail if nothing matches */
    return NULL;
  FAST_TOKENIZE_LOOP_END:;
  }

  return tokens;
}

#endif
