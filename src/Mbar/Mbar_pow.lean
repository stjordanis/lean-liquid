import topology.category.CompHaus
import for_mathlib.continuous_map
import for_mathlib.free_abelian_group
import for_mathlib.add_monoid_hom
import for_mathlib.extend_from_nat
import facts

import pseudo_normed_group.CLC

import locally_constant.Vhat
import Mbar.breen_deligne

/-!
# The completion of the group of locally constant maps from `Mbar_le r' S c` to `V`

In this file we define `V-hat(Mbar_{r'}(S)_{≤c}^a)`
as the completion of the normed group of locally constant maps from
`(Mbar_le r' S c)^a` to `V`, where the norm is the sup-norm.

This definition is recorded in `LCC_Mbar_pow`.

We also define `LC_Mbar_pow`, which is the uncompleted version:
locally constant maps from `(Mbar_le r' S c)^a` to `V`.
So `LCC_Mbar_pow` is the completion of `LC_Mbar_pow`, hence the extra `C`.

Several definition and lemmas follow the pattern of
first being defined/proven on the level of `LC_Mbar_pow`
(often indicated by a subscript `foo₀`)
and afterwards on the level of `LCC_Mbar_pow`.
-/

noncomputable theory

open opposite category_theory category_theory.category category_theory.limits
open_locale classical nnreal big_operators
local attribute [instance] type_pow

