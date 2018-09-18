#############################################################################
##
#W  standard/incidence-translat.tst
#Y  Copyright (C) 2016-17                                          Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

SEMIGROUPS.BitranslationsOfCongruenceFreeSemi := function(mat)
  local rows, m, n, rowsbycontainment, emptyrow, isPartialSuccess, isFullSuccess, extend, reject, restrict, bt, preimages, possiblerows, restrictionatstage, translist, v, x, i, j;
  rows := ShallowCopy(mat);
  m := Length(rows);
  n := Length(rows[1]);

  rows := List(rows, x -> BlistList([1 .. n], Positions(x, ())));
  rowsbycontainment := List([1 .. n + 1], x -> []);
  emptyrow := List([1 .. n], x -> false);
  for i in [1 .. m] do
    for j in [1 .. n] do
      if rows[i][j] then
        Add(rowsbycontainment[j], i);
      fi;
    od;
  od;
  
  isPartialSuccess := function(x)
    for i in rowsbycontainment[x[Length(x)]] do
      if Length(possiblerows[i]) = 0 then
        return false;
      fi;
    od;
    return true;
  end;

  isFullSuccess := function(x)
    local found;
    for i in [1 .. m] do
      if preimages[i] <> emptyrow then
        found := false;
        for j in possiblerows[i] do
          if rows[j] = preimages[i] then
            found := true;
          fi;
        od;
        if not found then
          return false;
        fi;
      fi;
    od;
    return true;
  end;

  extend := function(w)
    local k;
    Add(w, 1);
    k := Length(w);
    for i in rowsbycontainment[1] do
      preimages[i][k] := true;
    od;
  end;

  reject := function(q)
    local k;
    if x = 0 then
      return 0;
    fi;
    k := Length(q);
    for i in rowsbycontainment[q[k]] do
      preimages[i][k] := false;
      if restrictionatstage[k][i] <> 0 then
        UniteSet(possiblerows[i], restrictionatstage[k][i]);
      fi;
      restrictionatstage[k][i] := 0;
    od;
    if q[k] <= n then
      q[k] := q[k] + 1;
      for i in rowsbycontainment[q[k]] do
        preimages[i][k] := true;
      od;
    elif k > 1 then
      q := reject(q{[1 .. k - 1]});
    else return 0;
    fi;
    return q;
  end;

  restrict := function(x)
    local k;
    if x = 0 then
      return 0;
    fi;
    k := Length(x);
    for i in rowsbycontainment[x[k]] do
      restrictionatstage[k][i] := Difference(possiblerows[i], rowsbycontainment[k]);
      IntersectSet(possiblerows[i], rowsbycontainment[k]);
      if Length(possiblerows[i]) = 0 then
        return fail;
      fi;
    od;
    return true;
  end;

  bt := function(x)
    if x = 0 then
      return 0;
    fi;
    while Length(x) < n do
      if isPartialSuccess(x) then
        extend(x);
      else
        x := reject(x);
        if x = 0 then
          return 0;
        fi;
      fi;
      if restrict(x) = fail then
        x := reject(x);
        if x = 0 then
          return 0;
        fi;
      fi;
    od;
    return x;
  end;

  preimages   := List([1 .. m], x -> List([1 .. n], y -> false));
  possiblerows := List([1 .. m], x -> [1 .. m]);
  restrictionatstage := List([1 .. n], x -> List([1 .. m], y -> []));
  translist   := [];

  v           := 1;
  x           := [];
  extend(x);
  restrict(x);
  x := bt(x);
  while x <> 0 do
    if isFullSuccess(x) then
      Add(translist, Transformation(Concatenation(ShallowCopy(x), [n + 1])));
    fi;
    x := reject(x);
    restrict(x);
    x := bt(x);
  od;
  return translist;
end;
