#############################################################################
##
#W  translat.gi
#Y  Copyright (C) 2015-16                     James D. Mitchell, Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# TODO: Left/right translations of a monoid are all left/right multiplications

#############################################################################
## This file contains methods for dealing with left and right translation
## semigroups, as well as translational hulls. 
## When one of these semigroups is created, the attribute AsList
## is calculated.
## To avoid this calculation at the time of creation, you can call
## XTranslationsSemigroup or TranslationalHullSemigroup
##
## Left/Right translations are stored internally as transformations on the 
## incides of the underlying semigroup (determined by AsList). Hence, only 
## finite semigroups are supported.
##
## Much of the implementation in this file was based on the implementation of
## RMS in reesmatsemi.gi in the GAP library - in particular, the creation of
## the semigroups and their relation to their elements.
##  
## The code specific to rectangular bands is based on 
## Howie, J.M. (1995) 'Fundamentals of Semigroup theory'. 
## United Kingdom: Oxford University Press. (p. 116)
##
## This file is organised as follows:
##    1. Internal functions
##    2. Functions for the creation of left/right translations semigroup
##        and translational hulls
##    3. Methods for rectangular bands
##    4. Technical methods, eg. PrintObj, *, =, etc.
##
#############################################################################


#############################################################################
# 1. Internal Functions
#############################################################################

# Hash linked pairs as sum of underlying transformation hashes
SEMIGROUPS.HashFunctionForTranslationalHullElements := function(x, data)
    return (ORB_HashFunctionForTransformations(x![1]![1], data)
      + ORB_HashFunctionForTransformations(x![2]![1], data)) mod data + 1;
end;

# Choose how to calculate the elements of a translations semigroup
SEMIGROUPS.TranslationsSemigroupElements := function(T)
  local S;
  S := UnderlyingSemigroup(T);
  if IsZeroSimpleSemigroup(S) or IsRectangularBand(S) then
    return Semigroup(GeneratorsOfSemigroup(T));
  elif HasGeneratorsOfSemigroup(S) then
    if IsLeftTranslationsSemigroup(T) then
      return SEMIGROUPS.LeftTranslationsSemigroupWithGeneratorsElements(T);
    else 
      return SEMIGROUPS.RightTranslationsSemigroupWithGeneratorsElements(T); 
    fi;
  fi;
  Error("Semigroups: TranslationsSemigroupElements: \n",
        "no method of calculating this translations semigroup is known");
end;

# Choose how to calculate the elements of a translational hull
SEMIGROUPS.TranslationalHullElements := function(H)
  local S;
  S := UnderlyingSemigroup(H);
  if IsRectangularBand(S) then
    return Semigroup(GeneratorsOfSemigroup(H));
  elif IsZeroSimpleSemigroup(S) then
    return SEMIGROUPS.TranslationalHullOfZeroSimpleElements(H);
  else
    return SEMIGROUPS.TranslationalHullOfArbitraryElements(H);
  fi;
end;
    
# Left translations are the same as edge-label preserving endomorphisms of the
# right cayley graph
SEMIGROUPS.LeftTranslationsSemigroupWithGeneratorsElements := function(L)
  local S, digraph, n, nrgens, out, colors, gens, i, j;
  
  S := UnderlyingSemigroup(L);
  
  digraph := RightCayleyGraphSemigroup(S);
  n       := Length(digraph);
  nrgens  := Length(digraph[1]);
  out     := [];
  colors  := [];

  for i in [1 .. n] do
    out[i]    := [];
    colors[i] := 1;
    for j in [1 .. nrgens] do
      out[i][j] := n + nrgens * (i - 1) + j;
      out[n + nrgens * (i - 1) + j] := [digraph[i][j]];
      colors[n + nrgens * (i - 1) + j] := j + 1;
    od;
  od;
  gens := GeneratorsOfEndomorphismMonoid(Digraph(out), colors);
  Apply(gens, x -> LeftTranslation(L, RestrictedTransformation(x, [1 .. n])));
  return Semigroup(gens, rec(small := true));
end;

# Dual for right translations.
SEMIGROUPS.RightTranslationsSemigroupWithGeneratorsElements := function(R)
  local S, digraph, n, nrgens, out, colors, gens, i, j;

  S := UnderlyingSemigroup(R);
  
  digraph := LeftCayleyGraphSemigroup(S);
  n       := Length(digraph);
  nrgens  := Length(digraph[1]);
  out     := [];
  colors  := [];

  for i in [1 .. n] do
    out[i]    := [];
    colors[i] := 1;
    for j in [1 .. nrgens] do
      out[i][j] := n + nrgens * (i - 1) + j;
      out[n + nrgens * (i - 1) + j] := [digraph[i][j]];
      colors[n + nrgens * (i - 1) + j] := j + 1;
    od;
  od;
  gens := GeneratorsOfEndomorphismMonoid(Digraph(out), colors);
  Apply(gens, x -> RightTranslation(R,RestrictedTransformation(x, [1 .. n])));
  return Semigroup(gens, rec(small := true));
end;

