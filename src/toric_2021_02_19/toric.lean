--import data.polynomial.degree.lemmas
--import algebra.module.ordered
import algebra.regular
--import ring_theory.noetherian
import toric_2021_02_19.is_inj_nonneg
--import linear_algebra.basic
import linear_algebra.finite_dimensional
import algebra.big_operators.basic
import data.real.nnreal
--import facts.nnreal
--import algebra.algebra.basic
--import topology.separation
import topology.algebra.ordered
import toric_2021_02_19.PR_made
import toric_2021_02_19.pointed
--import analysis.normed_space.inner_product

/-! In the intended application, these are the players:
* `R₀ = ℕ`;
* `R = ℤ`;
* `M`and `N` are free finitely generated `ℤ`-modules that are dual to each other;
* `P = ℤ` is the target of the natural pairing `M ⊗ N → ℤ`.
-/

open_locale big_operators classical nnreal

-- Here we make the general statements that require few assumptions on the various types.
section abstract

variables (R₀ R M : Type*)

namespace submodule


section comm_semiring

variables {R₀} {M}

variables [comm_semiring R₀] [add_comm_monoid M] [semimodule R₀ M]

/-- This definition does not assume that `R₀` injects into `R`.  If the map `R₀ → R` has a
non-trivial kernel, this might not be the definition you think. -/
def saturated (s : submodule R₀ M) : Prop :=
∀ (r : R₀) (hr : is_regular r) (m : M), r • m ∈ s → m ∈ s

/--  The saturation of a submodule `s ⊆ M` is the submodule obtained from `s` by adding all
elements of `M` that admit a multiple by a regular element of `R₀` lying in `s`. -/
def saturation (s : submodule R₀ M) : submodule R₀ M :=
{ carrier := { m : M | ∃ (r : R₀), is_regular r ∧ r • m ∈ s },
  zero_mem' := ⟨1, is_regular_one, by { rw smul_zero, exact s.zero_mem }⟩,
  add_mem' := begin
    rintros a b ⟨q, hqreg, hqa⟩ ⟨r, hrreg, hrb⟩,
    refine ⟨q * r, is_regular_mul_iff.mpr ⟨hqreg, hrreg⟩, _⟩,
    rw [smul_add],
    refine s.add_mem _ _,
    { rw [mul_comm, mul_smul],
      exact s.smul_mem _ hqa },
    { rw mul_smul,
      exact s.smul_mem _ hrb },
  end,
  smul_mem' := λ c m ⟨r, hrreg, hrm⟩,
    ⟨r, hrreg, by {rw smul_algebra_smul_comm, exact s.smul_mem _ hrm}⟩ }

/--  The saturation of `s` contains `s`. -/
lemma le_saturation (s : submodule R₀ M) : s ≤ saturation s :=
λ m hm, ⟨1, is_regular_one, by rwa one_smul⟩

/-- The set `S` is contained in the saturation of the submodule spanned by `S` itself. -/
lemma set_subset_saturation  {S : set M} :
  S ⊆ (submodule.saturation (submodule.span R₀ S)) :=
set.subset.trans (submodule.subset_span : S ⊆ submodule.span R₀ S)
  (submodule.le_saturation (submodule.span R₀ S))

/-
TODO: develop the API for the definitions
`is_cyclic`, `pointed`, `has_extremal_ray`, `extremal_rays`.
Prove(?) `sup_extremal_rays`, if it is true, even in the test case.
-/
/--  A cyclic submodule is a submodule generated by a single element. -/
def is_cyclic (s : submodule R₀ M) : Prop := ∃ m : M, (R₀ ∙ m) = s

variables (R₀ M)

/--  A semimodule is cyclic if its top submodule is generated by a single element. -/
def semimodule.is_cyclic : Prop := is_cyclic (⊤ : submodule R₀ M)

variables {R₀ M}

/--  The zero submodule is cyclic. -/
lemma is_cyclic_bot : is_cyclic (⊥ : submodule R₀ M) :=
⟨_, span_zero_singleton⟩

/--  An extremal ray of a submodule `s` is a cyclic submodule `r` with the property that if two
elements of `s` have sum contained in `r`, then the elements themselves are contained in `r`.
These are the "edges" of the cone. -/
structure has_extremal_ray (s r : submodule R₀ M) : Prop :=
(incl : r ≤ s)
(is_cyclic : r.is_cyclic)
(mem_of_sum_mem : ∀ {x y : M}, x ∈ s → y ∈ s → x + y ∈ r → (x ∈ r ∧ y ∈ r))

/--  The set of all extremal rays of a submodule.  Hopefully, these are a good replacement for
generators, in the case in which the cone is `pointed`. -/
def extremal_rays (s : submodule R₀ M) : set (submodule R₀ M) :=
{ r | s.has_extremal_ray r }

/-  The `is_scalar_tower R₀ R M` assumption is not needed to state `pointed`, but will likely play
a role in the proof of `sup_extremal_rays`. -/
variables [semiring R] [semimodule R M]

variables [algebra R₀ R] [is_scalar_tower R₀ R M]

