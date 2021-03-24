import breen_deligne.universal_map
import breen_deligne.functorial_map
import system_of_complexes.complex

import for_mathlib.free_abelian_group

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

lemma double_comp_double {l m n : FreeMat} (f : l ⟶ m) (g : m ⟶ n) :
  (f.double ≫ g.double : l+l ⟶ n+n) = (f ≫ g).double :=
comp_double_double _ _

lemma double_add {m n : FreeMat} (f g : m ⟶ n) :
  ((f + g).double : m+m ⟶ n+n) = f.double + g.double :=
add_monoid_hom.map_add _ _ _

end FreeMat

/-- Roughly speaking, this is a collection of formal finite sums of matrices
that encode the data that rolls out of the Breen--Deligne resolution. -/
@[derive [small_category, preadditive]]
def data := chain_complex ℕ FreeMat

namespace data

variable (BD : data)

/-- `BD.double` is the Breen--Deligne data whose `n`-th rank is `2 * BD.rank n`. -/
@[simps] def double : data :=
{ X := λ n, BD.X n + BD.X n,
  d := λ m n, (BD.d m n).double,
  d_eq_zero := λ m n h, by { rw [BD.d_eq_zero h, universal_map.double_zero] },
  d_comp_d := λ l m n,
    calc _ = (BD.d l m ≫ BD.d m n).double : universal_map.comp_double_double _ _
    ... = 0 : by { rw [BD.d_comp_d, universal_map.double_zero] } }

/-- `BD.pow N` is the Breen--Deligne data whose `n`-th rank is `2^N * BD.rank n`. -/
def pow : ℕ → data
| 0     := BD
| (n+1) := (pow n).double

@[simps] def σ : BD.double ⟶ BD :=
{ f := λ n, universal_map.σ _,
  comm := λ m n, universal_map.σ_comp_double _ }

@[simps] def π₁ : BD.double ⟶ BD :=
{ f := λ n, universal_map.π₁ _,
  comm := λ m n, universal_map.π₁_comp_double _ }

@[simps] def π₂ : BD.double ⟶ BD :=
{ f := λ n, universal_map.π₂ _,
  comm := λ m n, universal_map.π₂_comp_double _ }

def π : BD.double ⟶ BD := BD.π₁ + BD.π₂

open differential_object.complex_like FreeMat

@[simps]
def hom_double {BD₁ BD₂ : data} (f : BD₁ ⟶ BD₂) : BD₁.double ⟶ BD₂.double :=
{ f := λ i, (f.f i).double,
  comm := λ i j,
  calc BD₁.double.d i j ≫ (f.f j).double
      = (BD₁.d i j ≫ f.f j).double : double_comp_double _ _
  ... = (f.f i ≫ BD₂.d i j).double : congr_arg _ (f.comm i j)
  ... = (f.f i).double ≫ BD₂.double.d i j : (double_comp_double _ _).symm }

def σ_pow : Π N, BD.pow N ⟶ BD
| 0     := 𝟙 _
| (n+1) := hom_double (σ_pow n) ≫ BD.σ

def π_pow : Π N, BD.pow N ⟶ BD
| 0     := 𝟙 _
| (n+1) := hom_double (π_pow n) ≫ BD.π

@[simps]
def homotopy_double {BD₁ BD₂ : data} {f g : BD₁ ⟶ BD₂} (h : homotopy f g) :
  homotopy (hom_double f) (hom_double g) :=
{ h := λ j i, (h.h j i).double,
  h_eq_zero := λ i j hij, by rw [h.h_eq_zero i j hij, universal_map.double_zero],
  comm := λ i j k hij hjk,
  begin
    simp only [double_d, double_comp_double, ← double_add, h.comm i j k hij hjk],
    exact add_monoid_hom.map_sub _ _ _
  end }

def homotopy_pow (h : homotopy BD.σ BD.π) :
  Π N, homotopy (BD.σ_pow N) (BD.π_pow N)
| 0     := homotopy.refl
| (n+1) := (homotopy_double (homotopy_pow n)).comp h

end data

section
universe variables u
open universal_map
variables {m n : ℕ} (A : Type u) [add_comm_group A] (f : universal_map m n)

end

open differential_object.complex_like

/-- A Breen--Deligne `package` consists of Breen--Deligne `data`
that forms a complex, together with a `homotopy`
between the two universal maps `σ_add` and `σ_proj`. -/
structure package :=
(data       : data)
(homotopy   : @homotopy ℕ FreeMat ff _ _ _ data.double data data.σ data.π)

namespace package

/-- `BD.rank i` is the rank of the `i`th entry in the Breen--Deligne resolution described by `BD`. -/
def rank (BD : package) := BD.data.X

def map (BD : package) (i : ℕ) := BD.data.d (i+1) i

@[simp] lemma map_comp_map (BD : package) (i : ℕ) : BD.map _ ≫ BD.map i = 0 :=
BD.data.d_comp_d _ _ _

end package

end breen_deligne