variables (V : NormedGroup) (S : Type*) (r r' c c₁ c₂ c₃ c₄ : ℝ≥0) (a : ℕ) [fintype S]

/-- The functor `V-hat`, from compact Hausdorff spaces to normed groups. -/
abbreviation hat := NormedGroup.LCC.obj V

/-- The normed group of locally constant functions
from `(Mbar_le r' S c)^a` to a normed group `V`.

Mnemonic: `LC` stands for *locally constant*. -/
def LC_Mbar_pow [fact (0 < r')] : NormedGroup :=
(NormedGroup.LocallyConstant.obj V).obj (op $ Profinite.of $ (Mbar_le r' S c)^a)

/-
In this ↑ definition, we apply the functor
`(NormedGroup.LocallyConstant.obj V)` to an object of `Profinite`,
namely `(Mbar_le r' S c)^a`.

* Since the functor is contravariant, we need to pass to `Profiniteᵒᵖ`,
  which is accomplished by the `op`,
* Since `(Mbar_le r' S c)^a` is a priori only a *type*
  it has to be packaged into an object of `Profinite`,
  which is accomplished by the `Profinite.of`.
  The topology is automatically inferred by the *typeclass system*.
* The `$` symbols are a syntactic trick to avoid excessive parentheses:
  `f $ g x` means `f (g x)`
-/

instance normed_with_aut_LC_Mbar_pow [fact (0 < r)] [fact (0 < r')] [normed_with_aut r V] :
  normed_with_aut r (LC_Mbar_pow V S r' c a) := by { unfold LC_Mbar_pow, apply_instance }

/-- The space `V-hat(Mbar_{r'}(S)_{≤c}^a)` is the completion
of the normed group of locally constant functions from `(Mbar_{r'}(S)_{≤c}^a)` to `V`.

Mnemonic: `LCC` stands for *locally compact, completed*. -/
def LCC_Mbar_pow [fact (0 < r')] : NormedGroup :=
(hat V).obj (op $ Profinite.of ((Mbar_le r' S c)^a))

lemma LCC_Mbar_pow_eq [fact (0 < r')] :
  LCC_Mbar_pow V S r' c a = NormedGroup.Completion.obj (LC_Mbar_pow V S r' c a) := rfl

instance LCC_Mbar_pow_complete_space [fact (0 < r')] : complete_space (LCC_Mbar_pow V S r' c a) :=
by { rw LCC_Mbar_pow_eq, apply_instance }

namespace LCC_Mbar_pow

-- Achtung! Achtung!
-- For technical reasons,
-- it is very important that the `[normed_with_aut r V]` instance comes last!
-- Reason: `r` is an out_param, so it should be fixed as soon as possible
-- by searching for `[normed_aut ?x_0 V]`
-- and Lean tries to fill in the typeclass assumptions from right to left.
-- Otherwise it might go on a wild goose chase for `[fact (0 < r)]`...
instance [fact (0 < r)] [fact (0 < r')] [normed_with_aut r V] :
  normed_with_aut r (LCC_Mbar_pow V S r' c a) :=
NormedGroup.normed_with_aut_LCC V _ r

lemma T_inv_eq [fact (0 < r)] [fact (0 < r')] [normed_with_aut r V] :
  (normed_with_aut.T.inv : LCC_Mbar_pow V S r' c a ⟶ LCC_Mbar_pow V S r' c a) =
    (NormedGroup.LCC.map (normed_with_aut.T.inv : V ⟶ V)).app
      (op $ Profinite.of ((Mbar_le r' S c)^a)) :=
begin
  dsimp [LCC_Mbar_pow, LCC_Mbar_pow.normed_with_aut, NormedGroup.normed_with_aut_LCC,
    NormedGroup.normed_with_aut_Completion, NormedGroup.normed_with_aut_LocallyConstant,
    NormedGroup.LCC],
  erw [locally_constant.comap_hom_id, category.comp_id]
end

/-- The natural restriction map. -/
@[simp] def res₀ [fact (0 < r')] [fact (c₁ ≤ c₂)] :
  LC_Mbar_pow V S r' c₂ a ⟶ LC_Mbar_pow V S r' c₁ a :=
(NormedGroup.LocallyConstant.obj V).map $ has_hom.hom.op $
⟨λ x, Mbar_le.cast_le ∘ x,
  continuous_pi $ λ i, (Mbar_le.continuous_cast_le r' S c₁ c₂).comp (continuous_apply i)⟩

lemma res₀_refl [fact (0 < r')] : res₀ V S r' c c a = 𝟙 _ :=
begin
  -- this can be cleaned up with some simp-lemmas
  -- will probably also make it faster
  delta res₀,
  convert category_theory.functor.map_id _ _,
  apply has_hom.hom.unop_inj,
  simp only [unop_id_op, has_hom.hom.unop_op],
  ext, dsimp, refl
end

lemma res₀_comp_res₀ [fact (0 < r')] [fact (c₁ ≤ c₂)] [fact (c₂ ≤ c₃)] [fact (c₁ ≤ c₃)] :
  res₀ V S r' c₂ c₃ a ≫ res₀ V S r' c₁ c₂ a = res₀ V S r' c₁ c₃ a :=
by { delta res₀, rw ← functor.map_comp, refl }

/-- The natural restriction map. -/
def res [fact (0 < r')] [fact (c₁ ≤ c₂)] :
  LCC_Mbar_pow V S r' c₂ a ⟶ LCC_Mbar_pow V S r' c₁ a :=
NormedGroup.Completion.map $ res₀ _ _ _ _ _ _

lemma res_refl [fact (0 < r')] : res V S r' c c a = 𝟙 _ :=
by { delta res, rw [res₀_refl], exact category_theory.functor.map_id _ _ }

@[reassoc] lemma res_comp_res [fact (0 < r')] [fact (c₁ ≤ c₂)] [fact (c₂ ≤ c₃)] [fact (c₁ ≤ c₃)] :
  res V S r' c₂ c₃ a ≫ res V S r' c₁ c₂ a = res V S r' c₁ c₃ a :=
by {delta res, rw [← functor.map_comp, res₀_comp_res₀] }

/-- The action of `T⁻¹` as morphism
`LC_Mbar_pow V S r' (r'⁻¹ * c) a ⟶ LC_Mbar_pow V S r' c a`. -/
def Tinv₀ [fact (0 < r')] :
  LC_Mbar_pow V S r' (r'⁻¹ * c) a ⟶ LC_Mbar_pow V S r' c a :=
(NormedGroup.LocallyConstant.obj V).map $ has_hom.hom.op $
⟨λ x, Mbar_le.Tinv ∘ x,
  continuous_pi $ λ i, (Mbar_le.continuous_Tinv r' S _ _).comp (continuous_apply i)⟩

/-- The action of `T⁻¹` as morphism
`LCC_Mbar_pow V S r' (r'⁻¹ * c) a ⟶ LCC_Mbar_pow V S r' c a`. -/
def Tinv [fact (0 < r')] :
  LCC_Mbar_pow V S r' (r'⁻¹ * c) a ⟶ LCC_Mbar_pow V S r' c a :=
NormedGroup.Completion.map $ Tinv₀ _ _ _ _ _

lemma Tinv₀_res [fact (0 < r')] [fact (c₁ ≤ c₂)] :
  Tinv₀ V S r' c₂ a ≫ res₀ V S r' c₁ c₂ a = res₀ V S r' _ _ a ≫ Tinv₀ V S r' _ a :=
by { delta Tinv₀ res₀, rw [← functor.map_comp, ← functor.map_comp], refl }

lemma Tinv_res [fact (0 < r')] [fact (c₁ ≤ c₂)] :
  Tinv V S r' c₂ a ≫ res V S r' c₁ c₂ a = res V S r' _ _ a ≫ Tinv V S r' _ a :=
by { delta Tinv res, rw [← functor.map_comp, ← functor.map_comp, Tinv₀_res] }

open uniform_space NormedGroup

@[reassoc] lemma T_res₀ [fact (0 < r)] [fact (0 < r')] [fact (c₁ ≤ c₂)] [normed_with_aut r V] :
  normed_with_aut.T.hom ≫ res₀ V S r' c₁ c₂ a = res₀ V S r' _ _ a ≫ normed_with_aut.T.hom :=
begin
  simp only [LocallyConstant_obj_map, iso.app_hom, normed_with_aut_LocallyConstant_T,
    continuous_map.coe_mk, functor.map_iso_hom, LocallyConstant_map_app, res₀, has_hom.hom.unop_op],
  ext x s,
  simp only [locally_constant.comap_hom_to_fun, function.comp_app,
    locally_constant.map_hom_to_fun, locally_constant.map_apply, coe_comp],
  repeat { erw locally_constant.coe_comap },
  refl,
  repeat
  { exact continuous_pi (λ i, (Mbar_le.continuous_cast_le r' S c₁ c₂).comp (continuous_apply i)) }
end

@[reassoc] lemma T_inv₀_res₀ [fact (0 < r)] [fact (0 < r')] [fact (c₁ ≤ c₂)] [normed_with_aut r V] :
  normed_with_aut.T.inv ≫ res₀ V S r' c₁ c₂ a = res₀ V S r' _ _ a ≫ normed_with_aut.T.inv :=
by simp only [iso.inv_comp_eq, T_res₀_assoc, iso.hom_inv_id, comp_id]

@[reassoc] lemma T_res [fact (0 < r)] [fact (0 < r')] [fact (c₁ ≤ c₂)] [normed_with_aut r V] :
  normed_with_aut.T.hom ≫ res V S r' c₁ c₂ a = res V S r' _ _ a ≫ normed_with_aut.T.hom :=
begin
  change NormedGroup.Completion.map _ ≫ NormedGroup.Completion.map (res₀ _ _ _ _ _ _) = _,
  change _ = NormedGroup.Completion.map (res₀ _ _ _ _ _ _) ≫ NormedGroup.Completion.map _,
  simp_rw ← category_theory.functor.map_comp,
  apply congr_arg,
  --apply T_res₀, -- doesn't work (WHY?) :-(
  exact @T_res₀ V S r r' c₁ c₂ a _ _ _ _ _,
end

@[reassoc] lemma T_inv_res [fact (0 < r)] [fact (0 < r')] [fact (c₁ ≤ c₂)] [normed_with_aut r V] :
  normed_with_aut.T.inv ≫ res V S r' c₁ c₂ a = res V S r' _ _ a ≫ normed_with_aut.T.inv :=
by simp only [iso.inv_comp_eq, T_res_assoc, iso.hom_inv_id, comp_id]

end LCC_Mbar_pow

namespace breen_deligne

variable [fact (0 < r')]

variables {l m n : ℕ}

namespace basic_universal_map

/-- This function is a packaged version of `f.eval_Mbar_le` as morphism in `Profinite`.
We only use this in the definition of `f.eval_Mbar_pow`. -/
def eval_Mbar_pow_aux (f : basic_universal_map m n) [f.suitable c₁ c₂] :
  Profinite.of (Mbar_le r' S c₁ ^ m) ⟶ Profinite.of (Mbar_le r' S c₂ ^ n) :=
{ to_fun := f.eval_Mbar_le _ _ _ _,
  continuous_to_fun := f.eval_Mbar_le_continuous _ _ _ _}

/-- `f.eval_Mbar_pow` is the morphism of normed groups
`(LCC_Mbar_pow V S r' c₂ n) ⟶ (LCC_Mbar_pow V S r' c₁ m)`
induced by `f : basic_universal_map m n` (aka a matrix).

Roughly speaking, `f` induces a map between powers of `Mbar_le`,
by matrix multiplication. We push that map through the functor `V-hat`,
to obtain `f.eval_Mbar_pow`.

Implementation details:
This definition only makes sense when `c₁` and `c₂` are *suitable* with respect to `f`.
However, several induction proofs below become horribly complicated
if we add this suitability condition as assumption in the definition.
(For example because addition will change the constants `c₁` and `c₂`
at the most inconvenient moments.)
We therefore apply an old trick:
we extend the definition to the arbitrary `c₁` and `c₂` by defining `f.eval_Mbar_pow`
to be `0` when the suitability condition is not satisfied. -/
def eval_Mbar_pow (f : basic_universal_map m n) :
  (LCC_Mbar_pow V S r' c₂ n) ⟶ (LCC_Mbar_pow V S r' c₁ m) :=
if H : f.suitable c₁ c₂
then (hat V).map $ has_hom.hom.op $ @eval_Mbar_pow_aux S r' c₁ c₂ _ _ _ _ f H
else 0

lemma eval_Mbar_pow_def (f : basic_universal_map m n) [f.suitable c₁ c₂] :
  f.eval_Mbar_pow V S r' c₁ c₂ =
    (hat V).map (has_hom.hom.op $ ⟨f.eval_Mbar_le _ _ _ _, f.eval_Mbar_le_continuous _ _ _ _⟩) :=
by { rw [eval_Mbar_pow, dif_pos], refl }

lemma eval_Mbar_pow_comp (g : basic_universal_map m n) (f : basic_universal_map l m)
  [hg : g.suitable c₂ c₃] [hf : f.suitable c₁ c₂] :
  (g.comp f).eval_Mbar_pow V S r' c₁ c₃ =
  g.eval_Mbar_pow V S r' c₂ c₃ ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  haveI : (g.comp f).suitable c₁ c₃ := suitable_comp c₂,
  simp only [eval_Mbar_pow_def],
  rw [← category_theory.functor.map_comp, ← op_comp],
  congr' 2,
  simpa [eval_Mbar_le_comp r' S _ c₂],
end

lemma eval_Mbar_pow_comp_res (f : basic_universal_map m n)
  [f.suitable c₁ c₂] [f.suitable c₃ c₄] [fact (c₁ ≤ c₃)] [fact (c₂ ≤ c₄)] :
  f.eval_Mbar_pow V S r' c₃ c₄ ≫ LCC_Mbar_pow.res V S r' c₁ c₃ m =
  LCC_Mbar_pow.res V S r' c₂ c₄ n ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  rw [eval_Mbar_pow_def, eval_Mbar_pow_def, NormedGroup.LCC_obj_map', NormedGroup.LCC_obj_map'],
  delta LCC_Mbar_pow.res LCC_Mbar_pow.res₀,
  rw [← functor.map_comp, ← functor.map_comp, ← functor.map_comp,
      ← functor.map_comp, ← op_comp, ← op_comp],
  congr' 3,
  ext x i s k,
  show (f.eval_Mbar_le r' S c₃ c₄ ∘ (function.comp Mbar_le.cast_le)) x i s k =
    ((function.comp Mbar_le.cast_le) ∘ (f.eval_Mbar_le r' S c₁ c₂)) x i s k,
  dsimp [function.comp],
  simp only [Mbar_le.coe_cast_le]
end

lemma eval_Mbar_pow_comp_Tinv (f : basic_universal_map m n) [f.suitable c₁ c₂] :
  f.eval_Mbar_pow V S r' (r'⁻¹ * c₁) (r'⁻¹ * c₂) ≫ LCC_Mbar_pow.Tinv V S r' c₁ m =
    LCC_Mbar_pow.Tinv V S r' c₂ n ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  rw [eval_Mbar_pow_def, eval_Mbar_pow_def, NormedGroup.LCC_obj_map', NormedGroup.LCC_obj_map'],
  delta LCC_Mbar_pow.Tinv LCC_Mbar_pow.Tinv₀,
  rw [← functor.map_comp, ← functor.map_comp, ← functor.map_comp,
      ← functor.map_comp, ← op_comp, ← op_comp],
  congr' 3,
  ext x j s k, dsimp at *,
  show (f.eval_Mbar_le r' S _ _ ∘ (function.comp Mbar_le.Tinv)) x j s k =
    ((function.comp Mbar_le.Tinv) ∘ (f.eval_Mbar_le r' S c₁ c₂)) x j s k,
  dsimp [function.comp, Mbar.Tinv],
  cases k,
  { simp only [Mbar.coeff_zero] },
  { simp only [Mbar.Tinv_aux_succ, add_monoid_hom.coe_mk', eval_Mbar_le_apply, Mbar.coe_smul,
      Mbar.coe_mk, Mbar_le.coe_coe_to_fun, eval_png_apply, Mbar.coe_sum, fintype.sum_apply,
      pi.smul_apply, Mbar.Tinv_succ],
    refl }
end

lemma eval_Mbar_pow_comp_T_inv (f : basic_universal_map m n) [f.suitable c₁ c₂]
  [fact (0 < r)] [normed_with_aut r V] :
  f.eval_Mbar_pow V S r' c₁ c₂ ≫ normed_with_aut.T.inv =
    normed_with_aut.T.inv ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  rw [LCC_Mbar_pow.T_inv_eq, LCC_Mbar_pow.T_inv_eq, eval_Mbar_pow_def],
  apply nat_trans.naturality
end

end basic_universal_map

namespace universal_map

open free_abelian_group

/-- `f.eval_Mbar_pow` is the morphism
`(LCC_Mbar_pow V S r' c₂ n) ⟶ (LCC_Mbar_pow V S r' c₁ m)`
induced by `f : universal_map m n`, in the following way:

For every `g : basic_universal_map m n` occurring in the
the formal sum `f`, we have `g.eval_Mbar_pow`.
Now we take the sum of those maps.

Since `V-hat` is not an additive functor,
this definition is not the same as apply `V-hat`
to the sum of the maps `g.eval_Mbar_le`.

Implementation details:
we apply the same trick as in the definition
`breen_deligne.basic_universal_map.eval_Mbar_pow`.
The definition only makes sense if the constants `c₁` and `c₂`
are *suitable* with respect to `f`.
We extend the definition to other input values, by declaring it to be `0`. -/
def eval_Mbar_pow {m n : ℕ} (f : universal_map m n) :
  (LCC_Mbar_pow V S r' c₂ n) ⟶ (LCC_Mbar_pow V S r' c₁ m) :=
if H : (f.suitable c₁ c₂)
then by exactI
  ∑ g in f.support, coeff g f • (g.eval_Mbar_pow V S r' c₁ c₂)
else 0

lemma eval_Mbar_pow_def {m n : ℕ} (f : universal_map m n) [H : f.suitable c₁ c₂] :
  f.eval_Mbar_pow V S r' c₁ c₂ = ∑ g in f.support, coeff g f • (g.eval_Mbar_pow V S r' c₁ c₂) :=
by { rw [eval_Mbar_pow, dif_pos], exact H }

@[simp] lemma eval_Mbar_pow_of (f : basic_universal_map m n) [f.suitable c₁ c₂] :
  eval_Mbar_pow V S r' c₁ c₂ (of f) = f.eval_Mbar_pow V S r' c₁ c₂ :=
by simp only [eval_Mbar_pow_def, support_of, coeff_of_self, one_smul, finset.sum_singleton]

@[simp] lemma eval_Mbar_pow_zero :
  (0 : universal_map m n).eval_Mbar_pow V S r' c₁ c₂ = 0 :=
by rw [eval_Mbar_pow_def, support_zero, finset.sum_empty]

@[simp] lemma eval_Mbar_pow_neg (f : universal_map m n) :
  eval_Mbar_pow V S r' c₁ c₂ (-f) = -f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  rw eval_Mbar_pow,
  split_ifs,
  { rw suitable_neg_iff at h,
    rw [eval_Mbar_pow, dif_pos h],
    simp only [add_monoid_hom.map_neg, finset.sum_neg_distrib, neg_smul, support_neg] },
  { rw suitable_neg_iff at h,
    rw [eval_Mbar_pow, dif_neg h, neg_zero] }
end

lemma eval_Mbar_pow_add (f g : universal_map m n)
  [hf : f.suitable c₁ c₂] [hg : g.suitable c₁ c₂] :
  eval_Mbar_pow V S r' c₁ c₂ (f + g) =
    f.eval_Mbar_pow V S r' c₁ c₂ + g.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  simp only [eval_Mbar_pow_def],
  rw finset.sum_subset (support_add f g), -- two goals
  simp only [add_monoid_hom.map_add _ f g, add_smul],
  convert finset.sum_add_distrib using 2, -- three goals
  apply finset.sum_subset (finset.subset_union_left _ _), swap,
  apply finset.sum_subset (finset.subset_union_right _ _),
  all_goals { rintros x - h, rw not_mem_support_iff at h, simp [h] },
end

lemma eval_Mbar_pow_comp_of (g : basic_universal_map m n) (f : basic_universal_map l m)
  [hg : g.suitable c₂ c₃] [hf : f.suitable c₁ c₂] :
  eval_Mbar_pow V S r' c₁ c₃ ((comp (of g)) (of f)) =
    eval_Mbar_pow V S r' c₂ c₃ (of g) ≫ eval_Mbar_pow V S r' c₁ c₂ (of f) :=
begin
  haveI hfg : (g.comp f).suitable c₁ c₃ := basic_universal_map.suitable_comp c₂,--hg.comp hf,
  simp only [comp_of, eval_Mbar_pow_of],
  rw ← basic_universal_map.eval_Mbar_pow_comp,
end

lemma eval_Mbar_pow_comp (g : universal_map m n) (f : universal_map l m)
  [hg : g.suitable c₂ c₃] [hf : f.suitable c₁ c₂] :
  (comp g f).eval_Mbar_pow V S r' c₁ c₃ =
    g.eval_Mbar_pow V S r' c₂ c₃ ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  unfreezingI { revert hf },
  apply free_abelian_group.induction_on_free_predicate
    (suitable c₂ c₃) (suitable_free_predicate c₂ c₃) g hg; unfreezingI { clear_dependent g },
  { intros h₂,
    simp only [eval_Mbar_pow_zero, zero_comp, pi.zero_apply,
      add_monoid_hom.coe_zero, add_monoid_hom.map_zero] },
  { intros g hg hf,
    -- now do another nested induction on `f`
    apply free_abelian_group.induction_on_free_predicate
      (suitable c₁ c₂) (suitable_free_predicate c₁ c₂) f hf; unfreezingI { clear_dependent f },
    { simp only [eval_Mbar_pow_zero, comp_zero, add_monoid_hom.map_zero] },
    { intros f hf,
      rw suitable_of_iff at hf,
      resetI,
      apply eval_Mbar_pow_comp_of },
    { intros f hf IH,
      show _ = normed_group_hom.comp_hom _ _,
      simp only [IH, pi.neg_apply, add_monoid_hom.map_neg, eval_Mbar_pow_neg,
        add_monoid_hom.coe_neg, neg_inj],
      refl },
    { rintros (f₁ : universal_map l m) (f₂ : universal_map l m) hf₁ hf₂ IH₁ IH₂, resetI,
      haveI Hg₁f : (comp (of g) f₁).suitable c₁ c₃ := suitable.comp c₂,
      haveI Hg₂f : (comp (of g) f₂).suitable c₁ c₃ := suitable.comp c₂,
      simp only [add_monoid_hom.map_add, add_monoid_hom.add_apply, eval_Mbar_pow_add, IH₁, IH₂],
      show _ = normed_group_hom.comp_hom _ _,
      simpa [add_monoid_hom.map_add] } },
  { intros g hg IH hf, resetI, specialize IH,
    show _ = normed_group_hom.comp_hom _ _,
    simp only [IH, pi.neg_apply, add_monoid_hom.map_neg, eval_Mbar_pow_neg, add_monoid_hom.coe_neg,
      neg_inj],
    refl },
  { rintros (g₁ : universal_map m n) (g₂ : universal_map m n) hg₁ hg₂ IH₁ IH₂ hf, resetI,
    haveI Hg₁f : (comp g₁ f).suitable c₁ c₃ := suitable.comp c₂,
    haveI Hg₂f : (comp g₂ f).suitable c₁ c₃ := suitable.comp c₂,
    simp only [add_monoid_hom.map_add, add_monoid_hom.add_apply, eval_Mbar_pow_add, IH₁, IH₂],
    show _ = normed_group_hom.comp_hom _ _,
    simpa [add_monoid_hom.map_add] }
end

@[simp] lemma eval_Mbar_pow_smul (k : ℤ) (f : universal_map m n)
  [f.suitable c₁ c₂] [(k • f).suitable c₁ c₂] :
  eval_Mbar_pow V S r' c₁ c₂ (k • f) = k • f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  by_cases hk : k = 0,
  { simp only [hk, eval_Mbar_pow_zero, zero_smul] },
  simp only [eval_Mbar_pow_def, support_smul k hk],
  rw finset.smul_sum,
  apply finset.sum_congr rfl,
  rintro g hg,
  rw ← smul_assoc,
  simp only [← gsmul_eq_smul k, ← add_monoid_hom.map_gsmul]
end

@[reassoc] lemma eval_Mbar_pow_comp_res (f : universal_map m n)
  [f.suitable c₁ c₂] [f.suitable c₃ c₄] [fact (c₁ ≤ c₃)] [fact (c₂ ≤ c₄)] :
  f.eval_Mbar_pow V S r' c₃ c₄ ≫ LCC_Mbar_pow.res V S r' c₁ c₃ m =
  LCC_Mbar_pow.res V S r' c₂ c₄ n ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  show normed_group_hom.comp_hom _ _ = normed_group_hom.comp_hom _ _,
  rw [eval_Mbar_pow_def, add_monoid_hom.map_sum,
      eval_Mbar_pow_def, add_monoid_hom.map_sum,
      add_monoid_hom.sum_apply],
  apply finset.sum_congr rfl,
  rintro g hg,
  rw [← gsmul_eq_smul, add_monoid_hom.map_gsmul,
      ← gsmul_eq_smul, add_monoid_hom.map_gsmul,
      add_monoid_hom.gsmul_apply],
  haveI : g.suitable c₁ c₂ := f.suitable_of_mem_support c₁ c₂ g hg,
  haveI : g.suitable c₃ c₄ := f.suitable_of_mem_support c₃ c₄ g hg,
  have := basic_universal_map.eval_Mbar_pow_comp_res V S r' c₁ c₂ c₃ c₄ g,
  change normed_group_hom.comp_hom _ _ = normed_group_hom.comp_hom _ _ at this,
  rw this
end

@[reassoc] lemma eval_Mbar_pow_comp_Tinv (f : universal_map m n) [f.suitable c₁ c₂] :
  eval_Mbar_pow V S r' (r'⁻¹ * c₁) (r'⁻¹ * c₂) f ≫ LCC_Mbar_pow.Tinv V S r' c₁ m =
    LCC_Mbar_pow.Tinv V S r' c₂ n ≫ eval_Mbar_pow V S r' c₁ c₂ f :=
begin
  show normed_group_hom.comp_hom _ _ = normed_group_hom.comp_hom _ _,
  rw [eval_Mbar_pow_def, eval_Mbar_pow_def, add_monoid_hom.map_sum, add_monoid_hom.map_sum,
      add_monoid_hom.sum_apply],
  apply finset.sum_congr rfl,
  intros g hg,
  rw [← gsmul_eq_smul, ← gsmul_eq_smul, add_monoid_hom.map_gsmul, add_monoid_hom.map_gsmul,
      add_monoid_hom.gsmul_apply],
  congr' 1,
  haveI : g.suitable c₁ c₂ := suitable_of_mem_support f c₁ c₂ g hg,
  exact g.eval_Mbar_pow_comp_Tinv V S r' _ _
end

@[reassoc] lemma eval_Mbar_pow_comp_T_inv (f : universal_map m n) [f.suitable c₁ c₂]
  [fact (0 < r)] [normed_with_aut r V] :
  f.eval_Mbar_pow V S r' c₁ c₂ ≫ normed_with_aut.T.inv =
    normed_with_aut.T.inv ≫ f.eval_Mbar_pow V S r' c₁ c₂ :=
begin
  show normed_group_hom.comp_hom _ _ = normed_group_hom.comp_hom _ _,
  rw [eval_Mbar_pow_def, add_monoid_hom.map_sum, add_monoid_hom.map_sum,
      add_monoid_hom.sum_apply],
  apply finset.sum_congr rfl,
  intros g hg,
  rw [← gsmul_eq_smul, add_monoid_hom.map_gsmul, add_monoid_hom.map_gsmul,
      add_monoid_hom.gsmul_apply],
  congr' 1,
  haveI : g.suitable c₁ c₂ := suitable_of_mem_support f c₁ c₂ g hg,
  exact g.eval_Mbar_pow_comp_T_inv V S r r' _ _
end

end universal_map

end breen_deligne
#lint- only unused_arguments def_lemma doc_blame
