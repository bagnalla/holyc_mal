#ifndef CORE_HC
#define CORE_HC

#include "Env.HC"
#include "Intrinsics.HC"

Env *_ns(Env *env)
{
  Env *ns = EnvEmpty(NULL);
  EnvSet(ns, StringMk("+"),           MalFunIntrinsicMk(env, &_plus));
  EnvSet(ns, StringMk("-"),           MalFunIntrinsicMk(env, &_minus));
  EnvSet(ns, StringMk("*"),           MalFunIntrinsicMk(env, &_mult));
  EnvSet(ns, StringMk("/"),           MalFunIntrinsicMk(env, &_div));
  EnvSet(ns, StringMk("pr-str"),      MalFunIntrinsicMk(env, &_prStr));
  EnvSet(ns, StringMk("str"),         MalFunIntrinsicMk(env, &_str));
  EnvSet(ns, StringMk("prn"),         MalFunIntrinsicMk(env, &_prn));
  EnvSet(ns, StringMk("println"),     MalFunIntrinsicMk(env, &_println));
  EnvSet(ns, StringMk("list"),        MalFunIntrinsicMk(env, &_list));
  EnvSet(ns, StringMk("list?"),       MalFunIntrinsicMk(env, &_isList));
  EnvSet(ns, StringMk("empty?"),      MalFunIntrinsicMk(env, &_isEmpty));
  EnvSet(ns, StringMk("count"),       MalFunIntrinsicMk(env, &_count));
  EnvSet(ns, StringMk("="),           MalFunIntrinsicMk(env, &_equal));
  EnvSet(ns, StringMk("<"),           MalFunIntrinsicMk(env, &_lt));
  EnvSet(ns, StringMk("<="),          MalFunIntrinsicMk(env, &_le));
  EnvSet(ns, StringMk(">"),           MalFunIntrinsicMk(env, &_gt));
  EnvSet(ns, StringMk(">="),          MalFunIntrinsicMk(env, &_ge));
  EnvSet(ns, StringMk("read-string"), MalFunIntrinsicMk(env, &_readString));
  EnvSet(ns, StringMk("slurp"),       MalFunIntrinsicMk(env, &_slurp));
  EnvSet(ns, StringMk("atom"),        MalFunIntrinsicMk(env, &_mkRef));
  EnvSet(ns, StringMk("atom?"),       MalFunIntrinsicMk(env, &_isRef));
  EnvSet(ns, StringMk("deref"),       MalFunIntrinsicMk(env, &_deref));
  EnvSet(ns, StringMk("reset!"),      MalFunIntrinsicMk(env, &_reset));
  EnvSet(ns, StringMk("swap!"),       MalFunIntrinsicMk(env, &_swap));
  EnvSet(ns, StringMk("cons"),        MalFunIntrinsicMk(env, &_cons));
  EnvSet(ns, StringMk("concat"),      MalFunIntrinsicMk(env, &_concat));
  EnvSet(ns, StringMk("nth"),         MalFunIntrinsicMk(env, &_nth));
  EnvSet(ns, StringMk("first"),       MalFunIntrinsicMk(env, &_first));
  EnvSet(ns, StringMk("rest"),        MalFunIntrinsicMk(env, &_rest));
  EnvSet(ns, StringMk("throw"),       MalFunIntrinsicMk(env, &_throw));
  EnvSet(ns, StringMk("nil?"),        MalFunIntrinsicMk(env, &_isNil));
  EnvSet(ns, StringMk("true?"),       MalFunIntrinsicMk(env, &_isTrue));
  EnvSet(ns, StringMk("false?"),      MalFunIntrinsicMk(env, &_isFalse));
  EnvSet(ns, StringMk("symbol?"),     MalFunIntrinsicMk(env, &_isSymbol));
  EnvSet(ns, StringMk("apply"),       MalFunIntrinsicMk(env, &_apply));
  EnvSet(ns, StringMk("map"),         MalFunIntrinsicMk(env, &_map));
  EnvSet(ns, StringMk("symbol"),      MalFunIntrinsicMk(env, &_symbol));
  EnvSet(ns, StringMk("keyword"),     MalFunIntrinsicMk(env, &_keyword));
  EnvSet(ns, StringMk("keyword?"),    MalFunIntrinsicMk(env, &_isKeyword));
  EnvSet(ns, StringMk("vector"),      MalFunIntrinsicMk(env, &_vector));
  EnvSet(ns, StringMk("vector?"),     MalFunIntrinsicMk(env, &_isVector));
  EnvSet(ns, StringMk("sequential?"), MalFunIntrinsicMk(env, &_isSequential));
  EnvSet(ns, StringMk("hash-map"),    MalFunIntrinsicMk(env, &_hashmap));
  EnvSet(ns, StringMk("map?"),        MalFunIntrinsicMk(env, &_isHashmap));
  EnvSet(ns, StringMk("assoc"),       MalFunIntrinsicMk(env, &_assoc));
  EnvSet(ns, StringMk("dissoc"),      MalFunIntrinsicMk(env, &_dissoc));
  EnvSet(ns, StringMk("get"),         MalFunIntrinsicMk(env, &_hashmapGet));
  EnvSet(ns, StringMk("contains?"),   MalFunIntrinsicMk(env, &_hashmapContains));
  EnvSet(ns, StringMk("keys"),        MalFunIntrinsicMk(env, &_hashmapKeys));
  EnvSet(ns, StringMk("vals"),        MalFunIntrinsicMk(env, &_hashmapValues));
  EnvSet(ns, StringMk("sequential?"), MalFunIntrinsicMk(env, &_isSequential));
  EnvSet(ns, StringMk("readline"),    MalFunIntrinsicMk(env, &_readLine));
  EnvSet(ns, StringMk("meta"),        MalFunIntrinsicMk(env, &_meta));
  EnvSet(ns, StringMk("with-meta"),   MalFunIntrinsicMk(env, &_withMeta));
  EnvSet(ns, StringMk("time-ms"),     MalFunIntrinsicMk(env, &_timeMs));
  EnvSet(ns, StringMk("conj"),        MalFunIntrinsicMk(env, &_conj));
  EnvSet(ns, StringMk("string?"),     MalFunIntrinsicMk(env, &_isString));
  EnvSet(ns, StringMk("number?"),     MalFunIntrinsicMk(env, &_isNumber));
  EnvSet(ns, StringMk("fn?"),         MalFunIntrinsicMk(env, &_isFunction));
  EnvSet(ns, StringMk("macro?"),      MalFunIntrinsicMk(env, &_isMacro));
  EnvSet(ns, StringMk("seq"),         MalFunIntrinsicMk(env, &_seq));
  EnvSet(ns, StringMk("run-holyc"),   MalFunIntrinsicMk(env, &_runHolyC));
  EnvSet(ns, StringMk("load-extern"), MalFunIntrinsicMk(env, &_loadExtern));
  return ns;
}

#endif
