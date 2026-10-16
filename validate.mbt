///|
fn validate_type(
  schema : Schema,
  ty : Type,
  depth : Int,
) -> Unit raise XdrError {
  if depth > schema.limits.max_depth {
    raise Invalid(0, "type nesting limit")
  }
  match ty {
    TRef(name) => ignore(schema.lookup(name))
    TString(n) | TOpaque(n, _) =>
      if n < 0 {
        raise Invalid(0, "negative byte bound")
      }
    TArray(inner, n, _) => {
      if n < 0 {
        raise Invalid(0, "negative array bound")
      }
      if schema.resolve(inner) is TVoid {
        raise Invalid(0, "void array element")
      }
      validate_type(schema, inner, depth + 1)
    }
    TOptional(inner) => {
      if schema.resolve(inner) is TVoid {
        raise Invalid(0, "void optional element")
      }
      validate_type(schema, inner, depth + 1)
    }
    TStruct(fields) =>
      for field in fields {
        if schema.resolve(field.ty) is TVoid {
          raise Invalid(0, "void struct member")
        }
        validate_type(schema, field.ty, depth + 1)
      }
    TUnion(tag, arms, fallback) => {
      let resolved = schema.resolve(tag)
      match resolved {
        TInt | TUInt | TBool | TEnum(_) => ()
        _ =>
          raise Invalid(
            0, "union discriminant must be int unsigned int bool or enum",
          )
      }
      for arm in arms {
        for label in arm.labels {
          validate_tag(resolved, label)
        }
        validate_type(schema, arm.ty, depth + 1)
      }
      if fallback is Some(t) {
        validate_type(schema, t, depth + 1)
      }
    }
    _ => ()
  }
}

///|
pub fn validate_tag(tag : Type, value : Int) -> Unit raise XdrError {
  match tag {
    TBool =>
      if value != 0 && value != 1 {
        raise Invalid(0, "invalid boolean discriminant")
      }
    TEnum(values) => {
      for pair in values {
        if pair.1 == value {
          return
        }
      }
      raise Invalid(0, "unknown enum discriminant")
    }
    TInt | TUInt => ()
    _ => raise Invalid(0, "invalid discriminant type")
  }
}

///|
fn can_terminate(
  ty : Type,
  finite : Map[String, Bool],
  work : Budget,
  depth : Int,
) -> Bool raise XdrError {
  work.visit(depth, 0)
  match ty {
    TRef(name) => finite.get(name).unwrap_or(false)
    TOptional(_) | TArray(_, _, true) => true
    TArray(inner, n, false) =>
      n == 0 || can_terminate(inner, finite, work, depth + 1)
    TStruct(fields) => {
      for field in fields {
        if !can_terminate(field.ty, finite, work, depth + 1) {
          return false
        }
      }
      true
    }
    TUnion(_, arms, fallback) => {
      for arm in arms {
        if can_terminate(arm.ty, finite, work, depth + 1) {
          return true
        }
      }
      match fallback {
        Some(t) => can_terminate(t, finite, work, depth + 1)
        None => false
      }
    }
    _ => true
  }
}

///|
/// Fixed-point inhabitation detects mandatory recursive cycles while permitting pointers.
pub fn Schema::validate(self : Schema) -> Unit raise XdrError {
  for _, ty in self.types {
    validate_type(self, ty, 0)
  }
  let finite : Map[String, Bool] = Map([])
  let work = Budget::{
    left: self.limits.max_schema_tokens * 4,
    limits: self.limits,
  }
  for iteration = 0; iteration <= self.types.length(); iteration = iteration + 1 {
    let mut changed = false
    for name, ty in self.types {
      if !finite.contains(name) && can_terminate(ty, finite, work, 0) {
        finite[name] = true
        changed = true
      }
    }
    if !changed {
      break
    }
  }
  for name, _ in self.types {
    if !finite.contains(name) {
      raise Invalid(0, "type has no finite value: " + name)
    }
  }
}

///|
pub fn union_arm(
  arms : Array[Arm],
  fallback : Type?,
  tag : Int,
) -> Type raise XdrError {
  for arm in arms {
    for label in arm.labels {
      if label == tag {
        return arm.ty
      }
    }
  }
  match fallback {
    Some(t) => t
    None => raise Invalid(0, "union has no matching arm")
  }
}
