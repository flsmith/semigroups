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
gap> S := Semigroup([Transformation([1,3,2]), Transformation([1,4,4,2])]);
<transformation semigroup of degree 4 with 2 generators>
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 4 with 2 generators>>
gap> S := Semigroup([Transformation([1,3,2]), Transformation([1,4,4,2])]);;
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
gap> S := Semigroup([Transformation([2,6,3,2,4,2]),
> Transformation([5,5,6,1,4,5]),
> Transformation([5,3,1,6,4,5])]);;
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 6 with 3 generators>>
gap> Size(T);
385
gap> S := Semigroup([Transformation([2,6,3,2,4,2]),
> Transformation([5,5,6,1,4,5]),
> Transformation([5,3,1,6,4,5])]);;
gap> T := DualSemigroup(S);
<dual semigroup of <transformation semigroup of degree 6 with 3 generators>>
gap> Size(T) = Size(S);
true
gap> AsList(T) = List(S, s -> DualSemigroupElement(T, s));
true

#T# DClasses of dual semigroups - 1
gap> S := Semigroup([Transformation([2,6,3,2,4,2]),
> Transformation([5,5,6,1,4,5]),
> Transformation([5,3,1,6,4,5])]);;
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
gap> List(DClasses(T), d -> Size(d)) = List(DClasses(S), d -> Size(d));
true
gap> DS := AsSortedList(DClasses(T));;
gap> for i in [1 .. Size(DS) - 1] do
> if not DS[i] < DS[i + 1] then
> Print("comparison failure");
> fi;
> od;

#T# Green's classes of dual semigroups
gap> S := Semigroup([Transformation([2,6,3,2,4,2]),
> Transformation([5,5,6,1,4,5])]);;
gap> T := DualSemigroup(S);;
gap> ForAll(DClasses(T), x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S, DualSemigroupElement(S, Representative(x)))));
true
gap> ForAll(DClasses(T), x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S, DualSemigroupElement(S, Representative(x)))));
true
gap> ForAll(DClasses(T), x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S, DualSemigroupElement(S, Representative(x)))));
true
gap> ForAll(DClasses(T), x -> AsSortedList(List(x, y -> DualSemigroupElement(S, y))) =
> AsSortedList(GreensDClassOfElement(S, DualSemigroupElement(S, Representative(x)))));
true
gap> AsList(DClasses(T)[7]);
[ <Transformation( [ 4, 4, 5, 5, 1, 4 ] ) in the dual semigroup>, 
  <Transformation( [ 5, 5, 6, 6, 4, 5 ] ) in the dual semigroup>, 
  <Transformation( [ 5, 5, 1, 1, 4, 5 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 6, 4, 4, 5, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 1, 4, 4, 5, 1 ] ) in the dual semigroup>, 
  <Transformation( [ 4, 4, 5, 5, 6, 4 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 5, 4, 4, 5, 1 ] ) in the dual semigroup>, 
  <Transformation( [ 4, 6, 5, 5, 6, 4 ] ) in the dual semigroup>, 
  <Transformation( [ 4, 1, 5, 5, 1, 4 ] ) in the dual semigroup>, 
  <Transformation( [ 5, 4, 6, 6, 4, 5 ] ) in the dual semigroup>, 
  <Transformation( [ 5, 4, 1, 1, 4, 5 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 5, 4, 4, 5, 6 ] ) in the dual semigroup> ]
gap> AsList(LClasses(T)[4]);
[ <Transformation( [ 6, 2, 3, 6, 2, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 4, 3, 2, 4, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 5, 3, 1, 5, 1 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 2, 6, 3, 2, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 4, 2, 3, 4, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 5, 1, 3, 5, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 3, 2, 6, 3, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 3, 4, 2, 3, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 1, 3, 5, 1, 3, 1 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 3, 6, 2, 3, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 4, 3, 2, 4, 3, 4 ] ) in the dual semigroup>, 
  <Transformation( [ 5, 3, 1, 5, 3, 5 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 6, 2, 3, 6, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 2, 4, 3, 2, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 1, 5, 3, 1, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 6, 3, 2, 6, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 4, 2, 3, 4, 2, 4 ] ) in the dual semigroup>, 
  <Transformation( [ 5, 1, 3, 5, 1, 5 ] ) in the dual semigroup> ]
gap> AsList(RClasses(T)[4]);
[ <Transformation( [ 6, 2, 3, 6, 2, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 2, 6, 3, 2, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 3, 2, 6, 3, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 3, 6, 2, 3, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 6, 2, 3, 6, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 6, 3, 2, 6, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 3, 6, 6, 6, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 6, 3, 3, 3, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 2, 6, 6, 6, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 6, 2, 2, 2, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 2, 3, 3, 3, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 3, 2, 2, 2, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 2, 6, 3, 6, 3 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 2, 3, 6, 3, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 3, 6, 2, 6, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 6, 3, 2, 6, 2, 6 ] ) in the dual semigroup>, 
  <Transformation( [ 2, 6, 3, 2, 3, 2 ] ) in the dual semigroup>, 
  <Transformation( [ 3, 6, 2, 3, 2, 3 ] ) in the dual semigroup> ]

# Froidure Pin 
gap> S := Semigroup([Transformation([2,6,3,2,4,2]),
> Transformation([5,5,6,1,4,5]),
> Transformation([5,3,1,6,4,5])]);;
gap> T := DualSemigroup(S);;
gap> FroidurePinExtendedAlg(T);;
gap> HasLeftCayleyGraphSemigroup(T);
true
gap> HasSize(T);
true

#
gap> SEMIGROUPS.StopTest();
gap> STOP_TEST("Semigroups package: standard/dual.tst");
