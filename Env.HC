#ifndef ENV_HC
#define ENV_HC

// A symbol table mapping strings to Malvals

#include "GCCommon.HC"
#include "Hashmap.HC"
#include "String.HC"

extern class Malval;
extern String *PrintMalval(Malval*, BOOL, BOOL);
extern Malval *MalStringMk(String *s);

class Env
{
  BOOL _reachable; // for GC
  CHAR _gc_tag;
  Env *_outer;     // parent environment
  Hashmap *_data;  // symbol table
};

VOID EnvGCMark(Env *e)
{
  if (!e->_reachable) {
    e->_reachable = TRUE;
    if (e->_outer) EnvGCMark(e->_outer);
    HashGCMark(e->_data);
  }
}

Env *EnvEmpty(Env *outer)
{
  Env *m = mal_alloc(sizeof(Env));
  m->_gc_tag = GC_ENV;
  m->_outer = outer;
  m->_data = HashmapEmpty;
  return m;
}

VOID EnvPrint(Env *m)
{
  NullCheck(m, "environment");
  if (m->_outer)
    EnvPrint(m->_outer);
  INT i;
  PArray *keys = HashmapKeys(m->_data);
  Malval *key, *val;
  String *valString;
  CHAR *c;
  for (i = 0; i < PArraySize(keys); ++i) {
    key = PArrayGet(keys, i)(Malval*);
    val = HashmapGet(m->_data, key);
    StringPrint(PrintMalval(key, TRUE, TRUE));
    valString = PrintMalval(val, TRUE, TRUE);
    c = StringCString(valString);
    ":%s\n", c;
    Free(c);
  }
}

VOID EnvDelete(Env *m)
{
  NullCheck(m, "environment");
  HashmapDelete(m->_data);
  Free(m);
}

// doesn't make a copy of key or val
VOID EnvSet(Env *m, String *key, Malval *val)
{
  NullCheck(m, "environment");
  NullCheck(key, "key");
  HashmapSet(m->_data, MalStringMk(key), val);
}

Malval *EnvGet(Env *m, String *key)
{
  NullCheck(m, "environment");
  NullCheck(key, "key");
  Malval *val = HashmapGet(m->_data, MalStringMk(key))(Malval*);
  if (val) return val;
  else if (m->_outer) return EnvGet(m->_outer, key);
  else return NULL;
}

Malval *EnvGetC(Env *m, CHAR *key)
{
  NullCheck(m, "environment");
  NullCheck(key, "key");
  Malval *val = HashmapGet(m->_data, MalStringMk(StringMk(key)))(Malval*);
  if (val) return val;
  else if (m->_outer) return EnvGetC(m->_outer, key);
  else return NULL;
}

Env *EnvCopy(Env *m)
{
  NullCheck(m, "environment");
  Env *e = mal_alloc(sizeof(Env));
  e->_outer = m->_outer;
  e->_data = HashmapCopy(m->_data);
  return e;
}

PArray *EnvKeys(Env *m)
{
  NullCheck(m, "environment");
  PArray *keys = PArrayEmpty;
  PArray *hashmap_keys = HashmapKeys(m->_data);
  PArrayConcat(keys, hashmap_keys);
  return keys;
}

PArray *EnvValues(Env *m)
{
  NullCheck(m, "environment");
  PArray *vals = PArrayEmpty;
  PArray *hashmap_vals = HashmapValues(m->_data);
  PArrayConcat(vals, hashmap_vals);
  return vals;
}

// Returns a PArray containing the key/value pairs as alternating elements.
// ONLY FOR USE BY THE GC
PArray *_EnvEntries_GC(Env *m)
{
  NullCheck(m, "environment");
  PArray *outer_entries;
  PArray *entries = _HashmapKeysValues_GC(m->_data);
  if (m->_outer) {
    outer_entries = _EnvEntries_GC(m->_outer);
    PArrayConcat(entries, outer_entries);
    PArrayDelete(outer_entries);
  }
  return entries;
}

// Merge two environments m1 and m2 with m2 taking priority.
Env *EnvMerge(Env *m1, Env *m2)
{
  NullCheck(m1, "environment 1");
  NullCheck(m2, "environment 2");
  INT i;
  Env *copy = EnvCopy(m1);
  PArray *keys = EnvKeys(m2);
  String *key;
  Malval *val;
  for (i = 0; i < PArraySize(keys); ++i) {
    key = StringOfMalval(PArrayGet(keys, i));
    val = EnvGet(m2, key);
    EnvSet(copy, key, val);
  }
  return copy;
}

Env *EnvRoot(Env *m)
{
  NullCheck(m, "environment");
  if (m->_outer) return EnvRoot(m->_outer);
  else return m;
}

#endif
