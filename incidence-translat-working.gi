#############################################################################
##
#W  standard/incidence-translat.tst
#Y  Copyright (C) 2016-17                                          Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

SEMIGROUPS.BitranslationsOfCongruenceFreeSemi2 := function(mat)
  local rows, m, n, rownumbers, rowsbycontainment, emptyrow, isPartialSuccess, isFullSuccess, extend, reject, bt, v, x, inv, invnumber, translist, i, j;
  rows := ShallowCopy(mat);
  m := Length(rows);
  n := Length(rows[1]);

  rows := List(rows, x -> BlistList([1 .. n], Positions(x, ())));
  rownumbers := Concatenation([1], List(rows, x -> NumberBlist(x)));
  Sort(rownumbers);
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
    local invblock;
    for i in rowsbycontainment[x[Length(x)]] do
      invblock := UnionBlist(inv{ListBlist([1 .. n], rows[i])});
      if not ForAny(rows, y -> IsSubsetBlist(y, invblock)) then
        return false;
      fi;
    od;
    return true;
  end;

  isFullSuccess := function(x)
    local rowlist;
    for i in [1 .. m] do
      rowlist := ListBlist([1 .. n], rows[i]);
      if not Sum(invnumber{rowlist}) - Size(rowlist) + 1 in rownumbers then
        return false;
      fi;
    od;
    return true;
  end;

  extend := function(w)
    local k;
    Add(w, 1);
    k := Length(w);
    inv[1][k] := true;
    invnumber[1] := invnumber[1] + 2^(n - k);
  end;

  reject := function(q)
    local k;
    # return the next list to consider
    k := Length(q);
    inv[q[k]][k] := false;
    invnumber[q[k]] := invnumber[q[k]] - 2^(n - k);
    if q[k] <= n then
      q[k] := q[k] + 1;
      inv[q[k]][k] := true;
      invnumber[q[k]] := invnumber[q[k]] + 2^(n - k);
    elif k > 1 then
      q := reject(q{[1 .. k - 1]});
    else return 0;
    fi;
    return q;
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
    od;
    return x;
  end;

  v           := 1;
  x           := [];
  inv         := List([1 .. n + 1], x -> List([1 .. n], y -> false));
  invnumber   := List([1 .. n + 1], x -> 1);
  translist   := [];
  extend(x);
  x := bt(x);
  while x <> 0 do
    if isFullSuccess(x) then
      Add(translist, Transformation(Concatenation(ShallowCopy(x), [n + 1])));
    fi;
    x := bt(reject(x));
  od;
  return translist;
end;
