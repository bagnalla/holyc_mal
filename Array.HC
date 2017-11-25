#ifndef ARRAY_HC
#define ARRAY_HC

#include "PrimitiveTypes.HC"
#include "Util.HC"

// A generic dynamic array. Don't access the fields directly.
class Array
{
  INT _dsize;   // size of payload type
  INT _size;    // current size of array
  INT _cap;     // capacity
  CHAR *_data;  // pointer to data
};

/*******************************************
  Internal functions -- no bounds checking
********************************************/

CHAR *_array_get(Array *a, INT i)
{
  return a->_data + i * a->_dsize;
}

VOID _array_set(Array *a, INT i, CHAR *buf)
{
  MemCpy(a->_data + i * a->_dsize, buf, a->_dsize);
}

VOID _array_resize(Array *a)
{
  INT new_cap = a->_cap * 2;
  INT new_data_size = a->_dsize * new_cap;
  CHAR *new_data = MAlloc(new_data_size);
  MemCpy(new_data, a->_data, a->_dsize * a->_cap);
  Free(a->_data);
  a->_data = new_data;
  a->_cap = new_cap;
}

VOID _array_shiftRight(Array *a, INT i, INT n)
{
  if (!n) return;
  INT orig_size = a->_size;
  INT j;
  for (j = orig_size-1; j >= i; --j) {
    _array_set(a, j+n, _array_get(a, j));
  }
}

VOID _array_shiftLeft(Array *a, INT i, INT n)
{
  if (!n) return;
  INT j;
  for (j = i; j < a->_size; ++j) {
    _array_set(a, j-n, _array_get(a, j));
  }
}

// Erase a range of elements, reducing the _size of the array.
VOID _array_erase(Array *a, INT i, INT j)
{
  _array_shiftLeft(a, j, j-i);
  a->_size -= j-i;
}

// Initialize an array
VOID _array_init(Array *a, INT dsize, INT cap)
{
  a->_dsize = dsize;
  a->_cap = cap;
  a->_data = MAlloc(dsize * cap);
  a->_size = 0;
}

// Check if two elements are equal
BOOL _array_elemEq(CHAR *x, CHAR *y, INT dsize)
{
  INT i;
  for (i = 0; i < dsize; ++i) {
    if (x[i] != y[i]) return FALSE;
  }
  return TRUE;
}

/*************************
  END internal functions
**************************/

// Allocate and initialize an Array.
Array *ArrayMk(INT dsize, INT cap)
{
  Array *a = MAlloc(sizeof(Array));
  LtCheck(dsize, 1, "dsize");
  cap = NextPowerOf2(cap);
  LtCheck(cap, 1, "cap");
  _array_init(a, dsize, cap);
  return a;
}

Array *ArrayCopy(Array *a)
{
  NullCheck(a, "array");
  Array *_a = ArrayMk(a->_dsize, a->_cap);
  _a->_size = a->_size;
  MemCpy(_a->_data, a->_data, a->_dsize * _a->_cap);
  return _a;
}

// Create and initialize an Array with all elements equal to buf
Array *ArrayFull(INT dsize, INT size, CHAR *buf)
{
  Array *a = ArrayMk(dsize, size);
  a->_size = size;
  INT i;
  for (i = 0; i < size; ++i) {
    _array_set(a, i, buf);
  }
  return a;
}

VOID ArrayDelete(Array *a)
{
  NullCheck(a, "array");
  Free(a->_data);
  Free(a);
}

INT ArrayDSize(Array *a)
{
  NullCheck(a, "array");
  return a->_dsize;
}

INT ArraySize(Array *a)
{
  NullCheck(a, "array");
  return a->_size;
}

// Get (returns pointer to element)
CHAR *ArrayGet(Array *a, INT i)
{
  NullCheck(a, "array");
  if (i < 0 || i >= a->_size) {
    PrintError("index out of range.");
    return NULL;
  }
  return _array_get(a, i);
}

// Set
VOID ArraySet(Array *a, INT i, CHAR *buf)
{
  NullCheck(a, "array");
  NullCheck(buf, "buf");
  if (i < 0 || i > a->_size) {
    PrintError("index out of range.");
    return;
  }
  _array_set(a, i, buf);
}

// Push
VOID ArrayPush(Array *a, CHAR *buf)
{
  NullCheck(a, "array");
  NullCheck(buf, "buf");
  if (a->_size == a->_cap) {
    _array_resize(a);
  }
  _array_set(a, a->_size++, buf);
}

// Front - returns pointer to first element.
// This is kind of pointless since it just returns the _data pointer but
// it checks for erroneous conditions so it's better to use this.
CHAR *ArrayFront(Array *a)
{
  NullCheck(a, "array");
  LtCheck(a->_size, 1, "array size");
  return a->_data;
}

CHAR *ArrayBack(Array *a)
{
  NullCheck(a, "array");
  LtCheck(a->_size, 1, "array size");
  return _array_get(a, a->_size-1);
}

BOOL ArrayIsEmpty(Array *a)
{
  NullCheck(a, "array");
  return a->_size < 1;
}

// Clear contents.
VOID ArrayClear(Array *a)
{
  NullCheck(a, "array");
  a->_size = 0;
}

// Insert an element at a specific index, shifting to the right.
VOID ArrayInsert(Array *a, INT i, CHAR *buf)
{
  NullCheck(a, "array");
  NullCheck(buf, "buf");
  if (a->_size == a->_cap) {
    _array_resize(a);
  }
  _array_shiftRight(a, i, 1);
  _array_set(a, i, buf);
  ++a->_size;
}

// Erase a range of elements, reducing the size of the array.
VOID ArrayErase(Array *a, INT i, INT j)
{
  NullCheck(a, "array");
  if (i < 0 || i >= a->_size) {
    PrintError("index out of range.");
    return;
  }
  if (j == -1) {
    j = i+1;
  }
  LtCheck(j, i, "j");
  _array_erase(a, i, j);
}

// Remove the last element.
VOID ArrayPop(Array *a)
{
  NullCheck(a, "array");
  LtCheck(a->_size, 1, "array size");
  _array_erase(a, a->_size-1, a->_size);
}

// Check if a value exists in the array
BOOL ArrayExists(Array *a, CHAR *buf)
{
  NullCheck(a, "array");
  INT i;
  CHAR *x;
  for (i = 0; i < a->_size; ++i) {
    x = _array_get(a, i);
    if (_array_elemEq(x, buf, a->_dsize)) return TRUE;
  }
  return FALSE;
}

VOID ArrayReserve(Array *a, INT r)
{
  NullCheck(a, "array");
  while (a->_cap < r) {
    _array_resize(a);
  }
}

// Subarray of length l starting at index i
Array *ArraySubarray(Array *a, INT i, INT l)
{
  NullCheck(a, "array");
  BoundsCheck(i, 0, ArraySize(a), "i");
  if (l < 0) l = ArraySize(a) - i;
  GtCheck(l, ArraySize(a) - i, "l");
  Array *sub = ArrayMk(a->_dsize, l);
  MemCpy(sub->_data, a->_data + (i*a->_dsize), l * a->_dsize);
  sub->_size = l;
  return sub;
}

#endif
