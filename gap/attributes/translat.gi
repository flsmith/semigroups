#############################################################################
##
# W  translat.gi
# Y  Copyright (C) 2015-18                     James D. Mitchell, Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##
##
#############################################################################
## This file contains methods for dealing with left and right translation
## semigroups, as well as translational hulls.
## When one of these semigroups is created, the attribute AsList
## is calculated.
## To avoid this calculation at the time of creation, you can call
## XTranslationsSemigroup or TranslationalHullSemigroup
##
## Left/Right translations are stored internally as transformations on the
## indices of the underlying semigroup (determined by AsListCanonical). Hence,
## only finite semigroups are supported.
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
##        and translational hulls, and their elements
##    3. Methods for rectangular bands
##    4. Methods for monoids
##    5. Technical methods, eg. PrintObj, *, =, etc.
##
#############################################################################

#############################################################################
# 1. Internal Functions
#############################################################################

# Hash translations by their underlying transformations
  SEMIGROUPS.HashFunctionForTranslations := function(x, data)
    return ORB_HashFunctionForTransformations(x![1], data);
  end;

# Hash linked pairs as sum of underlying transformation hashes
  SEMIGROUPS.HashFunctionForBitranslations := function(x, data)
      return (SEMIGROUPS.HashFunctionForTranslations(x![1], data)
        + SEMIGROUPS.HashFunctionForTranslations(x![2], data)) mod data + 1;
  end;

# Choose how to calculate the elements of a translations semigroup
SEMIGROUPS.TranslationsSemigroupElements := function(T)
  local S;
  S := UnderlyingSemigroup(T);
  if IsZeroSimpleSemigroup(S) or
      IsRectangularBand(S) or
      IsSimpleSemigroup(S) or
      SEMIGROUPS.IsNormalRMSOverGroup(S) then
    return Semigroup(GeneratorsOfSemigroup(T));
  elif HasGeneratorsOfSemigroup(S) then
    if IsLeftTranslationsSemigroup(T) then
      return SEMIGROUPS.LeftTranslationsBacktrack(T);
    else
      return SEMIGROUPS.RightTranslationsByDual(T);
    fi;
  fi;
  Error("Semigroups: TranslationsSemigroupElements: \n",
        "no method of calculating this translations semigroup is known,");
end;

SEMIGROUPS.LeftTranslationsBacktrack := function(L)
  local S, n, slist, sortedlist, gens, m, t, tinv, M, multtable,
  possiblefgenvals, genspos, I, q, possibleidempotentfvals, gen, idempos,
  extend, next, propagate, reject, bt, whenbound, translist, restrictionatstage,
  f, posinfgenvals, k, e, i, s, x, pos, genpos;

  S           := UnderlyingSemigroup(L);
  n           := Size(S);
  slist       := AsListCanonical(S);
  sortedlist  := AsSortedList(S);
  gens        := GeneratorsOfSemigroup(S);
  m           := Size(gens);

  t    := Transformation(List([1 .. n],
                         i -> PositionCanonical(S, sortedlist[i])));
  tinv := InverseOfTransformation(t);
  M    := MultiplicationTable(S);

  multtable := List([1 .. n], i -> List([1 .. n],
                                        j -> M[i ^ tinv][j ^ tinv] ^ t));

  possiblefgenvals        := List([1 .. m], i -> [1 .. n]);
  genspos                 := List(gens, g -> Position(slist, g));
  I                       := Idempotents(S);
  q                       := Size(I);
  possibleidempotentfvals := [1 .. q];
  for e in I do
    possibleidempotentfvals[Position(I, e)] := PositionsProperty(slist,
                                                   x -> x * e = x);
  od;
  for i in [1 .. m] do
    gen := gens[i];
    for s in S do
      if gen * s in Idempotents(S) then
        idempos             := Position(I, gen * s);
        possiblefgenvals[i] := Intersection(possiblefgenvals[i],
                                            PositionsProperty(slist,
                                              x -> PositionCanonical(S, x * s) in
                                              possibleidempotentfvals[idempos]));
        possiblefgenvals[i] := Intersection(possiblefgenvals[i],
                                            PositionsProperty(slist,
                                              x -> x * s = x * s * gen * s));
      fi;
    od;
  od;

  extend := function(k)
    # assign the first possible value to the next rep
    f[genspos[k + 1]]     := possiblefgenvals[k + 1][1];
    posinfgenvals[k + 1]  := 1;
    return k + 1;
  end;

  next := function(k)
    for i in [1 .. n] do
      if whenbound[i] = k then
        whenbound[i] := 0;
        Unbind(f[i]);
      fi;
    od;
    for i in [1 .. m] do
      UniteSet(possiblefgenvals[i], restrictionatstage[k][i]);
      restrictionatstage[k][i] := [];
    od;
    if posinfgenvals[k] = Size(possiblefgenvals[k]) then
      return fail;
    fi;
    # whenbound[genspos[k]] := k; ???
    posinfgenvals[k] := posinfgenvals[k] + 1;
    f[genspos[k]]    := possiblefgenvals[k][posinfgenvals[k]];
    return k;
  end;

  propagate := function(k)
    # multiply through on the right by S to assign all other possible positions
    x := genspos[k];
    for i in [1 .. n] do
      pos := multtable[x][i];
      if slist[pos] in gens then
        # we don't want to restrict f[gens[k]] based on the value of f[gens[k]]
        # and there's no point restricting f[gens[i]] for i < k
        genpos := Position(gens, slist[pos]);
        if genpos > k and multtable[f[x]][i] in possiblefgenvals[genpos] then
          restrictionatstage[k][genpos] :=
            UnionSet(restrictionatstage[k][genpos],
                     Difference(possiblefgenvals[genpos],
                                [multtable[f[x]][i]]));
          possiblefgenvals[genpos] := Intersection(possiblefgenvals[genpos],
                                                   [multtable[f[x]][i]]);
        fi;
      fi;
      if IsBound(f[pos]) then
        if not f[pos] = multtable[f[x]][i] then
          return fail;
        fi;
        continue;
      fi;
      f[pos]          := multtable[f[genspos[k]]][i];
      whenbound[pos]  := k;
    od;
    return k;
  end;

  reject := function(k)
    if k = m + 1 then
      k := m;
    fi;
    while k > 0 and next(k) = fail do
      Unbind(f[genspos[k]]);
      posinfgenvals[k] := 0;
      for i in [k .. m] do
        UniteSet(possiblefgenvals[i], restrictionatstage[k][i]);
        restrictionatstage[k][i] := [];
      od;
      k := k - 1;
    od;
    return k;
  end;

  bt := function(k)
    if k = 0 or k = m + 1 then
      return k;
    fi;
    if propagate(k) = fail then
      return bt(reject(k));
    fi;
    if k = m then
      return m + 1;
    fi;
    return bt(extend(k));
  end;

  whenbound           := List([1 .. n], i -> 0);
  translist           := [];
  restrictionatstage  := List([1 .. m], i -> List([1 .. m], j -> []));
  f                   := [];
  posinfgenvals       := List([1 .. m], i -> 0);

  extend(0);
  k := bt(1);
  while k = m + 1 do
    Add(translist, LeftTranslationNC(L, Transformation(ShallowCopy(f))));
    k := bt(reject(k));
  od;
  return translist;
