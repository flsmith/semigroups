############################################################################
##
#W  boolean.gi
#Y  Copyright (C) 2015                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains an implementation of boolean matrices.

# A boolean matrix <mat> is a positional object where mat![i] is the i-th row
# of the matrix, and it is a blist in blist rep.

#############################################################################
## Internal
#############################################################################

SEMIGROUPS.HashFunctionBooleanMat := function(x, data)
  local n, h, i, j;

  n := DimensionOfMatrixOverSemiring(x);
  h := 0;
  for i in [1 .. n] do
    for j in [1 .. n] do
      if x[i][j] then
        h := ((h * 2) + 1) mod data;
      else
        h := (h * 2) mod data;
      fi;
    od;
  od;
  return h + 1;
end;

SEMIGROUPS.HashFunctionBMat8 := function(x, data)
  return (BMAT8_TO_INT(x![2]) mod data) + 1;
end;

SEMIGROUPS.SetBooleanMat := function(x)
  local n, out, i;
  n := Length(x![1]);
  out := EmptyPlist(n);
  for i in [1 .. n] do
    out[i] := NumberBlist(x![i]) + (i - 1) * 2 ^ n;
  od;
  return out;
end;

SEMIGROUPS.BooleanMatSet := function(set)
  local n, x, i;
  n := Length(set);
  x := EmptyPlist(n);
  for i in [1 .. n] do
    x[i] := BlistNumber(set[i] - (i - 1) * 2 ^ n, n);
  od;
  return BooleanMat(x);
end;

#############################################################################
## Specializations of methods for MatrixOverSemiring
#############################################################################

InstallMethod(SEMIGROUPS_TypeViewStringOfMatrixOverSemiring,
"for a boolean matrix",
[IsBooleanMat], x -> "boolean");

InstallMethod(SEMIGROUPS_FilterOfMatrixOverSemiring,
"for a boolean matrix",
[IsBooleanMat], x -> IsBooleanMat);

InstallMethod(SEMIGROUPS_TypeOfMatrixOverSemiringCons,
"for IsBooleanMat",
[IsBooleanMat], x -> BooleanMatType);

InstallGlobalFunction(BooleanMat,
function(mat)
  local i, j, n, type, x;
  
  type := BooleanMatType;
  n := Length(mat);
  if n <= 8 then
    type := BMat8Type;
  fi;

  if (not IsPList(mat)) or IsEmpty(mat)
      or not ForAll(mat, IsHomogeneousList) then
    ErrorNoReturn("Semigroups: BooleanMat: usage,\n",
                  "the argument must be a non-empty plain list ",
                  "of homogeneous lists,");
  elif IsRectangularTable(mat) then #0s and 1s or blists
    n := Length(mat);
    if not Size(mat[1]) = n then
        ErrorNoReturn("Semigroups: BooleanMat: usage,\n",
                      "the argument must represent a ",
                      "square matrix,");
    fi;
    if ForAll(mat, row -> ForAll(row, x -> x = 0 or x = 1)) then
      # 0s and 1s
      if n <= 8 then
        x := BMAT8_NEW();
        for i in [1 .. n] do
          for j in [1 .. n] do
            if mat[i][j] = 1 then
              BMAT8_SET(x, i, j, true);
            fi;
          od;
        od;
      else
        x := BOOLEAN_MAT_NEW(List(mat, 
                row -> BlistList(PositionsProperty(row, x -> x = 1))));
      fi;
      return Objectify(type, [n, x]);
    elif ForAll(mat, row -> ForAll(row, x -> x = true or x = false)) then
      #blists
      if n <= 8 then
        x := BMAT8_NEW();
        for i in [1 .. n] do
          for j in [1 .. n] do
            BMAT8_SET(x, i, j, mat[i][j]);
          od;
        od;
      else
        x := BOOLEAN_MAT_NEW(mat); 
      fi;
      return Objectify(type, [n, x]);
    fi;
  fi;
  
  # mat is a list of successors
  n := Length(mat);
  if not ForAll(mat, x -> ForAll(x, y -> IsPosInt(y) and y <= n)) then
    ErrorNoReturn("Semigroups: BooleanMat:\n",
                  "the entries of each list must not exceed ", n, ",");
  fi;
 
  if n <= 8 then
    x := BMAT8_NEW();
    for i in [1 .. n] do
      for j in mat[i] do
        BMAT8_SET(x, i, j, true);
      od;
    od;
  else 
    x := BOOLEAN_MAT_NEW(List(mat, row -> BlistList(row)));
  fi;
  return Objectify(type, [n, x]);
end);

