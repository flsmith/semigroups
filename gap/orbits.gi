#############################################################################
##
#W  orbits.gi
#Y  Copyright (C) 2011-12                                James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

#

InstallOtherMethod(EvaluateWord, "for partial perm coll and list pos ints", 
[IsPartialPermCollection, IsList],
function ( gens, w )
    local  i, res, pts;
    if Length( w ) = 0  then
        return One(gens);
    fi;
    res := gens[w[1]];
    for i  in [ 2 .. Length( w ) ]  do
        res := res * gens[w[i]];
    od;
    return res;
end);

#

InstallGlobalFunction(EnumeratePosition, 
"for an orbit, value, and boolean",
function(o, val, onlynew)
  local pos;
  
  if not onlynew then 
    pos:=Position(o, val);
    if pos<>fail or IsClosed(o) then 
      return pos;
    fi;
  fi;
 
  if IsClosed(o) then 
    return fail;
  fi;
  o!.looking:=true;
  o!.lookingfor:=function(o, x) return x=val; end;
  o!.lookfunc:=o!.lookingfor;
  Enumerate(o);
  pos:=PositionOfFound(o);
  o!.found:=false;
  o!.looking:=false;
  Unbind(o!.lookingfor);
  Unbind(o!.lookfunc);
  if pos<>false then 
    return pos;
  fi;
  return fail;
end);

#

InstallGlobalFunction(LookForInOrb, 
"for an orbit, a function, and positive integer",
function(o, func, start)
  local pos, i;
 
  # not including this line means that when considering LambdaOrb(s) 
  # the first point is considered which it shouldn't be. Whatever is broken
  # when this line is not included should be fixed as at present this is not
  # consistent. JDM
  Enumerate(o, Length(o)+1);
  
  if start<=Length(o) then 
    for i in [start..Length(o)] do 
      if func(o, o[i]) then 
        return i;
      fi;
    od;
  fi;

  if IsClosed(o) then 
    return false;
  fi;
  
  o!.looking:=true;
  o!.lookingfor:=func;
  o!.lookfunc:=o!.lookingfor;
  Enumerate(o);
  pos:=PositionOfFound(o);
  o!.found:=false;
  o!.looking:=false;
  Unbind(o!.lookingfor);
  Unbind(o!.lookfunc);
  return pos;
end);

#

InstallGlobalFunction(OrbSCC,
function(o)
  local scc, r, i;

  if IsBound(o!.scc) then 
    return o!.scc;
  fi;

  if not IsClosed(o) then #JDM good idea?
    Enumerate(o, infinity);
  fi;

  scc:=Set(List(STRONGLY_CONNECTED_COMPONENTS_DIGRAPH(OrbitGraphAsSets(o)),
     Set));;
  r:=Length(scc);

  o!.scc:=scc;
  o!.scc_lookup:=ListWithIdenticalEntries(Length(o), 1);

  if r>1 then
    for i in [2..r] do
      o!.scc_lookup{scc[i]}:=ListWithIdenticalEntries(Length(scc[i]), i);
    od;
  fi;

  return scc;
end); 

# new for 0.4! - OrbSCCLookup - "for an orbit"
#############################################################################

InstallGlobalFunction(OrbSCCLookup, 
function(o)

  if IsBound(o!.scc_lookup) then 
    return o!.scc_lookup;
  fi;

  OrbSCC(o);
  return o!.scc_lookup;
end);

# mod for 1.0! - OrbSCCTruthTable - "for an orbit"
#############################################################################

InstallGlobalFunction(OrbSCCTruthTable, 
function(o)
  local scc, r;

  if IsBound(o!.truth) then
    return o!.truth;
  fi;

  scc:=OrbSCC(o); r:=Length(scc);
  o!.truth:=List([1..r], i-> BlistList([1..Length(o)], scc[i]));
  return o!.truth;
end);

#RRR

# new for 0.4! - ReverseSchreierTreeOfSCC - "for an orbit and pos. int."
###########################################################################

