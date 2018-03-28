#############################################################################
##
#W  dual.gi
#Y  Copyright (C) 2017                                      James D. Mitchell
##                                                          Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

InstallMethod(DualSemigroup, "for a semigroup",
[IsSemigroup],
function(S)
  local dual, fam, filts, type;

  fam := NewFamily("DualSemigroupElementsFamily", IsDualSemigroupElement);
  dual := Objectify(NewType(CollectionsFamily(fam),
                            IsWholeFamily and
                            IsDualSemigroup and
                            IsEnumerableSemigroupRep and
                            IsAttributeStoringRep),
                    rec());

  filts := IsDualSemigroupElement;

  if IsMultiplicativeElementWithOne(Representative(S)) then
    filts := filts and IsMultiplicativeElementWithOne;
  fi;

  type := NewType(fam, filts);
  fam!.type := type;

  SetTypeDualSemigroupElements(dual, type);
  SetDualSemigroupOfFamily(fam, dual);

  SetDualSemigroup(dual, S);

  if HasIsFinite(S) then
    SetIsFinite(dual, IsFinite(S));
  fi;

  if IsTransformationSemigroup(S) then
    SetAntiIsomorphismTransformationSemigroup(dual,
      AntiIsomorphismDualSemigroup(dual));
  fi;

  if HasGeneratorsOfSemigroup(S) then
    SetGeneratorsOfSemigroup(dual, List(GeneratorsOfSemigroup(S),
                                        x -> DualSemigroupElementNC(dual, x)));
  fi;

  if HasGeneratorsOfMonoid(S) then
    SetGeneratorsOfMonoid(dual, List(GeneratorsOfMonoid(S),
                                        x -> DualSemigroupElementNC(dual, x)));
  fi;

  return dual;
end);

# FS: the first argument is the dual of the semigroup the second belongs to.
# FS: We must provide either the semigroup or its dual so that we can
# FS: create the dual semigroup element object, and it seems more intuitive
# FS: to provide the dual.
InstallGlobalFunction(DualSemigroupElement,
function(S, s)
  if not IsSemigroup(S) then
    ErrorNoReturn("Semigroups: DualSemigroupElement: \n",
                  "the first argument must be a semigroup,");
  fi;
  if not s in DualSemigroup(S) then
    ErrorNoReturn("Semigroups: DualSemigroupElement: \n",
                  "the second argument must be an element of the dual ",
                  "semigroup of the first argument,");
  fi;
  return DualSemigroupElementNC(S, s);
end);

InstallGlobalFunction(DualSemigroupElementNC,
function(S, s)
  if not IsDualSemigroupElement(s) then
    return Objectify(TypeDualSemigroupElements(S), [s]);
  fi;
  return s![1];
end);

InstallMethod(AntiIsomorphismDualSemigroup, "for a semigroup",
[IsSemigroup],
function(S)
  local dual, inv, iso;

  dual := DualSemigroup(S);
  iso := function(x)
    return DualSemigroupElement(dual, x);
  end;

  inv := function(x)
    return DualSemigroupElement(S, x);
  end;

  return MappingByFunction(S, dual, iso, inv);
end);

################################################################################
## Technical methods
################################################################################

InstallMethod(OneMutable, "for a dual semigroup element",
[IsDualSemigroupElement and IsMultiplicativeElementWithOne],
function(s)
  local S;
  S := DualSemigroupOfFamily(FamilyObj(s));
  return DualSemigroupElementNC(S,
                                OneMutable(DualSemigroupElement(
                                            DualSemigroup(S), s)));
end);

InstallMethod(MultiplicativeNeutralElement, "for a dual semigroup",
[IsDualSemigroup],
10, # add rank to beat enumeration methods
function(S)
  local m;
  m := MultiplicativeNeutralElement(DualSemigroup(S));
  if m <> fail then
    return DualSemigroupElementNC(S, m);
  fi;
  return fail;
end);

InstallMethod(Representative, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  return DualSemigroupElementNC(S, Representative(DualSemigroup(S)));
end);

InstallMethod(Size, "for a dual semigroup",
[IsDualSemigroup],
10, # add rank to beat enumeration methods
function(S)
  return Size(DualSemigroup(S));
end);

InstallMethod(AsList, "for a dual semigroup",
[IsDualSemigroup],
10, # add rank to beat enumeration methods
function(S)
  return List(DualSemigroup(S), s -> DualSemigroupElementNC(S, s));
end);

InstallMethod(\*, "for dual semigroup elements",
IsIdenticalObj,
[IsDualSemigroupElement, IsDualSemigroupElement],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [y![1] * x![1]]);
end);

InstallMethod(\=, "for dual semigroup elements",
IsIdenticalObj,
[IsDualSemigroupElement, IsDualSemigroupElement],
function(x, y)
  return x![1] = y![1];
end);

InstallMethod(\<, "for dual semigroup elements",
IsIdenticalObj,
[IsDualSemigroupElement, IsDualSemigroupElement],
function(x, y)
  return x![1] < y![1];
end);

InstallMethod(ViewObj, "for dual semigroup elements",
[IsDualSemigroupElement], PrintObj);

InstallMethod(PrintObj, "for dual semigroup elements",
[IsDualSemigroupElement],
function(x)
  Print("<", ViewString(x![1]), " in the dual semigroup>");
end);

InstallMethod(ViewObj, "for a dual semigroup",
[IsDualSemigroup], PrintObj);

InstallMethod(PrintObj, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  Print("<dual semigroup of ",
        ViewString(DualSemigroup(S)),
        ">");
end);

InstallMethod(ChooseHashFunction, "for a dual semigroup element and int",
[IsDualSemigroupElement, IsInt],
function(x, data)
  local H, hashfunc;
  H := ChooseHashFunction(x![1], data);
  hashfunc := function(a, b)
    return H.func(a![1], b);
  end;
  return rec(func := hashfunc, data := H.data);
end);
