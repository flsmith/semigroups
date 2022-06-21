#############################################################################
##
# W  translat.gi
# Y  Copyright (C) 2015-22                     James D. Mitchell, Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##
##
#############################################################################
## This file contains methods for dealing with left and right translation
## semigroups, as well as translational hulls.
##
## Some of the implementation in this file was based on the implementation of
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

SEMIGROUPS.HasEasyTranslationsGenerators := function(T)
  local S;

  S := UnderlyingSemigroup(T);
  return IsZeroSimpleSemigroup(S) or
         IsRectangularBand(S) or
         IsSimpleSemigroup(S) or
         SEMIGROUPS.IsNormalRMSOverGroup(S) or
         IsMonogenicSemigroup(S) or
         IsMonoid(S);
end;

SEMIGROUPS.HasEasyBitranslationsGenerators := function(T)
  local S;

  S := UnderlyingSemigroup(T);
  return IsRectangularBand(S) or
         IsMonogenicSemigroup(S);
end;

# Hash translations by their underlying transformations
SEMIGROUPS.HashFunctionForTranslations := function(x, data)
  return ORB_HashFunctionForPlainFlatList(x![1], data);
end;

# Hash bitranslations as sum of underlying transformation hashes
SEMIGROUPS.HashFunctionForBitranslations := function(x, data)
    return (SEMIGROUPS.HashFunctionForTranslations(x![1], data)
      + SEMIGROUPS.HashFunctionForTranslations(x![2], data)) mod data + 1;
end;

SEMIGROUPS.LeftAutoTranslations := function(mult_table, reps_pos)
  local n, m, D, x, vertex_cols, edge_cols, g, s;
  n := Size(mult_table);
  m := Size(reps_pos);
  D := Digraph(IsMutableDigraph, []);
  DigraphAddVertices(D, n);
  for g in reps_pos do
    for s in [1 .. Size(mult_table)] do
      x := mult_table[s][g];
      DigraphAddEdge(D, [s, x]);
    od;
  od;
  vertex_cols := fail;
  edge_cols := List([1 .. n], x -> [1 .. m]);
  MakeImmutable(D);
  if IsMultiDigraph(D) then
    return Range(Projection(AutomorphismGroup(D, vertex_cols, edge_cols), 1));
  else
    return AutomorphismGroup(D, vertex_cols, edge_cols);
  fi;
end;

SEMIGROUPS.RightAutoTranslations := function(mult_table, reps_pos)
  local n, m, D, x, vertex_cols, edge_cols, g, s;
  n := Size(mult_table);
  m := Size(reps_pos);
  D := Digraph(IsMutableDigraph, []);
  DigraphAddVertices(D, n);
  for g in reps_pos do
    for s in [1 .. Size(mult_table)] do
      x := mult_table[g][s];
      DigraphAddEdge(D, [s, x]);
    od;
  od;
  vertex_cols := fail;
  edge_cols := List([1 .. n], x -> [1 .. m]);
  MakeImmutable(D);
  if IsMultiDigraph(D) then
    return Range(Projection(AutomorphismGroup(D, vertex_cols, edge_cols), 1));
  else
    return AutomorphismGroup(D, vertex_cols, edge_cols);
  fi;
end;

SEMIGROUPS.AutoBitranslations := function(mult_table, reps_pos)
  local G, left_proj, right_proj, foo;
  G := DirectProduct(SEMIGROUPS.LeftAutoTranslations(mult_table, reps_pos),
                     SEMIGROUPS.RightAutoTranslations(mult_table, reps_pos));
  left_proj := Projection(G, 1);
  right_proj := Projection(G, 2);
  foo := x -> ForAll(reps_pos,
                     i -> ForAll(reps_pos,
                                 j -> mult_table[i][j ^ (x ^ left_proj)] =
                                      mult_table[i ^ (x ^ right_proj)][j]));
  return SubgroupByProperty(G, foo);
end;

SEMIGROUPS.LeftTranslationsBacktrackData := function(S)
  local n, m, id, repspos, multtable, multsets, r_classes, r_class_map,
  r_class_inv_map, r_classes_below, max_R_intersects, intersect, reps,
  left_canon_inverse_by_gen, left_inverses_by_rep, x, right_inverses, seen, t,
  s, transposed_multtable, transposed_multsets, U, Ui, keep, B, sb, r, i, j, a,
  u;

  n       := Size(S);
  reps    := UnderlyingRepresentatives(LeftTranslations(S));
  m       := Size(reps);
  id      := n + 1;
  repspos := List(reps, x -> PositionCanonical(S, x));

  multtable := List(MultiplicationTableWithCanonicalPositions(S), ShallowCopy);
  for i in [1 .. n] do
    Add(multtable[i], i);
  od;
  Add(multtable, [1 .. id]);

  multsets := List(multtable, Set);

  r_classes := RClasses(S);
  r_class_map := [];

  for i in [1 .. Length(r_classes)] do
    for s in r_classes[i] do
      r_class_map[PositionCanonical(S, s)] := i;
    od;
  od;

  r_class_inv_map := List(r_classes,
                          x -> PositionCanonical(S, Representative(x)));
  r_classes_below := List([1 .. m], i -> Set(r_class_map{multsets[repspos[i]]}));
  max_R_intersects := List([1 .. m], x -> []);

  for i in [1 .. m - 1] do
    for j in [i + 1 .. m] do
      intersect := Intersection(r_classes_below[i], r_classes_below[j]);
      reps := r_class_inv_map{intersect};

      max_R_intersects[i][j] := Filtered(reps,
                                         x -> not ForAny(reps,
                                                         y -> x <> y and
                                                           x in multsets[y]));

      max_R_intersects[j][i] := max_R_intersects[i][j];
    od;
  od;

  left_canon_inverse_by_gen := List([1 .. n], x -> []);

  # for all s in S, store the elements t such that reps[i] * t = s for each i
  left_inverses_by_rep := List([1 .. n], x -> List([1 .. m], y -> []));
  for i in [1 .. m] do
    for t in [1 .. id] do
      x := multtable[repspos[i]][t];
      Add(left_inverses_by_rep[x][i], t);
      if not IsBound(left_canon_inverse_by_gen[x][i]) then
        left_canon_inverse_by_gen[x][i] := t;
      fi;
    od;
  od;

  # for each t in the left inverses of some a in max_R_intersects[i][j] by
  # reps[j], compute the right inverses of each s in S under t
  right_inverses := List([1 .. n], x -> ListWithIdenticalEntries(n + 1, fail));
  seen := List([1 .. id], x -> false);
  for i in [1 .. m] do
    for j in [1 .. m] do
      if i = j then
        continue;
      fi;
      for a in max_R_intersects[i][j] do
        t := left_canon_inverse_by_gen[a][j];
        # don't repeat the calculation if we've already done it for t!
        if not seen[t] then
          seen[t] := true;
          for u in [1 .. n] do
            s := multtable[u][t];
            if right_inverses[s][t] = fail then
              right_inverses[s][t] := [];
            fi;
            Add(right_inverses[s][t], u);
          od;
        fi;
      od;
    od;
  od;

  transposed_multtable := TransposedMat(multtable);
  transposed_multsets  := List(transposed_multtable, Set);

  # compute intersection over a of the sets U_{i, a} from the paper
  U := [];
  for i in [1 .. m] do
    Ui := BlistList([1 .. n], []);
    for s in [1 .. n] do
      if Ui[s] then
        continue;
      fi;
      keep := true;
      for a in multsets[repspos[i]] do
        B := left_inverses_by_rep[a][i];
        sb := multtable[s][B[1]];
        if multtable[s]{B} <> ListWithIdenticalEntries(Size(B), sb) then
          keep := false;
          break;
        fi;
      od;
      if keep then
        UniteBlistList([1 .. n], Ui, transposed_multsets[s]);
        Ui[s] := true;
      fi;
    od;
    U[i] := ListBlist([1 .. n], Ui);
  od;

  r := rec();
  r.left_canon_inverse_by_gen := left_canon_inverse_by_gen;
  r.left_inverses_by_rep := left_inverses_by_rep;
  r.max_R_intersects := max_R_intersects;
  r.multsets := multsets;
  r.multtable := multtable;
  r.n := n;
  r.right_inverses := right_inverses;
  r.U := U;
  r.V := List([1 .. m], j -> List([1 .. n], a -> []));
  r.W := List([1 .. m], i -> List([1 .. m], j -> []));
  return r;