# Translational hull elements of an arbitrary (finite) semigroup
# This is a backtrack search on functions from the semigroup to itself.
# Given a set A which hits every L class and R class, a linked pair (f, g) of
# translations is completely determined by the values on A. Having fixed a_i,
# we can restrict the values on a_k, k > i, by the linked pair conditions
# s*a_i f(a_k) = (s*a_i)g a_k and a_k f(a_i * s) = (a_k)g a_i * s,
# as well as restriction by the translation condition if Sa_i intersect Sa_k is
# non-empty or a_i S intersect a_k S is non-empty.
SEMIGROUPS.TranslationalHullOfArbitraryElements := function(H)
  local S, multtable, transpose, reps, repspos, dclasses, lclasses, rclasses,
        d, f, g, i, j, k, m, n, p, r, s, slist, fposrepk, gposrepk,
        possiblefrepvals, possiblegrepvals, whenboundfvals, whenboundgvals, pos,
        multtablepositionsets, transposepositionsets, posrepsks, posfrepsks,
        possrepsk, possgrepsk, undosortinglist, sortinglist, p1, p2, L, R,
        fvalsi, gvalsi, ftransrestrictionatstage, gtransrestrictionatstage, 
        flinkedrestrictionatstage, glinkedrestrictionatstage, 
        extendf, extendg, reject, propagatef, propagateg, restrictfromf,
        restrictfromg, bt, unrestrict, linkedpairs, linkedpairsunsorted;

  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroup(S);
  R := RightTranslationsSemigroup(S);
  n := Size(S);
  slist := ShallowCopy(AsList(S));
  undosortinglist := [1 .. n];
  SortParallel(slist, undosortinglist);
  sortinglist := [];
  for i in [1 .. n] do
    sortinglist[i] := Position(undosortinglist, i);
  od;
  
  multtable := MultiplicationTable(S);
  transpose := TransposedMat(multtable);
  
  # TODO: for now, choose the reps by L/R classes - but better to choose 
  # minimal set A such that SA = AS = S.
  dclasses := DClasses(S);
  reps := [];
  repspos := [];
  
  # choose diagonally through the D classes for now
  for d in dclasses do
    lclasses := ShallowCopy(LClasses(d));
    rclasses := ShallowCopy(RClasses(d));
    for i in [1 .. Minimum(Size(lclasses), Size(rclasses)) - 1] do
      r := Representative(Intersection(lclasses[1], rclasses[1]));
      Add(reps, r);
      Add(repspos, Position(slist, r));
      Remove(lclasses, 1);
      Remove(rclasses, 1);
    od;
    if Size(lclasses) > Size(rclasses) then
      #Size(rclasses) = 1
      for j in [1 .. Size(lclasses)] do
        r := Representative(Intersection(lclasses[1], rclasses[1]));
        Add(reps, r);
        Add(repspos, Position(slist, r));
        Remove(lclasses, 1);
      od;
    else
      #Size(lclasses) = 1
      for j in [1 .. Size(rclasses)] do
        r := Representative(Intersection(lclasses[1], rclasses[1]));
        Add(reps, r);
        Add(repspos, Position(slist, r));
        Remove(rclasses, 1);
      od;
    fi;
  od;
  
  m := Size(reps);
  
  multtablepositionsets := List([1 .. n], x -> []);
  transposepositionsets := List([1 .. n], x -> []);
  for i in [1 .. n] do
    for j in [1 .. n] do
      multtablepositionsets[i][j] := PositionsProperty(multtable[i],
                                                       x -> x = j);
      transposepositionsets[i][j] := PositionsProperty(transpose[i],
                                                       x -> x = j);
    od;
  od;
    
  extendf := function(k)
    f[repspos[k + 1]] := possiblefrepvals[k + 1][1];
    return k + 1;
  end;
  
  propagatef := function(k)
    for s in S do
      pos := Position(slist, reps[k] * s);
      if IsBound(f[pos]) then
        if not f[pos] = Position(slist, slist[f[repspos[k]]] * s) then
          UniteSet(glinkedrestrictionatstage[k][k], possiblegrepvals[k]);
          possiblegrepvals[k] := [];
          return fail;
        fi;
      else
        f[pos] := Position(slist, slist[f[repspos[k]]] * s);
        whenboundfvals[pos] := k;
      fi;
    od;
    return k;
  end;
  
  propagateg := function(k)
    for s in S do
      pos := Position(slist, s * reps[k]);
      if IsBound(g[pos]) then
        if not g[pos] = Position(slist, s * slist[g[repspos[k]]]) then
          return fail;
        fi;
      else
        g[pos] := Position(slist, s * slist[g[repspos[k]]]);
        whenboundgvals[pos] := k;
      fi;
    od;
    return k;
  end;
  
  restrictfromf := function(k)
    for i in [k + 1 .. m] do
      for s in S do
        posrepsks := Position(slist, reps[k] * s);
        posfrepsks := Position(slist, slist[f[repspos[k]]] * s);
        #restrict by the translation condition
        for p in multtablepositionsets[repspos[i]][posrepsks] do
          fvalsi := transposepositionsets[p][posfrepsks];
          UniteSet(ftransrestrictionatstage[i][k], 
                    Difference(possiblefrepvals[i], fvalsi));
          possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
        od;
        
        #deal with the cases reps[i] = reps[k] * s and reps[i] * t = reps[k]
        if reps[i] = reps[k] * s then 
          fvalsi := [posfrepsks];
          UniteSet(ftransrestrictionatstage[i][k],
                    Difference(possiblefrepvals[i], fvalsi));
          possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
        fi;
      od;
      for p in multtablepositionsets[repspos[i]][repspos[k]] do
        fvalsi := transposepositionsets[p][f[repspos[k]]];  
        UniteSet(ftransrestrictionatstage[i][k], 
                  Difference(possiblefrepvals[i], fvalsi));
        possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
      od;
      if Size(possiblefrepvals[i]) = 0 then
        return fail;
      fi;
    od;
    for i in [k .. m] do
      for s in S do
        posrepsks := Position(slist, reps[k] * s);
        #restrict by the linked pair condition
        gvalsi := transposepositionsets[posrepsks][Position(slist, 
                      reps[i] * slist[f[Position(slist, reps[k] * s)]])];  
        UniteSet(glinkedrestrictionatstage[i][k], 
                  Difference(possiblegrepvals[i], gvalsi));
        possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
      od;
      #deal with linked condition on reps[k]
      gvalsi := transposepositionsets[repspos[k]][Position(slist, 
                  reps[i] * slist[f[repspos[k]]])];
      UniteSet(glinkedrestrictionatstage[i][k],
                Difference(possiblegrepvals[i], gvalsi));
      possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
      if Size(possiblegrepvals[i]) = 0 then
        return fail;
      fi; 
    od;
    return k;
  end;
  
  restrictfromg := function(k)
    for i in [k + 1 .. m] do
      for s in S do
        possrepsk := Position(slist, s * reps[k]);
        possgrepsk := Position(slist, s * slist[g[repspos[k]]]);
        for p in transposepositionsets[repspos[i]][possrepsk] do
          gvalsi := multtablepositionsets[p][possgrepsk];
          UniteSet(gtransrestrictionatstage[i][k],
                    Difference(possiblegrepvals[i], gvalsi));
          possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
        od;
        
        #deal with the cases reps[i] = s * reps[k] and s * reps[i] = reps[k]
        if reps[i] = s * reps[k] then 
          gvalsi := [possgrepsk];
          UniteSet(gtransrestrictionatstage[i][k],
                    Difference(possiblegrepvals[i], gvalsi));
          possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
        fi;
        
        for p in transposepositionsets[repspos[i]][repspos[k]] do
          gvalsi := multtablepositionsets[p][g[repspos[k]]];  
          UniteSet(gtransrestrictionatstage[i][k],
                    Difference(possiblegrepvals[i], gvalsi));
          possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
        od;
        
        fvalsi := multtablepositionsets[possrepsk][Position(slist, 
                      slist[g[possrepsk]] * reps[i])];  
        UniteSet(flinkedrestrictionatstage[i][k], 
                  Difference(possiblefrepvals[i], fvalsi));
        possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
      od;
      if Size(possiblefrepvals[i]) = 0 or Size(possiblegrepvals[i]) = 0 then
        return fail;
      fi;
    od;
    return k;
  end;
  
  unrestrict := function(k, unrestrictf)
    for i in [1 .. n] do
        if whenboundgvals[i] = k then
          Unbind(g[i]);
          whenboundgvals[i] := 0;
        fi;
      od;
      for i in [k .. m] do
        UniteSet(possiblegrepvals[i], gtransrestrictionatstage[i][k]);
        UniteSet(possiblefrepvals[i], flinkedrestrictionatstage[i][k]);
        gtransrestrictionatstage[i][k] := [];
        flinkedrestrictionatstage[i][k] := [];
      od; 
  
    if(unrestrictf) then
      for i in [1 .. n] do
        if whenboundfvals[i] = k then
          Unbind(f[i]);
          whenboundfvals[i] := 0;
        fi;
      od;
      for i in [k .. m] do
        UniteSet(possiblefrepvals[i], ftransrestrictionatstage[i][k]);
        UniteSet(possiblegrepvals[i], glinkedrestrictionatstage[i][k]);
        ftransrestrictionatstage[i][k] := [];
        glinkedrestrictionatstage[i][k] := [];
      od;
    fi;
  end;
  
  reject := function(k)
    if k = 0 then
      return 0;
    fi;
    fposrepk := Position(possiblefrepvals[k], f[repspos[k]]);
    if IsBound(g[repspos[k]]) then
      gposrepk := Position(possiblegrepvals[k], g[repspos[k]]);
    else
      gposrepk := 0;
    fi;
    if gposrepk < Size(possiblegrepvals[k]) then
      g[repspos[k]] := possiblegrepvals[k][gposrepk + 1];
      unrestrict(k, false);
      return k;
    elif fposrepk < Size(possiblefrepvals[k]) then
      f[repspos[k]] := possiblefrepvals[k][fposrepk + 1];
      Unbind(g[repspos[k]]);
      unrestrict(k, true);
      return k;
    else
      if whenboundfvals[repspos[k]] = 0 then
        Unbind(f[repspos[k]]);
      fi;
      if whenboundgvals[repspos[k]] = 0 then
        Unbind(g[repspos[k]]);
      fi;
      unrestrict(k, true);
      return reject(k - 1);
    fi;
  end;

  bt := function(k)
    if k = 0 then
      return 0;
    fi;
    if k = m + 1 then
      return k;
    fi;
    if k = m then
      if not (propagatef(k) = fail or restrictfromf(k) = fail) then
        if not IsBound(g[repspos[k]]) then
          g[repspos[k]] := possiblegrepvals[k][1];
        fi;
        if not propagateg(k) = fail then
          return m + 1;
        fi;
      fi;
      return bt(reject(k));
    elif not (propagatef(k) = fail or restrictfromf(k) = fail) then
      if not IsBound(g[repspos[k]]) then
        g[repspos[k]] := possiblegrepvals[k][1];
      fi;
      if not (propagateg(k) = fail or restrictfromg(k) = fail) then
        return bt(extendf(k));
      else
        return bt(reject(k));
      fi;
    else 
      return bt(reject(k));
    fi;
  end;
  
  #The actual search
  ftransrestrictionatstage := List([1..m], x -> List([1..m], y -> []));  
  flinkedrestrictionatstage := List([1..m], x -> List([1..m], y -> []));
  gtransrestrictionatstage := List([1..m], x -> List([1..m], y -> []));
  glinkedrestrictionatstage := List([1..m], x -> List([1..m], y -> []));
  possiblefrepvals := List([1 .. m], x -> [1 .. n]);
  possiblegrepvals := ShallowCopy(possiblefrepvals);
  whenboundfvals := List([1 .. n], x -> 0);
  whenboundgvals := ShallowCopy(whenboundfvals);
  linkedpairs := [];
  
  f := [];
  g := [];
  
  k := extendf(0);
  k := bt(k);
  while k = m + 1 do
    Add(linkedpairs, [ShallowCopy(f), ShallowCopy(g)]);
    k := bt(reject(k - 1));
  od;
  
  linkedpairsunsorted := [];
  for p in linkedpairs do
    p1 := [];
    p2 := [];
    for i in [1 .. n] do
      p1[i] := undosortinglist[p[1][sortinglist[i]]];
      p2[i] := undosortinglist[p[2][sortinglist[i]]];
    od;
    Add(linkedpairsunsorted, [ShallowCopy(p1), ShallowCopy(p2)]);
  od;
  Apply(linkedpairsunsorted, x -> TranslationalHullElement(H, 
                                  LeftTranslation(L, Transformation(x[1])),
                                  RightTranslation(R, Transformation(x[2]))));
  return linkedpairsunsorted;
