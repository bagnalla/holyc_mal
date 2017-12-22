#ifndef INTRINSICS_HC
#define INTRINSICS_HC

#include "GC.HC"
#include "MalList.HC"
#include "MalListVector.HC"
#include "MalNumber.HC"
#include "MalVector.HC"
#include "PArray.HC"
#include "Printer.HC"
#include "Reader.HC"
#include "String.HC"
#include "Types.HC"
#include "Util.HC"

// The first argument is always the symbol of the function.
// The arguments are assumed to be a Mal list.

extern VOID _bindEnv(Env *env, PArray *binders, Malval *ast);
extern Malval *mkQuote(Malval *v);
extern Malval *EVAL(Env *env, Malval *m);

Malval *_plus_aux(Malval *x, Malval *y)
{
  return MalNumberMk(MalIntOfNumber(x) + MalIntOfNumber(y));
}
Malval *_plus(Malval *args)
{
  return ListFoldr(ListTail(MalListOfList(args)),
		   &_plus_aux, MalNumberMk(0));
}

Malval *_minus_aux(Malval *x, Malval *y)
{
  return MalNumberMk(MalIntOfNumber(x) - MalIntOfNumber(y));
}
Malval *_minus(Malval *args)
{
  return ListFoldl(ListTail(ListTail(MalListOfList(args))),
		   &_minus_aux, MalHead(MalTail(args)));
}

Malval *_mult_aux(Malval *x, Malval *y)
{
  return MalNumberMk(MalIntOfNumber(x) * MalIntOfNumber(y));
}
Malval *_mult(Malval *args)
{
  return ListFoldr(ListTail(MalListOfList(args)),
		   &_mult_aux, MalNumberMk(1));
}

Malval *_div_aux(Malval *x, Malval *y)
{
  return MalNumberMk(MalIntOfNumber(x) / MalIntOfNumber(y));
}
Malval *_div(Malval *args)
{
  return ListFoldl(ListTail(ListTail(MalListOfList(args))),
		   &_div_aux, MalHead(MalTail(args)));
}

Malval *_list(Malval *args)
{
  NullCheck(args, "args");
  return MalListTail(args);
}

Malval *_isList(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'list?' requires exactly one argument");
  }
  Malval *v = MalListNth(args, 1);
  return MalBoolMk(MalIsList(v));
}

Malval *_isEmpty(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'empty?' requires exactly one argument");
  }
  Malval *v = MalListNth(args, 1);
  return MalBoolMk(!MalSize(v));
}

Malval *_count(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'count' requires exactly one argument");
  }
  Malval *l = MalListNth(args, 1);
  return MalNumberMk(MalSize(l));
}

Malval *_equal(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'=' requires exactly two arguments");
  }
  Malval *v1 = MalListNth(args, 1);
  Malval *v2 = MalListNth(args, 2);
  return MalBoolMk(MalvalEqual(v1, v2));
}

Malval *_lt(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'<' requires exactly two arguments");
  }
  Malval *v1 = MalListNth(args, 1);
  Malval *v2 = MalListNth(args, 2);
  return MalBoolMk(MalIntOfNumber(v1) < MalIntOfNumber(v2));
}

Malval *_le(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'<=' requires exactly two arguments");
  }
  Malval *v1 = MalListNth(args, 1);
  Malval *v2 = MalListNth(args, 2);
  return MalBoolMk(MalIntOfNumber(v1) <= MalIntOfNumber(v2));
}

Malval *_gt(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'>' requires exactly two arguments");
  }
  Malval *v1 = MalListNth(args, 1);
  Malval *v2 = MalListNth(args, 2);
  return MalBoolMk(MalIntOfNumber(v1) > MalIntOfNumber(v2));
}

Malval *_ge(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'>=' requires exactly two arguments");
  }
  Malval *v1 = MalListNth(args, 1);
  Malval *v2 = MalListNth(args, 2);
  return MalBoolMk(MalIntOfNumber(v1) >= MalIntOfNumber(v2));
}

Malval *_prAux(Malval *args, CHAR *sep, BOOL print_readably,
	       BOOL trimQuotes)
{
  NullCheck(args, "args");
  INT i;
  String *s = StringEmpty;
  String *_s;
  for (i = 1; i < MalListSize(args); ++i) {
    _s = PrintMalval(MalListNth(args, i), print_readably, TRUE);
    if (trimQuotes) _s = StringTrimQuotes(_s);
    StringConcat(s, _s);
    if (i < MalListSize(args) - 1)
      StringConcatC(s, sep);
  }
  return MalStringMk(s);
}

