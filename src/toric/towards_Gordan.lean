/-
import linear_algebra.matrix

open_locale big_operators

universe u
variables {V : Type u} [fintype V]

lemma sum_coe_nat (F : V → ℕ) : ↑ (∑ x : V, F x) = ∑ x : V, (F x : ℤ) :=
begin
  rw ← add_monoid_hom.coe_sum _ _,
  unfold_coes,
  simp,
  rw sum_congr (λ f, (F f : ℤ)) F,
  simp,

  sorry
end

#exit
-/

import toric.toric
import linear_algebra.free_module


/-!
Let `V` be a `ℚ`-vector space and let `ι` be an indexing set.  Assume that `v : ι → V` is a
basis for `V`.  For the statement of Gordan's lemma, the basis is finite, but for some of the
following lemmas, this assumption may not be needed.
The basis is what gives the lattice structure to `V`: in what follows we are interested in making
statements about elements of vector subspaces of `V` that are also in the `ℤ`-span of the elements
of the basis.
 -/

section reduction_from_ℚ_to_ℤ

variables {V ι : Type*} [add_comm_group V] [semimodule ℚ V] [fintype ι] {v : ι → V}
  (bv : is_basis ℚ v)
include bv

/-- The vectors with integer coordinates in a `ℚ`-vector subspace `s ⊆ V` admit a finite basis.
# Important: we transport finite generation of `V` to finite generation of `ℤ ^ N ∩ s`

## Close to something in mathlib?
This lemma may already be very close to something in mathlib, as an outcome of the
"finitely generated modules over a PID" result.

## Possible generalization?
A more general result with `ℤ`and `ℚ` replaced by a subring `R` of a field `K` may also be true
and possibly useful to play around with the tower `ℤ ⊂ ℚ ⊂ ℝ`, though it may not be strictly
needed in what follows.
 -/
lemma reduction_to_lattice (s : submodule ℚ V) :
  ∃ (n : ℕ) (vn : fin n → s.restrict_scalars ℤ ⊓ submodule.span ℤ (set.range v)),
  is_basis ℤ vn :=