InstallMethod(\*, "for boolean matrices", [IsBooleanMat, IsBooleanMat],
function(x, y)
  return Objectify(BooleanMatType, [DimensionOfMatrixOverSemiring(x),
                   BOOLEAN_MAT_MULTIPLY(x![2], y![2])]);
end);

InstallMethod(\<, "for boolean matrices",
[IsBooleanMat, IsBooleanMat],
function(x, y)
  return BOOLEAN_MAT_LT(x![2], y![2]);
end);

InstallMethod(\=, "for boolean matrices",
[IsBooleanMat, IsBooleanMat],
function(x, y)
  return BOOLEAN_MAT_EQ(x![2], y![2]);
end);

InstallMethod(ELM_LIST, "for boolean matrices",
[IsBooleanMat, IsPosInt],
function(x, i)
  return List([1 .. DimensionOfMatrixOverSemiring(x)], j -> BOOLEAN_MAT_GET(x![2], i, j));
end);

InstallMethod(OneImmutable, "for a boolean mat",
[IsBooleanMat],
function(x)
  return Objectify(BooleanMatType, [DimensionOfMatrixOverSemiring(x), BOOLEAN_MAT_ONE(x)]);;
end);

InstallMethod(TransposedMat, "for a boolean mat",
[IsBooleanMat],
function(x)
  return Objectify(BooleanMatType, [DimensionOfMatrixOverSemiring(x), BOOLEAN_MAT_TRANSPOSE(x)]);
end);

InstallMethod(DimensionOfMatrixOverSemiring, "for a boolean mat",
[IsBooleanMat],
function(x)
  return x![1];
end);

InstallMethod(RandomMatrixCons, "for boolean matrices and a pos int",
[IsBooleanMat, IsPosInt],
function(filter, n)
  if n <= 8 then
    return Objectify(BMat8Type, [n, BMAT8_RANDOM(n)]);
  fi;
end);

InstallMethod(\*, "for BMat8 representatives of boolean matrices",
[IsLibsemigroupsBMat8Rep, IsLibsemigroupsBMat8Rep],
function(x, y)
  return Objectify(BMat8Type, [DimensionOfMatrixOverSemiring(x),
                   BMAT8_MULTIPLY(x![2], y![2])]);
end);

InstallMethod(\<, "for BMat8 representatives of boolean matrices",
[IsLibsemigroupsBMat8Rep, IsLibsemigroupsBMat8Rep],
function(x, y)
  return BMAT8_LT(x![2], y![2]);
end);

InstallMethod(\=, "for BMat8 representatives of boolean matrices",
[IsLibsemigroupsBMat8Rep, IsLibsemigroupsBMat8Rep],
function(x, y)
  return BMAT8_EQ(x![2], y![2]);
end);

InstallMethod(ELM_LIST, "for BMat8 representatives of boolean matrices",
[IsLibsemigroupsBMat8Rep, IsPosInt],
function(x, i)
  return List([1 .. DimensionOfMatrixOverSemiring(x)], j -> BMAT8_GET(x![2], i, j));
end);

InstallMethod(OneImmutable, "for a BMat8 represenative of a boolean matix",
[IsLibsemigroupsBMat8Rep],
function(x)
  local i, one;
  one := BMAT8_ONE(x![2]); 
  for i in [1 .. 8 - DimensionOfMatrixOverSemiring(x)] do
    BMAT8_SET(one, 9 - i, 9 - i, false);
  od;
  return Objectify(BMat8Type, [DimensionOfMatrixOverSemiring(x), one]);;
end);

