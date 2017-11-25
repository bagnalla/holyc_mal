#ifndef LIST_HC
#define LIST_HC

#include "GCCommon.HC"
#include "PArray.HC"
#include "Util.HC"

extern CHAR *mal_alloc(INT size);

#define LIST_NIL 0
#define LIST_CONS 1

// A cons/nil style list data structure.
// Elements should be only pointers to garbage-collected objects.
class List
{
  BOOL _reachable; // for GC
  CHAR _gc_tag;
  CHAR _tag;
  CHAR *_head;
  List *_tail;
};

List *ListNil()
{
  List *l = mal_alloc(sizeof(List));
  l->_gc_tag = GC_LIST;
  l->_tag = LIST_NIL;
  l->_head = NULL;
  l->_tail = NULL;
  return l;
}

List *ListCons(CHAR *head, List *tail)
{
  List *l = mal_alloc(sizeof(List));
  l->_gc_tag = GC_LIST;
  l->_tag = LIST_CONS;
  l->_head = head;
  l->_tail = tail;
  return l;
}

// Just delete the list node, not its contents.
VOID ListDelete(List *l)
{
  NullCheck(l, "list");
  Free(l);
}

// Not really a deep copy since only the pointers are copied.
List *ListCopy(List *l)
{
  NullCheck(l, "list");
  switch (l->_tag) {
  case LIST_NIL:
    return ListNil;
  case LIST_CONS:
    return ListCons(l->_head, l->_tail);
  default:
    return throws("ListCopy: unknown list tag");
  }
}

extern VOID GC_mark_object(GCCommon *o);
VOID ListGCMark(GCCommon *list)
{
  List *l = list(List*);
  if (!l->_reachable) {
    l->_reachable = TRUE;
    switch (l->_tag) {
    case LIST_NIL:
      break;
    case LIST_CONS:
      GC_mark_object(l->_head);
      ListGCMark(l->_tail(GCCommon*));
      break;
    default:
      throws("ListGCMark: unknown list tag");
    }
  }
}

List *_listFromPArray_aux(PArray *pa, INT i)
{
  if (i >= PArraySize(pa))
    return ListNil;
  else
    return ListCons(PArrayGet(pa, i), _listFromPArray_aux(pa, i+1));
}

List *ListFromPArray(PArray *pa)
{
  return _listFromPArray_aux(pa, 0);
}

VOID _parrayFromList_aux(PArray *pa, List *l)
{
  switch (l->_tag) {
  case LIST_NIL:
    break;
  case LIST_CONS:
    PArrayPush(pa, l->_head);
    _parrayFromList_aux(pa, l->_tail);
    break;
  default:
    throws("_parrayFromList_aux: unknown list tag");
  }
}
PArray *PArrayFromList(List *l)
{
  PArray *pa = PArrayEmpty;
  _parrayFromList_aux(pa, l);
  return pa;
}

INT ListSize(List *l)
{
  switch (l->_tag) {
  case LIST_NIL:
    return 0;
  case LIST_CONS:
    return 1 + ListSize(l->_tail);
  default:
    throws("ListSize: unknown list tag");
    return 0; // make compiler stfu
  }
}

CHAR *ListNth(List *l, INT n)
{
  switch (l->_tag) {
  case LIST_NIL:
    return throws("ListNth: index out of bounds");
  case LIST_CONS:
    if (n == 0)
      return l->_head;
    else
      return ListNth(l->_tail, n-1);
  default:
    return throws("ListNth: unknown list tag");
  }
}

CHAR ListTag(List *l)
{
  return l->_tag;
}

CHAR *ListHead(List *l)
{
  switch (l->_tag) {
  case LIST_NIL:
    return throws("ListHead: empty list");
  case LIST_CONS:
    return l->_head;
  default:
    return throws("ListHead: unknown list tag");
  }
}

List *ListTail(List *l)
{
  switch (l->_tag) {
  case LIST_NIL:
    return throws("ListTail: empty list");
  case LIST_CONS:
    return l->_tail;
  default:
    return throws("ListTail: unknown list tag");
  }
}

BOOL ListIsNil(List *l)
{
  return l->_tag == LIST_NIL;
}

// Non-recursive
List *ListRev(List *l)
{
  List *cur = l;
  List *copy = ListNil;
  while (!ListIsNil(cur)) {
    switch (cur->_tag) {
    case LIST_CONS: {
      copy = ListCons(ListHead(cur), copy);
      cur = ListTail(cur);
      break;
    }
    case LIST_NIL:
      return throws("ListRev: shouldn't be nil");
    default:
      return throws("ListRev: unknown list tag");
    }
  }
  return copy;
}

// NOTE: The following functions are not tail-call optimized. They perform
// a number of recursive calls equal to the length of the list.

// This hasn't been tested
List *ListAppend(List *l, CHAR *x)
{
  switch (l->_tag) {
  case LIST_NIL:
    return ListCons(x, ListNil);
  case LIST_CONS:
    return ListCons(l->_head, ListAppend(l->_tail, x));
  default:
    return throws("ListAppend: unknown list tag");
  }
}

List *ListConcat(List *l1, List *l2)
{
  switch (l1->_tag) {
  case LIST_NIL:
    return l2;
  case LIST_CONS: {
    switch (l2->_tag) {
    case LIST_NIL:
      return l1;
    case LIST_CONS:
      return ListCons(l1->_head, ListConcat(l1->_tail, l2));
    default:
      throws("ListConcat: unknown list tag");
    }
  }
  default:
    return throws("ListConcat: unknown list tag");
  }
}

List *ListMap(List *l, CHAR* (*f) (CHAR*))
{
  switch (l->_tag) {
  case LIST_NIL:
    return ListNil;
  case LIST_CONS:
    return ListCons(f(l->_head), ListMap(l->_tail, f));
  default:
    return throws("ListMap: unknown list tag");
  }
}

CHAR *ListFoldr(List *l, CHAR* (*f) (CHAR*, CHAR*), CHAR *acc)
{
  switch (l->_tag) {
  case LIST_NIL:
    return acc;
  case LIST_CONS: {
    CHAR *new_acc = ListFoldr(l->_tail, f, acc);
    return f(l->_head, new_acc);
  }
  default:
    return throws("ListMap: unknown list tag");
  }
}

CHAR *ListFoldl(List *l, CHAR* (*f) (CHAR*, CHAR*), CHAR *acc)
{
  switch (l->_tag) {
  case LIST_NIL:
    return acc;
  case LIST_CONS: {
    CHAR *new_acc = f(acc, l->_head);
    return ListFoldl(l->_tail, f, new_acc);
  }
  default:
    return throws("ListMap: unknown list tag");
  }
}

// Prepend l2 in reverse order to the front of l1
List *ListConj(List *l1, List *l2)
{
  switch (l2->_tag) {
  case LIST_NIL:
    return l1;
  case LIST_CONS:
    return ListConj(ListCons(l2->_head, l1), l2->_tail);
  default:
    return throws("ListConj: unknown list tag");
  }
}

#endif
