InstallGlobalFunction(SemigroupCongruence,
function(arg)
  local s, pairs;
  if not Length(arg) >= 2 then
    Error("Semigroups: SemigroupCongruence: usage,\n",
          "at least 2 arguments are required,");
    return;
  fi;
  if not IsSemigroup(arg[1]) then
    Error("Semigroups: SemigroupCongruence: usage,\n",
          "1st argument <s> must be a semigroup,");
    return;
  fi;
  s := arg[1];
  
  if IsHomogeneousList(arg[2]) then
    # We should have a list of generating pairs
    if Length(arg) = 2 then
      pairs := arg[2];
      if not IsList(pairs[1]) then
        pairs := [pairs];
      fi;
    elif Length(arg) > 2 then
      pairs := arg{[2..Length(arg)]};
    fi;
    if not ForAll(pairs, p-> Size(p) = 2) then
      Error("Semigroups: SemigroupCongruence: usage,\n",
            "<pairs> should be a list of lists of size 2,");
      return;
    fi;
    if not ForAll(pairs, p-> p[1] in s and p[2] in s) then
      Error("Semigroups: SemigroupCongruence: usage,\n",
            "each pair should contain elements from the semigroup <s>,");
      return;
    fi;
    if IsSimpleSemigroup(s) or IsZeroSimpleSemigroup(s) then
      return SIMPLECONG_FROM_PAIRS(s, pairs);
    else
      return SemigroupCongruenceByGeneratingPairs(s, pairs);
    fi;
  elif (IsRMSCongruenceByLinkedTriple(arg[2]) and IsSimpleSemigroup(s)) or
    (IsRZMSCongruenceByLinkedTriple(arg[2]) and IsZeroSimpleSemigroup(s)) then
    if Range(IsomorphismReesMatrixSemigroup(s)) = Range(arg[2]) then
      return SIMPLECONG_FROM_RMSCONG(s, arg[2]);
    else
      Error("Semigroups: SemigroupCongruence: usage,\n<cong> should be ",
            "over a Rees (0-)matrix semigroup isomorphic to <s>");
      return;
    fi;
  else
    TryNextMethod();
  fi;
end);

#

InstallGlobalFunction(SIMPLECONG_FROM_PAIRS,
function(s, pairs)
  local iso, r, rmspairs, pcong, rmscong, cong;
  iso := IsomorphismReesMatrixSemigroup(s);
  r := Range(iso);
  rmspairs := List(pairs, p-> [p[1]^iso, p[2]^iso]);
  pcong := SemigroupCongruenceByGeneratingPairs(r, rmspairs);
  if IsReesMatrixSemigroup(r) then
    rmscong := AsRMSCongruenceByLinkedTriple(pcong);
  else #elif IsReesZeroMatrixSemigroup(r) then
    rmscong := AsRZMSCongruenceByLinkedTriple(pcong);
  fi;
  cong := SIMPLECONG_FROM_RMSCONG(s, rmscong);
  SetGeneratingPairsOfMagmaCongruence(cong, pairs);
  return cong;
end);

#

InstallGlobalFunction(SIMPLECONG_FROM_RMSCONG,
function(s, rmscong)
  local iso, r, fam, cong;
  # Find the isomorphism from s to r
  iso := IsomorphismReesMatrixSemigroup(s);
  r := Range(rmscong);

  # Construct the object
  fam := GeneralMappingsFamily(
                 ElementsFamily(FamilyObj(s)),
                 ElementsFamily(FamilyObj(s)) );
  cong := Objectify( NewType(fam, SEMICONG_SIMPLE),
                     rec(rmscong := rmscong, iso := iso) );
  SetSource(cong, s);
  SetRange(cong, s);
  return cong;
end);

#

InstallGlobalFunction(SIMPLECLASS_FROM_RMSCLASS,
function(cong, rmsclass)
  local iso, fam, class;
  iso := IsomorphismReesMatrixSemigroup(Range(cong));
  fam := FamilyObj(Range(cong));
  class := Objectify( NewType(fam, SEMICONG_SIMPLE_CLASS),
                      rec(rmsclass := rmsclass, iso := iso) );
  SetParentAttr(class, cong);
  SetRepresentative(class, Representative(rmsclass)^InverseGeneralMapping(iso));
  SetEquivalenceClassRelation(class, cong);
  return class;
end);

#