end;

SEMIGROUPS.RightTranslationsByDual := function(R)
  local S, Sl, D, Dl, map, dual_trans, map_list, inv_list, j, i;

  S           := UnderlyingSemigroup(R);
  Sl          := AsListCanonical(S);
  D           := DualSemigroup(S);
  Dl          := AsListCanonical(D);
  map         := AntiIsomorphismDualSemigroup(S);
  dual_trans  := LeftTranslations(D);

  map_list := List(S, x -> []);
  inv_list := List(S, x -> []);
  for i in [1 .. Size(S)] do
    j           := Position(Dl, Sl[i] ^ map);
    map_list[i] := j;
    inv_list[j] := i;
  od;

  return List(dual_trans,
              d -> RightTranslation(R, Transformation(List([1 .. Size(S)],
                                       i -> inv_list[map_list[i] ^ d![1]]))));
end;

# Left translations are the same as edge-label preserving endomorphisms of the
# right cayley graph
SEMIGROUPS.LeftTranslationsSemigroupElementsByGenerators := function(L)
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
      out[i][j]                         := n + nrgens * (i - 1) + j;
      out[n + nrgens * (i - 1) + j]     := [digraph[i][j]];
      colors[n + nrgens * (i - 1) + j]  := j + 1;
    od;
  od;
  gens := GeneratorsOfEndomorphismMonoid(Digraph(out), colors);
  Apply(gens, x -> LeftTranslationNC(L, RestrictedTransformation(x, [1 .. n])));
  return Semigroup(gens, rec(small := true));
end;

# Dual for right translations.
SEMIGROUPS.RightTranslationsSemigroupElementsByGenerators := function(R)
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
      out[i][j]                         := n + nrgens * (i - 1) + j;
      out[n + nrgens * (i - 1) + j]     := [digraph[i][j]];
      colors[n + nrgens * (i - 1) + j]  := j + 1;
    od;
  od;
  gens := GeneratorsOfEndomorphismMonoid(Digraph(out), colors);
  Apply(gens, x -> RightTranslationNC(R, RestrictedTransformation(x, [1 .. n])));
  return Semigroup(gens, rec(small := true));
end;

# Choose how to calculate the elements of a translational hull
SEMIGROUPS.Bitranslations := function(H)
  local S;
  S := UnderlyingSemigroup(H);
  if IsRectangularBand(S) then
    return Semigroup(GeneratorsOfSemigroup(H));
  elif IsReesZeroMatrixSemigroup(S) then
    return SEMIGROUPS.BitranslationsOfZeroSimple(H);
  elif SEMIGROUPS.IsNormalRMSOverGroup(S) then
    return SEMIGROUPS.BitranslationsOfNormalRMS(H);
  else
    return SEMIGROUPS.BitranslationsByGenerators(H);
  fi;
end;

