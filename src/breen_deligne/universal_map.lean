import linear_algebra.matrix
import group_theory.free_abelian_group
import algebra.direct_sum
import algebra.big_operators.finsupp

import for_mathlib.linear_algebra

import hacks_and_tricks.type_pow
import hacks_and_tricks.by_exactI_hack

/-!
# Breen-Deligne resolutions

Reference:
https://www.math.uni-bonn.de/people/scholze/Condensed.pdf#section*.4
("Appendix to Lecture IV", p. 28)

We formalize the notion of `breen_deligne_data`.
Roughly speaking, this is a collection of formal finite sums of matrices
that encode that data that rolls out of the Breen--Deligne resolution.

-/
noncomputable theory

-- get some notation working:
open_locale big_operators direct_sum

local attribute [instance] type_pow
local notation `ℤ[` A `]` := free_abelian_group A

namespace breen_deligne
open free_abelian_group


section move_this
variables {A : Type*}

def L {m n : ℕ} (x : A ^ (m+n)) : A ^ m := λ i, x $ fin_sum_fin_equiv $ sum.inl i

def R {m n : ℕ} (x : A ^ (m+n)) : A ^ n := λ i, x $ fin_sum_fin_equiv $ sum.inr i

@[simps]
def split {m n : ℕ} : A ^ (m + n) ≃ A ^ m × A ^ n :=
{ to_fun := λ x, (L x, R x),
  inv_fun := λ x j, sum.elim x.1 x.2 (fin_sum_fin_equiv.symm j),
  left_inv := λ x, by { ext j, dsimp [L, R, fin_sum_fin_equiv], split_ifs with h h,
    { dsimp, cases j, refl, },
    { dsimp, cases j, congr, push_neg at h, rw nat.add_sub_cancel' h, refl } },
  right_inv := λ x,
  begin
    ext j; dsimp [L, R],
    { rw fin_sum_fin_equiv_symm_apply_left, swap, exact j.2, simp only [sum.elim_inl, fin.eta] },
    { ext j, rw fin_sum_fin_equiv_symm_apply_right, swap,
      { simp only [le_add_iff_nonneg_right, zero_le', fin.coe_mk] },
      { simp only [nat.add_sub_cancel_left, sum.elim_inr, fin.eta] } }
  end }

@[ext] lemma map_to_pi_add_ext
  {A B : Type*} {m n : ℕ} (f g : A → B ^ (m + n))
  (h1 : L ∘ f = L ∘ g) (h2 : R ∘ f = R ∘ g) :
  f = g :=
begin
  ext1 x, apply split.injective,
  revert x, rw [← function.funext_iff],
  rw [function.funext_iff] at h1 h2,
  ext1 x, ext1, { exact h1 x }, { exact h2 x }
end

end move_this

/-!
Suppose you have an abelian group `A`.
What data do you need to specify a "universal" map `f : ℤ[A^m] → ℤ[A^n]`?
That is, it should be functorial in `A`.

Well, such a map is specified by what it does to `(a 1, a 2, a 3, ..., a m)`.
It can send this element to an arbitrary element of `ℤ[A^n]`,
but it has to be "universal".

In the end, this means that `f` will be a `ℤ`-linear combination of
"basic universal maps", where a "basic universal map" is one that
sends `(a 1, a 2, ..., a m)` to `(b 1, ..., b n)`,
where `b i` is a `ℤ`-linear combination `c i 1 * a 1 + ... + c i m * a m`.
So a "basic universal map" is specified by the `n × m`-matrix `c`.
-/

/-- A `basic_universal_map m n` is an `n × m`-matrix.
It captures data for a homomorphism `ℤ[A^m] → ℤ[A^n]`
functorial in the abelian group `A`.

A general such homomorphism is a formal linear combination
of `basic_universal_map`s, which we aptly call `universal_map`s. -/
@[derive add_comm_group]
def basic_universal_map (m n : ℕ) := matrix (fin n) (fin m) ℤ

namespace basic_universal_map

variables {k l m n : ℕ} (g : basic_universal_map m n) (f : basic_universal_map l m)
variables (A : Type*) [add_comm_group A]

def pre_eval : A^m → A^n :=
λ x i, ∑ j, g i j • (x : fin _ → A) j

/-- `f.eval A` for a `f : basic_universal_map m n`
is the homomorphism `ℤ[A^m] →+ ℤ[A^n]` induced by matrix multiplication. -/
def eval : ℤ[A^m] →+ ℤ[A^n] :=
map $ pre_eval g A

@[simp] lemma eval_of (x : A^m) :
  g.eval A (of x) = (of $ λ i, ∑ j, g i j • x j) :=
lift.of _ _

/-- The composition of basic universal maps,
defined as matrix multiplication. -/
def comp : basic_universal_map l n := matrix.mul g f

lemma eval_comp : (g.comp f).eval A = (g.eval A).comp (f.eval A) :=
begin
  ext1 x,
  simp only [add_monoid_hom.coe_comp, function.comp_app, eval_of, comp, finset.smul_sum,
    matrix.mul_apply, finset.sum_smul, mul_smul],
  congr' 1,
  ext1 i,
  exact finset.sum_comm
end

lemma comp_assoc
  (h : basic_universal_map m n) (g : basic_universal_map l m) (f : basic_universal_map k l) :
  comp (comp h g) f = comp h (comp g f) :=
matrix.mul_assoc _ _ _

/-- The identity `basic_universal_map`. -/
def id (n : ℕ) : basic_universal_map n n := (1 : matrix (fin n) (fin n) ℤ)

@[simp] lemma id_comp : (id _).comp f = f :=
by simp only [comp, id, matrix.one_mul]

@[simp] lemma comp_id : g.comp (id _) = g :=
by simp only [comp, id, matrix.mul_one]

/-- `double f` is the `universal_map` from `ℤ[A^m ⊕ A^m]` to `ℤ[A^n ⊕ A^n]`
given by applying `f` on both "components". -/
def double : basic_universal_map m n →+ basic_universal_map (m + m) (n + n) :=
add_monoid_hom.mk'
  (λ f, matrix.reindex_linear_equiv fin_sum_fin_equiv fin_sum_fin_equiv $
    matrix.from_blocks f 0 0 f)
  (λ f g, by rw [← linear_equiv.map_add, matrix.from_blocks_add, add_zero])

lemma comp_double_double (g : basic_universal_map m n) (f : basic_universal_map l m) :
  comp (double g) (double f) = double (comp g f) :=
by simp only [double, comp, add_monoid_hom.coe_mk', matrix.reindex_mul, matrix.from_blocks_multiply,
    matrix.zero_mul, matrix.mul_zero, add_zero, zero_add]

lemma pre_eval_double (f : basic_universal_map m n) :
  pre_eval (double f) A = (split.symm ∘ prod.map (f.pre_eval A) (f.pre_eval A) ∘ split) :=
begin
  ext1; ext x j; dsimp only [function.comp, L, R, double, pre_eval];
  rw [← fin_sum_fin_equiv.sum_comp, fintype.sum_sum_type];
  simp only [equiv.symm_apply_apply, sum.elim_inl, sum.elim_inr,
    split_symm_apply, split_apply, prod.map_mk,
    matrix.coe_reindex_linear_equiv, add_monoid_hom.coe_mk',
    matrix.from_blocks_apply₁₁, matrix.from_blocks_apply₁₂,
    matrix.from_blocks_apply₂₁, matrix.from_blocks_apply₂₂,
    pi.zero_apply, zero_smul, finset.sum_const_zero, add_zero, zero_add];
  refl
end

lemma eval_double (f : basic_universal_map m n) :
  eval (double f) A = (map $ split.symm ∘ prod.map (f.pre_eval A) (f.pre_eval A) ∘ split) :=
by rw [eval, pre_eval_double]

end basic_universal_map

/-- A `universal_map m n` is a formal `ℤ`-linear combination
of `basic_universal_map`s.
It captures the data for a homomorphism `ℤ[A^m] → ℤ[A^n]`. -/
@[derive add_comm_group]
def universal_map (m n : ℕ) := ℤ[basic_universal_map m n]

namespace universal_map
universe variable u

variables {k l m n : ℕ} (g : universal_map m n) (f : universal_map l m)
variables (A : Type u) [add_comm_group A]

/-- `f.eval A` for a `f : universal_map m n`
is the homomorphism `ℤ[A^m] →+ ℤ[A^n]` induced by matrix multiplication
of the summands occurring in the formal linear combination `f`. -/
def eval : universal_map m n →+ ℤ[A^m] →+ ℤ[A^n] :=
free_abelian_group.lift $ λ (f : basic_universal_map m n), f.eval A

@[simp] lemma eval_of (f : basic_universal_map m n) :
  eval A (of f) = f.eval A :=
lift.of _ _

/-- The composition of `universal_map`s `g` and `f`,
given by the formal linear combination of all compositions
of summands occurring in `g` and `f`. -/
def comp : universal_map m n →+ universal_map l m →+ universal_map l n :=
free_abelian_group.lift $ λ (g : basic_universal_map m n), free_abelian_group.lift $ λ f,
of $ g.comp f

@[simp] lemma comp_of (g : basic_universal_map m n) (f : basic_universal_map l m) :
  comp (of g) (of f) = of (g.comp f) :=
by rw [comp, lift.of, lift.of]

section
open add_monoid_hom

lemma eval_comp : eval A (comp g f) = (eval A g).comp (eval A f) :=
show comp_hom (comp_hom (@eval l n A _)) (comp) g f =
  comp_hom (comp_hom (comp_hom.flip (@eval l m A _)) (comp_hom)) (@eval m n A _) g f,
begin
  congr' 2, clear f g, ext g f : 2,
  show eval A (comp (of g) (of f)) = (eval A (of g)).comp (eval A (of f)),
  simp only [basic_universal_map.eval_comp, comp_of, eval_of]
end

lemma comp_assoc (h : universal_map m n) (g : universal_map l m) (f : universal_map k l) :
  comp (comp h g) f = comp h (comp g f) :=
show comp_hom (comp_hom (@comp k l n)) (@comp l m n) h g f =
     comp_hom (comp_hom (comp_hom.flip (@comp k l m)) (comp_hom)) (@comp k m n) h g f,
begin
  congr' 3, clear h g f, ext h g f : 3,
  show comp (comp (of h) (of g)) (of f) = comp (of h) (comp (of g) (of f)),
  simp only [basic_universal_map.comp_assoc, comp_of]
end

/-- The identity `universal_map`. -/
def id (n : ℕ) : universal_map n n := of (basic_universal_map.id n)

@[simp] lemma id_comp : comp (id _) f = f :=
show comp (id _) f = add_monoid_hom.id _ f,
begin
  congr' 1, clear f, ext1 f,
  simp only [id, comp_of, id_apply, basic_universal_map.id_comp]
end

@[simp] lemma comp_id : comp g (id _) = g :=
show (@comp m m n).flip (id _) g = add_monoid_hom.id _ g,
begin
  congr' 1, clear g, ext1 g,
  show comp (of g) (id _) = (of g),
  simp only [id, comp_of, id_apply, basic_universal_map.comp_id]
end

/-- `double f` is the `universal_map` from `ℤ[A^m ⊕ A^m]` to `ℤ[A^n ⊕ A^n]`
given by applying `f` on both "components". -/
def double : universal_map m n →+ universal_map (m + m) (n + n) :=
map $ basic_universal_map.double

lemma double_of (f : basic_universal_map m n) :
  double (of f) = of (basic_universal_map.double f) :=
rfl

lemma comp_double_double (g : universal_map m n) (f : universal_map l m) :
  comp (double g) (double f) = double (comp g f) :=
show comp_hom (comp_hom (comp_hom.flip (@double l m)) ((@comp (l+l) (m+m) (n+n)))) (double) g f =
     comp_hom (comp_hom (@double l n)) (@comp l m n) g f,
begin
  congr' 2, clear g f, ext g f : 2,
  show comp (double (of g)) (double (of f)) = double (comp (of g) (of f)),
  simp only [double_of, comp_of, basic_universal_map.comp_double_double]
end

lemma double_zero : double (0 : universal_map m n) = 0 :=
double.map_zero

open basic_universal_map

lemma eval_comp_double :
  (eval A).comp (@double m n) = (free_abelian_group.lift $ λ g,
    map $ split.symm ∘ prod.map (pre_eval g A) (pre_eval g A) ∘ split) :=
begin
  rw [double, eval],
  simp only [← basic_universal_map.eval_double],
  ext1 g, refl
end

lemma eval_double :
  eval A (double f) = (free_abelian_group.lift $ λ g,
    map $ split.symm ∘ prod.map (pre_eval g A) (pre_eval g A) ∘ split) f :=
by rw [← add_monoid_hom.comp_apply, eval_comp_double]

end

/-
We use a small hack: mathlib only has block matrices with 4 blocks.
So we add two zero-width blocks in the definition of `σ`, `π₁`, and `π₂`.
-/

/-- The universal map `ℤ[A^n ⊕ A^n] → ℤ[A^n]` induced by the addition on `A^n`. -/
def σ (n : ℕ) : universal_map (n + n) n :=
of $ matrix.reindex_linear_equiv (equiv.sum_empty _) fin_sum_fin_equiv $
matrix.from_blocks 1 1 0 0

/-- The universal map `ℤ[A^n ⊕ A^n] → ℤ[A^n]` that is first projection map. -/
def π₁ (n : ℕ) : universal_map (n + n) n :=
(of $ matrix.reindex_linear_equiv (equiv.sum_empty _) fin_sum_fin_equiv $
matrix.from_blocks 1 0 0 0)

/-- The universal map `ℤ[A^n ⊕ A^n] → ℤ[A^n]` that is second projection map. -/
def π₂ (n : ℕ) : universal_map (n + n) n :=
(of $ matrix.reindex_linear_equiv (equiv.sum_empty _) fin_sum_fin_equiv $
matrix.from_blocks 0 1 0 0)

lemma σ_comp_double (f : universal_map m n) :
  comp (σ n) (double f) = comp f (σ m) :=
show add_monoid_hom.comp_hom ((@comp (m+m) (n+n) n) (σ _)) (double) f =
  (@comp (m+m) m n).flip (σ _) f,
begin
  congr' 1, clear f, ext1 f,
  show comp (σ n) (double (of f)) = comp (of f) (σ m),
  dsimp only [double_of, σ],
  simp only [comp_of],
  conv_rhs {
    rw ← (matrix.reindex_linear_equiv (equiv.sum_empty _) (equiv.sum_empty _)).apply_symm_apply f },
  simp only [basic_universal_map.double, add_monoid_hom.coe_mk', equiv.apply_symm_apply,
    basic_universal_map.comp, matrix.reindex_mul, matrix.from_blocks_multiply,
    add_zero, matrix.one_mul, matrix.mul_one, matrix.zero_mul, zero_add,
    matrix.reindex_linear_equiv_sum_empty_symm,
    basic_universal_map.double, add_monoid_hom.coe_mk'],
end

lemma π₁_comp_double (f : universal_map m n) :
  comp (π₁ n) (double f) = comp f (π₁ m) :=
show add_monoid_hom.comp_hom ((@comp (m+m) (n+n) n) (π₁ _)) (double) f =
  (@comp (m+m) m n).flip (π₁ _) f,
begin
  congr' 1, clear f, ext1 f,
  show comp (π₁ n) (double (of f)) = comp (of f) (π₁ m),
  dsimp only [double_of, π₁],
  simp only [add_monoid_hom.map_add, add_monoid_hom.add_apply, comp_of],
  conv_rhs {
    rw ← (matrix.reindex_linear_equiv (equiv.sum_empty _) (equiv.sum_empty _)).apply_symm_apply f },
  simp only [basic_universal_map.double, add_monoid_hom.coe_mk', equiv.apply_symm_apply,
    basic_universal_map.comp, matrix.reindex_mul, matrix.from_blocks_multiply,
    add_zero, matrix.one_mul, matrix.mul_one, matrix.zero_mul, matrix.mul_zero, zero_add,
    matrix.reindex_linear_equiv_sum_empty_symm],
end

lemma π₂_comp_double (f : universal_map m n) :
  comp (π₂ n) (double f) = comp f (π₂ m) :=
show add_monoid_hom.comp_hom ((@comp (m+m) (n+n) n) (π₂ _)) (double) f =
  (@comp (m+m) m n).flip (π₂ _) f,
begin
  congr' 1, clear f, ext1 f,
  show comp (π₂ n) (double (of f)) = comp (of f) (π₂ m),
  dsimp only [double_of, π₂],
  simp only [add_monoid_hom.map_add, add_monoid_hom.add_apply, comp_of],
  conv_rhs {
    rw ← (matrix.reindex_linear_equiv (equiv.sum_empty _) (equiv.sum_empty _)).apply_symm_apply f },
  simp only [basic_universal_map.double, add_monoid_hom.coe_mk', equiv.apply_symm_apply,
    basic_universal_map.comp, matrix.reindex_mul, matrix.from_blocks_multiply,
    add_zero, matrix.one_mul, matrix.mul_one, matrix.zero_mul, matrix.mul_zero, zero_add,
    matrix.reindex_linear_equiv_sum_empty_symm],
end

lemma eval_σ (n : ℕ) : eval A (σ n) = map (λ x, L x + R x) :=
begin
  ext x,
  delta σ,
  rw [eval_of, basic_universal_map.eval_of],
  congr' 1,
  ext i,
  simp only [pi.add_apply],
  rw (fin_sum_fin_equiv.sum_comp _).symm,
  swap, { apply_instance },
  rw [← finset.insert_erase (finset.mem_univ $ sum.inl i)],
  swap, { apply_instance },
  rw [finset.sum_insert (finset.not_mem_erase _ _)],
  simp only [equiv.symm_apply_apply, matrix.coe_reindex_linear_equiv],
  dsimp [equiv.sum_empty],
  simp only [one_smul, matrix.one_apply_eq, L, add_right_inj],
  rw finset.sum_eq_single (sum.inr i),
  { dsimp, simpa only [one_smul, matrix.one_apply_eq] using rfl, },
  { rintro (j|j) hj_mem hj; dsimp,
    { rw [matrix.one_apply_ne, zero_smul], rintro rfl,
      exact finset.not_mem_erase _ _ hj_mem },
    { rw [matrix.one_apply_ne, zero_smul], rintro rfl, exact hj rfl } },
  { intro h, refine (h _).elim, rw finset.mem_erase,
    exact ⟨sum.inl_ne_inr.symm, finset.mem_univ _⟩, }
end

lemma eval_π₁ (n : ℕ) : eval A (π₁ n) = map (λ x, L x) :=
begin
  ext x,
  delta π₁,
  rw [eval_of, basic_universal_map.eval_of],
  congr' 1,
  ext i,
  simp only [pi.add_apply, matrix.coe_reindex_linear_equiv],
  dsimp [equiv.sum_empty],
  rw (fin_sum_fin_equiv.sum_comp _).symm,
  swap, { apply_instance },
  rw finset.sum_eq_single (sum.inl i),
  { simp only [equiv.symm_apply_apply], dsimp,
    simpa only [one_smul, matrix.one_apply_eq] using rfl, },
  { rintro (j|j) - hj;
    simp only [equiv.symm_apply_apply]; dsimp,
    { rw [matrix.one_apply_ne, zero_smul], rintro rfl, exact hj rfl },
    { rw zero_smul } },
  { intro h, exact (h (finset.mem_univ _)).elim }
end

lemma eval_π₂ (n : ℕ) : eval A (π₂ n) = map (λ x, R x) :=
begin
  ext x,
  delta π₂,
  rw [eval_of, basic_universal_map.eval_of],
  congr' 1,
  ext i,
  simp only [pi.add_apply, matrix.coe_reindex_linear_equiv],
  dsimp [equiv.sum_empty],
  rw (fin_sum_fin_equiv.sum_comp _).symm,
  swap, { apply_instance },
  rw finset.sum_eq_single (sum.inr i),
  { simp only [equiv.symm_apply_apply], dsimp,
    simpa only [one_smul, matrix.one_apply_eq] using rfl, },
  { rintro (j|j) - hj;
    simp only [equiv.symm_apply_apply]; dsimp,
    { rw zero_smul },
    { rw [matrix.one_apply_ne, zero_smul], rintro rfl, exact hj rfl } },
  { intro h, exact (h (finset.mem_univ _)).elim }
end

end universal_map

end breen_deligne

-- #lint- only unused_arguments def_lemma doc_blame