end;

#############################################################################
# 2. Creation of translations semigroups, translational hull, and elements
#############################################################################

# Create the left translations semigroup without calculating the elements
InstallGlobalFunction(LeftTranslationsSemigroup,
function(S)
  local fam, type, L;
  
  if HasLeftTranslations(S) then
    return LeftTranslations(S);
  fi;
  fam := NewFamily("LeftTranslationsSemigroupElementsFamily",
                    IsLeftTranslationsSemigroupElement);
  
  #create the semigroup of left translations
  L := Objectify(NewType(CollectionsFamily(fam), IsLeftTranslationsSemigroup
                         and IsWholeFamily and IsAttributeStoringRep), rec());
    
  #store the type of the elements in the semigroup
  type := NewType(fam, IsLeftTranslationsSemigroupElement);
  fam!.type := type;
  SetTypeLeftTranslationsSemigroupElements(L, type);
  SetLeftTranslationsSemigroupOfFamily(fam, L); 
  
  SetUnderlyingSemigroup(L, S);
  SetLeftTranslations(S, L);
  
  return L;
end);

# Create the right translations semigroup without calculating the elements
InstallGlobalFunction(RightTranslationsSemigroup,
function(S)
  local fam, type, R;
  
  if HasRightTranslations(S) then
    return RightTranslations(S);
  fi;
  fam := NewFamily( "RightTranslationsSemigroupElementsFamily",
          IsRightTranslationsSemigroupElement);
  
  # create the semigroup of right translations
  R := Objectify(NewType(CollectionsFamily(fam), IsRightTranslationsSemigroup 
    and IsWholeFamily and IsAttributeStoringRep), rec());
    
  # store the type of the elements in the semigroup
  type := NewType(fam, IsRightTranslationsSemigroupElement);
  fam!.type := type;
  SetTypeRightTranslationsSemigroupElements(R, type);
  SetRightTranslationsSemigroupOfFamily(fam, R);
   
  SetUnderlyingSemigroup(R, S);
  SetRightTranslations(S, R);
  
  return R;
end);