# Calculates bitranslations of an arbitrary (finite)
# semigroup with known generators.
# This is a backtrack search on functions from the semigroup to itself.
# Given a set X of generators, a linked pair (f, g) of
# translations is completely determined by the values on X. Having fixed x_i,
# we can restrict the values on x_k, k > i, by the linked pair conditions
# s * x_i f(x_k) = (s * x_i)g x_k and x_k f(x_i * s) = (x_k)g x_i * s,
# as well as restriction by the translation condition if Sx_i intersect Sx_k is
# non-empty or x_i S intersect x_k S is non-empty.
SEMIGROUPS.BitranslationsByGenerators := function(H)
  local S, n, isweaklyreductive, nronly, slist, sortedlist, L, R, multtable, t,
  tinv, M, reps, repspos, m, multtablepossets, transposepossets, pos, I, q,
  possibleidempotentfvals, possibleidempotentgvals, possiblefrepvals,
  possiblegrepvals, possiblefrepvalsfromidempotent,
  possiblegrepvalsfromidempotent, restrictbyweakreductivity, extendf,
  propagatef, propagateg, restrictfromf, restrictfromg, unrestrict, reject, bt,
  ftransrestrictionatstage, flinkedrestrictionatstage, gtransrestrictionatstage,
  glinkedrestrictionatstage, whenboundfvals, whenboundgvals, linkedpairs, f, g,
  count, k, i, j, e, s, y;

  S                 := UnderlyingSemigroup(H);
  n                 := Size(S);
  isweaklyreductive := Size(InnerTranslationalHull(S)) = n;
  nronly            := ValueOption("SEMIGROUPS_bitranslat_nr_only") = true;
  slist             := AsListCanonical(S);
  sortedlist        := AsSSortedList(S);
  L                 := LeftTranslationsSemigroup(S);
  R                 := RightTranslationsSemigroup(S);
  multtable         := MultiplicationTable(S);

  t := Transformation(List([1 .. n], i -> PositionCanonical(S, sortedlist[i])));

  tinv := InverseOfTransformation(t);
  M    := MultiplicationTable(S);

  multtable := List([1 .. n], i -> List([1 .. n],
                                        j -> M[i ^ tinv][j ^ tinv] ^ t));

  reps    := GeneratorsOfSemigroup(S);
  repspos := [];
  m       := Size(reps);
  for i in [1 .. m] do
    repspos[i] := Position(slist, reps[i]);
  od;

  # store which elements of the semigroups multiply each given element to form
  # another given element
  # eg., if a * b = a * c = d, with (a,b,c,d) having indices (i,j,k,l)
  # in the multiplication table, then we store [j,k] in the cell [i][l]
  multtablepossets := List([1 .. n], x -> List([1 .. n], y -> []));
  transposepossets := List([1 .. n], x -> List([1 .. n], y -> []));
  for i in [1 .. n] do
    for j in [1 .. n] do
      pos := multtable[i][j];
      Add(multtablepossets[i][pos], j);
      Add(transposepossets[j][pos], i);
    od;
  od;

  I                       := Idempotents(S);
  q                       := Size(I);
  possibleidempotentfvals := [1 .. q];
  possibleidempotentgvals := [1 .. q];
  for e in I do
    possibleidempotentfvals[Position(I, e)] := PositionsProperty(slist,
                                                   x -> x * e = x);
    possibleidempotentgvals[Position(I, e)] := PositionsProperty(slist,
                                                   x -> e * x = x);
  od;

  possiblefrepvals := List([1 .. m], x -> [1 .. n]);
  possiblegrepvals := List([1 .. m], x -> [1 .. n]);

  # restrict values for f, g based on idemopotents
  # if e is an idempotent with r_i * s = e
  # then f(r_i)*s = f(r_i)*s * r_i * s
  # and f(r_i) satisfies f(r_i) * s = x for some value x such that x * e = e
  for i in [1 .. m] do
    for s in S do
      if IsIdempotent(reps[i] * s) then
        possiblefrepvals[i] := Intersection(possiblefrepvals[i],
                                            PositionsProperty(slist,
                                             x -> x * s = x * s * reps[i] * s));
        possiblefrepvalsfromidempotent := [];
        for y in possibleidempotentfvals[Position(I, reps[i] * s)] do
          UniteSet(possiblefrepvalsfromidempotent,
                    transposepossets[Position(slist, s)][y]);
        od;
        possiblefrepvals[i] := Intersection(possiblefrepvals[i],
                                              possiblefrepvalsfromidempotent);
      fi;

      if IsIdempotent(s * reps[i]) then
        possiblegrepvals[i] := Intersection(possiblegrepvals[i],
                                            PositionsProperty(slist,
                                             x -> s * x = s * reps[i] * s * x));
        possiblegrepvalsfromidempotent := [];
        for y in possibleidempotentgvals[Position(I, s * reps[i])] do
          UniteSet(possiblegrepvalsfromidempotent,
                    multtablepossets[Position(slist, s)][y]);
        od;
        possiblegrepvals[i] := Intersection(possiblegrepvals[i],
                                              possiblegrepvalsfromidempotent);
      fi;
    od;
  od;

  # if S is weakly reductive then every pair of bitranslations permute
  # i.e. for (f, g) and (f', g') bitranslations, for all s in S,
  # f(sg') = (fs)g'
  # so if fs is a generator x_i, then (x_i)g lies in the range of f
  restrictbyweakreductivity := function(f, g)
    for i in [1 .. m] do
      if repspos[i] in f then
        # add the restriction...
        possiblegrepvals[i] := Intersection(possiblegrepvals[i], f);
        # stop the backtracking from undoing the restriction
        # by only letting it restore those things in the range of f
        for j in [1 .. m] do
          gtransrestrictionatstage[i][j]
            := Intersection(gtransrestrictionatstage[i][j], f);
          glinkedrestrictionatstage[i][j]
            := Intersection(glinkedrestrictionatstage[i][j], f);
        od;
      fi;
      if repspos[i] in g then
        # add the restriction...
        possiblefrepvals[i] := Intersection(possiblefrepvals[i], g);
        # stop the backtracking from undoing the restriction
        # by only letting it restore those things in the range of g
        for j in [1 .. m] do
          ftransrestrictionatstage[i][j]
            := Intersection(ftransrestrictionatstage[i][j], g);
          flinkedrestrictionatstage[i][j]
            := Intersection(flinkedrestrictionatstage[i][j], g);
        od;
      fi;
    od;
  end;

  extendf := function(k)
    # assign the first possible value of f for the next rep
    f[repspos[k + 1]] := possiblefrepvals[k + 1][1];
    return k + 1;
  end;

  propagatef := function(k)
    for i in [1 .. n] do
      pos := multtable[repspos[k]][i];
      if IsBound(f[pos]) then
        if not f[pos] = multtable[f[repspos[k]]][i] then
          UniteSet(glinkedrestrictionatstage[k][k], possiblegrepvals[k]);
          possiblegrepvals[k] := [];
          return fail;
        fi;
      else
        f[pos]              := multtable[f[repspos[k]]][i];
        whenboundfvals[pos] := k;
      fi;
    od;
    return k;
  end;

  propagateg := function(k)
    for i in [1 .. n] do
      pos := multtable[i][repspos[k]];
      if IsBound(g[pos]) then
        if not g[pos] = multtable[i][g[repspos[k]]] then
          return fail;
        fi;
      else
        g[pos]              := multtable[i][g[repspos[k]]];
        whenboundgvals[pos] := k;
      fi;
    od;
    return k;
  end;

  restrictfromf := function(k)
    local ipos, posrepsks, posfrepsks, fvalsi, gvalsi, p;
      for i in [k + 1 .. m] do
        ipos := repspos[i];
        for j in [1 .. n] do
          posrepsks   := multtable[repspos[k]][j];
          posfrepsks  := multtable[f[repspos[k]]][j];
          # restrict by the translation condition
          for p in multtablepossets[ipos][posrepsks] do
            fvalsi := transposepossets[p][posfrepsks];
            UniteSet(ftransrestrictionatstage[i][k],
                      Difference(possiblefrepvals[i], fvalsi));
            possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
            if Size(possiblefrepvals[i]) = 0 then
              return fail;
            fi;
          od;

          # deal with the cases reps[i] = reps[k] * slist[j]
          if ipos = multtable[repspos[k]][j] then
            fvalsi := [posfrepsks];
            UniteSet(ftransrestrictionatstage[i][k],
                      Difference(possiblefrepvals[i], fvalsi));
            possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
            if Size(possiblefrepvals[i]) = 0 then
              return fail;
            fi;
        fi;
      od;
      # deal with the cases reps[i] * slist[j] = reps[k]
      for p in multtablepossets[ipos][repspos[k]] do
        fvalsi := transposepossets[p][f[repspos[k]]];
        UniteSet(ftransrestrictionatstage[i][k],
                  Difference(possiblefrepvals[i], fvalsi));
        possiblefrepvals[i] := Intersection(possiblefrepvals[i], fvalsi);
        if Size(possiblefrepvals[i]) = 0 then
          return fail;
        fi;
      od;
    od;
    for i in [k .. m] do
      ipos := repspos[i];
      for j in [1 .. n] do
        # restrict by the linked pair condition
        posrepsks := multtable[repspos[k]][j];
        gvalsi    := transposepossets[posrepsks][multtable[ipos][f[posrepsks]]];
        UniteSet(glinkedrestrictionatstage[i][k],
                  Difference(possiblegrepvals[i], gvalsi));
        possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
      od;
      # deal with linked condition on reps[k]
      gvalsi := transposepossets[repspos[k]][multtable[ipos][f[repspos[k]]]];
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
    local ipos, possrepsk, possgrepsk, gvalsi, fvalsi, p;
    for i in [k + 1 .. m] do
      ipos := repspos[i];
      for j in [1 .. n] do
        possrepsk   := multtable[j][repspos[k]];
        possgrepsk  := multtable[j][g[repspos[k]]];
        for p in transposepossets[ipos][possrepsk] do
          gvalsi := multtablepossets[p][possgrepsk];
          UniteSet(gtransrestrictionatstage[i][k],
                    Difference(possiblegrepvals[i], gvalsi));
          possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
        od;

        # deal with the cases reps[i] = s * reps[k] and s * reps[i] = reps[k]
        if ipos = multtable[j][repspos[k]] then
          gvalsi := [possgrepsk];
          UniteSet(gtransrestrictionatstage[i][k],
                    Difference(possiblegrepvals[i], gvalsi));
          possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
        fi;

        for p in transposepossets[ipos][repspos[k]] do
          gvalsi := multtablepossets[p][g[repspos[k]]];
          UniteSet(gtransrestrictionatstage[i][k],
                    Difference(possiblegrepvals[i], gvalsi));
          possiblegrepvals[i] := Intersection(possiblegrepvals[i], gvalsi);
        od;

        fvalsi := multtablepossets[possrepsk][multtable[g[possrepsk]][ipos]];
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
      gtransrestrictionatstage[i][k]  := [];
      flinkedrestrictionatstage[i][k] := [];
    od;

    if unrestrictf then
      for i in [1 .. n] do
        if whenboundfvals[i] = k then
          Unbind(f[i]);
          whenboundfvals[i] := 0;
        fi;
      od;
      for i in [k .. m] do
        UniteSet(possiblefrepvals[i], ftransrestrictionatstage[i][k]);
        UniteSet(possiblegrepvals[i], glinkedrestrictionatstage[i][k]);
        ftransrestrictionatstage[i][k]  := [];
        glinkedrestrictionatstage[i][k] := [];
      od;
    fi;
  end;

  reject := function(k)
    local fposrepk, gposrepk;
    if k = 0 then
      return 0;
    fi;
    fposrepk := Position(possiblefrepvals[k], f[repspos[k]]);
    if IsBound(g[repspos[k]]) then
      gposrepk := Position(possiblegrepvals[k], g[repspos[k]]);
    else
      gposrepk := 0;
    fi;

    if gposrepk = 0 then
      if fposrepk < Size(possiblefrepvals[k]) then
        f[repspos[k]] := possiblefrepvals[k][fposrepk + 1];
        unrestrict(k, true);
        return k;
      else
        unrestrict(k, true);
        return reject(k - 1);
      fi;
    elif gposrepk < Size(possiblegrepvals[k]) then
      g[repspos[k]] := possiblegrepvals[k][gposrepk + 1];
      unrestrict(k, false);
      return k;
    elif fposrepk < Size(possiblefrepvals[k]) then
      f[repspos[k]] := possiblefrepvals[k][fposrepk + 1];
      if whenboundgvals[repspos[k]] = 0 then
        Unbind(g[repspos[k]]);
      fi;
      unrestrict(k, true);
      return k;
    else
      if whenboundfvals[repspos[k]] = 0 then
        # this occurs iff f[repspos[k]] was set at stage k
        # and not propagated from another rep
        Unbind(f[repspos[k]]);
      fi;
      if whenboundgvals[repspos[k]] = 0 then
        # this occurs iff g[repspos[k]] was set at stage k
        # and not propagated from another rep
        Unbind(g[repspos[k]]);
      fi;
      unrestrict(k, true);
      return reject(k - 1);
    fi;
  end;

  bt := function(k)
    if k = 0 or k = m + 1 then
      return k;
    elif k = m then
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

  # The actual search
  ftransrestrictionatstage  := List([1 .. m], x -> List([1 .. m], y -> []));
  flinkedrestrictionatstage := List([1 .. m], x -> List([1 .. m], y -> []));
  gtransrestrictionatstage  := List([1 .. m], x -> List([1 .. m], y -> []));
  glinkedrestrictionatstage := List([1 .. m], x -> List([1 .. m], y -> []));
  whenboundfvals            := List([1 .. n], x -> 0);
  whenboundgvals            := ShallowCopy(whenboundfvals);
  linkedpairs               := [];

  f := [];
  g := [];

  count := 0;

  k := extendf(0);
  k := bt(k);
  while k = m + 1 do
    if isweaklyreductive then
      restrictbyweakreductivity(f, g);
    fi;
    if nronly then
      count := count + 1;
    else
      Add(linkedpairs, [ShallowCopy(f), ShallowCopy(g)]);
    fi;
    k := bt(reject(k - 1));
  od;

  if nronly then
    return count;
  fi;

  Apply(linkedpairs, x -> BitranslationNC(H,
                            LeftTranslationNC(L, Transformation(x[1])),
                            RightTranslationNC(R, Transformation(x[2]))));

  return linkedpairs;
