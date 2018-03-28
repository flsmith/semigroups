############################################################################
##
#W  standard/dual.tst
#Y  Copyright (C) 2018                                  Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##
gap> START_TEST("Semigroups package: standard/dual.tst");
gap> LoadPackage("semigroups", false);;

#
gap> SEMIGROUPS.StartTest();;

#T# Creation of dual semigroups and elements - 1
gap> S := Semigroup([Transformation([1, 3, 2]), Transformation([1, 4, 4, 2])]);
<transformation semigroup of degree 4 with 2 generators>
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 4 with 2 generators>>
gap> S := Semigroup([Transformation([1, 3, 2]), Transformation([1, 4, 4, 2])]);;
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 4 with 2 generators>>
gap> AsSSortedList(T);
[ <Transformation( [ 1, 2, 2 ] ) in the dual semigroup>, 
  <IdentityTransformation in the dual semigroup>, 
  <Transformation( [ 1, 3, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 3, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 4, 4, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 4, 4, 3 ] ) in the dual semigroup> ]
gap> Size(T);
6

#T# Creation of dual semigroups and elements - 2
gap> S := Semigroup([Transformation([2, 6, 3, 2, 4, 2]),
> Transformation([5, 5, 6, 1, 4, 5]),
> Transformation([5, 3, 1, 6, 4, 5])]);;
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 6 with 3 generators>>
gap> Size(T);
385
gap> S := Semigroup([Transformation([2, 6, 3, 2, 4, 2]),
> Transformation([5, 5, 6, 1, 4, 5]),
> Transformation([5, 3, 1, 6, 4, 5])]);;
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 6 with 3 generators>>
gap> Size(T) = Size(S);
true
gap> AsSortedList(T) = AsSortedList(List(S, s -> DualSemigroupElement(T, s)));
true

#T# Creation of dual semigroups and elements - 3
gap> S := FullTransformationMonoid(20);;
gap> T := DualSemigroup(S);;
gap> HasGeneratorsOfSemigroup(T);
true
gap> HasGeneratorsOfMonoid(T);
true

#T# Creation of dual semigroup elements - errors
gap> S := FullBooleanMatMonoid(4);;
gap> Y := MagmaByMultiplicationTable([[1, 2], [1, 1]]);;
gap> DualSemigroupElement(Y, Representative(S));
Error, Semigroups: DualSemigroupElement: 
the first argument must be a semigroup,
gap> U := Semigroup(S.1, S.2, S.3, S.4);
<semigroup of 4x4 boolean matrices with 4 generators>
gap> T := DualSemigroup(U);;
gap> DualSemigroupElement(T, S.5);
Error, Semigroups: DualSemigroupElement: 
the second argument must be an element of the dual semigroup of the first argu\
ment,

#T# DClasses of dual semigroups - 1
gap> S := Semigroup([Transformation([2, 6, 3, 2, 4, 2]),
> Transformation([5, 5, 6, 1, 4, 5]),
> Transformation([5, 3, 1, 6, 4, 5])]);;
gap> T := DualSemigroup(S);;
gap> DClasses(T);
[ <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>>, <Green's D-class: <object>>, 
  <Green's D-class: <object>> ]
gap> DS := AsSortedList(DClasses(T));;
gap> for i in [1 .. Size(DS) - 1] do
> if not DS[i] < DS[i + 1] then
> Print("comparison failure");
> fi;
> od;

#T# Green's classes of dual semigroups
gap> S := Semigroup([Transformation([2, 6, 3, 2, 4, 2]),
> Transformation([5, 5, 6, 1, 4, 5])]);;
gap> T := DualSemigroup(S);;
gap> ForAll(DClasses(T),
> x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S, 
> DualSemigroupElement(S, Representative(x)))));
true
gap> ForAll(DClasses(T),
> x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S,
> DualSemigroupElement(S, Representative(x)))));
true
gap> ForAll(DClasses(T),
> x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S,
> DualSemigroupElement(S, Representative(x)))));
true
gap> ForAll(DClasses(T),
> x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S,
> DualSemigroupElement(S, Representative(x)))));
true

#T# Representatives
gap> S := FullTransformationMonoid(20);;
gap> T := DualSemigroup(S);;
gap> Representative(T);
<Transformation( [ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
 19, 20, 1 ] ) in the dual semigroup>

#T# Size
gap> S := FullTransformationMonoid(20);;
gap> T := DualSemigroup(S);;
gap> Size(T);
104857600000000000000000000

#T# AsList
gap> S := FullTransformationMonoid(6);;
gap> T := DualSemigroup(S);;
gap> AsList(T);;

#T# One and MultiplicativeNeutralElement - 1
gap> S := FullBooleanMatMonoid(5);;
gap> T := DualSemigroup(S);;
gap> One(Representative(T));
<Matrix(IsBooleanMat, [[1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], 
  [0, 0, 0, 1, 0], [0, 0, 0, 0, 1]]) in the dual semigroup>
gap> One(Representative(T)) = MultiplicativeNeutralElement(T);
true

#T# One and MultiplicativeNeutralElement - 2
gap> S := Semigroup([Transformation([2, 6, 3, 2, 4, 2]),
> Transformation([5, 5, 6, 1, 4, 5])]);;
gap> IsMonoidAsSemigroup(S);
false
gap> T := DualSemigroup(S);;
gap> One(Representative(T));
<IdentityTransformation in the dual semigroup>
gap> MultiplicativeNeutralElement(T);
fail

#T# AntiIsomorphisms
gap> S := FullTransformationMonoid(5);;
gap> T := DualSemigroup(S);;
gap> HasAntiIsomorphismTransformationSemigroup(T);
true
gap> Range(AntiIsomorphismTransformationSemigroup(T)) = S;
true
gap> antiso := AntiIsomorphismDualSemigroup(S);
MappingByFunction( <full transformation monoid of degree 5>, <dual semigroup o\
f <full transformation monoid of degree 5>>, function( x ) ... end, function( \
x ) ... end )
gap> inv := AntiIsomorphismTransformationSemigroup(T);
MappingByFunction( <dual semigroup of <full transformation monoid of degree 5>\
>, <full transformation monoid of degree 5>, function( x ) ... end, function( \
x ) ... end )
gap> ForAll(S, x -> (x ^ antiso) ^ inv = x);
true
gap> invantiso := InverseGeneralMapping(antiso);
MappingByFunction( <dual semigroup of <full transformation monoid of degree 5>\
>, <full transformation monoid of degree 5>, function( x ) ... end, function( \
x ) ... end )
gap> ForAll(S, x -> (x ^ antiso) ^ invantiso = x);
true

#T# UnbindVariables
gap> Unbind(antiso);
gap> Unbind(inv);
gap> Unbind(invantiso);
gap> Unbind(i);
gap> Unbind(U);
gap> Unbind(S);
gap> Unbind(T);

#
gap> SEMIGROUPS.StopTest();
gap> STOP_TEST("Semigroups package: standard/dual.tst");