# Create the translational hull without calculating the elements
InstallGlobalFunction(TranslationalHullSemigroup,
function(S)
  local fam, type, H;
  
  if HasTranslationalHull(S) then
    return TranslationalHull(S);
  fi;
  fam := NewFamily( "TranslationalHullElementsFamily", 
          IsTranslationalHullElement);
  
  # create the translational hull
  H := Objectify(NewType(CollectionsFamily(fam), IsTranslationalHull and
    IsWholeFamily and IsAttributeStoringRep), rec());
  
  # store the type of the elements in the semigroup
  type := NewType(fam, IsTranslationalHullElement);
  fam!.type := type;
  SetTypeTranslationalHullElements(H, type);
  
  SetTranslationalHullOfFamily(fam, H);
  SetUnderlyingSemigroup(H, S);
  SetTranslationalHull(S, H);
  
  return H;
end);

# Create and calculate the semigroup of left translations
InstallMethod(LeftTranslations, "for a semigroup", 
[IsSemigroup and IsFinite], 
function(S) 
  local L;
  
  L := LeftTranslationsSemigroup(S);
  AsList(L);
  
  return L;
end);

# Create and calculate the semigroup of right translations
InstallMethod(RightTranslations, "for a semigroup", 
[IsSemigroup and IsFinite],
function(S) 
  local R;
  
  R := RightTranslationsSemigroup(S);
  AsList(R);
  
  return R;
end);