end;

#############################################################################
# 2. Creation of translations semigroups, translational hull, and elements
#############################################################################

# Create the left translations semigroup without calculating the elements
InstallGlobalFunction(LeftTranslationsSemigroup,
function(S)
  local fam, L, type;

  if not IsEnumerableSemigroupRep(S) then
    ErrorNoReturn("Semigroups: LeftTranslationsSemigroup: \n",
                  "the semigroup must have representation ",
                  "IsEnumerableSemigroupRep,");
  fi;

  if HasLeftTranslations(S) then
    return LeftTranslations(S);
  fi;

  if SEMIGROUPS.IsNormalRMSOverGroup(S) then
    fam   := SEMIGROUPS.FamOfRMSLeftTranslationsByTriple();
    type  := fam!.type;
  else
    fam       := NewFamily("LeftTranslationsSemigroupElementsFamily",
                      IsLeftTranslationsSemigroupElement);
    type      := NewType(fam, IsLeftTranslationsSemigroupElement);
    fam!.type := type;
  fi;

  # create the semigroup of left translations
  L := Objectify(NewType(CollectionsFamily(fam), IsLeftTranslationsSemigroup
                         and IsWholeFamily and IsAttributeStoringRep), rec());

  # store the type of the elements in the semigroup
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

  if not IsEnumerableSemigroupRep(S) then
    ErrorNoReturn("Semigroups: RightTranslationsSemigroup: \n",
                  "the semigroup must have representation ",
                  "IsEnumerableSemigroupRep,");
  fi;

  if HasRightTranslations(S) then
    return RightTranslations(S);
  fi;

  if SEMIGROUPS.IsNormalRMSOverGroup(S) then
    fam   := SEMIGROUPS.FamOfRMSRightTranslationsByTriple();
    type  := fam!.type;
  else
    fam       := NewFamily("RightTranslationsSemigroupElementsFamily",
                      IsRightTranslationsSemigroupElement);
    type      := NewType(fam, IsRightTranslationsSemigroupElement);
    fam!.type := type;
  fi;

  # create the semigroup of right translations
  R := Objectify(NewType(CollectionsFamily(fam), IsRightTranslationsSemigroup
    and IsWholeFamily and IsAttributeStoringRep), rec());

  # store the type of the elements in the semigroup
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

  if SEMIGROUPS.IsNormalRMSOverGroup(S) then
    fam   := SEMIGROUPS.FamOfRMSBitranslationsByTriple();
    type  := fam!.type;
  else
    fam := NewFamily("BitranslationsFamily",
                      IsBitranslation);
    type      := NewType(fam, IsBitranslation);
    fam!.type := type;
  fi;

  # create the translational hull
  H := Objectify(NewType(CollectionsFamily(fam), IsTranslationalHull and
    IsWholeFamily and IsAttributeStoringRep), rec());

  # store the type of the elements in the semigroup
  SetTypeBitranslations(H, type);
  SetTranslationalHullOfFamily(fam, H);
  SetUnderlyingSemigroup(H, S);
  SetTranslationalHull(S, H);

  return H;
end);