InstallMethod(TransposedMat, "for BMat8 representatives of boolean matrices",
[IsLibsemigroupsBMat8Rep],
function(x)
  return Objectify(BMat8Type, [DimensionOfMatrixOverSemiring(x), BMAT8_TRANSPOSE(x)]);
end);

#############################################################################
## Special methods for Boolean matrices
#############################################################################

InstallMethod(\in, "for a boolean mat and boolean mat",
[IsBooleanMat, IsBooleanMat],
function(x, y)
  local n, i, j;

  n := Length(x![1]);

  if n <> Length(y![1]) then
    ErrorNoReturn("Semigroups: \\in: usage,\n",
                  "the arguments <x> and <y> must be boolean matrices ",
                  "of equal dimensions,");
  fi;

  for i in [1 .. n] do
    for j in [1 .. n] do
      if x![i][j] and not y![i][j] then
        return false;
      fi;
    od;
  od;

  return true;
end);

InstallGlobalFunction(OnBlist,
function(blist1, x)
  local n, blist2, i, j;

  n := Length(blist1);
  blist2 := BlistList([1 .. n], []);

  for i in [1 .. n] do
    for j in [1 .. n] do
      blist2[i] := blist2[i] or (blist1[j] and x![j][i]);
    od;
  od;
  return blist2;
end);

InstallMethod(Successors, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n;
  n := Length(x![1]);
  return List([1 .. n], i -> ListBlist([1 .. n], x![i]));
end);

InstallMethod(IsRowTrimBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, i, j;

  n := Length(x![1]);
  for i in [1 .. n - 1] do
    for j in [i + 1 .. n] do
      if IsSubsetBlist(x![i], x![j]) then
        return false;
      fi;
    od;
  od;
  return true;
end);

InstallMethod(IsColTrimBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, contained, row, i, j, k;

  n := Length(x![1]);
  for i in [1 .. n - 1] do
    for j in [i + 1 .. n] do
      contained := true;
      for k in [1 .. n] do
        row := x![k];
        if (row[j] and not row[i]) then
          contained := false;
          break;
        fi;
      od;
      if contained then
        return false;
      fi;
    od;
  od;
  return true;
end);

InstallMethod(IsTrimBooleanMat, "for a boolean matrix",
[IsBooleanMat], x -> IsRowTrimBooleanMat(x) and IsColTrimBooleanMat(x));

InstallMethod(DisplayString, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, str, i, j;

  n := DimensionOfMatrixOverSemiring(x);
  str := "";
  for i in [1 .. n] do
    for j in [1 .. n] do
      if x![i][j] then
        Append(str, String(1));
      else
        Append(str, String(0));
      fi;
      Append(str, " ");
    od;
    Remove(str, Length(str));
    Append(str, "\n");
  od;
  return str;
end);

InstallMethod(NumberBooleanMat, "for a boolean mat", [IsBooleanMat],
function(x)
  local n, nr, i, j;

  n := DimensionOfMatrixOverSemiring(x);
  nr := 0;
  for i in [1 .. n] do
    for j in [1 .. n] do
      if x![i][j] then
        nr := 2 * nr + 1;
      else
        nr := 2 * nr;
      fi;
    od;
  od;
  return nr + 1;   # to be in [1 .. 2 ^ (n ^ 2)]
end);

InstallMethod(BooleanMatNumber,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(nr, deg)
  local x, q, i, j;

  x := List([1 .. deg], x -> BlistList([1 .. deg], []));
  nr := nr - 1;   # to be in [0 .. 2 ^ (deg ^ 2) - 1]
  for i in [deg, deg - 1 .. 1] do
    for j in [deg, deg - 1 .. 1] do
      q := nr mod 2;
      if q = 0 then
        x[i][j] := false;
      else
        x[i][j] := true;
      fi;
      nr := (nr - q) / 2;
    od;
  od;
  return MatrixNC(BooleanMatType, x);
end);

