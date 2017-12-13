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
  local dual, fam, type;

  fam := NewFamily("DualSemigroupElementsFamily", IsDualSemigroupElement);
  dual := Objectify(NewType(CollectionsFamily(fam),
                            IsWholeFamily and 
                            IsDualSemigroup and
                            IsAttributeStoringRep),
                    rec());
  type := NewType(fam, IsDualSemigroupElement);
  fam!.type := type;

  SetTypeDualSemigroupElements(dual, type);
  
  if HasIsFinite(S) then
    SetIsFinite(dual, IsFinite(S));
  fi;
  
  # this might turn out to be a bad idea
  SetDualSemigroup(dual, S);

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
                  "the second argument must be an element of the dual",
                  "semigroup of the first argument,");
  fi;
  if not IsDualSemigroupElement(s) then
    return Objectify(TypeDualSemigroupElements(S), [s]);
  fi;
  return s![1];
end);


#InstallMethod(GreensDClasses, "for a dual semigroup",
#[IsDualSemigroup],
#function(S)
# local classes, dualclass;
#
# 
#
# classes := GreensDClasses(DualSemigroup(S));
# return List(classes, D -> Objectify(NewType(IsGreensDClass
#
#end);
#

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