# Create and calculate the semigroup of left translations
InstallMethod(LeftTranslations, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite],
function(S)
  local L;

  L := LeftTranslationsSemigroup(S);
  AsList(L);

  return L;
end);

# Create and calculate the semigroup of inner left translations
InstallMethod(InnerLeftTranslations, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite],
function(S)
  local A, I, L, l, s;

  I := [];
  L := LeftTranslationsSemigroup(S);

  if HasGeneratorsOfSemigroup(S) then
    A := GeneratorsOfSemigroup(S);
  else
    A := S;
  fi;
  for s in A do
    l := LeftTranslationNC(L, MappingByFunction(S, S, x -> s * x));
    Add(I, l);
  od;
  return Semigroup(I);
end);

# Create and calculate the semigroup of right translations
InstallMethod(RightTranslations, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite],
function(S)
  local R;

  R := RightTranslationsSemigroup(S);
  AsList(R);

  return R;
end);

# Create and calculate the semigroup of inner right translations
InstallMethod(InnerRightTranslations, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite],
function(S)
  local A, I, R, r, s;

  I := [];
  R := RightTranslationsSemigroup(S);

  if HasGeneratorsOfSemigroup(S) then
    A := GeneratorsOfSemigroup(S);
  else
    A := S;
  fi;
  for s in A do
    r := RightTranslationNC(R, MappingByFunction(S, S, x -> x * s));
    Add(I, r);
  od;
  return Semigroup(I);
end);

# Create a left translation as an element of a left translations semigroup.
# Second argument should be a mapping on the underlying semigroup or
# a transformation of its indices (as defined by AsListCanonical)
InstallGlobalFunction(LeftTranslation,
function(L, x)
  local R, S, reps, semiList;
  S     := UnderlyingSemigroup(L);
  reps  := [];

  if not (IsLeftTranslationsSemigroup(L)) then
    ErrorNoReturn("Semigroups: LeftTranslation: \n",
          "the first argument must be a semigroup of left translations,");
  fi;

  if HasGeneratorsOfSemigroup(S) then
    reps := GeneratorsOfSemigroup(S);
  else
    for R in RClasses(S) do
      Add(reps, Representative(R));
    od;
  fi;

  if IsGeneralMapping(x) then
    if not (S = Source(x) and Source(x) = Range(x)) then
      ErrorNoReturn("Semigroups: LeftTranslation (from Mapping): \n",
            "the domain and range of the second argument must be ",
            "the underlying semigroup of the first,");
    fi;
    if ForAny(reps, s -> ForAny(S, t -> (s ^ x) * t <> (s * t) ^ x)) then
      ErrorNoReturn("Semigroups: LeftTranslation: \n",
             "the mapping given must define a left translation,");
    fi;
  elif IsTransformation(x) then
    if not DegreeOfTransformation(x) <= Size(S) then
      ErrorNoReturn("Semigroups: LeftTranslation (from transformation): \n",
            "the second argument must act on the indices of the underlying ",
            "semigroup of the first argument,");
    fi;
    semiList := AsListCanonical(S);
    if ForAny(reps,
              s -> ForAny(S,
                          t -> semiList[PositionCanonical(S, s) ^ x] * t <>
                          semiList[PositionCanonical(S, s * t) ^ x])) then
      ErrorNoReturn("Semigroups: LeftTranslation: \n",
            "the transformation given must define a left translation,");
    fi;
  else
    ErrorNoReturn("Semigroups: LeftTranslation: \n",
          "the first argument should be a left translations semigroup, and ",
          "the second argument should be a mapping on the underlying ",
          "semigroup of the first argument, or a transformation on the ",
          "indices of its elements,");
  fi;
  return LeftTranslationNC(L, x);
end);

InstallGlobalFunction(LeftTranslationNC,
function(L, x)
  local S, tup, semiList, mapAsTransList, i;
  S := UnderlyingSemigroup(L);
  if IsLeftTranslationOfNormalRMSSemigroup(L) then
    tup := SEMIGROUPS.LeftTransToNormalRMSTuple(S, x);
    return LeftTranslationOfNormalRMSNC(L, tup[1], tup[2]);
  fi;
  if IsTransformation(x) then
    return Objectify(TypeLeftTranslationsSemigroupElements(L), [x]);
  fi;
  # x is a mapping on UnderlyingSemigroup(S)
  semiList        := AsListCanonical(S);
  mapAsTransList  := [];
  for i in [1 .. Length(semiList)] do
    mapAsTransList[i] := PositionCanonical(S, semiList[i] ^ x);
  od;

  return Objectify(TypeLeftTranslationsSemigroupElements(L),
                   [Transformation(mapAsTransList)]);
end);

