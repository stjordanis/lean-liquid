import topology.subset_properties
import topology.algebra.monoid

variables {X Y : Type*} [topological_space X]

open_locale topological_space

def is_locally_constant (f : X → Y) : Prop := ∀ s, is_open (f ⁻¹' s)

namespace is_locally_constant

lemma exists_open {f : X → Y} (hf : is_locally_constant f) (x : X) :
  ∃ (U : set X) (hU : is_open U) (hx : x ∈ U), ∀ x' ∈ U, f x' = f x :=
⟨f ⁻¹' {(f x)}, hf _, set.mem_singleton _, λ x' hx', set.mem_singleton_iff.mp hx'⟩

lemma exists_nhds {f : X → Y} (hf : is_locally_constant f) (x : X) :
  ∃ U ∈ 𝓝 x, ∀ x' ∈ U, f x' = f x :=
let ⟨U, hU, hx, H⟩ := hf.exists_open x in ⟨U, mem_nhds_sets hU hx, H⟩

lemma iff_exists_open (f : X → Y) :
  is_locally_constant f ↔ ∀ x, ∃ (U : set X) (hU : is_open U) (hx : x ∈ U), ∀ x' ∈ U, f x' = f x :=
begin
  refine ⟨exists_open, _⟩,
  assume h s,
  rw is_open_iff_forall_mem_open,
  assume x hx,
  obtain ⟨U, hU, hxU, H⟩ := h x,
  refine ⟨U, _, hU, hxU⟩,
  assume x' hx',
  simp only [*, set.mem_preimage] at *,
end

lemma iff_exists_nhds (f : X → Y) :
  is_locally_constant f ↔ ∀ x, ∃ U ∈ 𝓝 x, ∀ x' ∈ U, f x' = f x :=
begin
  refine ⟨exists_nhds, _⟩,
  assume h,
  rw iff_exists_open,
  assume x,
  obtain ⟨U, hU, H⟩ := h x,
  obtain ⟨V, hVU, hV, hxV⟩ : ∃ (V : set X) (H : V ⊆ U), is_open V ∧ x ∈ V,
  by rwa mem_nhds_sets_iff at hU,
  refine ⟨V, hV, hxV, _⟩,
  assume x' hx',
  solve_by_elim only [H, hxV, hx', hVU]
end

lemma of_constant (f : X → Y) (h : ∃ y, ∀ x, f x = y) :
  is_locally_constant f :=
begin
  obtain ⟨y, hy⟩ := h,
  rw iff_exists_nhds,
  intro x,
  refine ⟨set.univ, filter.univ_mem_sets, _⟩,
  rintro x -,
  rw [hy, hy]
end

lemma const (y : Y) : is_locally_constant (function.const X y) :=
of_constant _ ⟨y, λ _, rfl⟩

lemma continuous {_ : topological_space Y} {f : X → Y} (hf : is_locally_constant f) :
  continuous f :=
⟨λ U hU, hf _⟩

lemma iff_continuous {_ : topological_space Y} [discrete_topology Y] (f : X → Y) :
  is_locally_constant f ↔ _root_.continuous f :=
⟨continuous, λ h s, h.is_open_preimage s (is_open_discrete _)⟩

lemma map_eq_of_is_preconnected {f : X → Y} (hf : is_locally_constant f)
  (s : set X) (hs : is_preconnected s) (x y : X) (hx : x ∈ s) (hy : y ∈ s) :
  f y = f x :=
begin
  letI : topological_space Y := ⊥,
  haveI : discrete_topology Y := ⟨rfl⟩,
  have aux := is_preconnected.image hs f hf.continuous.continuous_on {f x} (f '' s \ {f x})
    (is_open_discrete _) (is_open_discrete _),
  simp only [set.union_diff_self, ← set.inter_diff_assoc, set.inter_self, set.inter_diff_self,
    set.inter_empty, ← @set.ne_empty_iff_nonempty _ ∅, eq_self_iff_true, not_true, ne.def] at aux,
  classical, by_contra hxy,
  exact aux (set.subset_union_right _ _)
    ⟨f x, set.mem_inter (set.mem_image_of_mem f hx) (set.mem_singleton _)⟩
    ⟨f y, set.mem_diff_singleton.mpr ⟨set.mem_image_of_mem f hy, hxy⟩⟩
end

@[to_additive]
lemma one [has_one Y] : is_locally_constant (1 : X → Y) := const 1

@[to_additive]
lemma inv [has_inv Y] ⦃f : X → Y⦄ (hf : is_locally_constant f) :
  is_locally_constant f⁻¹ :=
begin
  intro s,
  suffices : f⁻¹ ⁻¹' s = f ⁻¹' (has_inv.inv ⁻¹' s), by { rw this, exact hf _ },
  ext, simp only [set.mem_preimage, pi.inv_apply],
end

@[to_additive]
lemma mul [has_mul Y] ⦃f g : X → Y⦄ (hf : is_locally_constant f) (hg : is_locally_constant g) :
  is_locally_constant (f * g) :=
begin
  letI : topological_space Y := ⊥,
  haveI : discrete_topology Y := ⟨rfl⟩,
  rw @iff_continuous X Y ‹_› ‹_› at hf hg ⊢,
  exact hf.mul hg
end

-- -- to additive doesn't want to generate this
-- -- also, `[has_sub Y]` doesn't work :sad:
-- lemma sub [add_group Y] ⦃f g : X → Y⦄ (hf : is_locally_constant f) (hg : is_locally_constant g) :
--   is_locally_constant (f - g) :=
-- begin
--   rw iff_exists_open at hf hg ⊢,
--   intro x,
--   obtain ⟨U, hU, hxU, HU⟩ := hf x,
--   obtain ⟨V, hV, hxV, HV⟩ := hg x,
--   use [U ∩ V, is_open_inter hU hV, ⟨hxU, hxV⟩],
--   rintro x' ⟨hx'U, hx'V⟩,
--   simp only [pi.sub_apply, HU x' hx'U, HV x' hx'V]
-- end

-- @[to_additive]
-- lemma div [group Y] ⦃f g : X → Y⦄ (hf : is_locally_constant f) (hg : is_locally_constant g) :
--   is_locally_constant (f / g) :=
-- begin
--   rw iff_exists_open at hf hg ⊢,
--   intro x,
--   obtain ⟨U, hU, hxU, HU⟩ := hf x,
--   obtain ⟨V, hV, hxV, HV⟩ := hg x,
--   use [U ∩ V, is_open_inter hU hV, ⟨hxU, hxV⟩],
--   rintro x' ⟨hx'U, hx'V⟩,
--   simp only [pi.div_apply, HU x' hx'U, HV x' hx'V]
-- end

end is_locally_constant

structure locally_constant (X Y : Type*) [topological_space X] :=
(to_fun : X → Y)
(is_locally_constant : is_locally_constant to_fun)

namespace locally_constant

instance : has_coe_to_fun (locally_constant X Y) := ⟨_, locally_constant.to_fun⟩

initialize_simps_projections locally_constant (to_fun → apply)

@[simp] lemma to_fun_eq_coe (f : locally_constant X Y) : f.to_fun = f := rfl

@[simp] lemma coe_mk (f : X → Y) (h) : ⇑(⟨f, h⟩ : locally_constant X Y) = f := rfl

theorem congr_fun {f g : locally_constant X Y} (h : f = g) (x : X) : f x = g x :=
congr_arg (λ h : locally_constant X Y, h x) h

theorem congr_arg (f : locally_constant X Y) {x y : X} (h : x = y) : f x = f y :=
congr_arg (λ x : X, f x) h

theorem coe_inj ⦃f g : locally_constant X Y⦄ (h : (f : X → Y) = g) : f = g :=
by cases f; cases g; cases h; refl

@[ext] theorem ext ⦃f g : locally_constant X Y⦄ (h : ∀ x, f x = g x) : f = g :=
coe_inj (funext h)

theorem ext_iff {f g : locally_constant X Y} : f = g ↔ ∀ x, f x = g x :=
⟨λ h x, h ▸ rfl, λ h, ext h⟩

lemma continuous [topological_space Y] (f : locally_constant X Y) : continuous f :=
f.is_locally_constant.continuous

/-- The constant locally constant function on `X` with value `y : Y`. -/
def const (X : Type*) {Y : Type*} [topological_space X] (y : Y) :
  locally_constant X Y :=
⟨function.const X y, is_locally_constant.const _⟩

section algebraic_instances

@[to_additive]
instance [has_one Y] : has_one (locally_constant X Y) :=
{ one := const X 1 }

@[simp, to_additive]
lemma one_apply [has_one Y] (x : X) : (1 : locally_constant X Y) x = 1 := rfl

@[to_additive]
instance [has_inv Y] : has_inv (locally_constant X Y) :=
{ inv := λ f, ⟨f⁻¹ , f.is_locally_constant.inv⟩ }

@[simp, to_additive]
lemma inv_apply [has_inv Y] (f : locally_constant X Y) (x : X) :
  f⁻¹ x = (f x)⁻¹ := rfl

@[to_additive]
instance [has_mul Y] : has_mul (locally_constant X Y) :=
{ mul := λ f g, ⟨f * g, f.is_locally_constant.mul g.is_locally_constant⟩ }

@[simp, to_additive]
lemma mul_apply [has_mul Y] (f g : locally_constant X Y) (x : X) :
  (f * g) x = f x * g x := rfl

-- instance [group Y] : has_div (locally_constant X Y) :=
-- { div := λ f g, ⟨f / g, f.is_locally_constant.div g.is_locally_constant⟩ }

-- @[simp, to_additive]
-- lemma div_apply [has_div Y] (f g : locally_constant X Y) (x : X) :
--   (f / g) x = f x / g x := rfl

@[to_additive]
instance [semigroup Y] : semigroup (locally_constant X Y) :=
{ mul_assoc := by { intros, ext, simp only [mul_apply, mul_assoc] },
  .. locally_constant.has_mul }

@[to_additive]
instance [comm_semigroup Y] : comm_semigroup (locally_constant X Y) :=
{ mul_comm := by { intros, ext, simp only [mul_apply, mul_comm] },
  .. locally_constant.semigroup }

@[to_additive]
instance [monoid Y] : monoid (locally_constant X Y) :=
{ one_mul := by { intros, ext, simp only [mul_apply, one_apply, one_mul] },
  mul_one := by { intros, ext, simp only [mul_apply, one_apply, mul_one] },
  .. locally_constant.semigroup, .. locally_constant.has_one }

@[to_additive]
instance [comm_monoid Y] : comm_monoid (locally_constant X Y) :=
{ .. locally_constant.comm_semigroup, .. locally_constant.monoid }

@[to_additive]
instance [group Y] : group (locally_constant X Y) :=
{ mul_left_inv := by { intros, ext, simp only [mul_apply, inv_apply, one_apply, mul_left_inv] },
  .. locally_constant.monoid, .. locally_constant.has_inv }

@[to_additive]
instance [comm_group Y] : comm_group (locally_constant X Y) :=
{ .. locally_constant.comm_monoid, .. locally_constant.group }

instance [distrib Y] : distrib (locally_constant X Y) :=
{ left_distrib := by { intros, ext, simp only [mul_apply, add_apply, mul_add] },
  right_distrib := by { intros, ext, simp only [mul_apply, add_apply, add_mul] },
  .. locally_constant.has_add, .. locally_constant.has_mul }

instance [mul_zero_class Y] : mul_zero_class (locally_constant X Y) :=
{ mul_zero := by { intros, ext, simp only [mul_apply, zero_apply, mul_zero] },
  zero_mul := by { intros, ext, simp only [mul_apply, zero_apply, zero_mul] },
  .. locally_constant.has_zero, .. locally_constant.has_mul }

instance [semiring Y] : semiring (locally_constant X Y) :=
{ .. locally_constant.add_comm_monoid, .. locally_constant.monoid,
  .. locally_constant.distrib, .. locally_constant.mul_zero_class }

instance [comm_semiring Y] : comm_semiring (locally_constant X Y) :=
{ .. locally_constant.semiring, .. locally_constant.comm_monoid }

instance [ring Y] : ring (locally_constant X Y) :=
{ .. locally_constant.semiring, .. locally_constant.add_comm_group }

instance [comm_ring Y] : comm_ring (locally_constant X Y) :=
{ .. locally_constant.comm_semiring, .. locally_constant.ring }

end algebraic_instances

end locally_constant
