#############################################################################
##
#W  dual.gd
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

  if HasIsFinite(S) then
    SetIsFinite(dual, IsFinite(S));
  fi;

  
  # this might turn out to be a bad idea
  SetDualSemigroup(dual, S);

  if HasGeneratorsOfSemigroup(S) then
    SetGeneratorsOfSemigroup(dual, List(GeneratorsOfSemigroup(S),
                                        x -> DualSemigroupElement(dual, x)));
  fi;

  if HasGeneratorsOfMonoid(S) then
    SetGeneratorsOfMonoid(dual, List(GeneratorsOfMonoid(S),
                                        x -> DualSemigroupElement(dual, x)));
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
  if not IsAssociativeElement(s) then
    ErrorNoReturn("Semigroups: DualSemigroupElement: \n",
                  "the second argument must be a semigroup element");
  fi;
  if not s in DualSemigroup(S) then
    ErrorNoReturn("Semigroups: DualSemigroupElement: \n",
                  "the second argument must be an element of the dual ",
                  "semigroup of the first argument,");
  fi;
  if not IsDualSemigroupElement(s) then
    return Objectify(TypeDualSemigroupElements(S), [s]);
  fi;
  return s![1];
end);


InstallMethod(MonoidByAdjoiningIdentity, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  local M;
  M := DualSemigroup(MonoidByAdjoiningIdentity(DualSemigroup(S)));
  SetUnderlyingSemigroupOfMonoidByAdjoiningIdentity(M, S);
  return M;
end);

InstallOtherMethod(UnderlyingSemigroupElementOfMonoidByAdjoiningIdentityElt,
"for an element of a dual monoid formed by adjoining an identity",
[IsDualSemigroupElement],
function(s)
  local S;
  S := DualSemigroupOfFamily(FamilyObj(s));
  return DualSemigroupElement(UnderlyingSemigroupOfMonoidByAdjoiningIdentity(S),
          UnderlyingSemigroupElementOfMonoidByAdjoiningIdentityElt(
            DualSemigroupElement(DualSemigroup(S), s)));
end);

InstallMethod(OneMutable, "for a dual semigroup element",
[IsDualSemigroupElement and IsMultiplicativeElementWithOne],
function(s)
  local S;
  S := DualSemigroupOfFamily(FamilyObj(s));
  return DualSemigroupElement(S, 
                              One(DualSemigroupElement(DualSemigroup(S), s)));
end);

InstallMethod(Representative, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  return DualSemigroupElement(S, Representative(DualSemigroup(S)));
end);

InstallMethod(GreensDClasses, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  local classes, D, dualclass, dualclasses, fam;

  dualclasses := [];
  classes := GreensDClasses(DualSemigroup(S));
  fam := FamilyObj(DualSemigroupElement(S, Representative(DualSemigroup(S))));
  
  for D in classes do
    dualclass := Objectify(NewType(CollectionsFamily(fam),
                                    IsDualGreensDClass and
                                    IsGreensDClass and 
                                    IsEquivalenceClass and 
                                    IsEquivalenceClassDefaultRep), 
                           rec());
    SetAssociatedSemigroup(dualclass, S);
    SetUnderlyingDClassOfDualGreensDClass(dualclass, D);
    Add(dualclasses, dualclass);
  od;
  return dualclasses;
end);

InstallMethod(Representative, "for a Greens's D class of a dual semigroup",
[IsDualGreensDClass],
function(D)
  local S;
  S := AssociatedSemigroup(D);
  return DualSemigroupElement(S, Representative(DualSemigroup(S)));
end);

InstallMethod(AsList, "for a Green's D class of a dual semigroup",
[IsDualGreensDClass],
function(D)
  return List(UnderlyingDClassOfDualGreensDClass(D),
              x -> DualSemigroupElement(AssociatedSemigroup(D), x));
end);

InstallMethod(AsSSortedList, "for a Green's D class of a dual semigroup",
[IsDualGreensDClass],
function(D)
  return List(AsSSortedList(UnderlyingDClassOfDualGreensDClass(D)),
              x -> DualSemigroupElement(AssociatedSemigroup(D), x));

end);

InstallMethod(AsList, "for a Green's L class of a dual semigroup",
[IsDualGreensLClass],
function(L)
  return List(UnderlyingRClassOfDualGreensLClass(L),
              x -> DualSemigroupElement(AssociatedSemigroup(L), x));
end);

InstallMethod(AsList, "for a Green's R class of a dual semigroup",
[IsDualGreensRClass],
function(R)
  return List(UnderlyingLClassOfDualGreensRClass(R),
              x -> DualSemigroupElement(AssociatedSemigroup(R), x));
end);

InstallMethod(Size, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  # since the dual of a dual semigroup is the original semigroup
  return Size(DualSemigroup(S));
end);

InstallMethod(AsList, "for a dual semigroup",
[IsDualSemigroup],
function(S)
  return List(DualSemigroup(S), s -> DualSemigroupElement(S, s));
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
  Print("<", ViewString(x![1])," in the dual semigroup>");
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
