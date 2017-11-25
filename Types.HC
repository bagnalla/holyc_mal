#ifndef TYPES_HC
#define TYPES_HC

#include "Env.HC"
#include "Exception.HC"
#include "List.HC"
#include "PArray.HC"
#include "String.HC"
#include "Hashmap.HC"
#include "Util.HC"

// Malval tags
#define ATOM 0
#define LIST 1
#define FUN  2
#define VEC  3
#define HASH 4
#define REF  5

// Atom tags
#define ATOM_NIL     0
#define ATOM_FALSE   1
#define ATOM_TRUE    2
#define ATOM_SYMBOL  3
#define ATOM_KEYWORD 4
#define ATOM_NUMBER  5
#define ATOM_STRING  6

// Fun tags
#define FUN_INTRINSIC 0
#define FUN_USER      1

// Forward declare Malval so it can appear in Closure
extern class Malval;

class Atom
{
  CHAR _tag;
  union {
    String *_str; // symbol, keyword, string
    INT _num;     // number
  };
};

class Closure
{
  BOOL _is_macro;
  PArray *_binds;  // symbols bound to arguments of the function
  Malval *_body;   // the function body
};

class Fun
{
  CHAR _tag;
  Env *_env;
  union {
    /* CHAR *_f;       // pointer to built-in function (INTRINSIC) */
    Malval*(*_f)(Malval*);
    Closure *_clos; // pointer to function closure  (USER)
  };
};

class Malval
{
  BOOL _reachable; // for GC
  CHAR  _gc_tag;
  CHAR _tag;
  Malval *_metadata;
  union {
    Atom *_atom;
    PArray *_array; // vec
    List *_list; // list
    Fun *_fun;
    Hashmap *_hash;
    Malval *_ref; // Used for meta as well
  };
};

extern VOID MalvalGCMark(CHAR *malval);

VOID _atomGCMark(Atom *a)
{
  switch (a->_tag) {
  case ATOM_SYMBOL:
  case ATOM_KEYWORD:
  case ATOM_STRING:
    StringGCMark(a->_str);
    break;
  case ATOM_NIL:
  case ATOM_FALSE:
  case ATOM_TRUE:
  case ATOM_NUMBER:
    break;
  default:
    throws("_atomGCMark: unknown atom tag");
  }
}

VOID _funGCMark(Fun *f)
{
  EnvGCMark(f->_env);
  switch (f->_tag) {
  case FUN_USER: {
    Closure *c = f->_clos;
    PArrayGCMark(c->_binds);
    MalvalGCMark(c->_body);
    break;
  }
  case FUN_INTRINSIC:
    break;
  default:
    throws("_funGCMark: unknown function tag");
  }
}

VOID MalvalGCMark(CHAR *malval)
{
  Malval *m = malval(Malval*);
  if (!m->_reachable) {
    m->_reachable = TRUE;
    if (m->_metadata) MalvalGCMark(m->_metadata);
    switch (m->_tag) {
    case ATOM:
      _atomGCMark(m->_atom);
      break;
    case LIST:
      ListGCMark(m->_list(GCCommon*));
      break;
    case VEC:
      PArrayGCMark(m->_array);
      break;
    case FUN:
      _funGCMark(m->_fun);
      break;
    case HASH:
      HashGCMark(m->_hash);
      break;
    case REF:
      MalvalGCMark(m->_ref);
      break;
    default:
      throws("MalvalGCMark: unknown malval tag");
    }
  }
}

// Doesn't make copies
Closure *ClosureMk(PArray *binds, Malval *body)
{
  NullCheck(binds, "binds");
  NullCheck(body, "body");
  Closure *clos = MAlloc(sizeof(Closure));
  clos->_is_macro = FALSE;
  clos->_binds = binds;
  clos->_body = body;
  return clos;
}

VOID ClosureDelete(Closure *c)
{
  NullCheck(c, "closure");
  Free(c);
}