InstallMethod(ViewObj,
"for a simple or 0-simple semigroup congruence",
[SEMICONG_SIMPLE],
function(cong)
  Print("<semigroup congruence over ");
  ViewObj(Range(cong));
  Print(" with linked triple (",
        StructureDescription(cong!.rmscong!.n:short), ",",
        Size(cong!.rmscong!.colBlocks), ",",
        Size(cong!.rmscong!.rowBlocks),")>");
end);

#

InstallMethod(CongruencesOfSemigroup,
"for a simple or 0-simple semigroup",
[IsSemigroup],
function(s)
  local congs, i;
  if not (IsFinite(s) and (IsSimpleSemigroup(s) or IsZeroSimpleSemigroup(s))) then
    TryNextMethod();
  fi;
  congs := ShallowCopy(CongruencesOfSemigroup(Range(IsomorphismReesMatrixSemigroup(s))));
  for i in [1..Length(congs)] do
    if IsUniversalSemigroupCongruence(congs[i]) then
      congs[i] := UniversalSemigroupCongruence(s);
    else
      congs[i] := SIMPLECONG_FROM_RMSCONG(s, congs[i]);
    fi;
  od;
  return congs;
end);

#

InstallMethod(\=,
"for two (0-)simple semigroup congruences",
[SEMICONG_SIMPLE, SEMICONG_SIMPLE],
function(cong1, cong2)
  return (Range(cong1) = Range(cong2) and cong1!.rmscong = cong2!.rmscong);
end);

#

InstallMethod(\in,
"for an associative element collection and a (0-)simple semigroup congruence",
[IsAssociativeElementCollection, SEMICONG_SIMPLE],
function(pair, cong)
  local s;
  # Check for validity
  if Size(pair) <> 2 then
    Error("usage: 1st argument <pair> must be a list of length 2,");
    return;
  fi;
  s := Range(cong);
  if not ForAll(pair, x-> x in s) then
    Error("usage: the elements of the 1st argument <pair> ",
          "must be in the range of the 2nd argument <cong>,");
    return;
  fi;
  return [pair[1]^cong!.iso, pair[2]^cong!.iso] in cong!.rmscong;
end);

#

InstallMethod(ImagesElm,
"for a simple semigroup congruence and an associative element",
[SEMICONG_SIMPLE, IsAssociativeElement],
function(cong, elm)
  return List( ImagesElm(cong!.rmscong, elm^cong!.iso),
               x-> x^InverseGeneralMapping(cong!.iso) );
end);

#

InstallMethod(EquivalenceClasses,
"for a (0-)simple semigroup congruence",
[SEMICONG_SIMPLE],
function(cong)
  return List( EquivalenceClasses(cong!.rmscong),
               c-> SIMPLECLASS_FROM_RMSCLASS(cong, c) );
end);

#

InstallMethod(EquivalenceClassOfElementNC,
"for a (0-)simple semigroup congruence",
[SEMICONG_SIMPLE, IsAssociativeElement],
function(cong, elm)
  return SIMPLECLASS_FROM_RMSCLASS(cong,
                 EquivalenceClassOfElementNC(cong!.rmscong, elm^cong!.iso) );
end);

#

InstallMethod(\in,
"for an associative element and a (0-)simple semigroup congruence class",
[IsAssociativeElement, SEMICONG_SIMPLE_CLASS],
function(elm, class)
  return (elm^EquivalenceClassRelation(class)!.iso in class!.rmsclass);
end);

#

InstallMethod(\*,
"for two (0-)simple semigroup congruence classes",
[SEMICONG_SIMPLE_CLASS, SEMICONG_SIMPLE_CLASS],
function(c1, c2)
  return SIMPLECLASS_FROM_RMSCLASS( EquivalenceClassRelation(c1),
                                    c1!.rmsclass * c2!.rmsclass );
end);

#

InstallMethod(Size,
"for a (0-)simple semigroup congruence class",
[SEMICONG_SIMPLE_CLASS],
function(class)
  return Size(class!.rmsclass);
end);

#

InstallMethod( \=,
"for two (0-)simple semigroup congruence classes",
[SEMICONG_SIMPLE_CLASS, SEMICONG_SIMPLE_CLASS],
function(c1, c2)
  return EquivalenceClassRelation(c1) = EquivalenceClassRelation(c2) and
         c1!.rmsclass = c2!.rmsclass;
end);

#

InstallMethod(GeneratingPairsOfMagmaCongruence,
"for a (0-)simple semigroup congruence",
[SEMICONG_SIMPLE],
function(cong)
  local map;
  map := InverseGeneralMapping(cong!.iso);
  return List( GeneratingPairsOfMagmaCongruence(cong!.rmscong),
               x-> [x[1]^map, x[2]^map] );
end);

#