# Same for right translations.
InstallGlobalFunction(RightTranslation,
function(R, x)
  local S, semiList, reps, L;

  S     := UnderlyingSemigroup(R);
  reps  := [];

  if not (IsRightTranslationsSemigroup(R)) then
    ErrorNoReturn("Semigroups: RightTranslation: \n",
          "the first argument must be a semigroup of right translations,");
    return;
  fi;

  if HasGeneratorsOfSemigroup(S) then
    reps := GeneratorsOfSemigroup(S);
  else
    for L in LClasses(S) do
      Add(reps, Representative(L));
    od;
  fi;

  if IsGeneralMapping(x) then
    if not (S = Source(x) and Source(x) = Range(x)) then
      ErrorNoReturn("Semigroups: RightTranslation (from Mapping): \n",
            "the domain and range of the second argument must be ",
            "the underlying semigroup of the first,");
    fi;
    if ForAny(reps, s -> ForAny(S, t -> t * (s ^ x) <> (t * s) ^ x)) then
      ErrorNoReturn("Semigroups: RightTranslation: \n",
             "the mapping given must define a right translation,");
    fi;
  elif IsTransformation(x) then
    if not DegreeOfTransformation(x) <= Size(S) then
      ErrorNoReturn("Semigroups: RightTranslation (from transformation): \n",
            "the second argument must act on the indices of the underlying ",
            "semigroup of the first argument,");
    fi;
    semiList := AsListCanonical(S);
    if ForAny(reps,
              s -> ForAny(S, t ->
                            t * semiList[PositionCanonical(S, s) ^ x]
                              <> semiList[PositionCanonical(S, t * s) ^ x])) then
      ErrorNoReturn("Semigroups: RightTranslation: \n",
            "the transformation given must define a right translation,");
    fi;
  else
    ErrorNoReturn("Semigroups: RightTranslation: \n",
          "the first argument should be a right translations semigroup, and ",
          "the second argument should be a mapping on the underlying ",
          "semigroup of the first argument, or a transformation on the ",
          "indices of its elements,");
  fi;
  return RightTranslationNC(R, x);
end);

InstallGlobalFunction(RightTranslationNC,
function(R, x)
  local S, tup, semiList, mapAsTransList, i;
  S := UnderlyingSemigroup(R);
  if IsRightTranslationOfNormalRMSSemigroup(R) then
    tup := SEMIGROUPS.RightTransToNormalRMSTuple(S, x);
    return RightTranslationOfNormalRMSNC(R, tup[1], tup[2]);
  fi;
  if IsTransformation(x) then
    return Objectify(TypeRightTranslationsSemigroupElements(R), [x]);
  fi;
  # x is a mapping on UnderlyingSemigroup(S)
  semiList        := AsListCanonical(S);
  mapAsTransList  := [];
  for i in [1 .. Length(semiList)] do
    mapAsTransList[i] := PositionCanonical(S, semiList[i] ^ x);
  od;

  return Objectify(TypeRightTranslationsSemigroupElements(R),
                   [Transformation(mapAsTransList)]);
end);

# Creates and calculates the elements of the translational hull.
InstallMethod(TranslationalHull, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite],
function(S)
  local H;

  H := TranslationalHullSemigroup(S);
  AsList(H);

  return H;
end);

# Creates the ideal of the translational hull consisting of
# all inner bitranslations
InstallMethod(InnerTranslationalHull, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite],
function(S)
  local A, I, H, L, R, l, r, s;

  I := [];
  H := TranslationalHullSemigroup(S);
  L := LeftTranslationsSemigroup(S);
  R := RightTranslationsSemigroup(S);
  if HasGeneratorsOfSemigroup(S) then
    A := GeneratorsOfSemigroup(S);
  else
    A := S;
  fi;
  for s in A do
    l := LeftTranslationNC(L, MappingByFunction(S, S, x -> s * x));
    r := RightTranslationNC(R, MappingByFunction(S, S, x -> x * s));
    Add(I, BitranslationNC(H, l, r));
  od;
  return Semigroup(I);
end);

# Get the number of bitranslations without necessarily computing them all
InstallMethod(NrBitranslations, "for a semigroup",
[IsEnumerableSemigroupRep and IsFinite and HasGeneratorsOfSemigroup],
function(S)
  return SEMIGROUPS.BitranslationsByGenerators(TranslationalHullSemigroup(S) :
                                               SEMIGROUPS_bitranslat_nr_only);
end);

# Creates a linked pair (l, r) from a left translation l and a right
# translation r, as an element of a translational hull H.
InstallGlobalFunction(Bitranslation,
function(H, l, r)
  local S, L, R, dclasses, lclasses, rclasses, reps, d, i, j, z;

  if not IsTranslationalHull(H) then
    ErrorNoReturn("Semigroups: Bitranslation: \n",
          "the first argument must be a translational hull,");
  fi;

  if not (IsLeftTranslationsSemigroupElement(l) and
            IsRightTranslationsSemigroupElement(r)) then
    ErrorNoReturn("Semigroups: Bitranslation: \n",
          "the second argument must be a left translation ",
          "and the third argument must be a right translation,");
    return;
  fi;

  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroupOfFamily(FamilyObj(l));
  R := RightTranslationsSemigroupOfFamily(FamilyObj(r));

  if HasGeneratorsOfSemigroup(S) then
    reps := GeneratorsOfSemigroup(S);
  else
    dclasses  := DClasses(S);
    reps      := [];
    for d in dclasses do
      lclasses := ShallowCopy(LClasses(d));
      rclasses := ShallowCopy(RClasses(d));
      for i in [1 .. Minimum(Size(lclasses), Size(rclasses)) - 1] do
        z := Representative(Intersection(lclasses[1], rclasses[1]));
        Add(reps, z);
        Remove(lclasses, 1);
        Remove(rclasses, 1);
      od;
      if Size(lclasses) > Size(rclasses) then
        # Size(rclasses) = 1
        for j in [1 .. Size(lclasses)] do
          z := Representative(Intersection(lclasses[1], rclasses[1]));
          Add(reps, z);
          Remove(lclasses, 1);
        od;
      else
        # Size(lclasses) = 1
        for j in [1 .. Size(rclasses)] do
          z := Representative(Intersection(lclasses[1], rclasses[1]));
          Add(reps, z);
          Remove(rclasses, 1);
        od;
      fi;
    od;
  fi;

  if not (UnderlyingSemigroup(L) = S and UnderlyingSemigroup(R) = S) then
      ErrorNoReturn("Semigroups: Bitranslation: \n",
            "each argument must have the same underlying semigroup,");
  fi;

  if ForAny(reps, t -> ForAny(reps, s -> s * (t ^ l) <> (s ^ r) * t)) then
     ErrorNoReturn("Semigroups: Bitranslation: \n",
           "the translations given must form a linked pair,");
  fi;

  return BitranslationNC(H, l, r);
end);

InstallGlobalFunction(BitranslationNC,
function(H, l, r)
  return Objectify(TypeBitranslations(H), [l, r]);
end);

#############################################################################
# 3. Methods for rectangular bands
#############################################################################