# Create a left translation as an element of a left translations semigroup.
# Second argument should be a mapping on the underlying semigroup or
# a transformation of its indices (as defined by AsList)
InstallGlobalFunction(LeftTranslation,
function(L, x)
  local S, semiList, i, reps, R;
  
  S := UnderlyingSemigroup(L);
  
  if not (IsLeftTranslationsSemigroup(L)) then
    Error("Semigroups: LeftTranslation: \n",
          "the first argument must be a semigroup of left translations");
    return;
  fi;
  
  if IsGeneralMapping(x) then
    if not (S = Source(x) and Source(x) = Range(x)) then
      Error("Semigroups: LeftTranslation (from Mapping): \n",
            "the domain and range of the second argument must be ",
            "the underlying semigroup of the first.");
    fi;
    if HasGeneratorsOfSemigroup(S) then
      if ForAny(GeneratorsOfSemigroup(S), 
                t -> ForAny(S, s -> (s^x) * t <> (s * t)^x)) then
         Error("Semigroups: LeftTranslation: \n",
               "the mapping given must define a left translation.");
      fi;
    else
      reps := [];
      for R in RClasses(S) do
        Add(reps, Representative(R));
      od;
      if ForAny(reps, s -> ForAny(S, t -> (s^x) * t <> (s * t)^x)) then
        Error("Semigroups: LeftTranslation: \n",
               "the mapping given must define a left translation.");
      fi;
    fi;
  elif IsTransformation(x) then
    if not DegreeOfTransformation(x) <= Size(S) then
      Error("Semigroups: LeftTranslation (from transformation): \n",
            "the second argument must act on the indices of the underlying ",
            "semigroup of the first argument.");
    fi;
    semiList := AsList(S);
    if HasGeneratorsOfSemigroup(S) then
      if ForAny(GeneratorsOfSemigroup(S), 
                t -> ForAny(S, 
                            s -> semiList[Position(semiList, s)^x] * t <> 
                            semiList[Position(semiList, s * t)^x])) then
         Error("Semigroups: LeftTranslation: \n",
               "the transformation given must define a left translation.");
      fi;
    else
      reps := [];
      for R in RClasses(S) do
        Add(reps, Representative(R));
      od;
      if ForAny(reps, 
                s -> ForAny(S, 
                            t -> semiList[Position(semiList, s)^x] * t <> 
                            semiList[Position(semiList, s * t)^x])) then
        Error("Semigroups: LeftTranslation: \n",
               "the transformation given must define a left translation.");
      fi;
    fi;
  else
    Error("Semigroups: LeftTranslation: \n",
          "the first argument should be a left translations semigroup, and ",
          "the second argument should be a mapping on the underlying ",
          "semigroup of the first argument, or a transformation on the ",
          "indices of its elements.");
  fi;
  return LeftTranslationNC(L, x);
end);

InstallGlobalFunction(LeftTranslationNC,
function(L, x)
  local semiList, mapAsTransList, i;
  if IsTransformation(x) then
    return Objectify(TypeLeftTranslationsSemigroupElements(L), [x]);
  fi;
  # x is a mapping on UnderlyingSemigroup(S)
  semiList := AsList(UnderlyingSemigroup(L));
  mapAsTransList := [];
  for i in [1..Length(semiList)] do
    mapAsTransList[i] := Position(semiList, semiList[i]^x);
  od;
  
  return Objectify(TypeLeftTranslationsSemigroupElements(L),
                   [Transformation(mapAsTransList)]);
end);

# Same for right translations.
InstallGlobalFunction(RightTranslation,
function(R, x)
  local S, semiList, i, reps, L;
  
  S := UnderlyingSemigroup(R);
  
  if not (IsRightTranslationsSemigroup(R)) then
    Error("Semigroups: RightTranslation: \n",
          "the first argument must be a semigroup of right translations");
    return;
  fi;

  if IsGeneralMapping(x) then
    if not (S = Source(x) and Source(x) = Range(x)) then
      Error("Semigroups: RightTranslation (from Mapping): \n",
            "the domain and range of the second argument must be ",
            "the underlying semigroup of the first.");
    fi;
    if HasGeneratorsOfSemigroup(S) then
      if ForAny(GeneratorsOfSemigroup(S), 
                t -> ForAny(S, s -> t * (s^x) <> (t * s)^x)) then
         Error("Semigroups: RightTranslation: \n",
               "the mapping given must define a right translation.");
      fi;
    else
      reps := [];
      for L in LClasses(S) do
        Add(reps, Representative(L));
      od;
      if ForAny(reps, s -> ForAny(S, t -> t * (s^x) <> (t * s)^x)) then
        Error("Semigroups: RightTranslation: \n",
               "the mapping given must define a right translation.");
      fi;
    fi;
  elif IsTransformation(x) then
    if not DegreeOfTransformation(x) <= Size(S) then
      Error("Semigroups: RightTranslation (from transformation): \n",
            "the second argument must act on the indices of the underlying ",
            "semigroup of the first argument.");
    fi;
    semiList := AsList(S);
    if HasGeneratorsOfSemigroup(S) then
      if ForAny(GeneratorsOfSemigroup(S), 
                t -> ForAny(S, 
                            s -> t * semiList[Position(semiList, s)^x] <> 
                            semiList[Position(semiList, t * s)^x])) then
         Error("Semigroups: RightTranslation: \n",
               "the transformation given must define a right translation.");
      fi;
    else
      if ForAny(reps, 
                s -> ForAny(S, 
                            t -> t * semiList[Position(semiList, s)^x] <> 
                            semiList[Position(semiList, t * s)^x])) then
        Error("Semigroups: RightTranslation: \n",
               "the transformation given must define a right translation.");
      fi;
    fi;
  else
    Error("Semigroups: RightTranslation: \n",
          "the first argument should be a right translations semigroup, and ",
          "the second argument should be a mapping on the underlying ",
          "semigroup of the first argument, or a transformation on the ",
          "indices of its elements.");
  fi;
  return RightTranslationNC(R, x);
end);

InstallGlobalFunction(RightTranslationNC,
function(R, x)
  local semiList, mapAsTransList, i;
  if IsTransformation(x) then
    return Objectify(TypeRightTranslationsSemigroupElements(R), [x]);
  fi;
  # x is a mapping on UnderlyingSemigroup(S)
  semiList := AsList(UnderlyingSemigroup(R));
  mapAsTransList := [];
  for i in [1..Length(semiList)] do
    mapAsTransList[i] := Position(semiList, semiList[i]^x);
  od;
  
  return Objectify(TypeRightTranslationsSemigroupElements(R),
                   [Transformation(mapAsTransList)]);
end);

