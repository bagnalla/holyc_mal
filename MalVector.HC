// Functions for working with vector Malvals

#ifndef MALVECTOR_HC
#define MALVECTOR_HC

#include "MalList.HC"
#include "PArray.HC"
#include "Types.HC"
#include "Util.HC"

BOOL MalIsVector(Malval *m)
{
  NullCheck(m, "malval");
  return m->_tag == VEC;
}

Malval *MalVectorMk(PArray *pa)
{
  NullCheck(pa, "list array");
  Malval *m = _MalMk;
  m->_tag = VEC;
  m->_array = pa;
  m->_metadata = MalNilMk;
  return m;
}

Malval *MalVectorEmpty()
{
  return MalVectorMk(PArrayEmpty);
}

Malval *MalVectorCopy(Malval *l)
{
  if (MalIsVector(l)) {
    return MalVectorMk(PArrayCopy(l->_array));
  }
  else {
    return throws("MalVectorCopy expects vector argument");
  }
}

INT MalVectorSize(Malval *l)
{
  if (MalIsVector(l)) {
    return PArraySize(l->_array);
  }
  else {
    throws("MalVectorSize expects vector argument");
    return 0; // make compiler stfu
  }
}

Malval *MalVectorNth(Malval *l, INT i)
{
  if (MalIsVector(l)) {
    return PArrayGet(l->_array, i);
  }
  else {
    return throws("MalVectorGet expects vector argument");
  }
}

Malval *MalVectorHead(Malval *l)
{
  if (MalIsVector(l)) {
    if (MalVectorSize(l)) {
      return PArrayFront(l->_array);
    }
    else {
      return MalNilMk;
    }
  }
  else {
    return throws("MalVectorHead expects vector argument");
  }
}

Malval *MalVectorTail(Malval *l)
{
  if (MalIsVector(l)) {
    if (MalVectorSize(l)) {
      return MalVectorMk(PArrayTail(l->_array));
    }
    else {
      return MalVectorEmpty;
    }
  }
  else {
    return throws("MalVectorTail expects vector argument");
  }
}

Malval *MalVectorPush(Malval *l, Malval *x)
{
  Malval *v;
  if (MalIsVector(l)) {
    v = MalVectorMk(l->_array);
    PArrayPush(v->_array, x);
    return v;
  }
  else {
    return throws("MalVectorPush expects vector argument");
  }
}

Malval *MalVectorConcat(Malval *l1, Malval *l2)
{
  PArray *pa;
  if (MalIsVector(l1) && MalIsVector(l2)) {
    pa = PArrayEmpty;
    PArrayConcat(pa, l1->_array);
    PArrayConcat(pa, l2->_array);
    return MalVectorMk(pa);
  }
  else {
    return throws("MalVectorConcat expects vector arguments");
  }
}


#endif
