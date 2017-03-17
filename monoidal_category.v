Require Import HoTT.
Require Import UnivalenceAxiom.
Load stuff.



Section Monoidal_Category.
  Require Import Functor Category.
  Require Import NaturalTransformation.
  (*These notations are defined elsewhere, but I do not know how to import it.*)
  Local Notation "x --> y" := (morphism _ x y) (at level 99, right associativity, y at level 200) : type_scope.
  Notation "F '_0' x" := (object_of F x) (at level 10, no associativity, only parsing) : object_scope.
  Notation "F '_1' m" := (morphism_of F m) (at level 10, no associativity) : morphism_scope.
  Open Scope category_scope.
  Open Scope morphism_scope.

  
  
  (*Another strategy to define monoidal categories*)
  Record Magma : Type :=
    { magma_cat :> Category; binary_op : Functor (magma_cat*magma_cat) magma_cat }.
  Arguments binary_op {m}.
  
  Definition binary_op_0 {M : Magma} : ((object M) * (object M) -> object M )%type :=
    object_of binary_op.

  Local Notation "a + b" := (binary_op (a, b)).

  Definition binary_op_1 {M : Magma} {s1 s2 d1 d2 : object M} :
    ((s1 --> d1) * (s2 --> d2))%type -> ((s1 + s2) --> (d1 + d2)).
  Proof.
    intro m. apply (morphism_of binary_op). exact m.
  Defined.

  Local Notation "f +^ g" := (binary_op_1 (f, g)) (at level 80). (*Don't know how I should choose level.*)
  Record Symmetric_Monoidal_Category : Type :=
    {M : Magma ;
     e : M ;
     assoc : forall a b c : M, a + (b + c) --> (a + b) + c;
     iso_assoc : forall a b c : M, IsIsomorphism (assoc a b c);
     natural_assoc : forall (a b c a' b' c': M) (f : a-->a') (g : b --> b') (h : c --> c'),
       assoc a' b' c' o (f +^ (g +^ h)) = ((f +^ g) +^ h) o assoc a b c;
     lid : forall a : M, e + a --> a;
     iso_lid : forall a : M, IsIsomorphism (lid a);
     natural_lid : forall (a a' : M) (f : a --> a'),
       lid a' o (1 +^ f) = f o lid a;
     rid : forall a : M, a + e --> a;
     iso_rid : forall a : M, IsIsomorphism (rid a);
     natural_rid : forall (a a' : M) (f : a --> a'),
       rid a' o (f +^ 1) = f o rid a;
     symm : forall a b : M, a + b -->  b + a;
     natural_sym : forall (a b a' b' : M) (f : a --> a') (g : b --> b'),
         symm a' b' o (f +^ g) = (g +^ f) o symm a b;
     symm_inv : forall a b : M, symm a b o symm b a = 1;
     coh_tri : forall a b : M,
         (rid a +^ 1) o (assoc a e b) = (1 +^ lid b) ;
     coh_pent : forall a b c d : M,
         (assoc (a+b) c d) o (assoc a b (c+d)) =
         (assoc a b c +^ 1) o (assoc a (b+c) d) o (1 +^ assoc b c d);
     coh_hex : forall a b c : M,
         (assoc c a b) o (symm (a+b) c) o assoc a b c =
         (symm a c +^ 1) o (assoc a c b) o (1 +^ symm b c); (*I am guessing that this is correct*)
    }.

  (*Want to define the category [Sigma] of finite sets and isomorphisms. *)
  Definition isset_Finite (A : Type) :
    Finite A -> IsHSet A.
  Proof.
    intros [m finA]. strip_truncations.
    apply (trunc_equiv' (Fin m) finA^-1).
  Defined.
  
  (*obj Sigma := {A : Type & Finite A}
    morph A B := Equiv (Fin (card A)) (Fin (card B))*)

  (*Definition Sigma_morphism (m n : nat) := Equiv (Fin m) (Fin n).*)

  Definition Sigma_precat : PreCategory.
  Proof.
    srapply (@Build_PreCategory {A : Type & Finite A}
                                (fun A B => Equiv A.1 B.1)).
                                (* (fun A B => Equiv (Fin (@fcard A.1 A.2)) (Fin (@fcard B.1 B.2)))). *)
    - (*Identity*)
      intro m.
      apply equiv_idmap.
    - (*Compose*)
      intros A B C.
      apply equiv_compose'.
    - (*Associativity*)
      intros A B C D.
      intros e f g.
      apply ecompose_ee_e.
    - (*Composing with identity from left*)
      intros D E. intro f.
      apply ecompose_1e.
    - (*Composing with identity from right*)
      intros D E. intro f.
      apply ecompose_e1.
    - intros A B. simpl.
      srapply @istrunc_equiv. apply isset_Finite. exact B.2.
  Defined.

  Instance isgroupoid_Sigma {a b : Sigma_precat} (f : a --> b) : IsIsomorphism f.
  Proof.
    srapply @Build_IsIsomorphism.
    - exact (f^-1)%equiv.
    - apply ecompose_Ve.
    - apply ecompose_eV.
  Defined.


  (* This category is univalent *)
  (* Prove this by reducing to univalence in types *)
  (*First: An isomorphism is the same as an equivalence on the underlying type *)
  Definition equiv_isomorphic_Sigma (A B : Sigma_precat) : (A.1 <~> B.1) <~> Isomorphic A B.
  Proof.
    srapply @equiv_adjointify.
    - (*Inverse*)
      intro f. apply (@Build_Isomorphic _ A B f _).
    - (*Underlying map*)
      exact (@morphism_isomorphic _ A B).
    - intro g. apply path_isomorphic. exact idpath.
    - exact (fun _ => idpath).
  Defined.

  Definition idtoiso_is_path_equiv {A B : Sigma_precat} :
    @idtoiso Sigma_precat A B =
    (equiv_isomorphic_Sigma A B) oE (equiv_equiv_path A.1 B.1) oE (equiv_path_sigma_hprop A B)^-1.
  Proof.
    apply path_arrow. 
    intros []. apply path_isomorphic. exact idpath.
  Defined.    

  
  Lemma iscategory_Sigma : IsCategory Sigma_precat.
    intros A B.
    rewrite idtoiso_is_path_equiv. exact _.
  Qed.

  Definition Sigma_cat := Build_Category iscategory_Sigma.

  Definition Sigma_coprod : Functor (Sigma_cat*Sigma_cat) Sigma_cat.
  Proof.
    srapply @Build_Functor.
    - (*Map on objects is sum of types*)
      intros [A B].
      exists (A.1 + B.1)%type. apply finite_sum; exact _.2.
    - (*Map on morphisms.*)
      (*Fin respects sum*)
      intros [A B] [C D].
      unfold morphism. simpl.
      intros [f g]. apply (equiv_functor_sum' f g).
    - (*Respects composition*)
      intros [i1 i2] [j1 j2] [k1 k2].
      intros [f1 f2] [g1 g2]. simpl.
      apply path_equiv. apply path_arrow. 
      intros [m | n]; exact idpath.
    - (*Respects identity*)
      intros [i j]. simpl.
      apply path_equiv. apply path_arrow. intros [m | n]; exact idpath.
  Defined.

  Ltac reduce_sigma_morphism := intros; apply path_equiv; apply path_arrow; repeat (intros [?m | ]); intros.
  
  Definition Sigma : Symmetric_Monoidal_Category.
  Proof.
    srapply (@Build_Symmetric_Monoidal_Category (Build_Magma Sigma_cat Sigma_coprod) ( Fin 0 ; finite_fin 0 )).
    - (*Associativity*)
      intros A B C. apply equiv_inverse.
      apply equiv_sum_assoc.
    - (* Associativity is natural *)
      intros A B C A' B' C' f g h. apply path_equiv. apply path_arrow.
      repeat (intros [m | ]); intros; exact idpath.
    - (*Left identity*)
      intro a. apply sum_empty_l.
    - (*Left identity is natural*)
      intros A A' f.      
      apply path_equiv. apply path_arrow. intros [[] | n]. exact idpath.
    - (*Right identity*)
      intro a. apply sum_empty_r.
    - (*Right identity is natural*)
      intros A A' f. 
      apply path_equiv. apply path_arrow. intros [n | []]. exact idpath.
    - (*Symmetry*)
      intros A A'.
      apply equiv_sum_symm.
    - (*Symmetry is natural*)
      intros A A' B B' f g.
      apply path_equiv. apply path_arrow. intros [m | n]; exact idpath.
    - (*Symmetry is its own inverse*)
      intros A B.
      apply path_equiv. apply path_arrow. intros [m | n]; exact idpath.
    - (*Coherence triangle*)
      intros A B.
      apply path_equiv. apply path_arrow. intros [m | [[]|n]]; exact idpath.
    - (*Coherence pentagon*)
      intros A B C D.
      apply path_equiv. apply path_arrow. repeat (intros [m | ]); intros; exact idpath.
    - (*Coherence hexagon*)
      simpl. intros A B C.
      apply path_equiv. apply path_arrow. repeat (intros [m | ]); intros; exact idpath.
  Defined.

End Monoidal_Category.

(* Define the group completion of a symmetric monoidal category *)
Section Group_Completion.
End Group_Completion.  
 