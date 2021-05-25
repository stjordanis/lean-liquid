import analysis.special_functions.pow

import combinatorial_lemma
import breen_deligne.eg

import thm95.constants
/-!
# Explicit formulas for the constants in theorem 9.5
-/

noncomputable theory

open_locale nnreal


open real

lemma real.log_pow {x : ℝ} (hx : 0 < x) (n : ℕ) : real.log (x ^ n) = n * real.log x :=
begin
  suffices : real.log (x ^ (n : ℝ)) = n * real.log x,
  convert this using 2,
  simp,
  rw log_rpow hx
end

namespace helper

open real

def b (r r' k' ε : ℝ): ℕ := nat_ceil ((log $ ε/(2 * k'))/log (r/r'))

lemma b_spec {r r' k' ε : ℝ} (hr : 0 < r) ( hr' : 0 < r') (hrr' : r < r')
  (hk' : 0 < k') (hε : 0 < ε) : (2 * k') * (r / r') ^ (b r r' k' ε) ≤ ε :=
begin
  have f₁ : 0 < 2*k' := mul_pos zero_lt_two hk',
  have f₂ : r/r' < 1 := (div_lt_one hr').mpr hrr',
  have f₃ : 0 < r/r' := div_pos hr hr',
  have f₄ :0 < (r / r') ^ b r r' k' ε := pow_pos f₃ _,
  rw [← le_div_iff' f₁, ← log_le_log f₄ (div_pos hε f₁), log_pow f₃, ← div_le_iff_of_neg (log_neg f₃ f₂)],
  exact le_nat_ceil (log (ε / (2 * k')) / log (r / r')),
end

def N₂ (r' k' b : ℝ) := nat_ceil (log (k'/r'^b)/ log 2)

lemma N₂_spec {r' k' b : ℝ} (hr' : 0 < r') (hk' : 0 < k') : k'/ (2 ^ (N₂ r' k' b)) ≤ r' ^ b :=
begin
  have f₁ : (0 : ℝ) < 2 ^ N₂ r' k' b := pow_pos zero_lt_two _,
  have f₂ : (0 : ℝ) < r' ^ b := rpow_pos_of_pos hr' _,
  have f₃ : 0 < k' / r' ^ b := div_pos hk' f₂,
  have f₄ : 0 < log 2 := log_pos one_lt_two,
  rw [div_le_iff' f₁, ← div_le_iff f₂,  ← log_le_log f₃ f₁, log_pow zero_lt_two, ← div_le_iff f₄],
  apply le_nat_ceil,
end

end helper

variables (BD : breen_deligne.package) (c_ c' : ℕ → ℝ≥0)
variables (r r' : ℝ≥0) [fact (0 < r)] [fact (0 < r')] [fact (r < r')] [fact (r' ≤ 1)]
variables [breen_deligne.package.adept BD c_ c'] [BD.data.very_suitable r r' c_]
variables (Λ : PolyhedralLattice)
variables (m : ℕ)

namespace thm95

open system_of_double_complexes

namespace universal_constants

open breen_deligne

noncomputable
def k₁ : ℕ → ℝ≥0
| 0     := 2 -- should be anything > 1
| (m+1) := max 2 ((max (normed_spectral.k₀ m (k₁ m)) $ (finset.range (m+2)).sup c')^2)

instance one_lt_k₁ : Π (m : ℕ), fact (1 < k₁ c' m)
| 0     := ⟨one_lt_two⟩
| (m+1) := ⟨lt_of_lt_of_le one_lt_two (le_max_left _ _)⟩

instance one_le_k₁ (m : ℕ) : fact (1 ≤ k₁ c' m) := ⟨(fact.out (1 < k₁ c' m)).le⟩

def K₁ : ℕ → ℝ≥0
| 0     := 2 -- should be anything > 1, probably
| (m+1) := sorry

instance one_le_K₁ : ∀ m, fact (1 ≤ K₁ m)
| 0     := ⟨one_le_two⟩
| (m+1) := sorry

-- === jmc: I'm not completely convinced that the next three abbreviations are correct
-- === maybe we should pass an `m-1` around somewhere...

/-- `k₀ m` is the constant `k₀ m (k m)` used in the proof of `normed_spectral` -/
abbreviation k₀ : ℝ≥0 := normed_spectral.k₀ m (k₁ c' m)

/-- `K₀ m` is the constant `K₀ m (K m)` used in the proof of `normed_spectral` -/
abbreviation K₀ : ℝ≥0 := normed_spectral.K₀ m (K₁ m)

/-- `ε m` is the constant `ε m (K m)` used in the proof of `normed_spectral` -/
abbreviation ε : ℝ≥0 := normed_spectral.ε m (K₁ m)

instance ε_pos : fact (0 < ε m) := ⟨normed_spectral.ε_pos _ _⟩

/-- `k' c' m` is the maximum of `k₀ m` and the constants `c' 0`, `c' 1`, ..., `c' m`, `c' (m+1)` -/
def k' : ℝ≥0 := max (k₀ c' m) $ (finset.range (m+2)).sup c'

lemma c'_le_k' {i : ℕ} (hi : i ≤ m+1) : c' i ≤ k' c' m :=
le_max_iff.mpr $ or.inr $ finset.le_sup $ finset.mem_range.mpr $ nat.lt_succ_iff.mpr hi

instance fact_c'_le_k' {i : ℕ} (hi : fact (i ≤ m+1)) : fact (c' i ≤ k' c' m) :=
⟨c'_le_k' _ _ hi.1⟩

instance one_le_k' : fact (1 ≤ k' c' m) :=
⟨le_trans (fact.out _) $ le_max_left _ _⟩

instance k₀_le_k' : fact (normed_spectral.k₀ m (k₁ c' m) ≤ k' c' m) := ⟨le_max_left _ _⟩

-- in the PDF `b` is *positive*, we might need to make that explicit
lemma b_exists : ∃ b : ℕ, 2 * (k' c' m) * (r / r') ^ b ≤ (ε m) :=
begin
  have : 0 < 2 * (k' c' m) := mul_pos zero_lt_two (fact.out _),
  have h₁ : 0 < ((2 * k' c' m)⁻¹ * ε m : ℝ),
  { refine mul_pos (inv_pos.mpr this) _,
    rw [nnreal.coe_pos],
    exact fact.out _ },
  have h₂ : (r / r' : ℝ) < 1,
  { rw div_lt_iff,
    { rw [one_mul, nnreal.coe_lt_coe], exact fact.out _ },
    { rw [nnreal.coe_pos], exact fact.out _ } },
  obtain ⟨b, hb⟩ := exists_pow_lt_of_lt_one h₁ h₂,
  refine ⟨b, (nnreal.mul_le_iff_le_inv this.ne').mpr _⟩,
  refine nnreal.coe_le_coe.mp _,
  rw [nnreal.coe_pow],
  exact hb.le,
end

/-- `b c' r r' m` is the smallest `b` such that `2 * (k' c' m) * (r / r') ^ b ≤ (ε m)` -/
def b : ℕ := nat.find (b_exists c' r r' m)

lemma b_spec :
  (2 * k' c' m) * (r / r') ^ (b c' r r' m) ≤ ε m :=
nat.find_spec (b_exists c' r r' m)

lemma N₂_exists : ∃ N₂ : ℕ, (k' c' m) / (2 ^ N₂) ≤ r' ^ (b c' r r' m) :=
begin
  suffices : ∃ N₂ : ℕ, ((2⁻¹ : ℝ≥0) ^ N₂ : ℝ) < (k' c' m)⁻¹ * r' ^ (b c' r r' m),
  { rcases this with ⟨N₂, h⟩,
    use N₂,
    rw [← div_lt_iff', ← nnreal.coe_pow, inv_pow', nnreal.coe_inv, inv_div_left, mul_inv',
      inv_inv', ← div_eq_mul_inv] at h,
    { exact_mod_cast h.le },
    { rw [inv_pos, nnreal.coe_pos], exact fact.out _ } },
  refine exists_pow_lt_of_lt_one (mul_pos _ _) _,
  { rw [inv_pos, nnreal.coe_pos], exact fact.out _ },
  { apply pow_pos, rw [nnreal.coe_pos], exact fact.out _ },
  { refine lt_of_le_of_lt (one_div _).symm.le one_half_lt_one }
end

/-- `N₂ c' r r' m` is the smallest `N₂` such that `N = 2 ^ N₂` satisfies
`(k' c' m) / N ≤ r' ^ (b c' r r' m)` -/
def N₂ : ℕ := nat.find (N₂_exists c' r r' m)

lemma N₂_spec : (k' c' m) / (2 ^ (N₂ c' r r' m)) ≤ r' ^ b c' r r' m :=
nat.find_spec (N₂_exists c' r r' m)

variables {c' r r' m}
/--  This lemma is not just the line with `nat.find_min` since, when we apply it in
`r_pow_b_mul_N_le`, it is a little smoother if we massage the inequality first a bit. -/
lemma N₂_spec_of_pos' (h : 0 < N₂ c' r r' m) :
  r' ^ b c' r r' m < 2 * k' c' m / 2 ^ N₂ c' r r' m :=
begin
  obtain (F : r' ^ b c' r r' m < (k' c' m) / (2 ^ (N₂ c' r r' m - 1))) :=
    not_le.mp (nat.find_min (N₂_exists c' r r' m) (nat.pred_lt (zero_lt_iff.mp h) : _ - 1 < _)),
  rwa [pow_sub' _ (@two_ne_zero ℝ≥0 _ _) h, pow_one, mul_comm, ← div_div_eq_div_mul,
    div_eq_mul_one_div _ ((2 : ℝ≥0)⁻¹), inv_eq_one_div, one_div_one_div, mul_comm] at F,
end

lemma k'_eq_one_of_N₂_spec_eq_zero (h : N₂ c' r r' m = 0) :
  k' c' m = 1 :=
begin
  refine le_antisymm _ (universal_constants.one_le_k' _ _).1,
  obtain F := N₂_spec c' r r' m,
  rw [h, pow_zero, div_one] at F,
  refine F.trans (pow_le_one (b c' r r' m) (le_of_lt _) _);
  { apply fact.out _,
    assumption }
end

variables (c' r r' m)
/-- `N c' r r' m = 2 ^ N₂ c' r r' m` is the smallest `N` that satisfies
`(k' c' m) / N ≤ r' ^ (b c' r r' m)` -/
def N : ℕ := 2 ^ N₂ c' r r' m

instance N_pos : fact (0 < N c' r r' m) := ⟨pow_pos zero_lt_two _⟩

instance k'_le_two_pow_N : fact (k' c' m ≤ 2 ^ N₂ c' r r' m) :=
{ out := begin
  rw [← mul_one ((2 : ℝ≥0) ^ _)],
  obtain F := N₂_spec c' r r' m,
  rw [nnreal.div_le_iff (pow_pos zero_lt_two _).ne', mul_comm] at F,
  refine F.trans (mul_le_mul rfl.le _ _ _),
  { refine pow_le_one _ (zero_le r') _,
    apply fact.out _,
    assumption },
  repeat { exact pow_nonneg (zero_le _) _ }
end }

lemma r_pow_b_mul_N_le :
  r ^ (b c' r r' m) * (N c' r r' m) ≤ 2 * k' c' m * (r / r') ^ (b c' r r' m) :=
begin
  rw [mul_comm _ (_ ^ _), N, div_pow, nat.cast_pow, nat.cast_bit0, nat.cast_one, div_eq_mul_one_div,
    mul_assoc, div_mul_comm', mul_one],
  refine mul_le_mul_left' _ _,
  rw [nnreal.le_div_iff_mul_le, mul_comm, ← nnreal.le_div_iff_mul_le],
  { by_cases N0 : N₂ c' r r' m = 0,
    { rw [k'_eq_one_of_N₂_spec_eq_zero N0, mul_one, N0, pow_zero, div_one],
      refine le_trans (pow_le_one _ (nnreal.coe_nonneg _) _) one_le_two,
      apply fact.out _,
      assumption },
    { exact le_of_lt (N₂_spec_of_pos' (zero_lt_iff.mpr N0)) } },
  { exact pow_ne_zero _ two_ne_zero },
  { exact pow_ne_zero _ (ne_of_gt (fact.out _)) }
end

lemma r_pow_b_le_ε : r ^ b c' r r' m * N c' r r' m ≤ ε m :=
(r_pow_b_mul_N_le _ _ _ _).trans (b_spec _ _ _ _)

lemma N₂_spec' : k' c' m * (2 ^ N₂ c' r r' m)⁻¹ ≤ r' ^ b c' r r' m :=
by { rw [inv_eq_one_div, mul_one_div], exact N₂_spec c' r r' m }

/-- `H BD c_ r r' m` is the universal bound on the norm of the `N₂`th Breen--Deligne homotopy
in the first `m` degrees. Here `N₂ = thm95.N₂ c' r r' m`. -/
def H : ℕ :=
max 1 $ (finset.range (m+1)).sup $ λ q,
  ((BD.data.homotopy_mul BD.homotopy (N₂ c' r r' m)).hom q (q + 1)).bound

lemma one_le_H : 1 ≤ H BD c' r r' m :=
le_max_left _ _

instance H_pos : fact (0 < H BD c' r r' m) :=
⟨zero_lt_one.trans_le $ one_le_H _ _ _ _ _⟩

instance H_pos' : fact ((0:ℝ≥0) < H BD c' r r' m) :=
by { norm_cast, apply_instance }

lemma bound_by_H {q : ℕ} (h : q ≤ m) :
  ((BD.data.homotopy_mul BD.homotopy (N₂ c' r r' m)).hom q (q + 1)).bound_by (H BD c' r r' m) :=
begin
  rw [H, universal_map.bound_by, le_max_iff],
  right,
  refine @finset.le_sup _ _ _ (finset.range (m+1))
    (λ q, ((BD.data.homotopy_mul BD.homotopy (N₂ c' r r' m)).hom q (q + 1)).bound) _ _,
  rwa [finset.mem_range, nat.lt_succ_iff],
end

def k : ℝ≥0 := k' c' m * k' c' m

instance one_le_k : fact (1 ≤ k c' m) := by { delta k, apply_instance }

def K : ℝ≥0 := 2 * normed_spectral.K₀ m (K₁ m) * H BD c' r r' m

instance one_le_K : fact (1 ≤ K BD c' r r' m) :=
fact.mk $
calc 1 = 1 * 1 * 1 : by simp
... ≤ 2 * normed_spectral.K₀ m (K₁ m) * H BD c' r r' m :
begin
  refine mul_le_mul' (mul_le_mul' one_le_two $ (normed_spectral.one_le_K₀ _ _).1) _,
  norm_cast,
  apply one_le_H
end

instance k_le_k₁ [fact (0 < m)] : fact (k c' (m - 1) ≤ k₁ c' m) :=
begin
  unfreezingI {cases m},
  { exact false.elim (lt_irrefl 0 (fact.elim infer_instance)) },
  { apply fact.mk,
    simp only [k₁],
    convert le_max_right _ _,
    rw pow_two,
    refl }
end

instance K_le_K₁ [fact (0 < m)] : fact (K BD c' r r' (m - 1) ≤ K₁ m) := sorry

def k₁_sqrt : ℝ≥0 := ⟨real.sqrt (k₁ c' m), real.sqrt_nonneg _⟩

instance one_lt_k₁_sqrt : fact (1 < k₁_sqrt c' m) := ⟨begin
  change (1 : ℝ) < real.sqrt (k₁ c' m),
  rw [real.lt_sqrt zero_le_one, pow_two, mul_one],
  exact (universal_constants.one_lt_k₁ c' m).elim,
  exact (k₁ c' m).coe_nonneg,
end⟩

lemma K₁_spec : (m + 2 + (r + 1) / r * (r / (1 - r) + 1) * (m + 2) * (m + 2) : ℝ≥0) ≤ K₁ m :=
sorry

section open simplex_category

def c₀_aux (r r' : ℝ≥0) [fact (0 < r)] [fact (0 < r')] [fact (r < r')] [fact (r' ≤ 1)]
  (c_ c' : ℕ → ℝ≥0) (m : ℕ) (Λ : PolyhedralLattice) : ℝ≥0 :=
N c' r r' m * lem98.d Λ (N c' r r' m) /
  (k₁_sqrt c' m - 1) / r' / (finset.range (m+1)).inf' ⟨0, by simp⟩ c_

-- define this such that the lemmas below hold
noncomputable def c₀ (r r' : ℝ≥0) [fact (0 < r)] [fact (0 < r')] [fact (r < r')] [fact (r' ≤ 1)]
  (c_ c' : ℕ → ℝ≥0) : ℕ → PolyhedralLattice → ℝ≥0
| 0 Λ := c₀_aux r r' c_ c' 0 Λ
| (m+1) Λ := max (c₀_aux r r' c_ c' (m+1) Λ)
    (c₀ m ((Λ.cosimplicial (N c' r r' (m+1))).obj (mk 0))) -- this is not done yet: we need more maxes!


-- Scott is really unhappy that these lemmas have `fact` in them.
-- Putting aside the fact that we're badly abusing the `fact` system,
-- typeclass inference can even use these, because it can't provide the inequality arguments.

lemma c₀_mono : fact (c₀ r r' c_ c' (m - 1) Λ ≤ c₀ r r' c_ c' m Λ) := sorry

lemma c₀_pred_le (hm : 0 < m) :
  fact (c₀ r r' c_ c' (m - 1) ((Λ.cosimplicial (N c' r r' m)).obj (mk 0)) ≤
    c₀ r r' c_ c' m Λ) :=
begin
  fsplit,
  cases m,
  { cases hm, },
  { dsimp [c₀],
    apply le_trans _ (le_max_right _ _),
    simp, }
end

lemma c₀_pred_le_of_le (i : ℕ) (hi : i + 2 ≤ m + 1) :
  fact (c₀ r r' c_ c' (m - 1) ((Λ.cosimplicial (N c' r r' m)).obj (mk (i + 1))) ≤
    c₀ r r' c_ c' m Λ) :=
sorry


-- This should be possible without `change`.
-- TODO find a home / generalize?
lemma nnreal.le_div_iff (a b c : ℝ≥0) (h : 0 < c) : a ≤ b / c ↔ a * c ≤ b :=
begin
  rcases a with ⟨a, a_pos⟩,
  rcases b with ⟨b, b_pos⟩,
  rcases c with ⟨c, c_pos⟩,
  change a ≤ b / c ↔ a * c ≤ b,
  change 0 < c at h,
  exact le_div_iff h,
end

lemma nnreal.le_div_iff' (a b c : ℝ≥0) (h : 0 < c) : a ≤ b / c ↔ c * a ≤ b :=
sorry

lemma nnreal.div_le_iff (a b c : ℝ≥0) (h : 0 < b) : a / b ≤ c ↔ a ≤ c * b :=
sorry

lemma nnreal.div_le_iff' (a b c : ℝ≥0) (h : 0 < b) : a / b ≤ c ↔ a ≤ b * c :=
sorry

lemma nnreal.div_le_div_left_of (a b c : ℝ≥0) (w : 0 < c) (h : c ≤ b) : a / b ≤ a / c := sorry

lemma c₀_spec (BD : breen_deligne.package) [BD.data.very_suitable r r' c_] [package.adept BD c_ c']
  [fact (0 < r')] (j : ℕ) (hj : j ≤ m) :
  lem98.d Λ (N c' r r' m) ≤
    (k₁_sqrt c' m - 1) * (r' * (c_ j * c₀ r r' c_ c' m Λ)) / (N c' r r' m) :=
begin
  have w : ∀ j, j ≤ m → 0 < c_ j := sorry, -- This is meant to come from `BD`?
  -- TODO golf
  rw nnreal.le_div_iff',
  rw ←nnreal.div_le_iff',
  rw ←nnreal.div_le_iff',
  rw ←nnreal.div_le_iff',
  cases m,
  { cases hj,
    apply le_refl, },
  refine le_trans _ (le_max_left _ _),
  dsimp [c₀_aux],
  apply nnreal.div_le_div_left_of,
  rw finset.lt_inf'_iff,
  intros b mem,
  exact w b (finset.mem_range_succ_iff.mp mem),
  refine finset.inf'_le _ _,
  exact finset.mem_range_succ_iff.mpr hj,
  exact w j hj,
  apply fact.out,
  rw ←add_lt_add_iff_right (1 : ℝ≥0),
  rw nnreal.sub_add_cancel_of_le,
  simp only [zero_add],
  apply fact.out,
  apply le_of_lt,
  apply fact.out,
  apply fact.out,
end

end

end universal_constants

end thm95
