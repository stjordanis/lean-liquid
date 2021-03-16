import polyhedral_lattice.pseudo_normed_group
import polyhedral_lattice.int
import polyhedral_lattice.category
import pseudo_normed_group.category

import for_mathlib.add_monoid_hom
import for_mathlib.free_abelian_group -- for int.cast_add_hom', which should move
import Mbar.basic -- for nnreal.coe_nat_abs, which should move

noncomputable theory
universe variables u
open_locale nnreal -- enable the notation `ℝ≥0` for the nonnegative real numbers.

variables (c' : ℕ → ℝ≥0)  -- implicit constants, chosen once and for all
                          -- see the sentence after that statement of Thm 9.5

open ProFiltPseuNormGrpWithTinv (of)

def polyhedral_lattice.Hom {r' : ℝ≥0} (Λ M : Type*) [polyhedral_lattice Λ]
  [profinitely_filtered_pseudo_normed_group_with_Tinv r' M] :
  ProFiltPseuNormGrpWithTinv r' :=
of r' (Λ →+ M)

namespace PolyhedralLattice
open opposite pseudo_normed_group polyhedral_lattice profinitely_filtered_pseudo_normed_group

variables {r' : ℝ≥0}

/-- Like `polyhedral_lattice.Hom` but functorial in the first entry.
Unfortunately, this means that the entries are now swapped.
So `(PolyhedralLattice.Hom M).obj (op Λ) = Λ →+ M`. -/
@[simps]
def Hom (M : ProFiltPseuNormGrpWithTinv r') : PolyhedralLatticeᵒᵖ ⥤ ProFiltPseuNormGrpWithTinv r' :=
{ obj := λ Λ, Hom (unop Λ : PolyhedralLattice) M,
  map := λ Λ₁ Λ₂ f,
  { to_fun := λ g, g.comp f.unop.to_add_monoid_hom,
    map_zero' := add_monoid_hom.zero_comp _,
    map_add' := λ g₁ g₂, add_monoid_hom.add_comp _ _ _,
    strict' := λ c g hg c' l hl, hg ((f.unop.strict_nnnorm _).trans hl),
    continuous' := λ c,
    begin
      rw [add_monoid_hom.continuous_iff],
      intro l,
      haveI : fact (nnnorm (f.unop l) ≤ nnnorm l) := f.unop.strict_nnnorm l,
      have aux := (continuous_apply (f.unop l)).comp
        (add_monoid_hom.incl_continuous (unop Λ₁ : PolyhedralLattice) r' M c),
      rw (embedding_cast_le (c * nnnorm (f.unop l)) (c * nnnorm l)).continuous_iff at aux,
      exact aux
    end,
    map_Tinv' := λ g, by { ext l, refl } },
  map_id' := λ Λ, by { ext, refl },
  map_comp' := by { intros, ext, refl } }

end PolyhedralLattice

namespace polyhedral_lattice

/-!
In the remainder of the file, we show that `Hom(ℤ, M)` is isomorphic to `M`.
-/

open pseudo_normed_group profinitely_filtered_pseudo_normed_group_with_Tinv_hom

notation `Tinv` := profinitely_filtered_pseudo_normed_group_with_Tinv.Tinv

variables {r' : ℝ≥0} [h0r' : fact (0 < r')] [hr'1 : fact (r' ≤ 1)]
variables {M M₁ M₂ : ProFiltPseuNormGrpWithTinv.{u} r'}
variables {f : M₁ ⟶ M₂}

/-- The isomorphism induced by a bijective `profinitely_filtered_pseudo_normed_group_with_Tinv_hom`
whose inverse is strict. -/
noncomputable
def iso_of_equiv_of_strict (e : M₁ ≃+ M₂) (he : ∀ x, f x = e x)
  (strict : ∀ ⦃c x⦄, x ∈ filtration M₂ c → e.symm x ∈ filtration M₁ c) :
  M₁ ≅ M₂ :=
{ hom := f,
  inv := inv_of_equiv_of_strict e he strict,
  hom_inv_id' := by { ext x, simp [inv_of_equiv_of_strict, he] },
  inv_hom_id' := by { ext x, simp [inv_of_equiv_of_strict, he] } }

@[simp]
lemma iso_of_equiv_of_strict.apply (e : M₁ ≃+ M₂) (he : ∀ x, f x = e x)
  (strict : ∀ ⦃c x⦄, x ∈ filtration M₂ c → e.symm x ∈ filtration M₁ c) (x : M₁) :
  (iso_of_equiv_of_strict e he strict).hom x = f x := rfl

@[simp]
lemma iso_of_equiv_of_strict_symm.apply (e : M₁ ≃+ M₂) (he : ∀ x, f x = e x)
  (strict : ∀ ⦃c x⦄, x ∈ filtration M₂ c → e.symm x ∈ filtration M₁ c) (x : M₂) :
  (iso_of_equiv_of_strict e he strict).symm.hom x = e.symm x := rfl

variables (M)

/-- The morphism `M ⟶ Hom ℤ M` for `M` a `profinitely_filtered_pseudo_normed_group_with_Tinv`. -/
noncomputable
def HomZ_map : M ⟶ (Hom ℤ M) :=
{ to_fun := int.cast_add_hom',
  map_zero' := by { ext1, simp only [pi.zero_apply, add_monoid_hom.coe_zero, smul_zero, int.cast_add_hom'_apply] },
  map_add' := by { intros, ext1, simp only [smul_add, add_monoid_hom.coe_add, add_left_inj,
    pi.add_apply, one_smul, int.cast_add_hom'_apply] },
  strict' := λ c x hx c₁ n hn,
  begin
    rw [normed_group.mem_filtration_iff] at hn,
    suffices : n • x ∈ pseudo_normed_group.filtration M (n.nat_abs * c),
    { rw [← int.cast_add_hom'_apply, nnreal.coe_nat_abs, mul_comm] at this,
      exact (pseudo_normed_group.filtration_mono (mul_le_mul_left' hn c) this) },
    exact pseudo_normed_group.int_smul_mem_filtration n x c hx,
  end,
  continuous' := λ c,
  begin
    rw [polyhedral_lattice.add_monoid_hom.continuous_iff],
    intro n,
    exact pfpng_ctu_smul_int M n _ (λ x, rfl),
  end,
  map_Tinv' := λ x,
  begin
    refine add_monoid_hom.ext (λ n, _),
    have h : Tinv (int.cast_add_hom' x) n = Tinv (int.cast_add_hom' x n) := rfl,
    simp only [h, int.cast_add_hom'_apply, profinitely_filtered_pseudo_normed_group_hom.map_gsmul],
  end }

include h0r' hr'1

/-- `HomZ_map` as an equiv. -/
@[simps]
def HomZ_map_equiv : M ≃+ Hom ℤ M :=
{ inv_fun := λ (f : ℤ →+ M), f 1,
  left_inv := λ x, one_smul _ _,
  right_inv := λ f, by { ext, exact one_smul _ _ },
  .. HomZ_map M }

/-- The inverse of `HomZ_map` is strict. -/
lemma HomZ_map_inverse_strict (c) (f) (hf : f ∈ filtration ((Hom ℤ M)) c) :
  (HomZ_map_equiv M).symm f ∈ filtration M c :=
by simpa [mul_one] using hf int.one_mem_filtration

/-- The isomorphism `Hom ℤ M ≅ M` for `M` a `profinitely_filtered_pseudo_normed_group_with_Tinv`. -/
noncomputable
def HomZ_iso : Hom ℤ M ≅ M :=
(iso_of_equiv_of_strict (HomZ_map_equiv M) (λ x, rfl) (HomZ_map_inverse_strict M)).symm

end polyhedral_lattice
