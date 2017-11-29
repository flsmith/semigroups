#include "orb.h"
#include "semigrp.h"

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include "bipart.h"
#include "converter.h"
#include "fropin.h"
#include "pkg.h"
#include "src/compiled.h"
#include "src/libsemigroups/src/orb.h"

using libsemigroups::BaseOrb;
using libsemigroups::Orb;
using libsemigroups::Transformation;
gap_orb_t semi_obj_init_orb(gap_semigroup_t so) {
  CHECK_SEMI_OBJ(so);
  initRNams();

  en_semi_obj_t es   = semi_obj_get_en_semi(so);
  en_semi_t     type = en_semi_get_type(es);

  // todo: bipart, trans4, pperm
  if (type == TRANS2) {
    Semigroup*                     semi_cpp = en_semi_get_semi_cpp(es);
    typedef std::vector<u_int16_t> point_type;
    auto act = [](Transformation<u_int16_t>* t, point_type* pt, point_type* tmp)
        -> point_type* { return t->lvalue(pt, tmp); };
    std::vector<Transformation<u_int16_t>*> gens;
    gens.reserve(semi_cpp->nrgens());
    for (size_t i = 0; i < semi_cpp->nrgens(); ++i) {
      gens.push_back(reinterpret_cast<Transformation<u_int16_t>*>(
          semi_cpp->gens(i)->really_copy()));
    }

    auto copier = [](point_type* pt) -> point_type* {
      return new point_type(*pt);
    };

    Orb<Transformation<u_int16_t>,
        point_type*,
        VectorHash<u_int16_t>,
        VectorEqual<u_int16_t>>* orb =
        new Orb<Transformation<u_int16_t>,
                point_type*,
                VectorHash<u_int16_t>,
                VectorEqual<u_int16_t>>(gens, act, copier);
   
    point_type* x   = new point_type();
    point_type* tmp   = new point_type();
    for (size_t i = 0; i < gens[0]->degree(); ++i) {
      x->push_back(i);
    }
    
    for (size_t i = 0; i < gens.size(); ++i) {
      gens[i]->lvalue(x, tmp);
      orb->add_seed(tmp);
    }
 
    // Use OBJ_CLASS instead
    Obj o = OBJ_CLASS(orb, T_SEMI_SUBTYPE_ORB);
    AssPRec(so, RNam_NewLambdaOrb, o);
    return o; 
  } else {
    gap_list_t gens = semi_obj_get_gens(so);
    SEMIGROUPS_ASSERT(LEN_LIST(gens) > 0);
    ErrorQuit("ORB_SIZE: the argument must be a transformation or partial perm "
              "semigroup, not a %s",
              (Int) TNAM_OBJ(ELM_LIST(gens, 1)),
              0L);
    return 0L;
  }
}

BaseOrb* semi_obj_get_orb(gap_semigroup_t so) {
  // TODO add assertions
  initRNams();
  if (!IsbPRec(so, RNam_NewLambdaOrb)) {
   semi_obj_init_orb(so);
  }
  return CLASS_OBJ<BaseOrb*>(ElmPRec(so, RNam_NewLambdaOrb));
}

gap_int_t AC_SEMI_L_ORB_SIZE(Obj self, gap_semigroup_t so) {
  CHECK_SEMI_OBJ(so);
  BaseOrb* o = semi_obj_get_orb(so);
  return INTOBJ_INT(o->size());
}