String *AtomTagToString(INT i)
{
  switch (i) {
  case ATOM_NIL:
    return StringMk("nil");
  case ATOM_FALSE:
    return StringMk("false");
  case ATOM_TRUE:
    return StringMk("true");
  case ATOM_SYMBOL:
    return StringMk("symbol");
  case ATOM_KEYWORD:
    return StringMk("keyword");
  case ATOM_NUMBER:
    return StringMk("number");
  case ATOM_STRING:
    return StringMk("string");
  };
  return NULL;
}

Malval *_MalMk()
{
  Malval *m = mal_alloc(sizeof(Malval));
  m->_gc_tag = GC_MALVAL;
  return m;
}

Malval *MalNilMk()
{
  Malval *m = _MalMk;
  m->_tag = ATOM;
  Atom *a = MAlloc(sizeof(Atom));
  a->_tag = ATOM_NIL;
  m->_atom = a;
  m->_metadata = NULL;
  return m;
}

Malval *MalFalseMk()
{
  Malval *m = _MalMk;
  m->_tag = ATOM;
  Atom *a = MAlloc(sizeof(Atom));
  a->_tag = ATOM_FALSE;
  m->_atom = a;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalTrueMk()
{
  Malval *m = _MalMk;
  m->_tag = ATOM;
  Atom *a = MAlloc(sizeof(Atom));
  a->_tag = ATOM_TRUE;
  m->_atom = a;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalBoolMk(BOOL b)
{
  if (b) return MalTrueMk;
  else return MalFalseMk;
}

Malval *MalFunIntrinsicMk(Env *env, CHAR *f)
{
  Malval *m = _MalMk;
  m->_tag = FUN;
  Fun *fun = MAlloc(sizeof(Fun));
  fun->_tag = FUN_INTRINSIC;
  fun->_f = f;
  fun->_env = env;
  m->_fun = fun;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalFunUserMk(Env *env, PArray *binds, Malval *body)
{
  Malval *m = _MalMk;
  m->_tag = FUN;
  Fun *fun = MAlloc(sizeof(Fun));
  fun->_tag = FUN_USER;
  fun->_env = env;
  fun->_clos = ClosureMk(binds, body);
  m->_fun = fun;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalSymbolMk(String *s)
{
  NullCheck(s, "symbol string");
  Malval *m = _MalMk;
  m->_tag = ATOM;
  Atom *a = MAlloc(sizeof(Atom));
  a->_tag = ATOM_SYMBOL;
  a->_str = s;
  m->_atom = a;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalKeywordMk(String *s)
{
  NullCheck(s, "keyword string");
  Malval *m = MalSymbolMk(s);
  m->_atom->_tag = ATOM_KEYWORD;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalStringMk(String *s)
{
  NullCheck(s, "string");
  Malval *m = MalSymbolMk(s);
  m->_atom->_tag = ATOM_STRING;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalRefMk(Malval *v)
{
  Malval *m = _MalMk;
  m->_tag = REF;
  m->_ref = v;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalHashMk(Hashmap *h)
{
  NullCheck(h, "hashmap");
  Malval *m = _MalMk;
  m->_tag = HASH;
  m->_hash = h;
  m->_metadata = MalNilMk;
  return m;
}

String *StringOfMalval(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag != ATOM) {
    "expected string, got tag: %d\n", m->_tag;
    throws("expected string");
  }
  if (!(m->_atom->_tag == ATOM_SYMBOL || m->_atom->_tag == ATOM_KEYWORD ||
	m->_atom->_tag == ATOM_STRING)) {
    "expected symbol, keyword, or string, got atom tag: %d\n", m->_atom->_tag;
    throws("expected symbol, keyword, or string");
  }
  return StringCopy(m->_atom->_str);
}

// doesn't make copy
Hashmap *HashmapOfMalval(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag != HASH) {
    throws("expected hash");
  }
  return m->_hash;
}

Malval *MalDeref(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag != REF) {
    throws("expected ref");
  }
  return m->_ref;
}

Malval *MalvalReset(Malval *ref, Malval *v)
{
  NullCheck(ref, "ref");
  NullCheck(v, "value");
  if (ref->_tag != REF) {
    throws("expected ref");
  }
  ref->_ref = v;
  return v;
}

VOID AtomDelete(Atom *a)
{
  NullCheck(a, "atom");
  Free(a);
}

VOID FunDelete(Fun *f)
{
  switch (f->_tag) {
  case FUN_INTRINSIC:
    break;
  case FUN_USER:
    ClosureDelete(f->_clos);
    break;
  default:
    throws("unknown fun tag");
  };
  Free(f);
}

VOID MalvalDelete(Malval *m)
{
  NullCheck(m, "malval");
  switch (m->_tag) {
  case ATOM:
    AtomDelete(m->_atom);
    break;
  case FUN:
    FunDelete(m->_fun);
    break;
  case HASH:
    HashmapDelete(m->_hash);
    break;
  case LIST:
  case VEC:
  case REF:
    break;
  default:
    PrintError("unknown Malval tag");
  };
  Free(m);
}

Atom *AtomCopy(Atom *a)
{
  NullCheck(a, "atom");
  Atom *_a = MAlloc(sizeof(Atom));
  _a->_tag = a->_tag;
  switch (a->_tag) {
  case ATOM_NIL:
  case ATOM_FALSE:
  case ATOM_TRUE:
    break;
  case ATOM_SYMBOL:
  case ATOM_KEYWORD:
  case ATOM_STRING:
    _a->_str = StringCopy(a->_str);
    break;
  case ATOM_NUMBER:
    _a->_num = a->_num;
    break;
  default:
    PrintError("unknown atom tag");
    return NULL;
  };
  return _a;
}

Closure *ClosureCopy(Closure *c)
{
  NullCheck(c, "closure");
  INT i;
  PArray *binds = PArrayEmpty;
  for (i = 0; i < PArraySize(c->_binds); ++i) {
    PArrayPush(binds, StringCopy(PArrayGet(c->_binds, i)));
  }
  return ClosureMk(binds, MalvalCopy(c->_body));
}

Fun *FunCopy(Fun *f)
{
  Fun *copy = MAlloc(sizeof(Fun));
  copy->_tag = f->_tag;
  copy->_env = f->_env;
  switch (f->_tag) {
  case FUN_INTRINSIC:
    copy->_f = f->_f;
    break;
  case FUN_USER:
    copy->_clos = ClosureCopy(f->_clos);
    break;
  default:
    throws("unknown fun tag");
  }
  return copy;
}

List *_MalvalListCopy(List *l)
{
  switch (l->_tag) {
  case LIST_NIL:
    return ListNil;
  case LIST_CONS:
    return ListCons(MalvalCopy(l->_head), _MalvalListCopy(l->_tail));
  default:
    return throws("_MalvalListCopy: unknown list tag");
  }
}

Malval *MalvalCopy(Malval *m)
{
  NullCheck(m, "malval");
  INT i;
  Malval *copy = _MalMk;
  copy->_tag = m->_tag;
  if (m->_metadata) copy->_metadata = MalvalCopy(m->_metadata);
  else copy ->_metadata = NULL;
  Malval *_m;
  switch (m->_tag) {
  case ATOM:
    copy->_atom = AtomCopy(m->_atom);
    break;
  case LIST:
    copy->_list = _MalvalListCopy(m->_list);
    break;
  case VEC:
    copy->_array = PArrayEmpty;
    for (i = 0; i < PArraySize(m->_array); ++i) {
      _m = MalvalCopy(PArrayGet(m->_array, i));
      PArrayPush(copy->_array, _m);
    }
    break;
  case FUN:
    copy->_fun = FunCopy(m->_fun);
    break;
  case HASH:
    copy->_hash = HashmapCopy(m->_hash);
    break;
  case REF:
    copy->_ref = m->_ref;
    break;
  default:
    PrintError("unknown Malval tag");
  };
  return copy;
}

PArray *RemoveDuplicateMalvals(PArray *pa)
{
  NullCheck(pa, "PArray of malvals");
  PArray *malvals = PArrayEmpty;
  INT  i, j;
  Malval *m1, *m2;
  for (i = PArraySize(pa)-1; i >= 0; --i) {
    m1 = PArrayGet(pa, i);
    for (j = 0; j < PArraySize(malvals); ++j) {
      m2 = PArrayGet(malvals, j);
      if (MalvalEqual(m1, m2)) goto END_OUTER;
    }
    PArrayPush(malvals, m1);
  END_OUTER:;
  }
  return malvals;
}

// Check if a Malval is in a list of Malvals
BOOL MalExists(PArray *pa, Malval *v)
{
  NullCheck(pa, "PArray");
  NullCheck(v, "Malval");
  INT i;
  Malval *x;
  for (i = 0; i < PArraySize(pa); ++i) {
    x = PArrayGet(pa, i)(Malval*);
    if (MalvalEqual(v, x)) return TRUE;
  }
  return FALSE;  
}

// Check if two lists of malvals are permutations of one another.
// Assumes there are no duplicates.
BOOL MalIsPermutation(PArray *pa1, PArray *pa2)
{
    NullCheck(pa1, "PArray of malvals 1");
    NullCheck(pa2, "PArray of malvals 2");
    if (PArraySize(pa1) != PArraySize(pa2)) return FALSE;
    INT i;
    for (i = 0; i < PArraySize(pa1); ++i) {
      if (!MalExists(pa2, PArrayGet(pa1, i)(Malval*))) return FALSE;
    }
    return TRUE;
}

extern BOOL MalvalEqual(Malval*, Malval*);

BOOL AtomEqual(Atom *a1, Atom *a2)
{
  NullCheck(a1, "atom 1");
  NullCheck(a2, "atom 2");
  if (a1->_tag != a2->_tag) return FALSE;
  if (a1->_tag == ATOM_NUMBER)
    return a1->_num == a2->_num;
  else if (a1->_tag == ATOM_SYMBOL || a1->_tag == ATOM_KEYWORD ||
	   a1->_tag == ATOM_STRING)
    return StringEq(a1->_str, a2->_str);
  else
    return TRUE;
}

BOOL _MalListEqual(List *l1, List *l2)
{
  NullCheck(l1, "list 1");
  NullCheck(l2, "list 2");
  switch (ListTag(l1)) {
  case LIST_NIL:
    return ListTag(l2) == LIST_NIL;
  case LIST_CONS: {
    switch (ListTag(l2)) {
    case LIST_NIL:
      return FALSE;
    case LIST_CONS:
      if (MalvalEqual(ListHead(l1), ListHead(l2)))
	return _MalListEqual(ListTail(l1), ListTail(l2));
      else return FALSE;
    default:
      throws("_MalListEqual: unknown list tag");
    }
  }
  default:
    throws("_MalListEqual: unknown list tag");
  }
  return TRUE;
}

BOOL _MalArrayEqual(PArray *l1, PArray *l2)
{
  NullCheck(l1, "array 1");
  NullCheck(l2, "array 2");
  if (PArraySize(l1) != PArraySize(l2)) return FALSE;
  INT i;
  for (i = 0; i < PArraySize(l1); ++i) {
    if (!MalvalEqual(PArrayGet(l1, i)(Malval*), PArrayGet(l2, i)(Malval*)))
      return FALSE;
  }
  return TRUE;
}

BOOL FunEqual(Fun *f1, Fun *f2)
{
  NullCheck(f1, "fun 1");
  NullCheck(f2, "fun 2");
  if (f1->_tag != f2->_tag) return FALSE;
  if (f1->_tag == FUN_INTRINSIC)
    return f1->_f == f2->_f;
  else
    if (_MalArrayEqual(f1->_clos->_binds, f2->_clos->_binds))
      return MalvalEqual(f1->_clos->_body, f2->_clos->_body);
    else return FALSE;
}

BOOL HashEqual(Hashmap *h1, Hashmap *h2)
{ 
  NullCheck(h1, "hashmap 1");
  NullCheck(h2, "hashmap 2");
  PArray *keys1 = RemoveDuplicateMalvals(HashmapKeys(h1));
  PArray *keys2 = RemoveDuplicateMalvals(HashmapKeys(h2));  
  if (!MalIsPermutation(keys1, keys2)) return FALSE;
  INT i;
  Malval *key, *v1, *v2;
  for (i = 0; i < PArraySize(keys1); ++i) {
    key = PArrayGet(keys1, i)(Malval*);
    v1 = HashmapGet(h1, key);
    v2 = HashmapGet(h2, key);
    if (!MalvalEqual(v1, v2)) return FALSE;
  }
  return TRUE;
}

BOOL MalvalEqual(Malval *m1, Malval *m2)
{
  NullCheck(m1, "malval 1");
  NullCheck(m2, "malval 2");
  switch (m1->_tag) {
  case ATOM:
    if (m2->_tag == ATOM) return AtomEqual(m1->_atom, m2->_atom);
    else return FALSE;
  case FUN:
    if (m2->_tag == FUN) return FunEqual(m1->_fun, m2->_fun);
    else return FALSE;
  case LIST:
    if (m2->_tag == LIST)
      return _MalListEqual(m1->_list, m2->_list);
    else if (m2->_tag == VEC)
      return _MalListEqual(m1->_list, ListFromPArray(m2->_array));
    else return FALSE;
  case VEC:
    if (m2->_tag == VEC)
      return _MalArrayEqual(m1->_array, m2->_array);
    else if (m2->_tag == LIST)
      return _MalListEqual(ListFromPArray(m1->_array), m2->_list);
    else return FALSE;
  case HASH:
    if (m2->_tag == HASH) return HashEqual(m1->_hash, m2->_hash);
    else return FALSE;
  case REF:
    if (m2->_tag == REF) return m1->_ref == m2->_ref;
    else return FALSE;
  };
  return FALSE;
}

BOOL MalIsNil(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_NIL;
  else return FALSE;
}

BOOL MalIsTrue(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_TRUE;
  else return FALSE;
}

BOOL MalIsFalse(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_FALSE;
  else return FALSE;
}

BOOL MalIsSymbol(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_SYMBOL;
  else return FALSE;
}

BOOL MalIsKeyword(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_KEYWORD;
  else return FALSE;
}

BOOL MalIsString(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_STRING;
  else return FALSE;
}

BOOL MalIsFunction(Malval *m)
{
  NullCheck(m, "malval");
  return m->_tag == FUN;
}

BOOL MalIsClosure(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == FUN)
    return m->_fun->_tag == FUN_USER;
  else return FALSE;
}

BOOL MalIsIntrinsic(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == FUN)
    return m->_fun->_tag == FUN_INTRINSIC;
  else return FALSE;
}

BOOL MalIsRef(Malval *m)
{
  NullCheck(m, "malval");
  return m->_tag == REF;
}

BOOL MalIsMacro(Malval *m)
{
  if (MalIsClosure(m))
    return m->_fun->_clos->_is_macro;
  else return FALSE;
}

VOID MalSetIsMacro(Malval *m, BOOL is_macro)
{
  if (!MalIsClosure(m)) {
    throws("MalSetIsMacro expects a closure argument");
  }
  else {
    m->_fun->_clos->_is_macro = is_macro;
  }
}

BOOL MalIsHash(Malval *m)
{
  NullCheck(m, "malval");
  return m->_tag == HASH;
}

VOID MalHashSet(Malval *m, Malval *k, Malval *v)
{
  NullCheck(m, "hashmap malval");
  NullCheck(m, "key malval");
  NullCheck(m, "value malval");
  if (!MalIsHash(m)) {
    throws("'MalHashSet' expects first argument to be a hashmap malval");
  }
  HashmapSet(m->_hash, k, v);
}

Env *MalEnvOfFunction(Malval *m)
{
  NullCheck(m, "malval");
  if (!MalIsFunction(m)) {
    return throws("MalEnvOfFunction expects a function argument");
  }
  else {
    return m->_fun->_env;
  }
}

Malval *MalMetadata(Malval *m)
{
  NullCheck(m, "malval");
  return m->_metadata;
}

VOID MalSetMetadata(Malval *m, Malval *v)
{
  NullCheck(m, "malval");
  m->_metadata = v;
}

BOOL MalIsFalsy(Malval *m)
{
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_NIL || m->_atom->_tag == ATOM_FALSE;
  else return FALSE;
}

BOOL MalIsTruthy(Malval *m)
{
  return !MalIsFalsy(m);
}

#endif