InstallGlobalFunction(NumberBlist,
function(blist)
  local n, nr, i;
  n := Length(blist);
  nr := 0;
  for i in [1 .. n] do
    if blist[i] then
      nr := 2 * nr + 1;
    else
      nr := 2 * nr;
    fi;
  od;
  return nr + 1;   # to be in [1 .. 2 ^ n]
end);

InstallGlobalFunction(BlistNumber,
function(nr, n)
  local x, q, i;

  x := BlistList([1 .. n], []);
  nr := nr - 1;   # to be in [0 .. 2 ^ n - 1]
  for i in [n, n - 1 .. 1] do
    q := nr mod 2;
    if q = 0 then
      x[i] := false;
    else
      x[i] := true;
    fi;
    nr := (nr - q) / 2;
  od;
  return x;
end);

InstallMethod(AsDigraph, "for a boolean matrix",
[IsBooleanMat],
function(mat)
  return DigraphByAdjacencyMatrix(AsList(mat));
end);

InstallMethod(AsBooleanMat, "for a digraph",
[IsDigraph],
function(digraph)
  local n, out, mat, X, i;

  n   := DigraphNrVertices(digraph);
  out := OutNeighbours(digraph);

  return BooleanMat(out);
end);

InstallMethod(AsBooleanMat, "for a partitioned binary relation",
[IsPBR], x -> AsBooleanMat(x, 2 * DegreeOfPBR(x)));

InstallMethod(AsBooleanMat, "for a partitioned binary relation and pos int",
[IsPBR, IsPosInt],
function(x, n)
  local y, i;

  y := EmptyPlist(n);
  for i in [2 .. 2 * x![1] + 1] do
    Add(y, BlistList([1 .. n], x![i]));
  od;
  for i in [2 * x![1] + 1 .. n] do
    Add(y, BlistList([1 .. n], []));
  od;

  return BooleanMat(y);
end);

InstallMethod(AsBooleanMat, "for a bipartition",
[IsBipartition], x -> AsBooleanMat(x, 2 * DegreeOfBipartition(x)));

InstallMethod(AsBooleanMat, "for a bipartition and pos int",
[IsBipartition, IsPosInt],
function(x, n)
  local deg, blocks, out, i, block;

  deg := DegreeOfBipartition(x);
  blocks := ShallowCopy(ExtRepOfObj(x));
  out := EmptyPlist(n);

  for block in blocks do
    block := ShallowCopy(block);
    for i in [1 .. Length(block)] do
      if block[i] < 0 then
        block[i] := -block[i] + deg;
      fi;
    od;
    for i in block do
      out[i] := BlistList([1 .. n], block);
    od;
  od;

  for i in [Length(out) + 1 .. n] do
    out[i] := BlistList([1 .. n], []);
  od;

  return BooleanMat(out);
end);

InstallMethod(AsBooleanMat, "for a transformation",
[IsTransformation], x -> AsBooleanMat(x, DegreeOfTransformation(x)));

InstallMethod(AsBooleanMat, "for a transformation and pos int",
[IsTransformation, IsPosInt],
function(x, n)
  local out, i;
  if ForAny([1 .. n], i -> i ^ x > n) then
    ErrorNoReturn("Semigroups: AsBooleanMat: usage,\n",
                  "the transformation in the first argument must map ",
                  "[1 .. ", String(n), "] to itself,");
  fi;

  out := List([1 .. n], x -> BlistList([1 .. n], []));
  for i in [1 .. n] do
    out[i][i ^ x] := true;
  od;
  return BooleanMat(out);
end);

InstallMethod(AsBooleanMat, "for a perm",
[IsPerm], x -> AsBooleanMat(AsTransformation(x)));

