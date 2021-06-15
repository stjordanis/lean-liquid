import algebra.homology.additive
import algebra.homology.homological_complex

import breen_deligne.universal_map

import for_mathlib.free_abelian_group

/-!

# The category of Breen-Deligne data

This file defines the category whose objects are the natural numbers
and whose morphisms `m ⟶ n` are functorial maps `φ_A : ℤ[A^m] → ℤ[A^n]`.

-/

open_locale big_operators

namespace breen_deligne

open free_abelian_group category_theory

/-- The category whose objects are natural numbers
and whose morphisms are the free abelian groups generated by
matrices with integer coefficients. -/
@[derive comm_semiring] def FreeMat := ℕ

namespace FreeMat

instance : small_category FreeMat :=
{ hom := λ m n, universal_map m n,
  id := universal_map.id,
  comp := λ l m n f g, universal_map.comp g f,
  id_comp' := λ n f, universal_map.comp_id,
  comp_id' := λ n f, universal_map.id_comp,
  assoc' := λ k l m n f g h, (universal_map.comp_assoc h g f).symm }

instance : preadditive FreeMat :=
{ hom_group := λ m n, infer_instance,
  add_comp' := λ l m n f g h, add_monoid_hom.map_add _ _ _,
  comp_add' := λ l m n f g h, show universal_map.comp (g + h) f = _,
    by { rw [add_monoid_hom.map_add, add_monoid_hom.add_apply], refl } }

open universal_map

@[simps]
def mul_functor (N : ℕ) : FreeMat ⥤ FreeMat :=
{ obj := λ n, N * n,
  map := λ m n f, mul N f,
  map_id' := λ n, (free_abelian_group.map_of _ _).trans $ congr_arg _ $
  begin
    dsimp [basic_universal_map.mul, basic_universal_map.id],
    ext i j,
    rw matrix.kronecker_one_one,
    simp only [matrix.minor_apply, matrix.one_apply, equiv.apply_eq_iff_eq, eq_self_iff_true],
    split_ifs; refl
  end,
  map_comp' := λ l m n f g, mul_comp _ _ _ }
.
instance mul_functor.additive (N : ℕ) : (mul_functor N).additive :=
{ map_zero' := λ m n, add_monoid_hom.map_zero _,
  map_add' := λ m n f g, add_monoid_hom.map_add _ _ _ }

@[simps] def iso_mk' {m n : FreeMat}
  (f : basic_universal_map m n) (g : basic_universal_map n m)
  (hfg : basic_universal_map.comp g f = basic_universal_map.id _)
  (hgf : basic_universal_map.comp f g = basic_universal_map.id _) :
  m ≅ n :=
{ hom := of f,
  inv := of g,
  hom_inv_id' := (comp_of _ _).trans $ congr_arg _ $ hfg,
  inv_hom_id' := (comp_of _ _).trans $ congr_arg _ $ hgf }

def one_mul_iso : mul_functor 1 ≅ 𝟭 _ :=
nat_iso.of_components (λ n, iso_mk'
  (basic_universal_map.one_mul_hom _) (basic_universal_map.one_mul_inv _)
  basic_universal_map.one_mul_inv_hom basic_universal_map.one_mul_hom_inv)
begin
  intros m n f,
  dsimp,
  show universal_map.comp _ _ = universal_map.comp _ _,
  rw [← add_monoid_hom.comp_apply, ← add_monoid_hom.comp_hom_apply_apply,
    ← add_monoid_hom.flip_apply _ f],
  congr' 1, clear f, ext1 f,
  have : f = matrix.reindex_linear_equiv
      ((fin_one_equiv.prod_congr $ equiv.refl _).trans $ equiv.punit_prod _)
      ((fin_one_equiv.prod_congr $ equiv.refl _).trans $ equiv.punit_prod _)
      (matrix.kronecker 1 f),
  { ext i j, dsimp [matrix.kronecker, matrix.one_apply],
    simp only [one_mul, if_true, eq_iff_true_of_subsingleton], },
  conv_rhs { rw this },
  simp only [comp_of, mul_of, basic_universal_map.comp, add_monoid_hom.mk'_apply,
    basic_universal_map.mul, basic_universal_map.one_mul_hom,
    add_monoid_hom.comp_hom_apply_apply, add_monoid_hom.comp_apply, add_monoid_hom.flip_apply,
    iso_mk'_hom],
  rw [← matrix.reindex_linear_equiv_mul, ← matrix.reindex_linear_equiv_mul,
    matrix.one_mul, matrix.mul_one],
end
.

lemma mul_mul_iso_aux (m n i j : ℕ) (f : basic_universal_map i j) :
  (comp (of (basic_universal_map.mul_mul_hom m n j))) (mul m (mul n (of f))) =
    comp (mul (m * n) (of f)) (of (basic_universal_map.mul_mul_hom m n i)) :=
begin
  simp only [comp_of, mul_of, basic_universal_map.comp, add_monoid_hom.mk'_apply,
    basic_universal_map.mul, basic_universal_map.mul_mul_hom, matrix.mul_reindex_linear_equiv_one],
  rw [← matrix.reindex_linear_equiv_mul, matrix.one_mul,
    matrix.kronecker_reindex_right, matrix.kronecker_assoc', matrix.kronecker_one_one,
    ← matrix.reindex_linear_equiv_one (@fin_prod_fin_equiv m n), matrix.kronecker_reindex_left],
  simp only [matrix.reindex_linear_equiv_reindex_linear_equiv],
  congr' 3,
  { ext ⟨⟨a, b⟩, c⟩ : 1, dsimp, simp only [equiv.symm_apply_apply], },
  { ext ⟨⟨a, b⟩, c⟩ : 1, dsimp, simp only [equiv.symm_apply_apply], },
end

def mul_mul_iso (m n : ℕ) : mul_functor n ⋙ mul_functor m ≅ mul_functor (m * n) :=
nat_iso.of_components (λ i, iso_mk'
  (basic_universal_map.mul_mul_hom m n i) (basic_universal_map.mul_mul_inv m n i)
  basic_universal_map.mul_mul_inv_hom basic_universal_map.mul_mul_hom_inv)
begin
  intros i j f,
  dsimp,
  show universal_map.comp _ _ = universal_map.comp _ _,
  rw [← add_monoid_hom.comp_apply, ← add_monoid_hom.comp_apply,
    ← add_monoid_hom.flip_apply _ (mul (m * n) f),
    ← add_monoid_hom.comp_apply],
  congr' 1, clear f, ext1 f,
  apply mul_mul_iso_aux,
end

end FreeMat

/-- Roughly speaking, this is a collection of formal finite sums of matrices
that encode the data that rolls out of the Breen--Deligne resolution. -/
@[derive [small_category, preadditive]]
def data := chain_complex FreeMat ℕ

namespace data

variable (BD : data)

section mul

open universal_map

@[simps]
def mul (N : ℕ) : data ⥤ data :=
(FreeMat.mul_functor N).map_homological_complex _

def mul_one_iso : (mul 1).obj BD ≅ BD :=
homological_complex.hom.iso_of_components (λ i, FreeMat.one_mul_iso.app _) $
λ i j _, (FreeMat.one_mul_iso.hom.naturality (BD.d i j)).symm

def mul_mul_iso (m n : ℕ) : (mul m).obj ((mul n).obj BD) ≅ (mul (m * n)).obj BD :=
homological_complex.hom.iso_of_components (λ i, (FreeMat.mul_mul_iso _ _).app _) $
λ i j _, ((FreeMat.mul_mul_iso _ _).hom.naturality (BD.d i j)).symm

end mul

/-- `BD.pow N` is the Breen--Deligne data whose `n`-th rank is `2^N * BD.rank n`. -/
def pow' : ℕ → data
| 0     := BD
| (n+1) := (mul 2).obj (pow' n)

@[simps] def sum (BD : data) (N : ℕ) : (mul N).obj BD ⟶ BD :=
{ f := λ n, universal_map.sum _ _,
  comm' := λ m n _, (universal_map.sum_comp_mul _ _).symm }

@[simps] def proj (BD : data) (N : ℕ) : (mul N).obj BD ⟶ BD :=
{ f := λ n, universal_map.proj _ _,
  comm' := λ m n _, (universal_map.proj_comp_mul _ _).symm }

open homological_complex FreeMat category_theory category_theory.limits

def hom_pow' {BD : data} (f : (mul 2).obj BD ⟶ BD) : Π N, BD.pow' N ⟶ BD
| 0     := 𝟙 _
| (n+1) := (mul 2).map (hom_pow' n) ≫ f

open_locale zero_object

def pow'_iso_mul : Π N, BD.pow' N ≅ (mul (2^N)).obj BD
| 0     := BD.mul_one_iso.symm
| (N+1) := show (mul 2).obj (BD.pow' N) ≅ (mul (2 * 2 ^ N)).obj BD, from
   (mul 2).map_iso (pow'_iso_mul N) ≪≫ mul_mul_iso _ _ _

lemma hom_pow'_sum : ∀ N, (BD.pow'_iso_mul N).inv ≫ hom_pow' (BD.sum 2) N = BD.sum (2^N)
| 0     :=
begin
  ext n : 2,
  simp only [hom_pow', category.comp_id],
  show (BD.pow'_iso_mul 0).inv.f n = (BD.sum 1).f n,
  dsimp only [sum_f, universal_map.sum],
  simp only [fin.default_eq_zero, univ_unique, finset.sum_singleton],
  refine congr_arg of _,
  apply basic_universal_map.one_mul_hom_eq_proj,
end
| (N+1) :=
begin
  dsimp [pow'_iso_mul, hom_pow'],
  slice_lhs 2 3 { rw [← functor.map_comp, hom_pow'_sum] },
  rw iso.inv_comp_eq,
  ext i : 2,
  iterate 2 { erw [homological_complex.comp_f] },
  dsimp [mul_mul_iso, FreeMat.mul_mul_iso, universal_map.sum],
  rw [universal_map.mul_of],
  show universal_map.comp _ _ = universal_map.comp _ _,
  simp only [universal_map.comp_of, add_monoid_hom.map_sum, add_monoid_hom.finset_sum_apply],
  congr' 1,
  rw [← finset.sum_product', finset.univ_product_univ, ← fin_prod_fin_equiv.symm.sum_comp],
  apply fintype.sum_congr,
  apply basic_universal_map.comp_proj_mul_proj,
end
.

lemma hom_pow'_sum' (N : ℕ) : hom_pow' (BD.sum 2) N = (BD.pow'_iso_mul N).hom ≫ BD.sum (2^N) :=
by { rw ← iso.inv_comp_eq, apply hom_pow'_sum }

lemma hom_pow'_proj : ∀ N, (BD.pow'_iso_mul N).inv ≫ hom_pow' (BD.proj 2) N = BD.proj (2^N)
| 0     :=
begin
  ext n : 2,
  simp only [hom_pow', category.comp_id],
  show (BD.pow'_iso_mul 0).inv.f n = (BD.proj 1).f n,
  dsimp only [proj_f, universal_map.proj],
  refine congr_arg of _,
  apply basic_universal_map.one_mul_hom_eq_proj,
end
| (N+1) :=
begin
  dsimp [pow'_iso_mul, hom_pow'],
  slice_lhs 2 3 { rw [← functor.map_comp, hom_pow'_proj] },
  rw iso.inv_comp_eq,
  ext i : 2,
  iterate 2 { erw [homological_complex.comp_f] },
  dsimp [mul_mul_iso, FreeMat.mul_mul_iso, universal_map.proj],
  simp only [add_monoid_hom.map_sum, add_monoid_hom.finset_sum_apply,
    preadditive.comp_sum, preadditive.sum_comp],
  rw [← finset.sum_comm, ← finset.sum_product', finset.univ_product_univ,
      ← fin_prod_fin_equiv.symm.sum_comp],
  apply fintype.sum_congr,
  intros j,
  rw [universal_map.mul_of],
  show universal_map.comp _ _ = universal_map.comp _ _,
  simp only [universal_map.comp_of, basic_universal_map.comp_proj_mul_proj],
end

lemma hom_pow'_proj' (N : ℕ) : hom_pow' (BD.proj 2) N = (BD.pow'_iso_mul N).hom ≫ BD.proj (2^N) :=
by { rw ← iso.inv_comp_eq, apply hom_pow'_proj }

end data

end breen_deligne
