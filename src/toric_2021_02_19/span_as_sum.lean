import linear_algebra.basis
import algebra.ring.basic
import ring_theory.subring

section span_as_sum

universe u

open submodule finsupp

open_locale big_operators classical

lemma span_as_sum_converse {R : Type*} {M : Type u} [semiring R] [add_comm_group M] [semimodule R M]
  {m : M} {s : set M}
  (hx : ∃ c : M →₀ R, (c.support : set M) ⊆ s ∧ (c.sum (λ i, (smul_add_hom R M).flip i)) = m) :
  m ∈ submodule.span R s :=
begin
  rcases hx with ⟨c, cM, rfl⟩,
  refine sum_mem (span R s) _,
  rintros d ds S ⟨h1, rfl⟩,
  rintros g ⟨h1m : s ⊆ ↑h1, rfl⟩,
  refine h1.smul_mem (c d) _,
  exact @set.mem_of_mem_of_subset M d _ _ ((finset.mem_coe).mpr ds) (set.subset.trans cM h1m),
end

/-- If `m ∈ M` is contained in the `R`-submodule spanned by a set `s ⊆ M`, then we can write
`m` as a finite `R`-linear combination of elements of `s`.
The implementation uses `finsupp.sum`.
The Type `M` has an explicit universe, since otherwise it gets assigned `Type (max u_2 u_3)`.
  -/
--lemma span_as_sum {R : Type*} {M : Type u} [semiring R] [add_comm_group M] [semimodule R M]
--  {m : M} {s : set M} (hm : m ∈ submodule.span R s) :
--  ∃ c : M →₀ R, (c.support : set M) ⊆ s ∧ (c.sum (λ i, (smul_add_hom R M).flip i)) = m :=
lemma span_as_sum {R : Type*} {M : Type u} [semiring R] [add_comm_group M] [semimodule R M]
  {m : M} {s : set M} (hm : m ∈ submodule.span R s) :
  ∃ c : M →₀ R, (c.support : set M) ⊆ s ∧ (c.sum (λ i, ((smul_add_hom R M).flip) i)) = m :=
begin
  classical,
  refine span_induction hm (λ x hx, _) ⟨0, by simp⟩ _ _; clear hm m,
  { refine ⟨finsupp.single x 1, λ y hy, _, by simp⟩,
    rw [finset.mem_coe, finsupp.mem_support_single] at hy,
    rwa hy.1 },
  { rintros x y ⟨c, hc, rfl⟩ ⟨d, hd, rfl⟩,
    refine ⟨c + d, _, by simp⟩,
    refine set.subset.trans _ (set.union_subset hc hd),
    rw [← finset.coe_union, finset.coe_subset],
    convert finsupp.support_add },
  { rintros r m ⟨c, hc, rfl⟩,
    refine ⟨r • c, λ x hx, hc _, _⟩,
    { rw [finset.mem_coe, finsupp.mem_support_iff] at hx ⊢,
      rw [finsupp.coe_smul] at hx,
      exact right_ne_zero_of_mul hx },
    { rw finsupp.sum_smul_index' (λ (m : M), _),
      { convert (add_monoid_hom.map_finsupp_sum (smul_add_hom R M r) _ _).symm,
        ext m s,
        simp [mul_smul r s m] },
      { exact (((smul_add_hom R M).flip) m).map_zero } } }
end

lemma span_as_sum_iff {R : Type*} {M : Type u} [semiring R] [add_comm_group M] [semimodule R M]
  {m : M} {s : set M} :
  m ∈ submodule.span R s ↔
  ∃ c : M →₀ R, (c.support : set M) ⊆ s ∧ (c.sum (λ i, (smul_add_hom R M).flip i)) = m :=
⟨λ h, span_as_sum h, λ h, span_as_sum_converse h⟩

end span_as_sum

section Rnnoneg

variables (R : Type*) [ordered_semiring R]