end;

SEMIGROUPS.RightInversesLeftReps := function(S)
  local n, reps, m, multtable, out, k, x, i, t;

  n         := Size(S);
  reps      := UnderlyingRepresentatives(LeftTranslations(S));
  m         := Size(reps);
  multtable := MultiplicationTableWithCanonicalPositions(S);
  out       := List([1 .. n], x -> List([1 .. m], y -> []));

  for i in [1 .. m] do
    k := PositionCanonical(S, reps[i]);
    for t in [1 .. n] do
      x := multtable[t][k];
      Add(out[x][i], t);
    od;
  od;
  return out;
end;

SEMIGROUPS.LeftInversesRightReps := function(S)
  local n, reps, m, multtable, out, k, x, i, t;

  n         := Size(S);
  reps      := UnderlyingRepresentatives(RightTranslations(S));
  m         := Size(reps);
  multtable := MultiplicationTableWithCanonicalPositions(S);
  out       := List([1 .. n], x -> List([1 .. m], y -> []));

  for i in [1 .. m] do
    k := PositionCanonical(S, reps[i]);
    for t in [1 .. n] do
      x := multtable[k][t];
      Add(out[x][i], t);
    od;
  od;
  return out;
end;

SEMIGROUPS.RightTranslationsBacktrackData := function(S)
  local n, m, id, repspos, transpose_multtable, transpose_multsets, l_classes,
  l_class_map, l_class_inv_map, l_classes_below, max_L_intersects, intersect,
  reps, right_canon_inverse_by_gen, right_inverses_by_rep, x, left_inverses,
  seen, s, multsets, T, Ti, keep, B, sb, r, i, j, t, a, u, multtable;

  n       := Size(S);
  reps    := UnderlyingRepresentatives(RightTranslations(S));
  m       := Size(reps);
  id      := n + 1;
  repspos := List(reps, x -> PositionCanonical(S, x));

  transpose_multtable :=
    List(TransposedMultiplicationTableWithCanonicalPositions(S),
         ShallowCopy);
  for i in [1 .. n] do
    Add(transpose_multtable[i], i);
  od;
  Add(transpose_multtable, [1 .. id]);
  transpose_multsets := List(transpose_multtable, Set);

  multtable := TransposedMat(transpose_multtable);  # For the added identity

  l_classes := LClasses(S);
  l_class_map := [];

  for i in [1 .. Length(l_classes)] do
    for s in l_classes[i] do
      l_class_map[PositionCanonical(S, s)] := i;
    od;
  od;

  l_class_inv_map := List(l_classes,
                          x -> PositionCanonical(S, Representative(x)));
  l_classes_below := List([1 .. m],
                      i -> Set(l_class_map{transpose_multsets[repspos[i]]}));
  max_L_intersects := List([1 .. m], x -> []);

  for i in [1 .. m - 1] do
    for j in [i + 1 .. m] do
      intersect := Intersection(l_classes_below[i], l_classes_below[j]);
      reps := l_class_inv_map{intersect};

      max_L_intersects[i][j] := Filtered(reps,
                                  x -> not ForAny(reps,
                                            y -> x <> y and
                                                 x in transpose_multsets[y]));

      max_L_intersects[j][i] := max_L_intersects[i][j];
    od;
  od;

  right_canon_inverse_by_gen := List([1 .. n], x -> []);

  # for all s in S, store the elements t such that t * reps[i] = s for each i
  right_inverses_by_rep := List([1 .. n], x -> List([1 .. m], y -> []));
  for i in [1 .. m] do
    for t in [1 .. id] do
      x := transpose_multtable[repspos[i]][t];
      Add(right_inverses_by_rep[x][i], t);
      if not IsBound(right_canon_inverse_by_gen[x][i]) then
        right_canon_inverse_by_gen[x][i] := t;
      fi;
    od;
  od;

  # for each t in the right inverses of some a in max_L_intersects[i][j] by
  # reps[j], compute the left inverses of each s in S under t
  left_inverses := List([1 .. n], x -> ListWithIdenticalEntries(n + 1, fail));
  seen := List([1 .. id], x -> false);
  for i in [1 .. m] do
    for j in [1 .. m] do
      if i = j then
        continue;
      fi;
      for a in max_L_intersects[i][j] do
        for t in right_inverses_by_rep[a][j] do
          # don't repeat the calculation if we've already done it for t!
          if not seen[t] then
            seen[t] := true;
            for u in [1 .. n] do
              s := transpose_multtable[u][t];
              if left_inverses[s][t] = fail then
                left_inverses[s][t] := [];
              fi;
              Add(left_inverses[s][t], u);
            od;
          fi;
        od;
      od;
    od;
  od;

  multsets := List(multtable, Set);

  T := [];
  for i in [1 .. m] do
    Ti := BlistList([1 .. n], []);
    for s in [1 .. n] do
      if Ti[s] then
        continue;
      fi;
      keep := true;
      for a in transpose_multsets[repspos[i]] do
        B := right_inverses_by_rep[a][i];
        sb := transpose_multtable[s][B[1]];
        if (transpose_multtable[s]{B} <>
            ListWithIdenticalEntries(Size(B), sb)) then
          keep := false;
          break;
        fi;
      od;
      if keep then
        UniteBlistList([1 .. n], Ti, multsets[s]);
        Ti[s] := true;
      fi;
    od;
    T[i] := ListBlist([1 .. n], Ti);
  od;

  r := rec();
  r.left_inverses := left_inverses;
  r.max_L_intersects := max_L_intersects;
  r.n := n;
  r.right_canon_inverse_by_gen := right_canon_inverse_by_gen;
  r.right_inverses_by_rep := right_inverses_by_rep;
  r.transpose_multtable := transpose_multtable;
  r.T := T;
  r.F := List([1 .. m], j -> List([1 .. n], a -> []));
  r.G := List([1 .. m], i -> List([1 .. m], j -> []));
  return r;