Malval *_prStr(Malval *args)
{
  Malval *v = _prAux(args, " ", TRUE, FALSE);
  return MalStringMk(StringOfMalval(v));
}

Malval *_str(Malval *args)
{
  return _prAux(args, "", FALSE, TRUE);
}

Malval *_prn(Malval *args)
{
  Malval *v = _prAux(args, " ", TRUE, FALSE);
  StringPrintLn(StringOfMalval(v));
  return MalNilMk;
}

Malval *_println(Malval *args)
{
  Malval *v = _prAux(args, " ", FALSE, TRUE);
  StringPrintLn(StringOfMalval(v));
  return MalNilMk;
}

Malval *_readString(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'read-string' requires exactly one argument");
  }
  Malval *v = MalListNth(args, 1);
  if (!MalIsString(v)) {
    return throws("'read-string' argument must be a string");
  }
  String *s = StringCopy(StringOfMalval(v));
  Reader *r = ReaderMk;
  Malval *m = NULL;
  try {
    m = ReaderReadString(r, s);
  }
  catch {
    ReaderDelete(r);
    "parse error in 'read-string'\n";
    RethrowException; // just to be explicit
  }
  ReaderDelete(r);
  return m;
}

Malval *_slurp(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'slurp' requires exactly one argument");
  }
  Malval *v = MalListNth(args, 1);
  if (!MalIsString(v)) {
    return throws("'slurp' argument must be a string");
  }
  String *s = StringOfMalval(v);
  CHAR *filename = StringCString(s);
  INT size;
  CHAR *str = FileRead(filename, &size);
  Free(filename);
  if (str) {
    String *result = MalStringMk(StringMk(str));
    Free(str);
    return result;
  }
  else return MalNilMk;
}

Malval *_mkRef(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'atom' requires exactly one argument");
  }
  return MalRefMk(MalListNth(args, 1));
}

Malval *_isRef(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'atom?' requires exactly one argument");
  }
  return MalBoolMk(MalIsRef(MalListNth(args, 1)));
}

Malval *_deref(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'deref' requires exactly one argument");
  }
  return MalDeref(MalListNth(args, 1));
}

Malval *_reset(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'reset' requires exactly two arguments");
  }
  return MalvalReset(MalListNth(args, 1), MalListNth(args, 2));
}

// NOTE: All of the arguments have already been evaluated, so any quoted lists
// have had the quote stripped off. To avoid erroneously attempting to evaluate
// quoted lists as function applications when we call EVAL below, we re-quote
// all lists.
// EDIT: actually, now everything is being quoted since it's all been evaluated
// already. Even if the topmost term isn't a list, it may contain subterms that
// are lists that we want to avoid trying to evaluate again.
Malval *_swap(Malval *args)
{
  INT i;
  NullCheck(args, "args");
  if (MalListSize(args) < 3) {
    return throws("'swap!' requires at least two arguments");
  }
  Malval *ref = MalListNth(args, 1);
  if (!MalIsRef(ref)) {
    return throws("'swap!' first argument must be an atom reference");
  }
  Malval *f = MalListNth(args, 2);
  if (!MalIsFunction(f)) {
    return throws("'swap!' second argument must be a function");
  }
  PArray *binds;
  if (MalIsClosure(f)) {
    binds = f->_fun->_clos->_binds;

    if (PArraySize(binds)-1 != MalListSize(args)-3) {
      if (!StringEqC(PArrayGet(binds, 0), "&")) {
	"%ld\n", PArraySize(binds);
	"%ld\n", MalListSize(args);
	for (i = 0; i < PArraySize(binds); ++i) {
	  StringPrintLn(PArrayGet(binds, i));
	}
	StringPrintLn(PrintMalval(f->_fun->_clos->_body, TRUE, TRUE));
	return throws("'swap!': number of optional arguments doesn't match the number of binds of the given function");
      }
    }
  }
  // Build the function application to be evaluated
  Malval *old_val = MalDeref(ref);
  old_val = mkQuote(old_val);

  List *list = ListNil;
  Malval *arg;
  for (i = MalListSize(args)-4; i >= 0; --i) {
    arg = MalListNth(args, i+3);
    arg = mkQuote(arg);
    list = ListCons(arg, list);
  }
  list = ListCons(f, ListCons(old_val, list));

  Malval *new_val;
  Env *env = MalEnvOfFunction(f);

  GC_push(old_val); GC_push(list); GC_push(env);
  new_val = EVAL(env, MalListMk(list));
  GC_pop; GC_pop; GC_pop;
  ref->_ref = new_val;
  return new_val;
}