/--  The subtype of non-negative elements of `R`. -/
def pR : subsemiring R :=
{ carrier := {r : R | 0 ≤ r},
  one_mem' := by simp only [set.mem_set_of_eq, zero_le_one],
  mul_mem' := begin
    rintros x y (x0 : 0 ≤ x) (y0 : 0 ≤ y),
    exact mul_nonneg x0 y0,
  end,
  zero_mem' := rfl.le,
  add_mem' := begin
    rintros x y (x0 : 0 ≤ x) (y0 : 0 ≤ y),
    exact add_nonneg x0 y0,
  end }


variables {α β : Type*}

open function

/-- Pullback an `ordered_comm_monoid` under an injective map. -/
@[to_additive function.injective.ordered_add_comm_monoid
"Pullback an `ordered_add_comm_monoid` under an injective map."]
def function.injective.ordered_comm_monoid [ordered_comm_monoid α] {β : Type*}
  [has_one β] [has_mul β]
  (f : β → α) (hf : function.injective f) (one : f 1 = 1)
  (mul : ∀ x y, f (x * y) = f x * f y) :
  ordered_comm_monoid β :=
{ mul_le_mul_left := λ a b ab c,
    show f (c * a) ≤ f (c * b), by simp [mul, mul_le_mul_left' ab],
  lt_of_mul_lt_mul_left :=
    λ a b c bc, @lt_of_mul_lt_mul_left' _ _ (f a) _ _ (by rwa [← mul, ← mul]),
  ..partial_order.lift f hf,
  ..hf.comm_monoid f one mul }

/-- Pullback an `ordered_cancel_comm_monoid` under an injective map. -/
@[to_additive function.injective.ordered_cancel_add_comm_monoid
"Pullback an `ordered_cancel_add_comm_monoid` under an injective map."]
def function.injective.ordered_cancel_comm_monoid [ordered_cancel_comm_monoid α] {β : Type*}
  [has_one β] [has_mul β]
  (f : β → α) (hf : function.injective f) (one : f 1 = 1)
  (mul : ∀ x y, f (x * y) = f x * f y) :
  ordered_cancel_comm_monoid β :=
{ le_of_mul_le_mul_left := λ a b c (ab : f (a * b) ≤ f (a * c)),
    (by { rw [mul, mul] at ab, exact le_of_mul_le_mul_left' ab }),
  ..hf.left_cancel_semigroup f mul,
  ..hf.right_cancel_semigroup f mul,
  ..hf.ordered_comm_monoid f one mul }

/-- Pullback an `ordered_semiring` under an injective map. -/
def function.injective.ordered_semiring {β : Type*} [ordered_semiring α]
  [has_zero β] [has_one β] [has_add β] [has_mul β]
  (f : β → α) (hf : function.injective f) (zero : f 0 = 0) (one : f 1 = 1)
  (add : ∀ x y, f (x + y) = f x + f y) (mul : ∀ x y, f (x * y) = f x * f y) :
  ordered_semiring β :=
{ zero_le_one := show f 0 ≤ f 1, by  simp only [zero, one, zero_le_one],
  mul_lt_mul_of_pos_left := λ  a b c ab c0, show f (c * a) < f (c * b),
    begin
      rw [mul, mul],
      refine mul_lt_mul_of_pos_left ab _,
      rwa ← zero,
    end,
  mul_lt_mul_of_pos_right := λ a b c ab c0, show f (a * c) < f (b * c),
    begin
      rw [mul, mul],
      refine mul_lt_mul_of_pos_right ab _,
      rwa ← zero,
    end,
  ..hf.ordered_cancel_add_comm_monoid f zero add,
  ..hf.semiring f zero one add mul }

instance : ordered_semiring (pR R) :=
subtype.coe_injective.ordered_semiring (@coe (pR R) R _)  rfl rfl (λ _ _, rfl) (λ _ _, rfl)

end Rnnoneg