InstallMethod(AsBooleanMat, "for a perm",
[IsPerm, IsPosInt],
function(x, n)
  return AsBooleanMat(AsTransformation(x), n);
end);

InstallMethod(AsBooleanMat, "for a partial perm",
[IsPartialPerm],
x -> AsBooleanMat(x, Maximum(DegreeOfPartialPerm(x),
                             CodegreeOfPartialPerm(x))));

#TODO this could be more elaborate, i.e. it could take a set, then just take
# the restriction of <x> to that set as a Boolean matrix
InstallMethod(AsBooleanMat, "for a transformation and pos int",
[IsPartialPerm, IsPosInt],
function(x, n)
  local out, j, i;

  if ForAny([1 .. n], i -> i ^ x > n) then
    ErrorNoReturn("Semigroups: AsBooleanMat: usage,\n",
                  "the partial perm in the first argument must map ",
                  "[1 .. ", String(n), "] into itself,");
  fi;

  out := List([1 .. n], x -> BlistList([1 .. n], []));
  for i in [1 .. n] do
    j := i ^ x;
    if j <> 0 then
      out[i][j] := true;
    fi;
  od;
  #TODO: OK? Is out in BlistRep?
  return MatrixNC(BooleanMatType, out);
end);

InstallMethod(AsBooleanMat, "for a boolean mat and IsPosInt",
[IsBooleanMat, IsPosInt],
function(mat, m)
  local n, out, i;

  n := Length(mat![1]);
  if m < n then
    return MatrixNC(BooleanMatType,
                    List([1 .. m], i -> mat![i]{[1 .. m]}));
  fi;
  #TODO use AsList
  out := List([1 .. n], i -> ShallowCopy(mat![i]));
  for i in [1 .. n] do
    Append(out[i], BlistList([n + 1 .. m], []));
  od;
  for i in [n + 1 .. m] do
    Add(out, BlistList([1 .. m], []));
  od;
  #TODO: OK? Is out in BlistRep?
  return MatrixNC(BooleanMatType, out);
end);

# TODO AsBooleanMat for a BooleanMat

InstallMethod(ChooseHashFunction, "for a boolean matrix",
[IsBooleanMat, IsInt],
  function(x, hashlen)
  return rec(func := SEMIGROUPS.HashFunctionBooleanMat,
             data := hashlen);
end);

InstallMethod(ChooseHashFunction, "for a BMat8 representation of a boolean matrix",
[IsLibsemigroupsBMat8Rep, IsInt],
function(x, hashlen)
  return rec(func := SEMIGROUPS.HashFunctionBMat8, data := hashlen);
end);

InstallMethod(CanonicalBooleanMat, "for boolean mat",
[IsBooleanMat],
function(mat)
  local _AsDigraph, _AsBooleanMat, gr, colors, p;

  # convert a boolean mat to a bipartite graph with all edges pointing in the
  # same direction (so that we may act on the rows and columns independently).
  _AsDigraph := function(mat)
    local n, out, ver, row, i, j;

    n := Length(mat![1]);
    out := List([1 .. 2 * n], x -> []);
    ver := [1 .. n];
    for i in ver do
      row := mat![i];
      for j in ver do
        if row[j] then
          Add(out[i], j + n);
        fi;
      od;
    od;
    return DigraphNC(out);
  end;

  # convert a digraph (of the type created by _AsDigraph above) back into a
  # boolean mat.
  _AsBooleanMat := function(digraph)
    local n, ver, out, mat, i;

    n := DigraphNrVertices(digraph) / 2;
    ver := [1 .. n];
    out := OutNeighbours(digraph);
    mat := EmptyPlist(n);

    for i in ver do
      mat[i] := BlistList(ver, out[i] - n);
    od;

    return MatrixNC(BooleanMatType, mat);
  end;

  # convert mat to a bipartite graph
  gr := _AsDigraph(mat);

  # calculate a canonical representative of the digraph, use colors to prevent
  # the two sets of vertices in the bipartite graph from being swapped (which
  # corresponds to swapping rows and columns of the Boolean matrix.
  colors := Concatenation([1 .. Length(mat![1])] * 0 + 1,
                          [1 .. Length(mat![1])] * 0 + 2);

  p  := BlissCanonicalLabelling(gr, colors);
  return _AsBooleanMat(OnDigraphs(gr, p));
end);