/--  Hopefully, this lemma will be easy to prove. -/
lemma sup_extremal_rays {s : submodule R₀ M} (sp : s.pointed R) :
  (⨆ r ∈ s.extremal_rays, r) = s :=
begin
  refine le_antisymm (bsupr_le $ λ i hi, hi.1) _,
  intros m ms t ht,
  rcases ht with ⟨y, rfl⟩,
  simp only [forall_apply_eq_imp_iff', supr_le_iff, set.mem_range, mem_coe, set.mem_Inter,
    set.mem_set_of_eq, exists_imp_distrib],
  intros a,
  rcases sp with ⟨el, lo⟩,
  sorry
end

end comm_semiring

section integral_domain

variables [integral_domain R₀] [add_comm_monoid M] [semimodule R₀ M]

/--  A sanity check that our definitions imply something not completely trivial
in an easy situation! -/
lemma sat {s t : submodule R₀ M}
  (s0 : s ≠ ⊥) (ss : s.saturated) (st : s ≤ t) (ct : is_cyclic t) :
  s = t :=
begin
  refine le_antisymm st _,
  rcases ct with ⟨t0, rfl⟩,
  refine (span_singleton_le_iff_mem t0 s).mpr _,
  rcases (submodule.ne_bot_iff _).mp s0 with ⟨m, hm, m0⟩,
  rcases (le_span_singleton_iff.mp st) _ hm with ⟨c, rfl⟩,
  refine ss _ (is_regular_of_ne_zero _) _ hm,
  exact λ h, m0 (by rw [h, zero_smul]),
end

end integral_domain

end submodule


section pairing

variables [comm_semiring R₀] [comm_semiring R] [algebra R₀ R]
  [add_comm_monoid M] [semimodule R₀ M] [semimodule R M] [is_scalar_tower R₀ R M]

variables (N P : Type*)
  [add_comm_monoid N] [semimodule R₀ N] [semimodule R N] [is_scalar_tower R₀ R N]
  [add_comm_monoid P] [semimodule R₀ P] [semimodule R P] [is_scalar_tower R₀ R P]
  (P₀ : submodule R₀ P)

/-- An R-pairing on the R-modules M, N, P is an R-linear map M -> Hom_R(N,P). -/
@[derive has_coe_to_fun] def pairing := M →ₗ[R] N →ₗ[R] P

namespace pairing

instance inhabited : inhabited (pairing R M N P) :=
⟨{to_fun := 0, map_add' := by simp, map_smul' := by simp }⟩

variables {R₀ R M N P}

/--  Given a pairing between the `R`-modules `M` and `N`, we obtain a pairing between `N` and `M`
by exchanging the factors. -/
def flip : pairing R M N P → pairing R N M P := linear_map.flip

variables (f : pairing R M N P)

