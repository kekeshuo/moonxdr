///|
/// RFC 4506 types. Bounds are nonnegative and checked before allocation.
pub(all) enum Type {
  TVoid
  TInt
  TUInt
  THyper
  TUHyper
  TBool
  TFloat
  TDouble
  TQuadruple
  TString(UInt)
  TOpaque(UInt, Bool)
  TArray(Type, UInt, Bool)
  TOptional(Type)
  TRef(String)
  TEnum(Array[(String, Int)])
  TStruct(Array[Field])
  TUnion(Type, Array[Arm], Type?)
}

///|
pub(all) struct Field {
  name : String
  ty : Type
}

///|
pub(all) struct Arm {
  labels : Array[Int64]
  ty : Type
}

///|
pub struct Schema {
  types : Map[String, Type]
  constants : Map[String, @bigint.BigInt]
  constant_defs : Map[String, Bool]
  limits : Limits
}

///|
pub fn Schema::lookup(self : Schema, name : String) -> Type raise XdrError {
  match self.types.get(name) {
    Some(t) => t
    None => raise Invalid(0, "unknown type: " + name)
  }
}

///|
pub fn Schema::constant(self : Schema, name : String) -> @bigint.BigInt? {
  self.constants.get(name)
}

///|
pub fn Schema::type_names(self : Schema) -> Array[String] {
  let names : Array[String] = []
  for name, _ in self.types {
    names.push(name)
  }
  names.sort()
  names
}

///|
pub fn Schema::resolve(self : Schema, ty : Type) -> Type raise XdrError {
  let mut current = ty
  for depth = 0; depth <= self.limits.max_depth; depth = depth + 1 {
    match current {
      TRef(name) => current = self.lookup(name)
      _ => return current
    }
  }
  raise Invalid(0, "cyclic or excessively deep typedef")
}

///|
/// Values preserve signed/unsigned 64-bit and IEEE representations without JSON rounding.
pub(all) enum Value {
  VVoid
  VInt(Int)
  VUInt(UInt)
  VHyper(Int64)
  VUHyper(UInt64)
  VBool(Bool)
  VFloat(Float)
  VDouble(Double)
  VQuadruple(Quadruple)
  VString(String)
  VOpaque(Array[Byte])
  VArray(Array[Value])
  VOptional(Value?)
  VEnum(Int)
  VStruct(Array[(String, Value)])
  VUnion(Int64, Value)
}

///|
pub fn Schema::empty(
  limits? : Limits = Limits::default(),
) -> Schema raise XdrError {
  limits.validate()
  { types: {}, constants: {}, constant_defs: {}, limits, }
}
