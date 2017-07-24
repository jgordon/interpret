(B (name kb01)
    (=> (steal-vb e1 x y u :0.6)
        (criminal-nn e2 x)))

(B (name kb02)
   (=> (kill-vb e1 x y u :0.6)
       (criminal-nn e2 x)))

(B (name kb03)
   (=> (meal-nn e1 x :0.6)
       (dinner-nn e2 x)))