begin
  let Λ := submodule.span ℤ (set.range v),
  let Λ₁ := s.restrict_scalars ℤ ⊓ submodule.span ℤ (set.range v),
  have Λ₁le  : Λ₁ ≤ Λ := inf_le_right,
  have hind : linear_independent ℤ v,
  { replace bv := bv.1,
    rw [linear_independent_iff'] at ⊢ bv,
    intros s g hg i hi,
    have H : ∀ (i : ι), (↑(g i) : ℚ) • v i = (g i) • v i,
    { intro i,
      rw [← gsmul_eq_smul, gsmul_eq_smul_cast _ _] },
    have hg' : s.sum (λ (i : ι), (λ (i : ι), (↑(g i) : ℚ)) i • v i) = 0,
    { simp only [H, hg]},
    simpa using bv s (λ i, g i) hg' i hi },
  have goal := submodule.exists_is_basis_of_le_span hind Λ₁le,
  --goal seems to be the literal statement, but exact goal doesn't work
  obtain ⟨n, b, hb⟩ := goal,
  use [n, b],
  split,
  { replace hb := hb.1,
    rw [linear_independent_iff'] at ⊢ hb,
    intros t g hg i hi,
    have hg' : t.sum (λ (i : fin n), g i • b i) = 0,
    { convert hg,
      ext i,
      simp only [submodule.coe_smul_of_tower],
      refine int.induction_on (g i) _ _ _,
      { simp only [zero_smul, submodule.coe_zero]},
      { intros j hj,
        rw [add_smul, one_smul, add_smul, one_smul, hj, submodule.coe_add] },
      { intros j hj,
        rw [sub_smul, one_smul, sub_smul, one_smul, hj, submodule.coe_sub] } },
    exact hb t g hg' i hi },
  { convert hb.2, }
end

end reduction_from_ℚ_to_ℤ

/-!
After the reduction to `ℤ`, we introduce linear inequalities: this is where we tackle the further
reduction from `ℤ` to `ℕ`.

The `ℚ`-vector space `V` gets replaced by a `ℤ`-module `N` with a finite basis `v : ι → N`.
Besides `N`, there is also a second `ℤ`-module `M` and a `ℤ`-valued pairing
`f : M × N → ℤ` that is linear in both variables.

The `ℤ`-module `M` gives rise to inequalities via duality and `dual_set`.

Here is an adaptation of the doc-string of `dual_set` to the present context.
For a subset `s ⊆ M`, the `dual_set s` is the submodule of `N` consisting of all the elements of `N`
that have non-negative pairing with all the elements of `s`.

## Intuition?

Of course, we could replace

* the module `M` by `N`,
* the pairing `f` with the "standard pairing associated to the basis `v`".

This happens in stages.  See `is_full` below.
-/
variables {M N ι : Type*} [add_comm_group M] [add_comm_group N] [semimodule ℤ M] [semimodule ℤ N]
  [fintype ι] {v : ι → N} (bv : is_basis ℤ v)

variables f : pairing ℕ M N ℤ

open pairing

/-- The non-negative integers are an `ℕ`-submodule of `ℤ`.-/
def nat_submodule : submodule ℕ ℤ :=
{ carrier := nnR ℤ,
  zero_mem' := (nnR ℤ).zero_mem,
  add_mem' := λ a b, (nnR ℤ).add_mem,
  smul_mem' := λ c x h, by simpa [(•)] using mul_nonneg (int.coe_zero_le c) h }

lemma half_space_split {s : set M} (v : M) :
  dual_set nat_submodule f (insert v s) ⊔ dual_set nat_submodule f (insert (- v) s)
    = dual_set nat_submodule f s :=
dual_set_insert_plus_minus f nat_submodule v (λ _ _, iff.rfl)

/-- The `pre_generators` are elements of the dual set of `s` that generate a 1-dimensional
subcone of the dual set.  They should be exactly the extremal rays and any generating set of
the dual set of `s` should contain them.

## Warning
Implicit in this definition is that we only consider subsets `t ⊆ s` that produce a ray
(a 1-dimensional subcone) **contained in the dual cone of `s`**.  Thus, not all maximal independent
subsets `t ⊆ s` give rise to a `pre_generator`.

## Looking ahead
Besides the `pre_generators`, we will have to "fill in" the holes.  Here is an example:

In `ℤ ^ 2` with coordinates `x, y`, the cone given by the inequalities
`0 ≤ x,  0 ≤ - x + 2 * y`,
is the cone dual to `(1,0), (- 1, 2)` under the standard pairing `(ℤ ^ 2) × (ℤ ^ 2) → ℤ`.
The extremal rays are generated by the two **primitive** vectors `(0,1), (2,1)`.
The integer vector `(1,1)` is in the cone, but is not a non-negative, integer combination of the
two generators of the extremal rays.
-/
def pre_generators (s : set M) : set N := { c : N | c ∈ dual_set nat_submodule f s ∧ ∃ t ⊆ s,
  dual_set nat_submodule f (({1, -1} : set ℤ) • t) = submodule.span ℕ {c} }

/-- If we start with a finite set `s` of elements in `M`, then the set of `pre_generators` of the
`dual_set` of `s` is also finite.

## Reason
Each `pre_generator` is uniquely determined by a subset of `s` (but not conversely!).
Thus, finiteness of `pre_generators` should be a direct consequence of finiteness of `s`. -/
lemma pre_generators_finite (s : set M) [fintype s] : fintype (pre_generators f s) :=
sorry

/-- Rational linear combinations of basis elements, with coefficients in `[0, 1]` and that are
contained in the `ℤ`-lattice spanned by the basis elements. -/
def in_box (v : ι → N) (s : set N) [semimodule ℚ N] : set N := { n : N |
  ∃ (c : N →₀ ℚ),
    (∀ {n0 : N}, 0 ≤ c n0 ∧ c n0 ≤ 1 ∧ n0 ∉ s → c n0 = 0) ∧
    n = c.sum (λ i q, q • i) ∧
    n ∈ (submodule.span ℤ (set.range v)).restrict_scalars ℤ }

/-- The required finiteness should be a consequence of the fact that the vectors in `in_box` are
contained simultaneously in a (pre-)compact set `[0,1] × s` and in the discrete set `ℤ-span (im v)`.
It may be that the proof will be easier going via real coefficients.  For this, it may be easier to
redefine `in_box`.  The reason for trying to avoid `ℝ`-coefficients is that I am trying to avoid
the example below.

## Example to keep in mind
The vectors with integral coordinates in the cone spanned by `(1,0), (1, √2)`
do not admit a finite generating set.  Still, there are only finitely many vectors with integers
coordinates in the "fundamental parallelogram" `[0,1] × (1,0) + [0,1] × (1, √2)`.
-/
lemma in_box_finite (v : ι → N) (s : set N) [fintype s] [semimodule ℚ N] : fintype (in_box v s) :=
sorry

/-- A pairing `f` is `full_on` a function `vm : ι → M` if, for each element `i ∈ ι`,
the linear function `f (vm i)` is non-negative on all the basis elements and it is strictly
positive on `v i` alone.
A non-degenerate pairing would have this property.  The condition should be equivalent to asserting
that the pairing induces a homomorphism `M → Nᵛ` with finite cokernel. -/
def is_full_on (v : ι → N) (vm : ι → M) : Prop :=
  ∀ (i j : ι) , (0 ≤ f (vm i) (v j) ∧ (i ≠ j ↔ 0 = f (vm i) (v j)))

/-- A `full` pairing represents the characteristic function of each element of the basis `v`.
A non-degenerate pairing would have this property.  The condition should be equivalent to asserting
that the pairing induces a homomorphism `M → Nᵛ` with finite cokernel. -/
def is_full : Prop :=
  ∃ vm : ι → M, ∀ (i j : ι) , (0 ≤ f (vm i) (v j) ∧ (i ≠ j ↔ 0 = f (vm i) (v j)))

/-- The main case of Gordan's lemma, assuming that the inequalities corner us in an octant. -/
lemma fg_with_basis (vm : ι → M) (hf : is_full_on f v vm) {s : set M} (hs : (set.range vm) ⊆ s) :
  ∃ g : finset N, dual_set nat_submodule f s = submodule.span ℕ g :=
sorry

/-- The proof of `Gordan` should be doable assuming `fg_with_basis`.
First, for each element `i` of a basis of `M`, add either `i` or `- i` to the set `s`, taking
advantage of `half_space_split`.
Second, use that changing the signs of a basis, produces a basis.
Third, on each piece, use `fg_with_basis`. -/
lemma Gordan (vm : ι → M) (hf : is_full_on f v vm) {s : set M} (bv : is_basis ℤ v) :
  ∃ g : finset N, dual_set nat_submodule f s = submodule.span ℕ g :=
sorry



--lemma reduce_to_pointed
