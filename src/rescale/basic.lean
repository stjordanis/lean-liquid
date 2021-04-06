import polyhedral_lattice.basic

noncomputable theory
open_locale big_operators classical nnreal

local attribute [-instance] add_comm_monoid.nat_semimodule add_comm_group.int_module

@[nolint unused_arguments]
def rescale (N : ℝ≥0) (V : Type*) := V

namespace rescale

variables {N : ℝ≥0} {V : Type*}

instance [i : add_comm_monoid V] : add_comm_monoid (rescale N V) := i
instance [i : add_comm_group V] : add_comm_group (rescale N V) := i

def of : V ≃ rescale N V := equiv.refl _

end rescale
