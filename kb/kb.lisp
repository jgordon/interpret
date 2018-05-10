(B (name criminals-steal)
    (=> (steal-vb e1 x y u)
        (criminal-nn e2 x) :0.6))

(B (name criminals-kill)
   (=> (kill e1 x y u)
       (criminal-nn e2 x) :0.6))

(B (name kill-vb)
   (=> (kill e1 x y u)
       (kill-vb e1 x y u) :0.9))

(B (name people-eat-meals)
   (=> (meal e3 x2)
       (^ (person e1 x1) (eat e2 x1 x2)) :0.9))

;; Flatten the role and throw away the extraneous argument to 'eat'.
(B (name eat-vb)
   (=> (eat e3 x1 x2)
       (^ (vn-agent e1 e2 x1) (eat-vb e2 u1 x2 u2)) :0.9))

(B (name dinner-is-a-meal)
   (=> (meal e1 x)
       (dinner-nn e2 x) :0.6))

(B (name financial-bank)
   (=> (financial-institution e1 x)
       (bank-nn e2 x) :0.2))

(B (name river-bank)
   (=> (river-bank e1 x)
       (bank-nn e2 x) :0.8))

(B (name friendly-adj)
   (=> (friendly e2 x1)
       (friendly-adj e1 x1) :0.9))

(B (name friendly-people-wave)
   (=> (friendly e3 x1)
       (^ (person e1 x1) (wave e2 x1)) :0.9))

;; 'Theme' may be wrong, but it's what Boxer gives.
(B (name wave-vb)
   (=> (wave e3 x1)
       (^ (vn-theme e1 e2 x1) (wave-vb e2 u1 u2 u3)) :0.9))

(B (name nice-people-are-friendly)
   (=> (nice e2 x1)
       (friendly e1 x1) :0.9))
