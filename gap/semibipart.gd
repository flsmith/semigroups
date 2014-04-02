############################################################################
##
#W  semibipart.gd
#Y  Copyright (C) 2013-14                                James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

DeclareSynonym("IsBipartitionSemigroup", IsSemigroup and
IsBipartitionCollection);
DeclareSynonym("IsBipartitionMonoid", IsMonoid and
IsBipartitionCollection);

DeclareProperty("IsBipartitionSemigroupGreensClass", IsGreensClass);
DeclareAttribute("DegreeOfBipartitionSemigroup", IsBipartitionSemigroup);
DeclareAttribute("IsomorphismBipartitionSemigroup", IsSemigroup);
DeclareAttribute("IsomorphismBlockBijectionSemigroup", IsSemigroup);

DeclareProperty("IsBlockBijectionSemigroup", IsBipartitionSemigroup);
DeclareProperty("IsPartialPermBipartitionSemigroup", IsBipartitionSemigroup);
DeclareProperty("IsPermBipartitionGroup", IsBipartitionSemigroup);
DeclareSynonymAttr("IsBlockBijectionMonoid", IsBlockBijectionSemigroup and IsMonoid);
DeclareSynonymAttr("IsPartialPermBipartitionMonoid", IsPartialPermBipartitionSemigroup and IsMonoid);