/-- For a given pairing `<_, _> : M × N → P` and an element `m ∈ M`, `mul_left` is the linear map
`n ↦ <m, n>`.
-- Left multiplication may not be needed.
def mul_left (m : M) : N →ₗ[R] P :=
{ to_fun := λ n, f m n,
  map_add' := λ x y, by simp only [linear_map.add_apply, linear_map.map_add],
  map_smul' := λ x y, by simp only [linear_map.smul_apply, linear_map.map_smul] }

/-- For a given pairing `<_, _> : M × N → P` and an element `n ∈ N`, `mul_right` is the linear map
`m ↦ <m, n>`. -/
def mul_right (n : N) : M →ₗ[R] P :=
{ to_fun := λ m, f m n,
  map_add' := λ x y, by simp only [linear_map.add_apply, linear_map.map_add],
  map_smul' := λ x y, by simp only [linear_map.smul_apply, linear_map.map_smul] }
-/

example {n : N} : f.flip n = f.flip n := rfl

/--  A pairing `M × N → P` is `left_nondegenerate` if `0 ∈ N` is the only element of `N` pairing
to `0` with all elements of `M`. -/
def left_nondegenerate : Prop := ∀ n : N, (∀ m : M, f m n = 0) → n = 0

/--  A pairing `M × N → P` is `right_nondegenerate` if `0 ∈ M` is the only element of `M` pairing
to `0` with all elements of `N`. -/
def right_nondegenerate : Prop := ∀ m : M, (∀ n : N, f m n = 0) → m = 0

/--  A pairing `M × N → P` is `perfect` if it is left and right nondegenerate. -/
def perfect : Prop := left_nondegenerate f ∧ right_nondegenerate f

/--  For a subset `s ⊆ M`, the `dual_set s` is the submodule consisting of all elements of `N`
that have "positive pairing with all the elements of `s`.  "Positive" means that it lies in the
`R₀`-submodule `P₀` of `P`. -/
def dual_set (s : set M) : submodule R₀ N :=
{ carrier := { n : N | ∀ m ∈ s, f m n ∈ P₀ },
  zero_mem' := λ m hm, by simp only [linear_map.map_zero, P₀.zero_mem],
  add_mem' := λ n1 n2 hn1 hn2 m hm, begin
    rw linear_map.map_add,
    exact P₀.add_mem (hn1 m hm) (hn2 m hm),
  end,
  smul_mem' := λ r n h m hms, by simp [h m hms, P₀.smul_mem] }

lemma mem_dual_set (s : set M) (n : N) :
  n ∈ f.dual_set P₀ s ↔ ∀ m ∈ s, f m n ∈ P₀ := iff.rfl

section saturated

variables {P₀} (hP₀ : P₀.saturated)
include hP₀

lemma smul_regular_iff {r : R₀} (hr : is_regular r) (p : P) :
  r • p ∈ P₀ ↔ p ∈ P₀ :=
⟨hP₀ _ hr _, P₀.smul_mem _⟩

lemma dual_set_saturated (s : set M) (hP₀ : P₀.saturated) :
  (f.dual_set P₀ s).saturated :=
λ r hr n hn m hm, by simpa [smul_regular_iff hP₀ hr] using hn m hm

end saturated

variable {P₀}

lemma dual_subset {s t : set M} (st : s ⊆ t) : f.dual_set P₀ t ≤ f.dual_set P₀ s :=
λ n hn m hm, hn m (st hm)

lemma mem_span_dual_set (s : set M) :
  f.dual_set P₀ (submodule.span R₀ s) = f.dual_set P₀ s :=
begin
  refine (dual_subset f submodule.subset_span).antisymm _,
  { refine λ n hn m hm, submodule.span_induction hm hn _ _ _,
    { simp only [linear_map.map_zero, submodule.zero_mem, linear_map.zero_apply] },
    { exact λ x y hx hy, by simp [P₀.add_mem hx hy] },
    { exact λ r m hm, by simp [P₀.smul_mem _ hm] } }
end

lemma subset_dual_dual {s : set M} : s ⊆ f.flip.dual_set P₀ (f.dual_set P₀ s) :=
λ m hm _ hm', hm' m hm

lemma subset_dual_set_of_subset_dual_set {S : set M} {T : set N}
  (ST : S ⊆ f.flip.dual_set P₀ T) :
  T ⊆ f.dual_set P₀ S :=
λ n hn m hm, ST hm _ hn

lemma le_dual_set_of_le_dual_set {S : submodule R₀ M} {T : submodule R₀ N}
  (ST : S ≤ f.flip.dual_set P₀ T) :
  T ≤ f.dual_set P₀ S :=
subset_dual_set_of_subset_dual_set _ ST

lemma dual_set_closure_eq {s : set M} :
  f.dual_set P₀ (submodule.span R₀ s) = f.dual_set P₀ s :=
begin
  refine (dual_subset _ submodule.subset_span).antisymm _,
  refine λ n hn m hm, submodule.span_induction hm hn _ _ _,
  { simp only [linear_map.map_zero, linear_map.zero_apply, P₀.zero_mem] },
  { exact λ x y hx hy, by simp only [linear_map.add_apply, linear_map.map_add, P₀.add_mem hx hy] },
  { exact λ r m hmn, by simp [P₀.smul_mem r hmn] },
end

lemma dual_eq_dual_saturation {S : set M} (hP₀ : P₀.saturated) :
  f.dual_set P₀ S = f.dual_set P₀ ((submodule.span R₀ S).saturation) :=
begin
  refine le_antisymm _ (dual_subset _ (submodule.set_subset_saturation)),
  rintro n hn m ⟨r, hr_reg, hrm⟩,
  refine (smul_regular_iff hP₀ hr_reg _).mp _,
  rw [← mem_span_dual_set, mem_dual_set] at hn,
  simpa using hn (r • m) hrm
end

/- flip the inequalities assuming saturatedness -/
lemma le_dual_set_of_le_dual_set_satu {S : submodule R₀ M} {T : submodule R₀ N}
  (ST : S ≤ f.flip.dual_set P₀ T) :
  T ≤ f.dual_set P₀ S :=
subset_dual_set_of_subset_dual_set _ ST

lemma subset_dual_set_iff {S : set M} {T : set N} :
  S ⊆ f.flip.dual_set P₀ T ↔ T ⊆ f.dual_set P₀ S :=
⟨subset_dual_set_of_subset_dual_set f, subset_dual_set_of_subset_dual_set f.flip⟩

lemma le_dual_set_iff {S : submodule R₀ M} {T : submodule R₀ N} :
  S ≤ f.flip.dual_set P₀ T ↔ T ≤ f.dual_set P₀ S :=
subset_dual_set_iff _

/- This lemma is a weakining of `dual_dual_of_saturated`.
It has the advantage that we can prove it in this level of generality!  ;) -/
lemma dual_dual_dual (S : set M) :
  f.dual_set P₀ (f.flip.dual_set P₀ (f.dual_set P₀ S)) = f.dual_set P₀ S :=
le_antisymm (λ m hm n hn, hm _ ((subset_dual_set_iff f).mpr set.subset.rfl hn))
  (λ m hm n hn, hn m hm)

variable (P₀)

/--  The rays of the dual of the set `s` are the duals of the subsets of `s` that happen to be
cyclic. -/
def dual_set_rays (s : set M) : set (submodule R₀ N) :=
{ r | r.is_cyclic ∧ ∃ s' ⊆ s, r = f.dual_set P₀ s' }

/-  We may need extra assumptions for this. -/
/--  The link between the rays of the dual and the extremal rays of the dual should be the
crucial finiteness step: if `s` is finite, there are only finitely many `dual_set_rays`, since
there are at most as many as there are subsets of `s`.  If the extremal rays generate
dual of `s`, then we are in a good position to prove Gordan's lemma! -/
lemma dual_set_rays_eq_extremal_rays (s : set M) :
  f.dual_set_rays P₀ s = (f.dual_set P₀ s).extremal_rays :=
sorry

lemma dual_set_pointed (s : set M) (hs : (submodule.span R₀ s).saturation) :
  (f.dual_set P₀ s).pointed R := sorry

--def dual_set_generators (s : set M) : set N := { n : N | }

--lemma dual_fg_of_finite {s : set M} (fs : s.finite) : (f.dual_set P₀ s).fg :=
--sorry

/-
/--  The behaviour of `dual_set` under smultiplication. -/
lemma dual_smul {s : set M} {r : R₀} {m : M} :
  f.dual_set P₀ (s.insert m) ≤ f.dual_set P₀ (s.insert (r • m)) :=
begin
  intros n hn m hm,
  rcases hm with rfl | hm,
  { rw [linear_map.map_smul_of_tower, linear_map.smul_apply],
    exact P₀.smul_mem r (hn m (s.mem_insert m)) },
  { exact hn _ (set.mem_insert_iff.mpr (or.inr hm)) }
end
-/

lemma dual_dual_of_saturated {S : submodule R₀ M} (Ss : S.saturated) :
  f.flip.dual_set P₀ (f.dual_set P₀ S) = S :=
begin
  refine le_antisymm _ (subset_dual_dual f),
  intros m hm,
--  rw mem_dual_set at hm,
  change ∀ (n : N), n ∈ (dual_set P₀ f ↑S) → f m n ∈ P₀ at hm,
  simp_rw mem_dual_set at hm,
  -- is this true? I (KMB) don't know and the guru (Damiano) has left!
  -- oh wait, no way is this true, we need some nondegeneracy condition
  -- on f, it's surely not true if f is just the zero map.
  -- I (DT) think that you are right, Kevin.  We may now start to make assumptions
  -- that are more specific to our situation.
  sorry,
end

/-
def to_linear_dual (f : pairing R M N R) : N →ₗ[R] (M →ₗ[R] R) :=
{ to_fun := λ n,
  { to_fun := λ m, f m n,
    map_add' := λ x y, by simp only [linear_map.add_apply, linear_map.map_add],
    map_smul' := λ x y, by simp only [linear_map.smul_apply, linear_map.map_smul] },
  map_add' := λ x y, by simpa only [linear_map.map_add],
  map_smul' := λ r n, by simpa only [algebra.id.smul_eq_mul, linear_map.map_smul] }

lemma to_ld (f : pairing R M N R) (n : N) : to_linear_dual f n = mul_right f n := rfl

-- this lemma requires some extra hypotheses: at the very least, some finite-generation
-- condition: the "standard" scalar product on `ℝ ^ (⊕ ℕ)` has power-series as its dual
-- but is non-degenerate.
/-- A pairing `f` between two `R`-modules `M` and `N` with values in `R` is perfect if every
linear function `l : M →ₗ[R] R` is represented as -/
lemma left_nondegenerate_exists {f : pairing R M N R} (r : right_nondegenerate f) :
  ∀ l : M →ₗ[R] R, ∃ n : N, ∀ m : M, l m = f m n :=
begin
  intros l,
  sorry,
end
-/

open submodule

lemma of_non_deg {M : Type*} [add_comm_group M] {ι : Type*} {f : pairing ℤ M M ℤ} {v : ι → M}
  (nd : perfect f) (sp : submodule.span ℤ (v '' set.univ)) :
  pointed ℤ (submodule.span ℕ (v '' set.univ)) :=
begin
--  tidy?,
  sorry
end


end pairing

end pairing

end abstract

-- ending the section to clear out all the assumptions

section add_group

variables {R₀ R : Type*} [comm_ring R₀] [comm_ring R] [algebra R₀ R]
variables {M : Type*} [add_comm_group M] [module R₀ M] [module R M] [is_scalar_tower R₀ R M]
--variables {M N : Type*} [add_comm_monoid M] --[semimodule ℕ M] [semimodule ℤ M]
  --[algebra ℕ ℤ] [is_scalar_tower ℕ ℤ M]

--variables {P : Type*}
--  [add_comm_monoid N] --[semimodule ℕ N] [semimodule ℤ N] --[is_scalar_tower ℕ ℤ N]
--  [add_comm_monoid P] --[semimodule ℕ P] [semimodule ℤ P] --[is_scalar_tower ℕ ℤ P]
--  (P₀ : submodule ℕ P)


open pairing submodule

/-
lemma pointed_of_is_basis {ι : Type*} (v : ι → M) (bv : is_basis R v) :
  pointed R (submodule.span R₀ (set.range v)) :=
begin
  obtain ⟨l, hl⟩ : ∃ l : M →ₗ[R] R, ∀ i : ι, l (v i) = 1 :=
    ⟨bv.constr (λ _, 1), λ i, constr_basis bv⟩,
  refine Exists.intro
  { to_fun := ⇑l,
    map_add' := by simp only [forall_const, eq_self_iff_true, linear_map.map_add],
    map_smul' := λ m x, by
    { rw [algebra.id.smul_eq_mul, linear_map.map_smul],
      refine congr _ rfl,
      exact funext (λ y, by simp only [has_scalar.smul, gsmul_int_int]) } } _,
  rintros m hm (m0 : l m = 0),
  obtain ⟨c, csup, rfl⟩ := span_as_sum hm,
  simp_rw [linear_map.map_sum] at m0,--, linear_map.map_smul_of_tower] at m0,
  have : linear_map.compatible_smul M R R₀ R := sorry,
  conv_lhs at m0 {
    apply_congr, skip, rw @linear_map.map_smul_of_tower _ _ _ _ _ _ _ _ _ _ _ this l, skip },
  have : ∑ (i : M) in c.support, (c i • l i : R) = ∑ (i : M) in c.support, (c i : R),
  { refine finset.sum_congr rfl (λ x hx, _),
    rcases set.mem_range.mp (set.mem_of_mem_of_subset (finset.mem_coe.mpr hx) csup) with ⟨i, rfl⟩,
    simp [hl _, (•)], },
  rw this at m0,
  have : ∑ (i : M) in c.support, (0 : M) = 0,
  { rw finset.sum_eq_zero,
    simp only [eq_self_iff_true, forall_true_iff] },
  rw ← this,
  refine finset.sum_congr rfl (λ x hx, _),
  rw finset.sum_eq_zero_iff_of_nonneg at m0,
  { rw [int.coe_nat_eq_zero.mp (m0 x hx), zero_smul] },
  { exact λ x hx, int.coe_nat_nonneg _ }
end
-/

end add_group

section concrete


/-! In the intended application, these are the players:
* `R₀ = ℕ`;
* `R = ℤ`;
* `M`and `N` are free finitely generated `ℤ`-modules that are dual to each other;
* `P = ℤ` is the target of the natural pairing `M ⊗ N → ℤ`.
-/

namespace pairing

open pairing submodule

variables {M : Type*} [add_comm_group M] --[semimodule ℕ M]
-- [semimodule ℤ M]
--variables {M N : Type*} [add_comm_monoid M] --[semimodule ℕ M] [semimodule ℤ M]
  --[algebra ℕ ℤ] [is_scalar_tower ℕ ℤ M]

--variables {P : Type*}
--  [add_comm_monoid N] --[semimodule ℕ N] [semimodule ℤ N] --[is_scalar_tower ℕ ℤ N]
--  [add_comm_monoid P] --[semimodule ℕ P] [semimodule ℤ P] --[is_scalar_tower ℕ ℤ P]
--  (P₀ : submodule ℕ P)

/-  Kevin's proof. -/
lemma finite.smul_of_finite {S M : Type*} [semiring S] [add_comm_monoid M] [semimodule S M]
  {G : set S} {v : set M} (fG : G.finite) (fv : v.finite) :
  (G • v).finite :=
fG.image2 (•) fv

lemma finite.span_restrict {R S : Type*} [semiring S]
  [comm_semiring R] [semimodule R M] [semimodule S M] [algebra R S]
  [is_scalar_tower R S M] {G : set S} {v : set M}
  (fG : G.finite) (spg : submodule.span R G = ⊤)
  (fv : v.finite) (hv : submodule.span S v = ⊤) :
  ∃ t : set M, t.finite ∧ submodule.span R (t : set M) = (span S (v : set M)).restrict_scalars R :=
⟨G • v, fG.image2 (•) fv, span_smul spg v⟩

lemma finset.span_restrict {R S : Type*} [semiring S]
  [comm_semiring R] [semimodule R M] [semimodule S M] [algebra R S]
  [is_scalar_tower R S M]
  (G : finset S) (spg : submodule.span R (G : set S) = ⊤)
  (v : finset M) (hv : submodule.span S (v : set M) = ⊤) :
  ∃ t : finset M, submodule.span R (t : set M) = (span S (v : set M)).restrict_scalars R :=
begin
  obtain ⟨t, ft, co⟩ := finite.span_restrict G.finite_to_set spg v.finite_to_set hv,
  haveI ff : fintype t := ft.fintype,
  refine ⟨t.to_finset, by simpa only [set.coe_to_finset]⟩
end


/--  The submodule spanned by a set `s` over an `R`-algebra `S` is spanned as an `R`-module by
`s ∪ - s`, if for every element `a ∈ S`, either `a` or `- a` is in the image of `R`. -/
lemma finset.restrict_inf_span {R S : Type*} [ordered_semiring S] [topological_space S]
  [order_topology S] [comm_semiring R] [semimodule R M] [semimodule S M] [algebra R S]
  [is_scalar_tower R S M]
  -- the `R`-algebra `S` is compactly generated as an `R`-module
  (G : set S) (cG : is_compact G) (spg : submodule.span R G = ⊤)
  -- `R` is discrete as an `S`-module
  -- this works well, for instance, in the case `ℤ ⊆ ℝ`.
  -- It does not apply in the case `ℚ ⊆ ℝ`
  (dR : discrete_topology (set.range (algebra_map R S)))
  -- the `R`-lattice structure on `M` is given by the span of the set `v`
  (v : set M) (hv : submodule.span S v = ⊤)
  -- a finitely generated `S`-submodule of `M` is also finitely generated over `R`.
  (s : finset M) (pro : finset S) :
  ∃ t : finset M, submodule.span R (t : set M) =
    ((submodule.span S (s : set M)).restrict_scalars R) ⊓ submodule.span R v :=
begin
  let GS : set S := (set.range (algebra_map R S)) ∩ G,
  haveI dGS : discrete_topology GS :=
    discrete_topology.of_subset dR ((set.range ⇑(algebra_map R S)).inter_subset_left G),
  have cGS : is_compact (set.univ : set GS), sorry,
  have GS_finite : (set.univ : set GS).finite := finite_of_is_compact_of_discrete set.univ cGS,
  set GSM : set M := (GS : set S) • (s : set M),
  have : GSM.finite,sorry,
  refine ⟨this.to_finset, _⟩,
  sorry,
/-
  -- con questo voglio concludere la finitezza
  --apply fintype_of_compact_of_discrete,
-/
end

/--  The submodule spanned by a set `s` over an `R`-algebra `S` is spanned as an `R`-module by
`s ∪ - s`, if for every element `a ∈ S`, either `a` or `- a` is in the image of `R`. -/
lemma subset.span_union_neg_self_eq {R S : Type*} [ordered_comm_ring S]
  [comm_semiring R] [semimodule R M] [module S M] [algebra R S] [is_scalar_tower R S M]
  (ff : ∀ a : S, ∃ n : R, a = algebra_map R S n ∨ a = - algebra_map R S n) (s : set M) :
  (submodule.span R (s ∪ - s)).carrier = submodule.span S (s : set M) :=
begin
  ext m,
  refine ⟨λ hm, _, λ hm, _⟩,
  { refine (span S (s : set M)).mem_coe.mpr _,
    rcases mem_span_set.mp hm with ⟨c, csup, rfl⟩,
    refine sum_mem _ (λ a as, (_ : c a • a ∈ span S s)),
    rw ← algebra_map_smul S (c a) a,
    refine smul_mem (span S s) _ _,
    obtain cams : a ∈ s ∪ - s := set.mem_of_mem_of_subset as csup,
    cases (set.mem_union a s _).mp cams,
    { exact subset_span h },
    { refine (neg_mem_iff _).mp (subset_span h) } },
  { rcases mem_span_set.mp hm with ⟨c, csup, rfl⟩,
    rw [mem_carrier, mem_coe],
    refine sum_mem _ (λ a as, (_ : c a • a ∈ span R (s ∪ - s))),
    rcases ff (c a) with ⟨ca, cap | can⟩,
    { rw [cap, algebra_map_smul],
      refine smul_mem _ ca _,
      refine subset_span (set.mem_union_left _ _),
      exact set.mem_of_mem_of_subset (finset.mem_coe.mpr as) csup },
    { rw [can, neg_smul, algebra_map_smul, ← smul_neg],
      refine smul_mem _ ca _,
      refine subset_span (set.mem_union_right _ _),
      rw [set.mem_neg, neg_neg],
      exact set.mem_of_mem_of_subset (finset.mem_coe.mpr as) csup } }
end


lemma finset.span_union_neg_self_eq {ι R S : Type*} [ordered_comm_ring S]
  [comm_semiring R] [semimodule R M] [module S M] [algebra R S] [is_scalar_tower R S M]
  (ff : ∀ s : S, ∃ n : R, s = algebra_map R S n ∨ s = - algebra_map R S n)
  {v : ι → M} (bv : is_basis S v) (s : finset M) (hRS : is_inj_nonneg (algebra_map R S)) :
  ∃ sR : finset M,
    (submodule.span R (sR : set M)).carrier = submodule.span S (s : set M) :=
begin
  let ms : finset M := s.image (λ i, - i),
  refine ⟨s ∪ (s.image (λ i, - i)), _⟩,
  ext m,
  refine ⟨_, _⟩;intros hm,
  { refine (span S (s : set M)).mem_coe.mpr _,
    rcases mem_span_finset.mp hm with ⟨c, rfl⟩,
    refine sum_mem _ (λ a as, _),
    rw ← algebra_map_smul S (c a) a,
    refine smul_mem (span S (s : set M)) _ _,
    sorry,
/-
    cases finset.mem_union.mp as,
    have : a ∈ span S {a} := mem_span_singleton_self a,
    have asu : {a} ⊆ s := finset.singleton_subset_iff.mpr h,
    have : a ∈ (span S ↑s).carrier,refine set.mem_of_mem_of_subset asu _,
    exact add_comm_group.to_add_comm_monoid M,
    exact _inst_5,exact coe_to_lift,
    simp,
    convert asu,
    simp,
    refine set.mem_of_mem_of_subset _ this,
    simp,
    rintros?,
    dsimp,
-/
     },
  { --rw [mem_coe] at hm,
    rcases mem_span_set.mp hm with ⟨c, csup, rfl⟩,
    rw [mem_carrier, mem_coe],
    refine sum_mem _ _,
    intros a as,
    dsimp,
    rcases ff (c a) with ⟨ca, cap | can⟩,
    rw [cap, algebra_map_smul],
    refine smul_mem _ ca _,
    simp,
    sorry,
    sorry,
  },
end

lemma subset.span_union_neg_self_eq_inf {ι R S : Type*} [linear_ordered_field S]
  [comm_semiring R] [semimodule R M] [module S M] [algebra R S] [is_scalar_tower R S M]
  (ff : ∀ s : S, 0 ≤ s → ∃ n d : R, s = algebra_map R S n / algebra_map R S d)
  {v : ι → M} (bv : is_basis S v) {s : finset M} (hRS : is_inj_nonneg (algebra_map R S)) :
  ∃ sR : finset M, (sR : set M) ⊆ (submodule.span R (set.range v ∪ set.range (λ i, - v i))) ∧
    (submodule.span R (sR : set M)).carrier =
      submodule.span R (set.range v) ∩ submodule.span S (set.range v) :=
begin

  sorry,
end

end pairing

end concrete
/- This might be junk
def standard_pairing_Z : pairing ℤ ℤ ℤ ℤ :=
{ to_fun := λ z,
  { to_fun := λ n, z * n,
    map_add' := mul_add z,
    map_smul' := λ m n, algebra.mul_smul_comm m z n },
  map_add' := λ x y, by simpa [add_mul],
  map_smul' := λ x y, by simpa only [algebra.smul_mul_assoc] }

lemma nond_Z : right_nondegenerate standard_pairing_Z :=
λ m hm, eq.trans (mul_one m).symm (hm 1)


def standard_pairing_Z_sq : pairing ℤ (ℤ × ℤ) (ℤ × ℤ) ℤ :=
{ to_fun := λ z,
  { to_fun := λ n, z.1 * n.1 + z.2 * n.2,
    map_add' := λ x y, by { rw [prod.snd_add, prod.fst_add], ring },
    map_smul' := λ x y,
      by simp only [smul_add, algebra.mul_smul_comm, prod.smul_snd, prod.smul_fst] },
  map_add' := λ x y, begin
    congr,
    ext,
    dsimp,
    rw [prod.snd_add, prod.fst_add, add_mul],
    ring,
  end,
  map_smul' := λ x y, begin
    congr,
    simp only [smul_add, prod.smul_snd, linear_map.coe_mk, prod.smul_fst, algebra.smul_mul_assoc],
  end }

lemma nond_Z_sq : right_nondegenerate standard_pairing_Z_sq :=
begin
  refine λ  m hm, prod.ext _ _,
  { obtain (F : m.fst * (1 : ℤ) + m.snd * (0 : ℤ) = 0) := hm (1, 0),
    simpa using F },
  { obtain (F : m.fst * (0 : ℤ) + m.snd * (1 : ℤ) = 0) := hm (0, 1),
    simpa using F }
end

lemma fd (v : fin 2 → ℤ × ℤ) (ind : linear_independent ℤ v) :
  pointed ℤ (submodule.span ℕ (v '' set.univ)) :=
begin
  refine ⟨_, _⟩,
  convert mul_right standard_pairing_Z_sq (v 0 + v 1),
--  convert @mul_right ℤ (ℤ × ℤ) _ _ _ (ℤ × ℤ) ℤ _ _ _ _ standard_pairing_Z_sq ((1, 1) : ℤ × ℤ),
  intros m hm m0,
  induction m with m1 m2,
  congr,

--  tidy?,

  refine (mul_right standard_pairing_Z_sq ((1, 1) : ℤ × ℤ) : ℤ × ℤ →ₗ[ℤ] ℤ),
--  refine ((λ m : ℤ × ℤ, standard_pairing_Z_sq m (1,1)) : ℤ × ℤ →ₗ[ℤ] ℤ),
  refine
  { to_fun := λ m, standard_pairing_Z_sq m (1,1),
    map_add' :=
      by simp only [forall_const, eq_self_iff_true, linear_map.add_apply, linear_map.map_add],
    map_smul' := λ x m, begin
      rw [standard_pairing_Z_sq, algebra.id.smul_eq_mul, linear_map.map_smul, linear_map.coe_mk, linear_map.coe_mk],
      simp only [has_scalar.smul, gsmul_int_int, linear_map.coe_mk],
  end },
  simp at *, fsplit, work_on_goal 0 { fsplit, work_on_goal 0 { intros ᾰ, cases ᾰ }, work_on_goal 1 { intros x y, cases y, cases x, dsimp at * }, work_on_goal 2 { intros m x, cases x, dsimp at * } }, work_on_goal 3 { intros x ᾰ ᾰ_1, cases x, dsimp at *, simp at *, simp at *, fsplit, work_on_goal 0 { assumption } },
  { refl },
  { simp [(•)] },

  convert pointed_of_sub_R M,
end

#exit

lemma fd {ι : Type*} (s : finset ι) (v : ι → ℤ × ℤ) (ind : linear_independent ℤ v) :
  pointed ℤ (submodule.span ℕ (v '' set.univ)) :=
begin
  refine ⟨_, _⟩,
  convert mul_right standard_pairing_Z_sq (∑ a in s, v a),
--  convert @mul_right ℤ (ℤ × ℤ) _ _ _ (ℤ × ℤ) ℤ _ _ _ _ standard_pairing_Z_sq ((1, 1) : ℤ × ℤ),
  intros m hm m0,
  induction m with m1 m2,
  congr,

--  tidy?,

  refine (mul_right standard_pairing_Z_sq ((1, 1) : ℤ × ℤ) : ℤ × ℤ →ₗ[ℤ] ℤ),
--  refine ((λ m : ℤ × ℤ, standard_pairing_Z_sq m (1,1)) : ℤ × ℤ →ₗ[ℤ] ℤ),
  refine
  { to_fun := λ m, standard_pairing_Z_sq m (1,1),
    map_add' :=
      by simp only [forall_const, eq_self_iff_true, linear_map.add_apply, linear_map.map_add],
    map_smul' := λ x m, begin
      rw [standard_pairing_Z_sq, algebra.id.smul_eq_mul, linear_map.map_smul, linear_map.coe_mk, linear_map.coe_mk],
      simp only [has_scalar.smul, gsmul_int_int, linear_map.coe_mk],
  end },
  simp at *, fsplit, work_on_goal 0 { fsplit, work_on_goal 0 { intros ᾰ, cases ᾰ }, work_on_goal 1 { intros x y, cases y, cases x, dsimp at * }, work_on_goal 2 { intros m x, cases x, dsimp at * } }, work_on_goal 3 { intros x ᾰ ᾰ_1, cases x, dsimp at *, simp at *, simp at *, fsplit, work_on_goal 0 { assumption } },
  { refl },
  { simp [(•)] },

  convert pointed_of_sub_R M,
end

lemma fd {ι : Type*} (v : ι → ℤ × ℤ) (ind : linear_independent ℤ v) :
  pointed ℤ (submodule.span ℕ (v '' set.univ)) :=
begin
  refine ⟨_, _⟩,
  convert mul_right standard_pairing_Z_sq (1, 1),
--  convert @mul_right ℤ (ℤ × ℤ) _ _ _ (ℤ × ℤ) ℤ _ _ _ _ standard_pairing_Z_sq ((1, 1) : ℤ × ℤ),
  intros m hm m0,

  refine (mul_right standard_pairing_Z_sq ((1, 1) : ℤ × ℤ) : ℤ × ℤ →ₗ[ℤ] ℤ),
--  refine ((λ m : ℤ × ℤ, standard_pairing_Z_sq m (1,1)) : ℤ × ℤ →ₗ[ℤ] ℤ),
  refine
  { to_fun := λ m, standard_pairing_Z_sq m (1,1),
    map_add' :=
      by simp only [forall_const, eq_self_iff_true, linear_map.add_apply, linear_map.map_add],
    map_smul' := λ x m, begin
      rw [standard_pairing_Z_sq, algebra.id.smul_eq_mul, linear_map.map_smul, linear_map.coe_mk, linear_map.coe_mk],
      simp only [has_scalar.smul, gsmul_int_int, linear_map.coe_mk],
  end },
  simp at *, fsplit, work_on_goal 0 { fsplit, work_on_goal 0 { intros ᾰ, cases ᾰ }, work_on_goal 1 { intros x y, cases y, cases x, dsimp at * }, work_on_goal 2 { intros m x, cases x, dsimp at * } }, work_on_goal 3 { intros x ᾰ ᾰ_1, cases x, dsimp at *, simp at *, simp at *, fsplit, work_on_goal 0 { assumption } },
  { refl },
  { simp [(•)] },

  convert pointed_of_sub_R M,
end



lemma pointed_of_sub_Z {ι : Type*} (v : ι → ℤ) (ind : linear_independent ℤ v) :
  pointed ℤ (submodule.span ℕ (v '' set.univ)) :=
by convert pointed_of_sub_R ℤ

lemma fd {ι : Type*} (v : ι → M) (ind : linear_independent ℤ v) :
  pointed ℤ (submodule.span ℕ (v '' set.univ)) :=
begin
  tidy?,
  convert pointed_of_sub_R M,
end
-/
