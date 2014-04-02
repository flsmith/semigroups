############################################################################
##
#W  PackageInfo.g
#Y  Copyright (C) 2011-13                                James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

##  <#GAPDoc Label="PKGVERSIONDATA">
##  <!ENTITY VERSION "2.0">
##  <!ENTITY GAPVERS "4.7.3">
##  <!ENTITY ORBVERS "4.7">
##  <!ENTITY IOVERS "4.3">
##  <!ENTITY GRAPEVERS "4.5">
##  <!ENTITY GENSSVERS "1.5">
##  <!ENTITY ARCHIVENAME "semigroups-2.0">
##  <!ENTITY COPYRIGHTYEARS "2011-14">
##  <#/GAPDoc>

SetPackageInfo( rec(
PackageName := "Semigroups",
Subtitle := "Methods for Semigroups",
Version := "2.0",
Date := "??",
ArchiveURL := "http://tinyurl.com/jdmitchell/semigroups/semigroups-2.0",
ArchiveFormats := ".tar.gz",
Persons := [
  rec( 
    LastName      := "Mitchell",
    FirstNames    := "J. D.",
    IsAuthor      := true,
    IsMaintainer  := true,
    Email         := "jdm3@st-and.ac.uk",
    WWWHome       := "tinyurl.com/jdmitchell",
    PostalAddress := Concatenation( [
                       "Mathematical Institute,",
                       " North Haugh,", " St Andrews,", " Fife,", " KY16 9SS,", 
                       " Scotland"] ),
    Place         := "St Andrews",
    Institution   := "University of St Andrews"
  )],

Status := "deposited",

README_URL := 
  "http://www-groups.mcs.st-andrews.ac.uk/~jamesm/semigroups/README",
PackageInfoURL := 
  "http://www-groups.mcs.st-andrews.ac.uk/~jamesm/semigroups/PackageInfo.g",

AbstractHTML := Concatenation(
   "<p>The Semigroups package is a GAP package containing methods for",
   " semigroups (principally semigroups of of transformations, partial",
   " permutations or subsemigroups of regular Rees 0-matrix semigroups). ",
   "Semigroups contains more efficient methods than those available in the ",
   "GAP library (and in many cases more efficient than any other software)",
   "for creating semigroups, calculating their Green's classes, size,",
   "elements, ",
   "group of units, minimal ideal, small generating sets, testing membership, ",
   "finding the inverses of a regular element, factorizing elements over the ",
   "generators, and many more. It is also possible to test if a semigroup ",
   "satisfies a particular property, such as if it is regular, simple, ",
   "inverse, completely regular, and a variety of further properties.</p>",
   "<p>There are also functions to define and manipulate free inverse", 
   "semigroups and their elements.<p/>"),

PackageWWWHome := "http://www-groups.mcs.st-andrews.ac.uk/~jamesm/semigroups.php",
               
PackageDoc := rec(
  BookName  := "Semigroups",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",  
  SixFile   := "doc/manual.six",
  LongTitle := "Semigroups - Methods for semigroups",
  Autoload  := true
),

Dependencies := rec(
  GAP := ">=4.7.3",
  NeededOtherPackages := [["orb", ">=4.7"], ["io", ">=4.3"]],
  SuggestedOtherPackages := [["gapdoc", ">=1.5.1"], ["grape", ">=4.5"],
  ["genss", ">=1.5"]], 
  ExternalConditions := []),
  AvailabilityTest := ReturnTrue, 
  Autoload := false,
  TestFile := "tst/testinstall.tst",
  Keywords := ["transformation semigroups", "partial permutations",
  "inverse semigroups", "Green's relations", "free inverse semigroup", 
  "partition monoid", "bipartitions", "Rees matrix semigroups"]
));
