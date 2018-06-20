;; Hypernym

(B (name poodle-is-dog)
   (=> (poodle-nn e1 x :0.9)
       (dog-nn e1 x)))

(B (name dog-is-animal)
   (=> (dog-nn e1 x :0.9)
       (animal-nn e2 x)))

(B (name cat-is-animal)
   (=> (cat-nn e1 x :0.9)
       (animal-nn e2 x)))

(B (name dinner-is-meal)
   (=> (dinner-nn e1 x :0.9)
       (meal-nn e2 x)))

(B (name financial-bank)
   (=> (financial-institution e1 x :0.4)
       (bank-nn e2 x)))

(B (name river-bank)
   (=> (river-bank e1 x :0.6)
       (bank-nn e2 x)))

;; Properties

(B (name friendly-adj)
   (=> (friendly e2 x1 :0.9)
       (friendly-adj e1 x1)))

(B (name nice-people-are-friendly)
   (=> (nice e2 x1 :0.9)
       (friendly e1 x1)))


;; Typical actions

(B (name criminals-steal)
    (=> (steal-vb e1 x y u :0.9)
        (criminal-nn e2 x)))

(B (name criminals-kill)
   (=> (kill e1 x y :0.9)
       (criminal-nn e2 x)))

(B (name friendly-people-wave)
   (=> (^ (person e1 x1 :0.45) (friendly e3 x1 :0.45))
       (wave e2 x1)))

;; Actions

(B (name kill-die)
   (=> (kill e1 x y :0.9)
       (die e2 y)))

(B (name die-vb)
   (=> (die e1 x :0.9)
       (die-vb e2 x)))

(B (name kill-vb)
   (=> (kill e1 x y :0.9)
       (kill-vb e1 x y u)))

(B (name people-eat-meals)
   (=> (meal e3 x2 :0.9)
       (^ (person e1 x1) (eat e2 x1 x2))))

;; Flatten the role and throw away the extraneous argument to 'eat'.
(B (name eat-vb)
   (=> (eat e3 x1 x2 :0.9)
       (^ (vn-agent e1 e2 x1) (eat-vb e2 u1 x2 u2))))

(B (name shoot-kill)
   (=> (shoot-vb e1 x y :0.9)
       (kill e2 x y)))

;; 'Theme' may be wrong, but it's what Boxer gives.
(B (name wave-vb)
   (=> (wave e3 x1 :0.9)
       (^ (vn-theme e1 e2 x1) (wave-vb e2 u1 u2 u3))))
