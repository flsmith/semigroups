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

#
gap> SEMIGROUPS.StopTest();
gap> STOP_TEST("Semigroups package: standard/dual.tst");