# For rectangular bands, don't calculate AsList for LeftTranslations
# Just get generators
InstallMethod(LeftTranslations, "for a rectangular band",
[IsEnumerableSemigroupRep and IsFinite and IsRectangularBand],
function(S)
  local L;

  L := LeftTranslationsSemigroup(S);
  GeneratorsOfSemigroup(L);

  return L;
end);

# For rectangular bands, don't calculate AsList for RightTranslations
# Just get generators
InstallMethod(RightTranslations, "for a rectangular band",
[IsEnumerableSemigroupRep and IsFinite and IsRectangularBand],
function(S)
  local R;

  R := RightTranslationsSemigroup(S);
  GeneratorsOfSemigroup(R);

  return R;
end);

# For rectangular bands, don't calculate AsList for TranslationalHull
# Just get generators
InstallMethod(TranslationalHull, "for a rectangular band",
[IsEnumerableSemigroupRep and IsFinite and IsRectangularBand],
function(S)
  local H;

  H := TranslationalHullSemigroup(S);
  GeneratorsOfSemigroup(H);

  return H;
end);

# Every transformation on the relevant index set corresponds to a translation.
# The R classes of an I x J rectangular band correspond to (i, J) for i in I.
# Dually for L classes.
InstallMethod(Size,
"for the semigroup of left or right translations of a rectangular band",
[IsTranslationsSemigroup and IsWholeFamily], 2,
function(T)
  local S, n;
  S := UnderlyingSemigroup(T);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;
  if IsLeftTranslationsSemigroup(T) then
    n := NrRClasses(S);
  else
    n := NrLClasses(S);
  fi;

  return n ^ n;
end);

# The translational hull of a rectangular band is the direct product of the
# left translations and right translations
InstallMethod(Size, "for the translational hull of a rectangular band",
[IsTranslationalHull and IsWholeFamily],
1,
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
InstallMethod(GeneratorsOfSemigroup,
"for the semigroup of left or right translations of a rectangular band",
[IsTranslationsSemigroup and IsWholeFamily],
2,
function(T)
  local S, n, iso, inv, reesMatSemi, gens, t, f;
  S := UnderlyingSemigroup(T);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;

  iso         := IsomorphismReesMatrixSemigroup(S);
  inv         := InverseGeneralMapping(iso);
  reesMatSemi := Range(iso);
  if IsLeftTranslationsSemigroup(T) then
    n := Length(Rows(reesMatSemi));
  else
    n := Length(Columns(reesMatSemi));
  fi;

  gens := [];
  for t in GeneratorsOfMonoid(FullTransformationMonoid(n)) do
    if IsLeftTranslationsSemigroup(T) then
      f := function(x)
        return ReesMatrixSemigroupElement(reesMatSemi, x[1] ^ t,
          (), x[3]);
      end;
      Add(gens, LeftTranslationNC(T, CompositionMapping(inv,
      MappingByFunction(reesMatSemi, reesMatSemi, f), iso)));
    else
      f := function(x)
        return ReesMatrixSemigroupElement(reesMatSemi, x[1],
          (), x[3] ^ t);
      end;
      Add(gens, RightTranslationNC(T, CompositionMapping(inv,
        MappingByFunction(reesMatSemi, reesMatSemi, f), iso)));
    fi;
  od;
  return gens;
end);

# Generators of translational hull are the direct product of
# generators of left/right translations semigroup for rectangular bands
# since they are monoids
InstallMethod(GeneratorsOfSemigroup,
"for the translational hull of a rectangular band",
[IsTranslationalHull],
2,
function(H)
  local S, leftGens, rightGens, l, r, gens;

  S := UnderlyingSemigroup(H);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;

  leftGens  := GeneratorsOfSemigroup(LeftTranslationsSemigroup(S));
  rightGens := GeneratorsOfSemigroup(RightTranslationsSemigroup(S));
  gens      := [];

  for l in leftGens do
    for r in rightGens do
      Add(gens, BitranslationNC(H, l, r));
    od;
  od;

  return gens;
end);

#############################################################################
# 4. Methods for monoids
#############################################################################

# Translations of a monoid are all inner translations
InstallMethod(LeftTranslations, "for a monoid",
[IsEnumerableSemigroupRep and IsMonoid and IsFinite],
function(S)
  local L;
  L := LeftTranslationsSemigroup(S);
  if not HasGeneratorsOfSemigroup(L) then
    SetGeneratorsOfSemigroup(L,
                            GeneratorsOfSemigroup(InnerLeftTranslations(S)));
  fi;
  return L;
end);

InstallMethod(RightTranslations, "for a monoid",
[IsEnumerableSemigroupRep and IsMonoid and IsFinite],
function(S)
  local R;
  R := RightTranslationsSemigroup(S);
  if not HasGeneratorsOfSemigroup(R) then
    SetGeneratorsOfSemigroup(R,
                            GeneratorsOfSemigroup(InnerRightTranslations(S)));
  fi;
  return R;
end);

# Translational hull of a monoid is inner translational hull
InstallMethod(TranslationalHull, "for a monoid",
[IsEnumerableSemigroupRep and IsMonoid and IsFinite],
function(S)
  local H;
  H := TranslationalHullSemigroup(S);
  if not HasGeneratorsOfSemigroup(H) then
    SetGeneratorsOfSemigroup(H,
                            GeneratorsOfSemigroup(InnerTranslationalHull(S)));
  fi;
  return H;
end);

InstallMethod(Size, "for a semigroup of left/right translations of a monoid",
[IsTranslationsSemigroup and IsWholeFamily],
1,
function(T)
  if not IsMonoid(UnderlyingSemigroup(T)) then
    TryNextMethod();
  fi;
  return Size(UnderlyingSemigroup(T));
end);

InstallMethod(Size, "for a translational hull of a monoid",
[IsTranslationalHull and IsWholeFamily],
1,
function(H)
  if not IsMonoid(UnderlyingSemigroup(H)) then
    TryNextMethod();
  fi;
  return Size(UnderlyingSemigroup(H));
end);

#############################################################################
# 5. Technical methods
#############################################################################

InstallMethod(AsList, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  if HasGeneratorsOfSemigroup(T) then
    return Immutable(AsList(Semigroup(GeneratorsOfSemigroup(T))));
  fi;
  return Immutable(AsList(SEMIGROUPS.TranslationsSemigroupElements(T)));
end);

InstallMethod(AsList, "for a translational hull",
[IsTranslationalHull and IsWholeFamily],
function(H)
  return Immutable(AsList(SEMIGROUPS.Bitranslations(H)));
end);

InstallMethod(Size, "for a semigroups of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  return Size(AsList(T));
end);

InstallMethod(Size, "for a translational hull",
[IsTranslationalHull and IsWholeFamily],
function(H)
  return Size(AsList(H));
end);

InstallMethod(Representative, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  local S;
  S := UnderlyingSemigroup(T);
  if IsLeftTranslationsSemigroup(T) then
    return LeftTranslation(T, MappingByFunction(S, S, x -> x));
  else
    return RightTranslation(T, MappingByFunction(S, S, x -> x));
  fi;
end);

InstallMethod(Representative, "for a translational hull",
[IsTranslationalHull and IsWholeFamily],
function(H)
  local L, R, S;
  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroup(S);
  R := RightTranslationsSemigroup(S);
  return Bitranslation(H, Representative(L), Representative(R));
end);

InstallMethod(ViewObj, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  Print("<the semigroup of");
  if IsLeftTranslationsSemigroup(T) then Print(" left");
    else Print(" right");
  fi;
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
    " generator");
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

InstallMethod(PrintObj, "for a subsemigroup of a translational hull",
[IsTranslationalHull],
function(H)
  Print("<semigroups of translational hull elements over ",
        ViewString(UnderlyingSemigroup(H)), ">");
end);

InstallMethod(ViewObj, "for a translational hull element",
[IsBitranslation], PrintObj);

InstallMethod(PrintObj, "for a translational hull element",
[IsBitranslation],
function(t)
  local H;
  H := TranslationalHullOfFamily(FamilyObj(t));
  Print("<linked pair of translations on ",
        ViewString(UnderlyingSemigroup(H)), ">");
end);

# Note the order of multiplication
InstallMethod(\*, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslationsSemigroupElement, IsLeftTranslationsSemigroupElement],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [y![1] * x![1]]);
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
  return Objectify(FamilyObj(x)!.type, [x![1] * y![1]]);
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
  local S;
  if IsLeftTranslationsSemigroupElement(t) then
    S := UnderlyingSemigroup(LeftTranslationsSemigroupOfFamily(FamilyObj(t)));
  else
    S := UnderlyingSemigroup(RightTranslationsSemigroupOfFamily(FamilyObj(t)));
  fi;
  if not x in S then
    ErrorNoReturn("Semigroups: ^ for a semigroup element and translation: \n",
                  "the first argument must be an element of the domain of the",
                  " second,");
  fi;
  return EnumeratorCanonical(S)[PositionCanonical(S, x) ^ t![1]];
