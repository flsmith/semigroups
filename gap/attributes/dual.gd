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


DeclareGlobalFunction("DualSemigroupElement");

DeclareCategory("IsDualGreensDClass", IsGreensDClass);