end;

SEMIGROUPS.LeftTranslationsBacktrackDataV := function(data, j, a, s)
  local right_inverses, V, C, t;

  if IsBound(data.V[j][a][s]) then
    return data.V[j][a][s];
  fi;

  t              := data.left_canon_inverse_by_gen[a][j];
  C              := right_inverses[s][t];
  right_inverses := data.right_inverses;

  if C = fail then
    V := [];
  else
  fi;
  data.V[j][a][s] := V;
  return V;
end;

SEMIGROUPS.LeftTranslationsBacktrackDataW := function(data, i, j, s)
  local left_canon_inverse_by_gen, multtable, right_inverses, W, r, x, a;

  if IsBound(data.W[i][j][s]) then
    return data.W[i][j][s];
  fi;

  left_canon_inverse_by_gen := data.left_canon_inverse_by_gen;
  multtable := data.multtable;
  right_inverses := data.right_inverses;
  W := [1 .. data.n];
  for a in data.max_R_intersects[i][j] do
    r := left_canon_inverse_by_gen[a][i];
    x := multtable[s][r];
    if right_inverses[x][left_canon_inverse_by_gen[a][j]] = fail then
      W := [];
      break;
    else
      W := Intersection(W,
           right_inverses[x][left_canon_inverse_by_gen[a][j]]);
    fi;
  od;
  data.W[i][j][s] := W;
  return W;
end;

SEMIGROUPS.RightTranslationsBacktrackDataF := function(data, j, a, s)
  local left_inverses, F, C, t;

  if IsBound(data.F[j][a][s]) then
    return data.F[j][a][s];
  fi;

  left_inverses := data.left_inverses;
  F := [1 .. data.n];
  for t in data.right_inverses_by_rep[a][j] do
    C := left_inverses[s][t];
    if C = fail then
      F := [];
      break;
    else
      F := Intersection(F, C);
    fi;
  od;
  data.F[j][a][s] := F;
  return F;
end;

SEMIGROUPS.RightTranslationsBacktrackDataG := function(data, i, j, s)
  local right_canon_inverse_by_gen, transpose_multtable, left_inverses, G, l, x,
  a;

  if IsBound(data.G[i][j][s]) then
    return data.G[i][j][s];
  fi;

  right_canon_inverse_by_gen := data.right_canon_inverse_by_gen;
  transpose_multtable := data.transpose_multtable;
  left_inverses := data.left_inverses;
  G := [1 .. data.n];
  for a in data.max_L_intersects[i][j] do
    l := right_canon_inverse_by_gen[a][i];
    x := transpose_multtable[s][l];
    if left_inverses[x][right_canon_inverse_by_gen[a][j]] = fail then
      G := [];
      break;
    else
      G := Intersection(G,
           left_inverses[x][right_canon_inverse_by_gen[a][j]]);
    fi;
  od;
  data.G[i][j][s] := G;
  return G;
end;

# TODO: possiblefgenvals is superfluous
SEMIGROUPS.LeftTranslationsBacktrack := function(L, opt...)
  local S, n, reps, m, omega_stack, possiblefgenvals, nr_only, nr, data, U, bt,
  lambda, out, i;

  S                 := UnderlyingSemigroup(L);
  n                 := Size(S);
  reps              := UnderlyingRepresentatives(L);
  m                 := Size(reps);
  omega_stack       := List([1 .. m], i -> List([1 .. m], j -> []));
  possiblefgenvals  := List([1 .. m], i -> [1 .. n]);
  nr_only           := opt = ["nr_only"];
  nr                := 0;

  data := SEMIGROUPS.LeftTranslationsBacktrackData(S);
  U := data.U;

  # restrict via the U_{i}
  for i in [1 .. m] do
    IntersectSet(possiblefgenvals[i], U[i]);
  od;

  bt := function(i)
    local consistent, W, s, j;

    for s in omega_stack[i][i] do
      lambda[i] := s;
      if i = m then
        if nr_only then
          nr := nr + 1;
        else
          Add(out, ShallowCopy(lambda));
        fi;
      else
        consistent := true;
        omega_stack[i + 1] := [];
        for j in [i + 1 .. m] do
          W := SEMIGROUPS.LeftTranslationsBacktrackDataW(data, i, j, s);
          omega_stack[i + 1][j] := Intersection(omega_stack[i][j], W);
          if IsEmpty(omega_stack[i + 1][j]) then
            consistent := false;
            break;
          fi;
        od;
        if consistent then
          bt(i + 1);
        fi;
      fi;
    od;
  end;

  omega_stack := [possiblefgenvals];
  lambda := [];
  out := [];
  bt(1);
  Apply(out, x -> LeftTranslationNC(L, x));
  return out;
end;

SEMIGROUPS.LeftTranslationsStabilisedBacktrack := function(L, opt...)
  local S, n, reps, m, omega_stack, possiblefgenvals, stabs, stab_thresh,
  coset_reps, nr_only, nr, multtable, data, U, aut, add_stabilised_lambda, bt,
  lambda, out, i;

  S                 := UnderlyingSemigroup(L);
  n                 := Size(S);
  reps              := UnderlyingRepresentatives(L);
  m                 := Size(reps);
  omega_stack       := List([1 .. m], i -> List([1 .. m], j -> []));
  possiblefgenvals  := List([1 .. m], i -> [1 .. n]);
  stabs             := [];
  stabs[m + 1]      := [];
  stab_thresh       := 20;  # a magic number which seems to be a decent choice
  coset_reps        := [];
  nr_only           := opt = ["nr_only"];
  nr                := 0;

  multtable := MultiplicationTableWithCanonicalPositions(S);

  data := SEMIGROUPS.LeftTranslationsBacktrackDataWithReps(S, reps);
  U := data.U;

  aut := SEMIGROUPS.LeftAutoTranslations(multtable,
                                         List(GeneratorsOfSemigroup(S),
                                              x -> PositionCanonical(S, x)));

  # restrict via the U_{i}
  for i in [1 .. m] do
    IntersectSet(possiblefgenvals[i], U[i]);
  od;

  add_stabilised_lambda := function()
    local stab_depth, it, mult;
    stab_depth := PositionProperty(stabs, x -> Size(x) = 0) - 1;
    if nr_only then
      nr := nr + Product(List(coset_reps{[1 .. stab_depth]}, Length));
    else
      AddSet(out, ShallowCopy(lambda));
      it := IteratorOfCartesianProduct(coset_reps{[1 .. stab_depth]});
      while not IsDoneIterator(it) do
        mult := Product(NextIterator(it));
        AddSet(out, OnTuples(lambda, mult));
      od;
    fi;
  end;

  bt := function(i)
    local stab, big_stab, orbs, reps, consistent, W, s, j;
    if i > 1 then
      stab := stabs[i - 1];
    else
      stab := aut;
    fi;
    big_stab := Size(stab) > stab_thresh;
    if big_stab then
      orbs := Orbits(stab, omega_stack[i][i]);
      reps := List(orbs, x -> x[1]);
    else
      reps := omega_stack[i][i];
    fi;
    for s in reps do
      lambda[i] := s;
      if i = m then
        if big_stab then
          # this is necessary in theory
          stabs[i] := Stabiliser(stab, s);
          coset_reps[i] := RightTransversal(stab, Stabiliser(stab, s));
        else
          stabs[i] := [];
        fi;
        add_stabilised_lambda();
      else
        consistent := true;
        omega_stack[i + 1] := [];
        for j in [i + 1 .. m] do
          W := SEMIGROUPS.LeftTranslationsBacktrackDataW(data, i, j, s);
          omega_stack[i + 1][j] := Intersection(omega_stack[i][j], W);
          if IsEmpty(omega_stack[i + 1][j]) then
            consistent := false;
            break;
          fi;
        od;
        if consistent then
          if big_stab then
            if Size(reps) = 1 then
              stabs[i] := stab;
              coset_reps[i] := [()];
            else
              stabs[i] := Stabiliser(stab, s);
              coset_reps[i] := RightTransversal(stab, stabs[i]);
            fi;
          else
            stabs[i] := [];
            coset_reps[i] := [];
          fi;
          bt(i + 1);
        fi;
      fi;
    od;
  end;

  omega_stack := [possiblefgenvals];
  lambda := [];
  out := [];
  nr := 0;
  bt(1);
  if nr_only then
    return nr;
  fi;
  Apply(out, x -> LeftTranslationNC(LeftTranslations(S), x));
  return out;