InstallGlobalFunction(ReverseSchreierTreeOfSCC,
function(o, i)
  local r, graph, rev, scc, gen, pos, seen, t, oo, j, k, l, m;

  r:=Length(OrbSCC(o));

  if i>r then 
    Error("the orbit only has ", r, " strongly connected components,");
    return;
  fi;

  if not IsBound(o!.reverse) then
    o!.reverse:=EmptyPlist(r);
  fi;
 
  if IsBound(o!.reverse[i]) then
    return o!.reverse[i];
  fi;

  if not IsBound(o!.rev) then
    graph:=OrbitGraph(o);

    rev:=List([1..Length(graph)], x-> List([1..Length(o!.gens)], x-> []));
 
    for j in [1..Length(graph)] do
      for k in [1..Length(graph[j])] do
        if IsBound(graph[j][k]) then
          Add(rev[graph[j][k]][k], j);
          #starting at position j and applying gens[k] we obtain graph[j][k];
        fi;
      od;
    od;

    o!.rev:=rev;
  fi;

  scc:=o!.scc[i]; rev:=o!.rev;
  #gen:=ListWithIdenticalEntries(Length(o), fail);
  #pos:=ListWithIdenticalEntries(Length(o), fail);
  gen:=EmptyPlist(Length(o));
  pos:=EmptyPlist(Length(o));

  gen[scc[1]]:=fail; pos[scc[1]]:=fail;

  seen:=BlistList([1..Length(o)], [scc[1]]);
 
  #JDM remove use of truth table here!
  t:=OrbSCCTruthTable(o)[i]; 
  oo:=EmptyPlist(Length(scc));
  oo[1]:=scc[1]; j:=0;

  while Length(oo)<Length(scc) do
    j:=j+1;
    k:=oo[j];
    l:=0;
    while l< Length(rev[k]) and Length(oo)<Length(scc) do
      l:=l+1;
      m:=0;
      while m< Length(rev[k][l]) and Length(oo)<Length(scc) do
        m:=m+1;
        if not seen[rev[k][l][m]] and t[rev[k][l][m]] then
          Add(oo, rev[k][l][m]); seen[rev[k][l][m]]:=true;
          gen[rev[k][l][m]]:=l; pos[rev[k][l][m]]:=k;
        fi;
      od;
    od;
  od;
  
  o!.reverse[i]:=[gen, pos];
  return [gen, pos];
end);

#TTT

#SSS

# new for 0.4! - SchreierTreeOfSCC - "for an orbit and pos. int."
###########################################################################

InstallGlobalFunction(SchreierTreeOfSCC,
function(o, i)
  local scc, len, gen, pos, seen, t, oo, m, graph, j, k, l, len_k;

  if not IsBound(o!.scc) then 
    OrbSCC(o);
  fi;

  if not IsBound(o!.trees) then
    o!.trees:=EmptyPlist(Length(o));
  fi;

  if IsBound(o!.trees[i]) then 
    return o!.trees[i];
  fi;

  if i=1 then
    o!.trees[i]:=[o!.schreiergen, o!.schreierpos];
    return o!.trees[i];
  fi;

  scc:=o!.scc[i]; len:=Length(o);

  #gen:=ListWithIdenticalEntries(len, fail);
  #pos:=ListWithIdenticalEntries(len, fail);
  gen:=EmptyPlist(len);
  pos:=EmptyPlist(len);
  gen[scc[1]]:=fail; pos[scc[1]]:=fail;

  seen:=BlistList([1..len], [scc[1]]);
#JDM remove the use of truth table here
  t:=OrbSCCTruthTable(o)[i];
  oo:=[scc[1]]; m:=1;
  graph:=OrbitGraph(o);
  j:=0;
  len:=Length(scc);

  while m<len do
    j:=j+1; k:=oo[j]; l:=0; len_k:=Length(graph[k]);
    while l<len_k and m<len do
      l:=l+1;
      if IsBound(graph[k][l]) and not seen[graph[k][l]] and t[graph[k][l]] then
        m:=m+1;
        oo[m]:=graph[k][l]; seen[graph[k][l]]:=true;
        gen[graph[k][l]]:=l; pos[graph[k][l]]:=k;
      fi;
    od;
  od;
  o!.trees[i]:=[gen, pos];

  return [gen, pos];
end);

# mod for 0.4! - TraceSchreierTreeOfSCCBack - "for an orb, pos int, pos int"
#############################################################################
# Usage: o = orbit of images; i = index of scc; j = element of scc[i].

# Notes: returns a word in the generators that takes o[j] to o!.scc[i][1]  
# assuming that j in scc[i]

InstallGlobalFunction(TraceSchreierTreeOfSCCBack,
function(o, i, j)
  local tree, scc, word;

  tree:=ReverseSchreierTreeOfSCC(o, i);
  scc:=OrbSCC(o)[i];

  word := [];
  while j > scc[1] do
    Add(word, tree[1][j]);
    j := tree[2][j];
  od;
  return word;
end);

# mod for 0.4! - TraceSchreierTreeOfSCCForward - "for an orb, pos int, pos int"
#############################################################################
# Usage: o = orbit of images; i = index of scc; j = element of scc[i].

# Notes: returns a word in the generators that takes o!.scc[i][1] to o[j] 
# assuming that j in scc[i]

InstallGlobalFunction(TraceSchreierTreeOfSCCForward,
function(o, i, j)
  local tree, scc, word;

  tree:=SchreierTreeOfSCC(o, i);
  scc:=OrbSCC(o)[i];

  word := [];
  while j > scc[1] do
    Add(word, tree[1][j]);
    j :=tree[2][j];
  od;
  return Reversed(word);
end);

#EOF