# Creates and calculates the elements of the translational hull.
InstallMethod(TranslationalHull, "for a semigroup",
[IsSemigroup and IsFinite],
function(S)
  local H;
  
  H := TranslationalHullSemigroup(S);
  AsList(H);
  
  return H;
end);

# Creates the ideal of the translational hull consisting of 
# all inner bitranslations
InstallMethod(InnerTranslationalHull, "for a semigroup",
[IsSemigroup and IsFinite],
function(S)
  local I, H, L, R, l, r, s;
  
  I := [];
  H := TranslationalHullSemigroup(S);
  for s in S do
    L := LeftTranslationsSemigroup(S);
    R := RightTranslationsSemigroup(S);
    l := LeftTranslation(L, MappingByFunction(S, S, x -> s * x));
    r := RightTranslation(R, MappingByFunction(S, S, x -> x * s));
    Add(I, TranslationalHullElement(H, l, r));
  od;
  return Monoid(I);
end);

# Creates a linked pair (l, r) from a left translation l and a right
# translation r, as an element of a translational hull H.
InstallGlobalFunction(TranslationalHullElement, 
function(H, l, r) 
  local S, L, R, dclasses, lclasses, rclasses, reps, d, i, j;
  
  if not IsTranslationalHull(H) then 
    Error("Semigroups: TranslationalHullElement: \n",
          "the first argument must be a translational hull.");
  fi;
  
  if not (IsLeftTranslationsSemigroupElement(l) and 
            IsRightTranslationsSemigroupElement(r)) then
    Error("Semigroups: TranslationalHullElement: \n",
          "the second argument must be a left translation ",
          "and the third argument must be a right translation.");
    return;
  fi;
  
  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroupOfFamily(FamilyObj(l));
  R := RightTranslationsSemigroupOfFamily(FamilyObj(r));
  
  if not (UnderlyingSemigroup(L) = S and UnderlyingSemigroup(R) = S) then
      Error("Semigroups: TranslationalHullElement: \n",
            "each argument must have the same underlying semigroup.");
  fi;
  
  if HasGeneratorsOfSemigroup(S) then
    if ForAny(GeneratorsOfSemigroup(S), 
              t -> ForAny(S, s -> s * (t^l) <> (s^r) * t)) then
       Error("Semigroups: TranslationalHullElement: \n",
             "the translations given must form a linked pair.");
    fi;
  else
    dclasses := DClasses(S);
    for d in dclasses do
      lclasses := ShallowCopy(LClasses(d));
      rclasses := ShallowCopy(RClasses(d));
      for i in [1 .. Minimum(Size(lclasses), Size(rclasses)) - 1] do
        r := Representative(Intersection(lclasses[1], rclasses[1]));
        Add(reps, r);
        Remove(lclasses, 1);
        Remove(rclasses, 1);
      od;
      if Size(lclasses) > Size(rclasses) then
        #Size(rclasses) = 1
        for j in [1 .. Size(lclasses)] do
          r := Representative(Intersection(lclasses[1], rclasses[1]));
          Add(reps, r);
          Remove(lclasses, 1);
        od;
      else
        #Size(lclasses) = 1
        for j in [1 .. Size(rclasses)] do
          r := Representative(Intersection(lclasses[1], rclasses[1]));
          Add(reps, r);
          Remove(rclasses, 1);
        od;
      fi;
    od;
    if ForAny(reps, t -> ForAny(S, s -> s * (t^l) <> (s^r) * t)) then
      Error("Semigroups: TranslationalHullElement: \n",
             "the translations given must form a linked pair.");
    fi;
  fi;
  
  return TranslationalHullElementNC(H, l, r);
end);

InstallGlobalFunction(TranslationalHullElementNC,
function(H, l, r)
  return Objectify(TypeTranslationalHullElements(H), [l, r]);
end);

#############################################################################
# 3. Methods for rectangular bands
#############################################################################

# For rectangular bands, don't calculate AsList for LeftTranslations 
# Just get generators
InstallMethod(LeftTranslations, "for a RZMS semigroup",
[IsSemigroup and IsFinite and IsZeroSimpleSemigroup],
function(S) 
  local L;
  
  L := LeftTranslationsSemigroup(S);
  GeneratorsOfSemigroup(L);
  
  return L;
end);

# For RZMS, don't calculate AsList for RightTranslations 
# Just get generators
InstallMethod(RightTranslations, "for a RZMS semigroup",
[IsSemigroup and IsFinite and IsZeroSimpleSemigroup],
function(S) 
  local R;
  
  R := RightTranslationsSemigroup(S);
  GeneratorsOfSemigroup(R);
  
  return R;
end);

# Every transformation on the relevant index set corresponds to a translation.
# The R classes of an I x J rectangular band correspond to (i, J) for i in I.
# Dually for L classes.
InstallMethod(Size, "for the semigroup of left or right translations of a rectangular band", 
[IsTranslationsSemigroup and IsWholeFamily], 1, 
function(T)
  local S, n;
  S := UnderlyingSemigroup(T);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;
  if IsLeftTranslationsSemigroup(T) then
    n := NrRClasses(S);
  else n := NrLClasses(S);
  fi;
  
  return n^n;
end);

# The translational hull of a rectangular band is the direct product of the
# left translations and right translations
InstallMethod(Size, "for the translational hull of a rectangular band",
[IsTranslationalHull and IsWholeFamily],
function(H)
  local S, L, R;
  S := UnderlyingSemigroup(H);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;
  L := LeftTranslationsSemigroup(S);
  R := RightTranslationsSemigroup(S);
  return Size(L) * Size(R);
end);