end;

SEMIGROUPS.RightTranslationsBacktrack := function(R, opt...)
  local S, reps, n, m, omega_stack, nr_only, nr, data, T, possiblegenvals, bt,
  rho, out, i;

  S           := UnderlyingSemigroup(R);
  reps        := UnderlyingRepresentatives(R);
  n           := Size(S);
  m           := Size(reps);
  omega_stack := List([1 .. m], i -> List([1 .. m], j -> []));
  nr_only     := opt = ["nr_only"];
  nr          := 0;

  data := SEMIGROUPS.RightTranslationsBacktrackData(S);
  T := data.T;

  possiblegenvals := List([1 .. m], i -> [1 .. n]);

  # restrict via the T_{i}
  for i in [1 .. m] do
    IntersectSet(possiblegenvals[i], T[i]);
  od;

  bt := function(i)
    local consistent, G, s, j;
    for s in omega_stack[i][i] do
      rho[i] := s;
      if i = m then
        if nr_only then
          nr := nr + 1;
        else
          Add(out, ShallowCopy(rho));
        fi;
      else
        consistent := true;
        omega_stack[i + 1] := [];
        for j in [i + 1 .. m] do
          G := SEMIGROUPS.RightTranslationsBacktrackDataG(data, i, j, s);
          omega_stack[i + 1][j] := Intersection(omega_stack[i][j], G);
          if IsEmpty(omega_stack[i + 1][j]) then
            consistent := false;
            break;
          fi;
        od;
        if consistent then
          bt(i + 1);
        fi;
      fi;
    od;
  end;

  omega_stack := [possiblegenvals];
  rho := [];
  out := [];
  bt(1);

  if nr_only then
    return nr;
  fi;
  Apply(out, x -> RightTranslationNC(RightTranslations(S), x));
  return out;
end;

SEMIGROUPS.BitranslationsBacktrack := function(H, opt...)
  local S, n, l_reps, r_reps, l_m, r_m, l_repspos, r_repspos, l_omega_stack,
  r_omega_stack, nr_only, nr, multtable, left_data, right_data,
  left_inverses_by_right_rep, right_inverses_by_left_rep, U, T, L, R, l_bt,
  r_bt, lambda, rho, out, i;

  S             := UnderlyingSemigroup(H);
  n             := Size(S);
  l_reps        := UnderlyingRepresentatives(LeftTranslations(S));
  r_reps        := UnderlyingRepresentatives(RightTranslations(S));
  l_m           := Size(l_reps);
  r_m           := Size(r_reps);
  l_repspos     := List(l_reps, x -> PositionCanonical(S, x));
  r_repspos     := List(r_reps, x -> PositionCanonical(S, x));
  l_omega_stack := List([1 .. l_m], i -> List([1 .. l_m], j -> []));
  r_omega_stack := List([1 .. r_m], i -> List([1 .. r_m], j -> []));
  nr_only       := opt = ["nr_only"];
  nr            := 0;

  multtable := MultiplicationTableWithCanonicalPositions(S);

  left_data                   := SEMIGROUPS.LeftTranslationsBacktrackData(S);
  right_data                  := SEMIGROUPS.RightTranslationsBacktrackData(S);
  left_inverses_by_right_rep  := SEMIGROUPS.LeftInversesRightReps(S);
  right_inverses_by_left_rep  := SEMIGROUPS.RightInversesLeftReps(S);

  U := left_data.U;
  T := right_data.T;

  l_omega_stack[1] := List([1 .. l_m], i -> [1 .. n]);
  r_omega_stack[1] := List([1 .. r_m], i -> [1 .. n]);

  # restrict via the T_{i} and U_{i}
  for i in [1 .. l_m] do
    l_omega_stack[1][i] := U[i];
  od;
  for i in [1 .. r_m] do
    r_omega_stack[1][i] := T[i];
  od;

  L := LeftTranslations(S);
  R := RightTranslations(S);

  l_bt := function(i)
    local depth, r_finished, consistent, W, x, s, j;

    if i <= r_m then
      depth := 2 * i - 1;
    else
      depth := r_m + i;
    fi;

    r_finished := i > r_m;

    for s in l_omega_stack[depth][i] do
      lambda[i] := s;

      if r_finished and i = l_m then
        Add(out, BitranslationNC(H,
                                 LeftTranslationNC(L, lambda),
                                 RightTranslationNC(R, rho)));
        continue;
      fi;

      consistent                := true;
      l_omega_stack[depth + 1]  := [];
      r_omega_stack[depth + 1]  := [];

      # make sure to take care of linking condition
      # x_i * lambda(x_i) = (x_i)rho * x_i
      for j in [i .. Maximum(l_m, r_m)] do
        if (j > i and j <= l_m) then
          W := SEMIGROUPS.LeftTranslationsBacktrackDataW(left_data, i, j, s);
          l_omega_stack[depth + 1][j] := Intersection(l_omega_stack[depth][j],
                                                      W);
        fi;

        if j <= r_m then
          x := multtable[r_repspos[j]][s];
          r_omega_stack[depth + 1][j] :=
              Intersection(r_omega_stack[depth][j],
                           right_inverses_by_left_rep[x][i]);
        fi;

        if ((j > i and j <= l_m and IsEmpty(l_omega_stack[depth + 1][j])) or
            (j <= r_m and IsEmpty(r_omega_stack[depth + 1][j]))) then
          consistent := false;
          break;
        fi;
      od;

      if consistent then
        if r_finished then
          l_bt(i + 1);
        else
          # this i is intentional, we go LRLRLR...
          r_bt(i);
        fi;
      fi;
    od;
  end;

  r_bt := function(i)
    local depth, l_finished, consistent, G, x, s, j;

    if i <= l_m then
      depth := 2 * i;
    else
      depth := l_m + i;
    fi;

    l_finished := i >= l_m;

    for s in r_omega_stack[depth][i] do
      rho[i] := s;

      if l_finished and i = r_m then
        Add(out, BitranslationNC(H,
                                 LeftTranslationNC(L, lambda),
                                 RightTranslationNC(R, rho)));
        continue;
      fi;

      consistent := true;
      l_omega_stack[depth + 1] := [];
      r_omega_stack[depth + 1] := [];

      for j in [i + 1 .. Maximum(r_m, l_m)] do
        if j <= r_m then
          G := SEMIGROUPS.RightTranslationsBacktrackDataG(right_data, i, j, s);
          r_omega_stack[depth + 1][j] := Intersection(r_omega_stack[depth][j],
                                                      G);
        fi;

        if j <= l_m then
          x := multtable[s][l_repspos[j]];
          l_omega_stack[depth + 1][j] :=
              Intersection(l_omega_stack[depth][j],
                           left_inverses_by_right_rep[x][i]);
        fi;

        if ((j <= l_m and IsEmpty(l_omega_stack[depth + 1][j])) or
            (j <= r_m and IsEmpty(r_omega_stack[depth + 1][j]))) then
          consistent := false;
          break;
        fi;
      od;

      if consistent then
        if l_finished then
          r_bt(i + 1);
        else
          l_bt(i + 1);
        fi;
      fi;
    od;
  end;

  lambda := [];
  rho := [];
  out := [];
  # Warning: it is assumed that the alternation starts with L; otherwise
  # the depth calculation in l_bt and r_bt must be altered, and some of the
  # logic changed
  l_bt(1);

  if nr_only then
    return nr;
  fi;

  return out;
