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
  local rows, m, n, isPartialSuccess, isFullSuccess, extend, reject, bt, v, x, inv, translist;
  rows := ShallowCopy(mat);
  m := Length(rows);
  n := Length(rows[1]);

  rows := List(rows, x -> BlistList([1 .. n], Positions(x, 1)));
  
  isPartialSuccess := function(x)
    local invblock, row;
    for row in rows do
      invblock := UnionBlist(inv{ListBlist([1 .. n], row)});
      if not ForAny(rows, y -> IsSubsetBlist(y, invblock)) then
        return false;
      fi;
    od;
    return true;
  end;

  isFullSuccess := function(x)
    local invblock, row;
    for row in rows do
      invblock := UnionBlist(inv{ListBlist([1 .. n], row)});
      if ForAny(invblock, x -> x) then
        if not ForAny(rows, y -> y = invblock) then
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
    inv[1][k] := true;
  end;

  reject := function(q)
    local k;
    # return the next list to consider
    k := Length(q);
    inv[q[k]][k] := false;
    if q[k] <= n then
      q[k] := q[k] + 1;
      inv[q[k]][k] := true;
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