# Generators of the left/right translations semigroup on the I x J rectangular 
# band correspond to the generators of the full transformation monoid on I or J. 
InstallMethod(GeneratorsOfSemigroup, "for the semigroup of left or right translations of a rectangular band",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  local S, L, n, iso, inv, reesMatSemi, semiList, gens, t, f;
  S := UnderlyingSemigroup(T);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;

  semiList := AsList(S);
  iso := IsomorphismReesMatrixSemigroup(S);
  inv := InverseGeneralMapping(iso);
  reesMatSemi := Range(iso);
  L := IsLeftTranslationsSemigroup(T);
  if L then
    n := Length(Rows(reesMatSemi));
  else
    n := Length(Columns(reesMatSemi));
  fi;
  
  gens := [];
  for t in GeneratorsOfMonoid(FullTransformationMonoid(n)) do
    if L then
      f := function(x)
        return ReesMatrixSemigroupElement(reesMatSemi, x[1]^t, 
          (), x[3]);
      end;
      Add(gens, LeftTranslation(T, CompositionMapping(inv, 
      MappingByFunction(reesMatSemi, reesMatSemi, f), iso)));
    else 
      f := function(x)
        return ReesMatrixSemigroupElement(reesMatSemi, x[1], 
          (), x[3]^t);
      end;
      Add(gens, RightTranslation(T, CompositionMapping(inv, 
        MappingByFunction(reesMatSemi, reesMatSemi, f), iso)));
    fi;
  od;
  return gens;
end);      

# Generators of translational hull are the direct product of 
# generators of left/right translations semigroup
InstallMethod(GeneratorsOfSemigroup, "for the translational hull of a rectangular band", 
[IsTranslationalHull],
function(H)
  local S, leftGens, rightGens, l, r, gens;
  
  S := UnderlyingSemigroup(H);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;

  leftGens := GeneratorsOfSemigroup(LeftTranslationsSemigroup(S));
  rightGens := GeneratorsOfSemigroup(RightTranslationsSemigroup(S));
  gens := [];
  
  for l in leftGens do
    for r in rightGens do
      Add(gens, TranslationalHullElement(H, l, r));
    od;
  od;
  
  return gens;
end);

#############################################################################
# 4. Technical methods
#############################################################################

InstallMethod(AsList, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  return Immutable(AsList(SEMIGROUPS.TranslationsSemigroupElements(T)));
end);

InstallMethod(AsList, "for a translational hull",
[IsTranslationalHull and IsWholeFamily],
function(H)
  return Immutable(AsList(SEMIGROUPS.TranslationalHullElements(H)));
end);

#TODO: fix this so SEMIGROUPS.TranslationsSemigroupElements is not called later
InstallMethod(Representative, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  if HasAsList(T) then
    return Representative(AsList(T));
  fi;
  return Representative(SEMIGROUPS.TranslationsSemigroupElements(T));
end);

#TODO: fix this so SEMIGROUPS.TranslationalHullElements is not called later
InstallMethod(Representative, "for a translational hull",
[IsTranslationalHull and IsWholeFamily],
function(H)
  if HasAsList(H) then
    return Representative(AsList(H));
  fi;
  return Representative(SEMIGROUPS.TranslationalHullElements(H));
end);

InstallMethod(ViewObj, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  Print("<the semigroup of");
  if IsLeftTranslationsSemigroup(T) then Print(" left");
  else Print(" right"); fi;
  Print(" translations of ", ViewString(UnderlyingSemigroup(T)), ">");
end);
  
InstallMethod(ViewObj, "for a semigroup of translations", 
[IsTranslationsSemigroup], PrintObj);

InstallMethod(PrintObj, "for a semigroup of translations",
[IsTranslationsSemigroup and HasGeneratorsOfSemigroup],
function(T)
  Print("<semigroup of ");
  if IsLeftTranslationsSemigroup(T) then Print("left ");
  else Print("right ");
  fi;
  Print("translations of ", ViewString(UnderlyingSemigroup(T)), " with ",
    Length(GeneratorsOfSemigroup(T)),
    " generators");
  if Length(GeneratorsOfSemigroup(T)) > 1 then
    Print("s");
  fi;
  Print(">");
  return;
end);

InstallMethod(ViewObj, "for a translation", 
[IsTranslationsSemigroupElement], PrintObj);

InstallMethod(PrintObj, "for a translation",
[IsTranslationsSemigroupElement],
function(t)
  local L, S;
  L := IsLeftTranslationsSemigroupElement(t); 
  if L then 
    S := UnderlyingSemigroup(LeftTranslationsSemigroupOfFamily(FamilyObj(t)));
    Print("<left ");
  else 
    S := UnderlyingSemigroup(RightTranslationsSemigroupOfFamily(FamilyObj(t)));
    Print("<right ");
  fi;
  
  Print("translation on ", ViewString(S), ">");
end);

InstallMethod(ViewObj, "for a translational hull", 
[IsTranslationalHull], PrintObj);

InstallMethod(PrintObj, "for a translational hull",
[IsTranslationalHull and IsWholeFamily],
function(H)
  Print("<translational hull over ", ViewString(UnderlyingSemigroup(H)), ">");
end);

InstallMethod(ViewObj, "for a translational hull element", 
[IsTranslationalHullElement], PrintObj);

InstallMethod(PrintObj, "for a translational hull element",
[IsTranslationalHullElement],
function(t)
  local H;
  H := TranslationalHullOfFamily(FamilyObj(t));
  Print("<linked pair of translations on ", ViewString(UnderlyingSemigroup(H)), ">");
end);