InstallMethod(CanonicalBooleanMat, "for perm group and boolean mat",
[IsPermGroup, IsBooleanMat],
function(G, x)
  if IsNaturalSymmetricGroup(G) and MovedPoints(G) = [1 .. Length(x![1])] then
    return CanonicalBooleanMat(x);
  fi;
  return CanonicalBooleanMat(G, G, x);
end);

InstallMethod(CanonicalBooleanMat, "for perm group and boolean mat",
[IsPermGroup, IsPermGroup, IsBooleanMat],
function(G, H, x)
  local n;
  n := Length(x![1]);
  if LargestMovedPoint(G) > n or LargestMovedPoint(H) > n then
    ErrorNoReturn("Semigroups: CanonicalBooleanMat: usage,\n",
                  "the largest moved point of the first argument must not",
                  " exceed the dimension\nof the Boolean matrix,");
  elif G = H and IsNaturalSymmetricGroup(G)
      and MovedPoints(G) = [1 .. n] then
    return CanonicalBooleanMat(x);
  fi;
  return CanonicalBooleanMatNC(G, H, x);
end);

#FIXME The following could be done without SmallestImageSet using vertex
# colors. Not sure how.

InstallMethod(CanonicalBooleanMatNC,
"for perm group, perm group, and boolean mat",
[IsPermGroup, IsPermGroup, IsBooleanMat],
function(G, H, x)
  local n, V, phi, act, map;
  n := Length(x![1]);
  V := DirectProduct(G, H);
  phi := Projection(V, 2);

  act := function(pt, p)
    local q, r, nr;
    pt := pt - 1;
    q := QuoInt(pt, 2 ^ n); # row
    r := pt - q * 2 ^ n;    # number blist of the row
                            # permute columns
    nr := NumberBlist(Permuted(BlistNumber(r + 1, n), p));
    return nr + ((q + 1) ^ (p ^ phi) - 1) * 2 ^ n; # and then the row
  end;

   map := ActionHomomorphism(V, [1 .. n * 2 ^ n], act);
   return SEMIGROUPS.BooleanMatSet(SmallestImageSet(Image(map),
                                   SEMIGROUPS.SetBooleanMat(x)));
end);

InstallMethod(IsSymmetricBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, i, j;
  n := Length(x![1]);
  for i in [1 .. n - 1] do
    for j in [i + 1 .. n] do
      if x![i][j] <> x![j][i] then
        return false;
      fi;
    od;
  od;
  return true;
end);

InstallMethod(IsReflexiveBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, i;
  n := Length(x![1]);
  for i in [1 .. n] do
    if not x![i][i] then
      return false;
    fi;
  od;
  return true;
end);

InstallMethod(IsTransitiveBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, i, j, k;
  n := [1 .. Length(x![1])];
  for i in n do
    for j in n do
      for k in n do
        if x![i][k] and x![k][j] and not x![i][j] then
          return false;
        fi;
      od;
    od;
  od;
  return true;
end);

InstallMethod(IsAntiSymmetricBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, i, j;
  n := Length(x![1]);
  for i in [1 .. n - 1] do
    for j in [i + 1 .. n] do
      if x![i][j] and x![j][i] then
        return false;
      fi;
    od;
  od;
  return true;
end);

InstallMethod(IsTotalBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  local n, i;
  n := Length(x![1]);
  for i in [1 .. n] do
    if SizeBlist(x![i]) = 0 then
      return false;
    fi;
  od;
  return true;
end);

InstallMethod(IsOntoBooleanMat, "for a boolean matrix",
[IsBooleanMat],
function(x)
  return IsTotalBooleanMat(TransposedMat(x));
end);