Malval *_cons(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'cons' requires exactly two arguments");
  }
  Malval *hd = MalListNth(args, 1);
  Malval *tl = MalListNth(args, 2);
  if (MalIsList(tl)) {
    return MalListCons(hd, tl);
  }
  else if (MalIsVector(tl)) {
    return MalListCons(hd, MalListOfVector(tl));
  }
  else {
    return throws("'cons' second argument must be a list or vector");
  }
}

Malval *_concat(Malval *args)
{
  NullCheck(args, "args");  
  INT i;
  Malval *res = MalListNil;
  Malval *l;
  for (i = 1; i < MalListSize(args); ++i) {
    l = MalListNth(args, i);
    if (MalIsList(l)) {
      res = MalListConcat(res, l);
    }
    else if (MalIsVector(l)) {
      res = MalListConcat(res, MalListOfVector(l));
    }
    else {
      return throws("'concat' arguments must be lists or vectors");
    }
  }
  return res;
}

Malval *_nth(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'nth' requires exactly two arguments");
  }
  Malval *i = MalListNth(args, 2);
  if (!MalIsNumber(i)) {
    return throws("'nth' second argument must be a number");
  }
  Malval *l = MalListNth(args, 1);
  INT n = MalIntOfNumber(i);
  if (n >= MalSize(l)) {
     return throws("'nth' index out of range");
  }
  if (MalIsList(l)) {
    return MalListNth(l, MalIntOfNumber(i));
  }
  else if (MalIsVector(l)) {
    return MalVectorNth(l, MalIntOfNumber(i));
  }
  else {
    return throws("'nth' first argument must be a list or vector");
  }
}

Malval *_first(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'first' requires exactly one argument");
  }
  Malval *l = MalListNth(args, 1);
  if (MalIsList(l)) {
    return MalListHead(l);
  }
  else if (MalIsVector(l)) {
    return MalVectorHead(l);
  }
  else if (MalIsNil(l)) {
    return l;
  }
  else {
    return throws("'first' argument must be a list or vector");
  }
}

Malval *_rest(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'rest' requires exactly one argument");
  }
  Malval *l = MalListNth(args, 1);
  if (MalIsList(l)) {
    return MalListTail(l);
  }
  else if (MalIsVector(l)) {
    return MalListTail(MalListOfVector(l));
  }
  else if (MalIsNil(l)) {
    return MalListNil;
  }
  else {
    return throws("'rest' argument must be a list or vector");
  }
}

Malval *_throw(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'throw' requires exactly one argument");
  }
  return throwval(MalListNth(args, 1));
}

Malval *_isNil(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'nil?' requires exactly one argument");
  }
  return MalBoolMk(MalIsNil(MalListNth(args, 1)));
}

Malval *_isTrue(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'true?' requires exactly one argument");
  }
  return MalBoolMk(MalIsTrue(MalListNth(args, 1)));
}

Malval *_isFalse(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'false?' requires exactly one argument");
  }
  return MalBoolMk(MalIsFalse(MalListNth(args, 1)));
}

Malval *_isSymbol(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'symbol?' requires exactly one argument");
  }
  return MalBoolMk(MalIsSymbol(MalListNth(args, 1)));
}

// TODO: can this be faster? (replace the loop?)
Malval *_apply(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) < 3) {
    return throws("'apply' requires at least two arguments");
  }
  Malval *f = MalListNth(args, 1);
  if (!MalIsFunction(f)) {
    return throws("'apply' first argument must be a function");
  }
  Malval *l = MalListNth(args, MalListSize(args)-1);
  if (!MalIsListOrVector(l)) {
    return throws("'apply' last argument must be a list or vector");
  }
  if (MalIsVector(l)) {
    l = MalListOfVector(l);
  }
  INT i;
  for (i = MalListSize(args)-2; i >= 2; --i) {
    l = MalCons(MalListNth(args, i), l);
  }
  l = MalListMap(l, &mkQuote);
  l = MalListCons(f, l);
  Env *env = MalEnvOfFunction(f);
  GC_push(l); GC_push(env);
  Malval *result = EVAL(env, l);
  GC_pop; GC_pop;
  return result;
}

