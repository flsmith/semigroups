#ifndef SEMIGROUPS_SRC_ORB_H_
#define SEMIGROUPS_SRC_ORB_H_

#include "converter.h"
#include "libsemigroups/src/semigroups.h"
#include "libsemigroups/src/orb.h"
#include "pkg.h"
#include "rnams.h"
#include "src/compiled.h"
#include <vector>

// Orbits
template <typename T> struct VectorEqual {
  bool operator()(std::vector<T>* pt1, std::vector<T>* pt2) const {
    return *pt1 == *pt2;
  }
};

template <typename T> struct VectorHash {
  size_t operator()(std::vector<T> const* vec) const {
    size_t seed = 0;
    for (auto const& x : *vec) {
      seed ^= x + 0x9e3779b9 + (seed << 6) + (seed >> 2);
    }
    return seed;
  }
};

typedef Obj gap_orb_t;


//debugging... #TODO: remove
//gap_orb_t semi_obj_init_orb(Obj self, gap_semigroup_t so);

//GAP Functions
gap_int_t AC_SEMI_L_ORB_SIZE(Obj self, gap_semigroup_t so); 

#endif  // SEMIGROUPS_SRC_ORB_H_