end);

InstallMethod(\*, "for translation hull elements (linked pairs)",
IsIdenticalObj,
[IsBitranslation, IsBitranslation],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [x![1] * y![1], x![2] * y![2]]);
end);

InstallMethod(\=, "for translational hull elements (linked pairs)",
IsIdenticalObj,
[IsBitranslation, IsBitranslation],
function(x, y)
  return x![1] = y![1] and x![2] = y![2];
end);

InstallMethod(\<, "for translational hull elements (linked pairs)",
IsIdenticalObj,
[IsBitranslation, IsBitranslation],
function(x, y)
  return x![1] < y![1] or (x![1] = y![1] and x![2] < y![2]);
end);

InstallMethod(UnderlyingSemigroup,
"for a semigroup of left or right translations",
[IsTranslationsSemigroup],
function(T)
  if IsLeftTranslationsSemigroup(T) then
    return UnderlyingSemigroup(LeftTranslationsSemigroupOfFamily(
                                                                ElementsFamily(
                                                                FamilyObj(T))));
  else
    return UnderlyingSemigroup(RightTranslationsSemigroupOfFamily(
                                                                ElementsFamily(
                                                                FamilyObj(T))));
  fi;
end);

InstallMethod(UnderlyingSemigroup,
"for a subsemigroup of the translational hull",
[IsTranslationalHull],
function(H)
    return UnderlyingSemigroup(TranslationalHullOfFamily(ElementsFamily(
                                                        FamilyObj(H))));
end);

InstallMethod(ChooseHashFunction, "for a left or right translation and int",
[IsTranslationsSemigroupElement, IsInt],
function(x, hashlen)
  return rec(func := SEMIGROUPS.HashFunctionForTranslations,
             data := hashlen);
end);

InstallMethod(ChooseHashFunction, "for a translational hull element and int",
[IsBitranslation, IsInt],
function(x, hashlen)
  return rec(func := SEMIGROUPS.HashFunctionForBitranslations,
             data := hashlen);
end);

InstallMethod(OneOp, "for a translational hull",
[IsBitranslation],
function(h)
  local H, L, R, S, l, r;
  H := TranslationalHullOfFamily(FamilyObj(h));
  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroup(S);
  R := RightTranslationsSemigroup(S);
  l := LeftTranslation(L, MappingByFunction(S, S, x -> x));
  r := RightTranslation(R, MappingByFunction(S, S, x -> x));
  return Bitranslation(H, l, r);
end);

InstallMethod(OneOp, "for a semigroup of translations",
[IsTranslationsSemigroupElement],
function(t)
  local S, T;
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

InstallGlobalFunction(LeftPartOfBitranslation, "for a bitranslation",
function(h)
  if not IsBitranslation(h) then
     ErrorNoReturn("Semigroups: LeftPartOfBitranslation: \n",
                    "the argument must be a bitranslation,");
  fi;
  return h![1];
end);

InstallGlobalFunction(RightPartOfBitranslation, "for a bitranslation",
function(h)
  if not IsBitranslation(h) then
     ErrorNoReturn("Semigroups: RightPartOfBitranslation: \n",
                    "the argument must be a bitranslation,");
  fi;
  return h![2];
end);

InstallMethod(IsWholeFamily, "for a collection of translations",
[IsTranslationsSemigroupElementCollection],
function(C)
  local L, S, T, t;

  t := Representative(C);
  L := IsLeftTranslationsSemigroupElement(t);

  if L then
    T := LeftTranslationsSemigroupOfFamily(FamilyObj(t));
  else
    T := RightTranslationsSemigroupOfFamily(FamilyObj(t));
  fi;

  S := UnderlyingSemigroup(T);

  if not HasSize(T) or
          IsRectangularBand(S) or
          IsSimpleSemigroup(S) or
          IsZeroSimpleSemigroup(S) or
          IsMonoidAsSemigroup(S) then
    TryNextMethod();
  fi;

  return Size(T) = Size(C);
end);

InstallMethod(IsWholeFamily, "for a collection of bitranslations",
[IsBitranslationCollection],
function(C)
  local b, H, S;
  b := Representative(C);
  H := TranslationalHullOfFamily(FamilyObj(b));
  S := UnderlyingSemigroup(H);

  if not HasSize(H) or
          IsRectangularBand(S) or
          IsMonoidAsSemigroup(S) then
    TryNextMethod();
  fi;

  return Size(H) = Size(C);
end);