Malval *_map(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'map' requires exactly two arguments");
  }
  Malval *f = MalListNth(args, 1);
  if (!MalIsFunction(f)) {
    return throws("'map' first argument must be a function");
  }
  Malval *l = MalListNth(args, 2);
  if (!MalIsListOrVector(l)) {
    return throws("'map' second argument must be a list or vector");
  }
  INT i;
  Env *env = MalEnvOfFunction(f);
  PArray *new_l = PArrayEmpty;
  Closure *clos;
  PArray *binds;
  Malval *body, *ll;
  GC_push(env); GC_push(new_l);
  if (MalIsClosure(f)) {
    clos = f->_fun->_clos;
    binds = clos->_binds;
    body = clos->_body;
    for (i = 0; i < MalSize(l); ++i) {
      ll = MalListCons(MalNth(l, i), MalListNil);
      _bindEnv(env, binds, ll);
      PArrayPush(new_l, EVAL(env, body));
    }
  }
  else {
    // TODO: can this be faster?
    for (i = 0; i < MalSize(l); ++i) {
      ll = MalListMk(ListCons(f, ListCons(MalNth(l, i), ListNil)));
      GC_push(ll);
      PArrayPush(new_l, (*f->_fun->_f)(ll));
      GC_pop;
    }
  }
  GC_pop; GC_pop;
  return MalListMk(ListFromPArray(new_l));
}

Malval *_symbol(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'symbol' requires exactly one argument");
  }
  return MalSymbolMk(StringOfMalval(MalListNth(args, 1)));
}

Malval *_keyword(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'keyword' requires exactly one argument");
  }
  Malval *x = MalListNth(args, 1);
  if (MalIsKeyword(x)) return x;
  String *s = StringOfMalval(x);
  StringInsert(s, 0, ':');
  return MalKeywordMk(s);
}

Malval *_isKeyword(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'keyword?' requires exactly one argument");
  }
  return MalBoolMk(MalIsKeyword(MalListNth(args, 1)));
}

Malval *_vector(Malval *args)
{
  NullCheck(args, "args");
  PArray *pa = PArrayFromList(ListTail(MalListOfList(args)));
  return MalVectorMk(pa);
}

Malval *_isVector(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'vector?' requires exactly one argument");
  }
  return MalBoolMk(MalIsVector(MalListNth(args, 1)));
}

Malval *_hashmap(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) % 2 == 0) {
    return throws("'hash-map' requires an even number of arguments");
  }
  PArray *pa = PArrayFromList(ListTail(MalListOfList(args)));
  return MalHashMk(HashmapFromSequence(pa));
}

Malval *_isHashmap(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'map?' requires exactly one argument");
  }
  return MalBoolMk(MalIsHash(MalListNth(args, 1)));
}

Malval *_assoc(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) < 2) {
    return throws("'assoc' requires at least one argument");
  }
  if (MalListSize(args) % 2 != 0) {
    return throws("'assoc' requires an even number of arguments after the first");
  }
  Hashmap *copy = HashmapCopy(HashmapOfMalval(MalListNth(args, 1)));
  INT i;
  for (i = 2; i < MalListSize(args); i += 2) {
    HashmapSet(copy, MalListNth(args, i), MalListNth(args, i+1));
  }
  return MalHashMk(copy);
}

Malval *_dissoc(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) < 2) {
    return throws("'dissoc' requires at least one argument");
  }
  Hashmap *copy = HashmapCopy(HashmapOfMalval(MalListNth(args, 1)));
  HashmapDissoc(copy, ListTail(ListTail(MalListOfList(args))));
  return MalHashMk(copy);
}

// hashmap first argument, key second
Malval *_hashmapGet(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'get' requires exactly two arguments");
  }
  Malval *m = MalListNth(args, 1);
  if (!MalIsHash(m)) return MalNilMk;
  Hashmap *h = HashmapOfMalval(m);
  Malval *key = MalListNth(args, 2);
  if (HashmapExists(h, key))
    return HashmapGet(h, key);
  else
    return MalNilMk;
}

