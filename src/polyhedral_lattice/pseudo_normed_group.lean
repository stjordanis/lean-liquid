import polyhedral_lattice.basic
import normed_group.pseudo_normed_group
import pseudo_normed_group.with_Tinv

import for_mathlib.topological_group
import for_mathlib.topology

noncomputable theory
open_locale nnreal

namespace polyhedral_lattice

open pseudo_normed_group normed_group

variables (Λ : Type*) (r' : ℝ≥0) (M : Type*)
variables [normed_group Λ] [polyhedral_lattice Λ]
variables [profinitely_filtered_pseudo_normed_group_with_Tinv r' M]

lemma filtration_finite (c : ℝ≥0) : (filtration Λ c).finite :=
begin
  obtain ⟨s, hs₀, hs⟩ := polyhedral_lattice.polyhedral' Λ,
  sorry
end

open metric

instance : discrete_topology Λ :=
discrete_topology_of_open_singleton_zero _ $
begin
  classical,
  have aux := filtration_finite Λ 1,
  let s := aux.to_finset,
  let s₀ := s.erase 0,
  by_cases hs₀ : s₀.nonempty,
  { let ε : ℝ≥0 := finset.min' (s₀.image $ nnnorm) (hs₀.image _),
    have hε : 0 < ε,
    { sorry },
    suffices : ({0} : set Λ) = ball (0:Λ) ε,
    { rw this, apply is_open_ball },
    ext,
    simp only [metric.mem_ball, set.mem_singleton_iff, dist_zero_right],
    split,
    { rintro rfl, rw norm_zero, exact_mod_cast hε },
    intro h,
    sorry },
  { suffices : ({0} : set Λ) = ball (0:Λ) 1,
    { rw this, apply is_open_ball },
    ext,
    simp only [metric.mem_ball, set.mem_singleton_iff, dist_zero_right],
    split,
    { rintro rfl, rw norm_zero, exact zero_lt_one },
    intro h,
    contrapose! hs₀,
    refine ⟨x, _⟩,
    simp only [set.finite.mem_to_finset, finset.mem_erase, mem_filtration_iff, nnreal.coe_one],
    exact ⟨hs₀, h.le⟩ }
end

instance filtration_fintype (c : ℝ≥0) : fintype (filtration Λ c) :=
(filtration_finite Λ c).fintype

instance : profinitely_filtered_pseudo_normed_group Λ :=
{ compact := λ c, by apply_instance, -- compact of finite
  continuous_add' := λ _ _, continuous_of_discrete_topology,
  continuous_neg' := λ _, continuous_of_discrete_topology,
  continuous_cast_le := λ _ _ _, continuous_of_discrete_topology,
  .. (show pseudo_normed_group Λ, by apply_instance) }

include r'

namespace add_monoid_hom

variables {Λ r' M} (c : ℝ≥0)

def incl (c : ℝ≥0) : filtration (Λ →+ M) c → Π l : Λ, filtration M (c * nnnorm l) :=
λ f l, ⟨f l, f.2 $ normed_group.mem_filtration_nnnorm _⟩

@[simp] lemma coe_incl_apply (f : filtration (Λ →+ M) c) (l : Λ) :
  (incl c f l : M) = f l :=
rfl

variables (Λ r' M)

lemma incl_injective : function.injective (@incl Λ r' M _ _ _ c) :=
begin
  intros f g h,
  ext l,
  show (incl c f l : M) = incl c g l,
  rw h
end

instance : topological_space (filtration (Λ →+ M) c) :=
topological_space.induced (incl c) infer_instance

lemma incl_embedding : embedding (@incl Λ r' M _ _ _ c) :=
{ induced := rfl,
  inj := incl_injective Λ r' M c }

instance : t2_space (filtration (Λ →+ M) c) :=
(incl_embedding Λ r' M c).t2_space

instance : totally_disconnected_space (filtration (Λ →+ M) c) :=
(incl_embedding Λ r' M c).totally_disconnected_space

-- need to prove that the range of `incl c` is closed
instance : compact_space (filtration (Λ →+ M) c) :=
sorry

instance profinitely_filtered_pseudo_normed_group :
  profinitely_filtered_pseudo_normed_group (Λ →+ M) :=
{ continuous_add' := sorry,
  continuous_neg' := sorry,
  continuous_cast_le := sorry,
  .. add_monoid_hom.pseudo_normed_group }

end add_monoid_hom

variables {Λ r' M}

open profinitely_filtered_pseudo_normed_group_with_Tinv

def Tinv' : (Λ →+ M) →+ (Λ →+ M) :=
add_monoid_hom.comp_hom
  (@Tinv r' M _).to_add_monoid_hom

@[simp] lemma Tinv'_apply (f : Λ →+ M) (l : Λ) :
  Tinv' f l = Tinv (f l) := rfl

lemma Tinv'_mem_filtration (c : ℝ≥0) (f : Λ →+ M) (hf : f ∈ filtration (Λ →+ M) c) :
  Tinv' f ∈ filtration (Λ →+ M) (r'⁻¹ * c) :=
begin
  intros x l hl,
  rw [Tinv'_apply, mul_assoc],
  apply Tinv_mem_filtration,
  exact hf hl
end

variables (Λ r' M)

def Tinv : profinitely_filtered_pseudo_normed_group_hom (Λ →+ M) (Λ →+ M) :=
profinitely_filtered_pseudo_normed_group_hom.mk' Tinv'
begin
  refine ⟨r'⁻¹, λ c, ⟨Tinv'_mem_filtration c, _⟩⟩,
  sorry
end

instance : profinitely_filtered_pseudo_normed_group_with_Tinv r' (Λ →+ M) :=
{ Tinv := Tinv Λ r' M,
  Tinv_mem_filtration := Tinv'_mem_filtration,
  .. add_monoid_hom.profinitely_filtered_pseudo_normed_group Λ r' M }

end polyhedral_lattice
