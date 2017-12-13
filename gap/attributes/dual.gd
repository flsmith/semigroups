#############################################################################
##
#W  dual.gd
#Y  Copyright (C) 2017                                      James D. Mitchell
##                                                          Finn Smith
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

DeclareCategory("IsDualSemigroupElement", IsAssociativeElement);
DeclareCategoryCollections("IsDualSemigroupElement");
DeclareAttribute("DualSemigroup", IsSemigroup);
DeclareSynonym("IsDualSemigroup", IsSemigroup and IsDualSemigroupElementCollection);
DeclareAttribute("TypeDualSemigroupElements", IsDualSemigroup);

DeclareAttribute("DualSemigroupOfFamily", IsFamily);

DeclareGlobalFunction("DualSemigroupElement");

DeclareCategory("IsDualGreensDClass", IsGreensDClass);
DeclareAttribute("UnderlyingDClassOfDualGreensDClass", IsDualGreensDClass);
DeclareCategory("IsDualGreensLClass", IsGreensLClass);
DeclareAttribute("UnderlyingRClassOfDualGreensLClass", IsDualGreensLClass);
DeclareCategory("IsDualGreensRClass", IsGreensRClass);
DeclareAttribute("UnderlyingLClassOfDualGreensRClass", IsDualGreensRClass);