Malval *_hashmapContains(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'contains?' requires exactly two arguments");
  }
  Malval *m = MalListNth(args, 1);
  Hashmap *h = HashmapOfMalval(m);
  Malval *key = MalListNth(args, 2);
  return MalBoolMk(HashmapExists(h, key));
}

Malval *_hashmapKeys(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'keys' requires exactly one argument");
  }
  Malval *m = MalListNth(args, 1);
  List *keys = HashmapKeysList(HashmapOfMalval(m));
  return MalListMk(keys);
}

Malval *_hashmapValues(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'vals' requires exactly one argument");
  }
  Malval *m = MalListNth(args, 1);
  List *values = HashmapValuesList(HashmapOfMalval(m));
  return MalListMk(values);
}

Malval *_isSequential(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'sequential?' requires exactly one argument");
  }
  return MalBoolMk(MalIsListOrVector(MalListNth(args, 1)));
}

Malval *_readLine(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'readline' requires exactly one argument");
  }
  Malval *m = MalListNth(args, 1);
  String *prompt = StringOfMalval(m);
  CHAR *str = StringCString(prompt);
  CHAR *response = GetStr(str, NULL, GSF_SHIFT_ESC_EXIT);
  String *s = StringMk(response);
  Free(str); Free(response);
  return MalStringMk(s);
}

Malval *_meta(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'meta' requires exactly one argument");
  }
  return MalMetadata(MalListNth(args, 1));
}

Malval *_withMeta(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 3) {
    return throws("'with-meta' requires exactly two arguments");
  }
  Malval *f = MalvalCopy(MalListNth(args, 1));
  MalSetMetadata(f, MalListNth(args, 2));
  return f;
}

Malval *_timeMs(Malval *args)
{
  return MalNumberMk(cnts.jiffies);
}

Malval *_conj(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) < 2) {
    return throws("'conj' requires at least one argument");
  }
  Malval *collection = MalListNth(args, 1);
  INT i;
  List *l;
  Malval *v;
  if (MalIsList(collection)) {
    l = MalListOfList(collection);
    l = ListConj(l, ListTail(ListTail(MalListOfList(args))));
    return MalListMk(l);
  }
  else if (MalIsVector(collection)) {
    v = MalvalCopy(collection);
    for (i = 2; i < MalSize(args); ++i) {
      MalVectorPush(v, MalNth(args, i));
    }
    return v;
  }
  else {
    return throws("the first argument to 'conj' must be a list or vector");
  }
}

Malval *_isString(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'string?' requires exactly one argument");
  }
  return MalBoolMk(MalIsString(MalListNth(args, 1)));
}

Malval *_isNumber(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'number?' requires exactly one argument");
  }
  return MalBoolMk(MalIsNumber(MalListNth(args, 1)));
}

Malval *_isFunction(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'fn?' requires exactly one argument");
  }
  return MalBoolMk(MalIsFunction(MalListNth(args, 1)));
}

Malval *_isMacro(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'macro?' requires exactly one argument");
  }
  return MalBoolMk(MalIsMacro(MalListNth(args, 1)));
}

Malval *_seq(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'seq' requires exactly one argument");
  }
  Malval *x = MalListNth(args, 1);
  PArray *pa;
  String *s;
  INT i;
  if (MalIsList(x)) {
    if (MalListSize(x) == 0)
      return MalNilMk;
    else
      return MalvalCopy(x);
  }
  else if (MalIsVector(x)) {
    if (MalVectorSize(x) == 0)
      return MalNilMk;
    else
      return MalListOfVector(x);
  }
  else if (MalIsString(x)) {
    if (StringEqC(StringOfMalval(x), ""))
      return MalNilMk;
    else {
      pa = PArrayEmpty;
      s = StringOfMalval(x);
      for (i = 0; i < StringLen(s); ++i) {
	PArrayPush(pa, MalStringMk(StringSubstr(s, i, 1)));
      }
      return MalListMk(ListFromPArray(pa));
    }
  }
  else if (MalIsNil(x)) {
    return MalNilMk;
  }
  else {
    return throws("the first argument to 'conj' must be a list or vector");
  }
}

#endif