end;

#############################################################################
# 2. Creation of translations semigroups, translational hull, and elements
#############################################################################

InstallMethod(LeftTranslations, "for a finite enumerable semigroup",
[IsSemigroup and CanUseFroidurePin and IsFinite],
function(S)
  local fam, L, type;

  if HasLeftTranslations(S) then
    return LeftTranslations(S);
  fi;

  if SEMIGROUPS.IsNormalRMSOverGroup(S) then
    fam   := SEMIGROUPS.FamOfRMSLeftTranslationsByTriple();
    type  := fam!.type;
  else
    fam       := NewFamily("LeftTranslationsSemigroupElementsFamily",
                      IsLeftTranslation);
    type      := NewType(fam, IsLeftTranslation);
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

  SetUnderlyingRepresentatives(L, GeneratorsOfSemigroup(S));

  return L;
end);

InstallMethod(RightTranslations, "for a finite enumerable semigroup",
[IsSemigroup and CanUseFroidurePin and IsFinite],
function(S)
  local fam, type, R;

  if HasRightTranslations(S) then
    return RightTranslations(S);
  fi;

  if SEMIGROUPS.IsNormalRMSOverGroup(S) then
    fam   := SEMIGROUPS.FamOfRMSRightTranslationsByTriple();
    type  := fam!.type;
  else
    fam       := NewFamily("RightTranslationsSemigroupElementsFamily",
                      IsRightTranslation);
    type      := NewType(fam, IsRightTranslation);
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

InstallMethod(TranslationalHull, "for a finite enumerable semigroup",
[IsSemigroup and CanUseFroidurePin and IsFinite],
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
  H := Objectify(NewType(CollectionsFamily(fam), IsBitranslationsSemigroup and
    IsWholeFamily and IsAttributeStoringRep), rec());

  # store the type of the elements in the semigroup
  SetTypeBitranslations(H, type);
  SetTranslationalHullOfFamily(fam, H);
  SetUnderlyingSemigroup(H, S);
  SetTranslationalHull(S, H);

  return H;
end);

# Create and calculate the semigroup of inner left translations
InstallMethod(InnerLeftTranslations, "for a semigroup",
[IsSemigroup and CanUseFroidurePin and IsFinite],
function(S)
  local A, I, L, l, s;

  I := [];
  L := LeftTranslations(S);

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

# Create and calculate the semigroup of inner right translations
InstallMethod(InnerRightTranslations, "for a semigroup",
[IsSemigroup and CanUseFroidurePin and IsFinite],
function(S)
  local A, I, R, r, s;

  I := [];
  R := RightTranslations(S);

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
function(L, l)
  local S, reps, semi_list, full_lambda, g, lg, x, y, i, s;

  if not (IsLeftTranslationsSemigroup(L)) then
    ErrorNoReturn("the first argument must be a semigroup of left ",
                  "translations");
  fi;

  S    := UnderlyingSemigroup(L);
  reps := UnderlyingRepresentatives(L);

  # TODO allow general mapping from reps to S
  # In fact, insist on it? Or document that other values are ignored
  if IsGeneralMapping(l) then
    if not (S = Source(l) and Source(l) = Range(l)) then
      ErrorNoReturn("the domain and range of the second argument must be ",
                    "the underlying semigroup of the first");
    fi;
    if ForAny(reps, s -> ForAny(S, t -> (s ^ l) * t <> (s * t) ^ l)) then
      ErrorNoReturn("the mapping given must define a left translation");
    fi;
  elif IsDenseList(l) then
    if not Size(l) = Size(reps) then
      ErrorNoReturn("the second argument must map indices of generators to ",
                    "indices of elements of the semigroup of the first ",
                    "argument");
    fi;
    if not ForAll(l, y -> IsInt(y) and y <= Size(S)) then
      ErrorNoReturn("the second argument must map indices of generators to ",
                    "indices of elements of the semigroup of the first ",
                    "argument");
    fi;
    # TODO store and use MultiplicationTableWithCanonicalPositions and
    # LeftTranslationsBacktrackData
    semi_list := AsListCanonical(S);
    full_lambda := [];
    for i in [1 .. Size(reps)] do
      g := reps[i];
      lg := l[i];
      for s in S do
        x := PositionCanonical(S, g * s);
        y := PositionCanonical(S, semi_list[lg] * s);
        if not IsBound(full_lambda[x]) then
          full_lambda[x] := y;
        fi;
        if full_lambda[x] <> y then
          ErrorNoReturn("the transformation given must define a left ",
                        "translation");
        fi;
      od;
    od;
  else
    ErrorNoReturn("the first argument should be a left translations ",
                  "semigroup, and the second argument should be a mapping ",
                  "on the underlying semigroup of the first argument, or a ",
                  "list of indices of values of the generators under the ",
                  "translation");
  fi;
  return LeftTranslationNC(L, l);
end);

InstallGlobalFunction(LeftTranslationNC,
function(L, l)
  local S, tup, reps, map_as_list, i;
  S := UnderlyingSemigroup(L);
  if IsLeftTranslationOfNormalRMSSemigroup(L) then
    tup := SEMIGROUPS.LeftTransToNormalRMSTuple(S, l);
    return LeftTranslationOfNormalRMSNC(L, tup[1], tup[2]);
  fi;
  if IsDenseList(l) then
    return Objectify(TypeLeftTranslationsSemigroupElements(L),
                    [ShallowCopy(l)]);
  fi;
  # l is a mapping on UnderlyingSemigroup(S)
  reps := UnderlyingRepresentatives(L);
  map_as_list  := [];
  for i in [1 .. Length(reps)] do
    map_as_list[i] := PositionCanonical(S, reps[i] ^ l);
  od;

  return Objectify(TypeLeftTranslationsSemigroupElements(L), [map_as_list]);
end);

# Same for right translations.
InstallGlobalFunction(RightTranslation,
function(R, r)
  local S, reps, semi_list, full_rho, g, rg, x, y, i, s;

  if not (IsRightTranslationsSemigroup(R)) then
    ErrorNoReturn("the first argument must be a semigroup of right ",
                  "translations");
  fi;

  S    := UnderlyingSemigroup(R);
  reps := UnderlyingRepresentatives(R);

  # TODO allow general mapping from reps to S
  if IsGeneralMapping(r) then
    if not (S = Source(r) and Source(r) = Range(r)) then
      ErrorNoReturn("the domain and range of the second argument must be ",
                    "the underlying semigroup of the first");
    fi;
    if ForAny(reps, s -> ForAny(S, t -> s * (t ^ r) <> (s * t) ^ r)) then
      ErrorNoReturn("the mapping given must define a right translation");
    fi;
  elif IsDenseList(r) then
    if not Size(r) = Size(reps) then
      ErrorNoReturn("the second argument must map indices of generators to ",
                    "indices of elements of the semigroup of the first ",
                    "argument");
    fi;
    if not ForAll(r, y -> IsInt(y) and y <= Size(S)) then
      ErrorNoReturn("the second argument must map indices of generators to ",
                    "indices of elements of the semigroup of the first ",
                    "argument");
    fi;
    # TODO store and use MultiplicationTableWithCanonicalPositions and
    # RightTranslationsBacktrackData
    semi_list := AsListCanonical(S);
    full_rho := [];
    for i in [1 .. Size(reps)] do
      g := reps[i];
      rg := r[i];
      for s in S do
        x := PositionCanonical(S, s * g);
        y := PositionCanonical(S, s * semi_list[rg]);
        if not IsBound(full_rho[x]) then
          full_rho[x] := y;
        fi;
        if full_rho[x] <> y then
          ErrorNoReturn("the transformation given must define a right ",
                        "translation");
        fi;
      od;
    od;
  else
    ErrorNoReturn("the first argument should be a right translations ",
                  "semigroup, and the second argument should be a mapping ",
                  "on the underlying semigroup of the first argument, or a ",
                  "list of indices of values of the generators under the ",
                  "translation");
  fi;
  return RightTranslationNC(R, r);
end);

InstallGlobalFunction(RightTranslationNC,
function(R, r)
  local S, tup, reps, map_as_list, i;
  S := UnderlyingSemigroup(R);
  if IsRightTranslationOfNormalRMSSemigroup(R) then
    tup := SEMIGROUPS.RightTransToNormalRMSTuple(S, r);
    return RightTranslationOfNormalRMSNC(R, tup[1], tup[2]);
  fi;
  if IsDenseList(r) then
    return Objectify(TypeRightTranslationsSemigroupElements(R),
                    [ShallowCopy(r)]);
  fi;
  # r is a mapping on UnderlyingSemigroup(S)
  reps := UnderlyingRepresentatives(R);
  map_as_list  := [];
  for i in [1 .. Length(reps)] do
    map_as_list[i] := PositionCanonical(S, reps[i] ^ r);
  od;

  return Objectify(TypeRightTranslationsSemigroupElements(R), [map_as_list]);
end);

# Creates the ideal of the translational hull consisting of
# all inner bitranslations
InstallMethod(InnerTranslationalHull, "for a semigroup",
[IsSemigroup and CanUseFroidurePin and IsFinite],
function(S)
  local A, I, H, L, R, l, r, s;

  I := [];
  H := TranslationalHull(S);
  L := LeftTranslations(S);
  R := RightTranslations(S);
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

# Creates a bitranslation (l, r) from a left translation l and a right
# translation r, as an element of a translational hull H.
InstallGlobalFunction(Bitranslation,
function(H, l, r)
  local S, L, R, l_reps, r_reps;

  if not IsBitranslationsSemigroup(H) then
    ErrorNoReturn("the first argument must be a translational hull");
  fi;

  if not (IsLeftTranslation(l) and
            IsRightTranslation(r)) then
    ErrorNoReturn("the second argument must be a left translation ",
                  "and the third argument must be a right translation");
    return;
  fi;

  S := UnderlyingSemigroup(H);
  L := LeftTranslationsSemigroupOfFamily(FamilyObj(l));
  R := RightTranslationsSemigroupOfFamily(FamilyObj(r));

  if not (UnderlyingSemigroup(L) = S and UnderlyingSemigroup(R) = S) then
      ErrorNoReturn("each argument must have the same underlying semigroup");
  fi;

  l_reps := UnderlyingRepresentatives(L);
  r_reps := UnderlyingRepresentatives(R);

  if ForAny(l_reps, t -> ForAny(r_reps, s -> s * (t ^ l) <> (s ^ r) * t)) then
     ErrorNoReturn("the translations given must satisfy the linking ",
                   "condition");
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
[IsBitranslationsSemigroup and IsWholeFamily],
1,
function(H)
  local S, L, R;
  S := UnderlyingSemigroup(H);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;
  L := LeftTranslations(S);
  R := RightTranslations(S);
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
[IsBitranslationsSemigroup],
2,
function(H)
  local S, leftGens, rightGens, l, r, gens;

  S := UnderlyingSemigroup(H);
  if not IsRectangularBand(S) then
    TryNextMethod();
  fi;

  leftGens  := GeneratorsOfSemigroup(LeftTranslations(S));
  rightGens := GeneratorsOfSemigroup(RightTranslations(S));
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

InstallMethod(GeneratorsOfSemigroup,
"for the left translations of a finite monogenic semigroup",
[IsLeftTranslationsSemigroup and IsWholeFamily],
function(L)
  if not IsMonoid(UnderlyingSemigroup(L)) then
    TryNextMethod();
  fi;
  return GeneratorsOfSemigroup(InnerLeftTranslations(UnderlyingSemigroup(L)));
end);

InstallMethod(GeneratorsOfSemigroup,
"for the right translations of a finite monogenic semigroup",
[IsRightTranslationsSemigroup and IsWholeFamily],
function(R)
  if not IsMonoid(UnderlyingSemigroup(R)) then
    TryNextMethod();
  fi;
  return GeneratorsOfSemigroup(InnerRightTranslations(UnderlyingSemigroup(R)));
end);

InstallMethod(GeneratorsOfSemigroup,
"for the right translations of a finite monogenic semigroup",
[IsBitranslationsSemigroup and IsWholeFamily],
function(H)
  if not IsMonoid(UnderlyingSemigroup(H)) then
    TryNextMethod();
  fi;
  return GeneratorsOfSemigroup(InnerTranslationalHull(UnderlyingSemigroup(H)));
end);

InstallMethod(Size,
"for a semigroup of left/right translations of a monogenic semigroup",
[IsTranslationsSemigroup and IsWholeFamily],
1,
function(T)
  if not IsMonoid(UnderlyingSemigroup(T)) then
    TryNextMethod();
  fi;
  return Size(UnderlyingSemigroup(T));
end);

InstallMethod(Size, "for a translational hull of a monogenic semigroup",
[IsBitranslationsSemigroup and IsWholeFamily],
1,
function(H)
  if not IsMonoid(UnderlyingSemigroup(H)) then
    TryNextMethod();
  fi;
  return Size(UnderlyingSemigroup(H));
end);

#############################################################################
# 5. Methods for monogenic semigroups
#############################################################################

InstallMethod(GeneratorsOfSemigroup,
"for the left translations of a finite monogenic semigroup",
[IsLeftTranslationsSemigroup and IsWholeFamily],
function(L)
  if not IsMonogenicSemigroup(UnderlyingSemigroup(L)) then
    TryNextMethod();
  fi;
  return Union([One(L)],
     GeneratorsOfSemigroup(InnerLeftTranslations(UnderlyingSemigroup(L))));
end);

InstallMethod(GeneratorsOfSemigroup,
"for the right translations of a finite monogenic semigroup",
[IsRightTranslationsSemigroup and IsWholeFamily],
function(R)
  if not IsMonogenicSemigroup(UnderlyingSemigroup(R)) then
    TryNextMethod();
  fi;
  return Union([One(R)],
     GeneratorsOfSemigroup(InnerRightTranslations(UnderlyingSemigroup(R))));
end);

InstallMethod(GeneratorsOfSemigroup,
"for the right translations of a finite monogenic semigroup",
[IsBitranslationsSemigroup and IsWholeFamily],
function(H)
  if not IsMonogenicSemigroup(UnderlyingSemigroup(H)) then
    TryNextMethod();
  fi;
  return Union([One(H)],
     GeneratorsOfSemigroup(InnerTranslationalHull(UnderlyingSemigroup(H))));
end);

InstallMethod(Size,
"for a semigroup of left/right translations of a monogenic semigroup",
[IsTranslationsSemigroup and IsWholeFamily],
1,
function(T)
  if not IsMonogenicSemigroup(UnderlyingSemigroup(T)) then
    TryNextMethod();
  fi;
  return Size(UnderlyingSemigroup(T));
end);

InstallMethod(Size, "for a translational hull of a monogenic semigroup",
[IsBitranslationsSemigroup and IsWholeFamily],
1,
function(H)
  if not IsMonogenicSemigroup(UnderlyingSemigroup(H)) then
    TryNextMethod();
  fi;
  return Size(UnderlyingSemigroup(H));
end);

#############################################################################
# 6. Technical methods
#############################################################################

InstallMethod(UnderlyingRepresentatives,
"for a semigroup of left or right translations",
[IsTranslationsSemigroup],
function(T)
  local S;

  S := UnderlyingSemigroup(T);
  if IsLeftTranslationsSemigroup(T) then
    return List(MaximalRClasses(S), Representative);
  else
    return List(MaximalLClasses(S), Representative);
  fi;
end);

InstallMethod(RepresentativeMultipliers,
"for a semigroup of left translation",
[IsTranslationsSemigroup],
function(T)
  local S, reps, M, out, x, i, j;

  S    := UnderlyingSemigroup(T);
  reps := UnderlyingRepresentatives(T);

  if IsLeftTranslationsSemigroup(T) then
    M := MultiplicationTableWithCanonicalPositions(S);
  else
    M := TransposedMultiplicationTableWithCanonicalPositions(S);
  fi;

  out  := ListWithIdenticalEntries(Length(M), fail);
  for i in [1 .. Length(reps)] do
    x := PositionCanonical(S, reps[i]);
    for j in [1 .. Size(S)] do
      if out[M[x][j]] = fail then
        # store [i, j] instead of [x, j] for efficiency
        out[M[x][j]] := [i, j];
      fi;
    od;
    out[x] := [i, 0];
  od;
  return out;
end);

InstallMethod(AsList, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  # Just use the AsList for semigroups if generators are known
  if SEMIGROUPS.HasEasyTranslationsGenerators(T) then
    TryNextMethod();
  fi;

  if IsLeftTranslationsSemigroup(T) then
    return SEMIGROUPS.LeftTranslationsBacktrack(T);
  else
    return SEMIGROUPS.RightTranslationsBacktrack(T);
  fi;
end);

# TODO: make arguments consistent
InstallMethod(AsList, "for a translational hull",
[IsBitranslationsSemigroup and IsWholeFamily],
function(H)
  local S;

  S := UnderlyingSemigroup(H);
  if SEMIGROUPS.HasEasyBitranslationsGenerators(H) then
    TryNextMethod();
  elif IsReesZeroMatrixSemigroup(S) then
    return SEMIGROUPS.BitranslationsOfRZMS(S);
  elif SEMIGROUPS.IsNormalRMSOverGroup(S) then
    return SEMIGROUPS.BitranslationsOfNormalRMS(S);
  else
    return SEMIGROUPS.BitranslationsBacktrack(H);
  fi;
end);

# TODO: use the nr_only options here
InstallMethod(Size, "for a semigroups of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  return Size(AsList(T));
end);

InstallMethod(Size, "for a translational hull",
[IsBitranslationsSemigroup and IsWholeFamily],
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
[IsBitranslationsSemigroup and IsWholeFamily],
function(H)
  local L, R, S;
  S := UnderlyingSemigroup(H);
  L := LeftTranslations(S);
  R := RightTranslations(S);
  return Bitranslation(H, Representative(L), Representative(R));
end);

InstallMethod(ViewObj, "for a semigroup of left or right translations",
[IsTranslationsSemigroup and IsWholeFamily],
function(T)
  Print("<the semigroup of ");
  if IsLeftTranslationsSemigroup(T) then Print("left ");
    else Print("right ");
  fi;
  Print("translations of ", ViewString(UnderlyingSemigroup(T)), ">");
end);

InstallMethod(ViewObj, "for a semigroup of translations",
[IsTranslationsSemigroup], PrintObj);

InstallMethod(PrintObj, "for a semigroup of translations",
[IsTranslationsSemigroup],
function(T)
  if IsLeftTranslationsSemigroup(T) then
    Print("<left ");
  else
    Print("<right ");
  fi;
  Print("translations semigroup over ",
        ViewString(UnderlyingSemigroup(T)),
        ">");
end);

InstallMethod(ViewObj, "for a translation",
[IsSemigroupTranslation], PrintObj);

InstallMethod(PrintObj, "for a translation",
[IsSemigroupTranslation],
function(t)
  local L, S;
  L := IsLeftTranslation(t);
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
[IsBitranslationsSemigroup], PrintObj);

InstallMethod(PrintObj, "for a translational hull",
[IsBitranslationsSemigroup and IsWholeFamily],
function(H)
  Print("<translational hull over ", ViewString(UnderlyingSemigroup(H)), ">");
end);

InstallMethod(PrintObj, "for a subsemigroup of a translational hull",
[IsBitranslationsSemigroup],
function(H)
  Print("<semigroup of bitranslations over ",
        ViewString(UnderlyingSemigroup(H)), ">");
end);

InstallMethod(ViewObj, "for a bitranslation",
[IsBitranslation], PrintObj);

InstallMethod(PrintObj, "for a bitranslation",
[IsBitranslation],
function(t)
  local H;
  H := TranslationalHullOfFamily(FamilyObj(t));
  Print("<bitranslation on ", ViewString(UnderlyingSemigroup(H)), ">");
end);

# Note the order of multiplication
InstallMethod(\*, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslation, IsLeftTranslation],
function(x, y)
  local L, S, prod, i;
  L := LeftTranslationsSemigroupOfFamily(FamilyObj(x));
  S := UnderlyingSemigroup(L);
  prod := [];
  for i in [1 .. Size(UnderlyingRepresentatives(L))] do
    prod[i] := PositionCanonical(S, EnumeratorCanonical(S)[y![1][i]] ^ x);
  od;
  return Objectify(FamilyObj(x)!.type, [prod]);
end);

InstallMethod(\=, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslation, IsLeftTranslation],
function(x, y)
  return x![1] = y![1];
end);

InstallMethod(\<, "for left translations of a semigroup",
IsIdenticalObj,
[IsLeftTranslation, IsLeftTranslation],
function(x, y)
  return x![1] < y![1];
end);

# Different order of multiplication
InstallMethod(\*, "for right translations of a semigroup",
IsIdenticalObj,
[IsRightTranslation, IsRightTranslation],
function(x, y)
  local R, S, prod, i;
  R := RightTranslationsSemigroupOfFamily(FamilyObj(x));
  S := UnderlyingSemigroup(R);
  prod := [];
  for i in [1 .. Size(UnderlyingRepresentatives(R))] do
    prod[i] := PositionCanonical(S, EnumeratorCanonical(S)[x![1][i]] ^ y);
  od;
  return Objectify(FamilyObj(x)!.type, [prod]);
end);

InstallMethod(\=, "for right translations of a semigroup",
IsIdenticalObj,
[IsRightTranslation, IsRightTranslation],
function(x, y)
  return x![1] = y![1];
end);

InstallMethod(\<, "for right translations of a semigroup",
IsIdenticalObj,
[IsRightTranslation, IsRightTranslation],
function(x, y)
  return x![1] < y![1];
end);

InstallMethod(\^, "for a semigroup element and a left translation",
[IsAssociativeElement, IsSemigroupTranslation],
function(x, t)
  local T, S, M, enum, y;

  if IsLeftTranslation(t) then
    T := LeftTranslationsSemigroupOfFamily(FamilyObj(t));
    S := UnderlyingSemigroup(T);
    M := MultiplicationTableWithCanonicalPositions(S);
  else
    T := RightTranslationsSemigroupOfFamily(FamilyObj(t));
    S := UnderlyingSemigroup(T);
    M := TransposedMultiplicationTableWithCanonicalPositions(S);
  fi;
  if not x in S then
    ErrorNoReturn("the first argument must be an element of the domain of ",
                  "the second");
  fi;
  enum := EnumeratorCanonical(S);
  x := PositionCanonical(S, x);
  y := RepresentativeMultipliers(T)[x];
  if y[2] = 0 then
    return enum[t![1][y[1]]];
  else
    return enum[M[t![1][y[1]]][y[2]]];
  fi;
end);

SEMIGROUPS.ImagePositionsOfTranslation := function(x)
  local T, S, tab, images, g;
  if IsLeftTranslation(x) then
    T := LeftTranslationsSemigroupOfFamily(FamilyObj(x));
    S := UnderlyingSemigroup(T);
    tab := MultiplicationTableWithCanonicalPositions(S);
  else
    T := RightTranslationsSemigroupOfFamily(FamilyObj(x));
    S := UnderlyingSemigroup(T);
    tab := TransposedMultiplicationTableWithCanonicalPositions(S);
  fi;
  images := [];
  for g in UnderlyingRepresentatives(T) do
    UniteSet(images, tab[PositionCanonical(S, g ^ x)]);
  od;
  return images;
end;

InstallMethod(ImageOfTranslation, "for a left or right translation",
[IsSemigroupTranslation],
function(x)
  local T, S, enum;
  if IsLeftTranslation(x) then
    T := LeftTranslationsSemigroupOfFamily(FamilyObj(x));
    S := UnderlyingSemigroup(T);
  else
    T := RightTranslationsSemigroupOfFamily(FamilyObj(x));
    S := UnderlyingSemigroup(T);
  fi;
  enum := EnumeratorCanonical(S);
  return Set(List(SEMIGROUPS.ImagePositionsOfTranslation(x), i -> enum[i]));
end);

InstallMethod(\*, "for bitranslations",
IsIdenticalObj,
[IsBitranslation, IsBitranslation],
function(x, y)
  return Objectify(FamilyObj(x)!.type, [x![1] * y![1], x![2] * y![2]]);
end);

InstallMethod(\=, "for bitranslations",
IsIdenticalObj,
[IsBitranslation, IsBitranslation],
function(x, y)
  return x![1] = y![1] and x![2] = y![2];
end);

InstallMethod(\<, "for bitranslations",
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
[IsBitranslationsSemigroup],
function(H)
    return UnderlyingSemigroup(TranslationalHullOfFamily(ElementsFamily(
                                                        FamilyObj(H))));
end);

InstallMethod(ChooseHashFunction, "for a left or right translation and int",
[IsSemigroupTranslation, IsInt],
function(x, hashlen)
  return rec(func := SEMIGROUPS.HashFunctionForTranslations,
             data := hashlen);
end);

InstallMethod(ChooseHashFunction, "for a bitranslation and int",
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
  L := LeftTranslations(S);
  R := RightTranslations(S);
  l := LeftTranslation(L, MappingByFunction(S, S, x -> x));
  r := RightTranslation(R, MappingByFunction(S, S, x -> x));
  return Bitranslation(H, l, r);
end);

InstallMethod(OneOp, "for a semigroup of translations",
[IsSemigroupTranslation],
function(t)
  local S, T;
  if IsLeftTranslation(t) then
    T := LeftTranslationsSemigroupOfFamily(FamilyObj(t));
    S := UnderlyingSemigroup(T);
    return LeftTranslation(T, MappingByFunction(S, S, x -> x));
  else
    T := RightTranslationsSemigroupOfFamily(FamilyObj(t));
    S := UnderlyingSemigroup(T);
    return RightTranslation(T, MappingByFunction(S, S, x -> x));
  fi;
end);

# TODO: why is this a global function?
InstallGlobalFunction(LeftPartOfBitranslation,
function(h)
  if not IsBitranslation(h) then
     ErrorNoReturn("the argument must be a bitranslation");
  fi;
  return h![1];
end);

InstallGlobalFunction(RightPartOfBitranslation,
function(h)
  if not IsBitranslation(h) then
     ErrorNoReturn("the argument must be a bitranslation");
  fi;
  return h![2];
end);

InstallMethod(IsWholeFamily, "for a collection of translations",
[IsSemigroupTranslationCollection],
function(C)
  local L, S, T, t;

  t := Representative(C);
  L := IsLeftTranslation(t);

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