# Note the order of multiplication
InstallMethod(\*, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslationsSemigroupElement, IsLeftTranslationsSemigroupElement],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [y![1]*x![1]]);
end);

InstallMethod(\=, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslationsSemigroupElement, IsLeftTranslationsSemigroupElement],
function(x, y) 
  return x![1] = y![1];
end);

InstallMethod(\<, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslationsSemigroupElement, IsLeftTranslationsSemigroupElement],
function(x, y) 
  return x![1] < y![1];
end);

# Different order of multiplication
InstallMethod(\*, "for right translations of a semigroup",
IsIdenticalObj,
[IsRightTranslationsSemigroupElement, IsRightTranslationsSemigroupElement],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [x![1]*y![1]]);
end);

InstallMethod(\=, "for right translations of a semigroup",
IsIdenticalObj,
[IsRightTranslationsSemigroupElement, IsRightTranslationsSemigroupElement],
function(x, y) 
  return x![1] = y![1];
end);

InstallMethod(\<, "for right translations of a semigroup",
IsIdenticalObj,
[IsRightTranslationsSemigroupElement, IsRightTranslationsSemigroupElement],
function(x, y) 
  return x![1] < y![1];
end);

InstallMethod(\^, "for a semigroup element and a translation",
[IsAssociativeElement, IsTranslationsSemigroupElement],
function(x, t)
  local list;
  if IsLeftTranslationsSemigroupElement(t) then
    list := AsList(UnderlyingSemigroup(LeftTranslationsSemigroupOfFamily(FamilyObj(t))));
  else
    list := AsList(UnderlyingSemigroup(RightTranslationsSemigroupOfFamily(FamilyObj(t))));
  fi;
  if not x in list then
    Error("Semigroups: ^ for a semigroup element and translation: \n",
          "the first argument must be an element of the domain of the second");
  fi;
  return list[Position(list, x)^t![1]];
end);

InstallMethod(\*, "for translation hull elements (linked pairs)",
IsIdenticalObj,
[IsTranslationalHullElement, IsTranslationalHullElement],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [x![1]*y![1], x![2]*y![2]]);
end);

InstallMethod(\=, "for translational hull elements (linked pairs)",
IsIdenticalObj,
[IsTranslationalHullElement, IsTranslationalHullElement],
function(x, y)
  return x![1] = y![1] and x![2] = y![2];
end);

InstallMethod(\<, "for translational hull elements (linked pairs)",
IsIdenticalObj,
[IsTranslationalHullElement, IsTranslationalHullElement],
function(x, y)
  return x![1] < y![1] or (x![1] = y![1] and x![2] < y![2]);
end);

InstallMethod(IsWholeFamily, "for a semigroup of translations of a rectangular band",
[IsTranslationsSemigroup],
function(T)
  if IsLeftTranslationsSemigroup(T) then  
    return Size(T) = Size(LeftTranslationsSemigroupOfFamily(ElementsFamily(
                                                                FamilyObj(T))));
  else return Size(T) = Size(RightTranslationsSemigroupOfFamily(ElementsFamily(
                                                                FamilyObj(T)))); 
  fi;
end);

InstallMethod(IsWholeFamily, "for a subsemigroup of the translational hull of a rectangular band",
[IsTranslationalHull],
function(H) 
  return Size(H) = Size(TranslationalHullOfFamily(ElementsFamily(FamilyObj(H))));
end);

InstallMethod(UnderlyingSemigroup, "for a semigroup of left or right translations",
[IsTranslationsSemigroup],
function(T)
  if IsLeftTranslationsSemigroup(T) then
    return UnderlyingSemigroup(LeftTranslationsSemigroupOfFamily(ElementsFamily(
                                                                FamilyObj(T))));
  else 
    return UnderlyingSemigroup(RightTranslationsSemigroupOfFamily(ElementsFamily(
                                                                FamilyObj(T))));
  fi;
end);

InstallMethod(UnderlyingSemigroup, "for a subsemigroup of the translational hull",
[IsTranslationalHull],
function(H)
    return UnderlyingSemigroup(TranslationalHullOfFamily(FamilyObj(
      Enumerator(H)[1])));
end);

InstallMethod(ChooseHashFunction, "for a translational hull element and int",
[IsTranslationalHullElement, IsInt],
function(x, hashlen)
  return rec(func := SEMIGROUPS.HashFunctionForTranslationalHullElements,
             data := hashlen);
end);

InstallMethod(OneOp, "for a translational hull",
[IsTranslationalHullElement],
function(h)
  local H, L, R, S, l, r;
  H := TranslationalHullOfFamily(FamilyObj(h));
  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroup(S);
  R := RightTranslationsSemigroup(S);
  l := LeftTranslation(L, MappingByFunction(S, S, x -> x));
  r := RightTranslation(R, MappingByFunction(S, S, x -> x));
  return TranslationalHullElement(H, l, r);
end);

InstallMethod(OneOp, "for a semigroup of translations",
[IsTranslationsSemigroupElement],
function(t)
  local T, S, l, r;
  if IsLeftTranslationsSemigroupElement(t) then
    T := LeftTranslationsSemigroupOfFamily(FamilyObj(t));
    S := UnderlyingSemigroup(T);
    return LeftTranslation(T, MappingByFunction(S, S, x -> x));
  else
    T := RightTranslationsSemigroupOfFamily(FamilyObj(t));
    S := UnderlyingSemigroup(T);
    return RightTranslation(T, MappingByFunction(S, S, x -> x));
  fi;
end);

