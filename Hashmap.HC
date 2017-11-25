#ifndef HASHMAP_HC
#define HASHMAP_HC

// Just an association list for now. Swap out for a better
// data structure later (with the same interface).

#include "List.HC"
#include "PArray.HC"
#include "String.HC"
#include "Util.HC"

extern class Malval;
extern Malval *MalvalCopy(Malval *m);
extern BOOL MalIsString(Malval *m);
extern BOOL MalIsKeyword(Malval *m);
extern String *StringOfMalval(Malval *m);
extern BOOL MalvalEqual(Malval *m1, Malval *m2);

class Hashmap
{
  PArray *_arr; // array of pointers to symtab entries
};

VOID HashGCMark(Hashmap *h)
{
  PArrayGCMark(h->_arr);
}

Hashmap *HashmapEmpty()
{
  Hashmap *m = MAlloc(sizeof(Hashmap));
  m->_arr = PArrayEmpty;
  return m;
}

// Delete entries and the Hashmap itself
VOID HashmapDelete(Hashmap *m)
{
  NullCheck(m, "hashmap");
  Free(m);
}

VOID HashmapSet(Hashmap *m, Malval *key, Malval *val)
{
  NullCheck(m, "hashmap");
  NullCheck(key, "key");

  // If the key exists, replace its value
  INT i;
  Malval *k;
  for (i = 0; i < PArraySize(m->_arr); i += 2) {
    k = PArrayGet(m->_arr, i);
    if (MalvalEqual(key, k)) {
      PArraySet(m->_arr, i+1, val);
      return;
    }
  }
  PArrayPush(m->_arr, key);
  PArrayPush(m->_arr, val);
}

// Search in reverse order from the end so that newly added
// entries shadow older ones. Returns NULL if the key isn't found.
CHAR *HashmapGet(Hashmap *m, Malval *key)
{
  NullCheck(m, "hashmap");
  NullCheck(key, "key");
  INT i;
  Malval *k;
  for (i = PArraySize(m->_arr) - 2; i >= 0; i -= 2) {
    k = PArrayGet(m->_arr, i);
    if (MalvalEqual(k, key))
      return PArrayGet(m->_arr, i+1);
  }
  return NULL;
}

// Remove all entries for a given key from the hashmap.
VOID HashmapRemove(Hashmap *m, Malval *key)
{
  NullCheck(m, "hashmap");
  NullCheck(key, "key");
  INT i;
  Malval *k;
  for (i = 0; i < PArraySize(m->_arr); ) {
    k = PArrayGet(m->_arr, i);
    if (MalvalEqual(k, key)) {
      PArrayErase(m->_arr, i, i+1);
      PArrayErase(m->_arr, i, i+1);
    }
    else i += 2;
  }
}

// May contain duplicate keys. Returns copies
PArray *HashmapKeys(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  PArray *keys = PArrayEmpty;
  Malval *k;
  for (i = 0; i < PArraySize(m->_arr); i += 2) {
    k = PArrayGet(m->_arr, i);
    PArrayPush(keys, MalvalCopy(k));
  }
  return keys;
}

// May contain duplicate keys. Returns copies
List *HashmapKeysList(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  List *keys = ListNil;
  Malval *k;
  for (i = PArraySize(m->_arr)-2; i >= 0; i -= 2) {
    k = PArrayGet(m->_arr, i);
    keys = ListCons(k, keys);
  }
  return keys;
}

// May contain multiple values corresponding to the same key
// Doesn't make copies.
PArray *HashmapValues(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  PArray *vals = PArrayEmpty;
  Malval *v;
  for (i = 1; i < PArraySize(m->_arr); i += 2) {
    v = PArrayGet(m->_arr, i);
    PArrayPush(vals, v);
  }
  return vals;
}

List *HashmapValuesList(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  List *vals = ListNil;
  Malval *v;
  for (i = PArraySize(m->_arr)-1; i >= 1; i -= 2) {
    v = PArrayGet(m->_arr, i);
    vals = ListCons(v, vals);
  }
  return vals;
}

Hashmap *HashmapCopy(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  Hashmap *copy = HashmapEmpty;
  for (i = 0; i < PArraySize(m->_arr); ++i) {
    copy->_arr = PArrayCopy(m->_arr);
  }
  return copy;
}

Hashmap *HashmapFromSequence(PArray *seq)
{
  if (PArraySize(seq) % 2) {
    return throws("HashmapFromSequence requires an even number of elements");
  }
  INT i;
  Hashmap *s = HashmapEmpty;
  Malval *k, *v;
  for (i = 0; i < PArraySize(seq); i += 2) {
    k = PArrayGet(seq, i);
    v = PArrayGet(seq, i+1);
    HashmapSet(s, k, v);
  }
  return s;
}

// Check if the given key is bound in a hashmap
BOOL HashmapExists(Hashmap *m, Malval *key)
{
  NullCheck(m, "hashmap");
  NullCheck(key, "key");
  INT i;
  Malval *k;
  for (i = 0; i < PArraySize(m->_arr); i += 2) {
    k = PArrayGet(m->_arr, i);
    if (MalvalEqual(key, k)) {
      return TRUE;
    }
  }
  return FALSE;
}

// Returns a PArray containing the key/value pairs as alternating elements.
PArray *HashmapKeysValues(Hashmap *m)
{
  return PArrayCopy(m->_arr);
}

// Returns a PArray containing the key/value pairs as alternating elements.
// ONLY FOR USE BY THE GC
PArray *_HashmapKeysValues_GC(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  PArray *pa = _PArrayEmpty_GC;
  Malval *k, *v;
  for (i = 0; i < PArraySize(m->_arr); i += 2) {
    k = PArrayGet(m->_arr, i);
    v = PArrayGet(m->_arr, i+1);
    PArrayPush(pa, k);
    PArrayPush(pa, v);
  }
  return pa;
}

VOID HashmapPrint(Hashmap *m)
{
  NullCheck(m, "hashmap");
  INT i;
  PArray *keys = HashmapKeys(m);
  Malval *key, *val;
  String *valString;
  CHAR *c;
  for (i = 0; i < PArraySize(keys); ++i) {
    key = PArrayGet(keys, i)(Malval*);
    val = HashmapGet(m, key);
    StringPrintLn(PrintMalval(key, TRUE, TRUE));
    valString = PrintMalval(val, TRUE, TRUE);
    c = StringCString(valString);
    ":%s, ", c;
    Free(c);
  }
}

// remove the given bindings from the hashmap. Mutates the hashmap in place.
VOID HashmapDissoc(Hashmap *m, List *l)
{
  switch (ListTag(l)) {
  case LIST_NIL:
    return;
  case LIST_CONS:
    HashmapRemove(m, ListHead(l));
    HashmapDissoc(m, ListTail(l));
    break;
  default:
    throws("HashmapDissoc: unknown list tag");
  }
}

#endif
