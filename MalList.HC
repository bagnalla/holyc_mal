// Functions for working with list Malvals

#ifndef MALLIST_HC
#define MALLIST_HC

#include "Util.HC"
#include "PArray.HC"
#include "Types.HC"

BOOL MalIsList(Malval *m)
{
  NullCheck(m, "malval");
  return m->_tag == LIST;
}

// Doesn't make copy of input list
Malval *MalListMk(List *l)
{
  NullCheck(l, "list");
  Malval *m = _MalMk;
  m->_tag = LIST;
  m->_list = l;
  m->_metadata = MalNilMk;
  return m;
}

// Doesn't make copy of input list
Malval *MalListFromPArray(PArray *pa)
{
  NullCheck(pa, "array");
  Malval *m = _MalMk;
  m->_tag = LIST;
  m->_list = ListFromPArray(pa);
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalListNil()
{
  return MalListMk(ListNil);
}

INT MalListSize(Malval *l)
{
  if (MalIsList(l)) {
    return ListSize(l->_list);
  }
  else {
    throws("MalListSize expects list argument");
    return 0;
  }
}

Malval *MalListNth(Malval *l, INT i)
{
  if (MalIsList(l)) {
    return ListNth(l->_list, i);
  }
  else {
    return throws("MalListGet expects list argument");
  }
}

Malval *MalListHead(Malval *l)
{
  if (MalIsList(l)) {
    if (MalListSize(l)) {
      return ListHead(l->_list);
    }
    else return MalNilMk;
  }
  else {
    return throws("MalListHead expects list argument");
  }
}

Malval *MalListTail(Malval *l)
{
  if (MalIsList(l)) {
    if (MalListSize(l)) {
      return MalListMk(ListTail(l->_list));
    }
    else {
      return MalListNil;
    }
  }
  else {
    return throws("MalListTail expects list argument");
  }
}

Malval *MalListCons(Malval *x, Malval *l)
{
  if (MalIsList(l)) {
    return MalListMk(ListCons(x, l->_list));
  }
  else {
    return throws("MalListCons expects second argument to be a list");
  }
}

Malval *MalListPush(Malval *l, Malval *x)
{
  if (MalIsList(l)) {
    return MalListMk(ListAppend(l->_list, x));
  }
  else {
    return throws("MalListCons expects second argument to be a list");
  }
}

Malval *MalListConcat(Malval *l1, Malval *l2)
{
  if (MalIsList(l1) && MalIsList(l2)) {
    return MalListMk(ListConcat(l1->_list, l2->_list));
  }
  else {
    return throws("MalListConcat expects list arguments");
  }
}

extern BOOL MalIsVector(Malval*);
Malval *MalListOfVector(Malval *vec)
{
  NullCheck(vec, "vector");
  if (!MalIsVector(vec)) {
    return throws("MalListOfVector expects vector argument");
  }
  return MalListFromPArray(PArrayCopy(vec->_array));
}

Malval *MalListMap(Malval *l, CHAR* (*f) (CHAR*))
{
  if (MalIsList(l)) {
    return MalListMk(ListMap(l->_list, f));
  }
  else {
    return throws("MalListMap expects first argument to be a list");
  }
}

List *MalListOfList(Malval *v)
{
  NullCheck(v, "malval");
  if (v->_tag != LIST) {
    throws("MalListOfList: expected number");
  }
  return v->_list;
}

#endif
