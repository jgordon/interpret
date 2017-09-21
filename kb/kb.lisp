(B (name kb01)
    (=> (steal-vb e1 x y u)
        (criminal-nn e2 x) :0.6))

(B (name kb02)
   (=> (kill-vb e1 x y u)
       (criminal-nn e2 x) :0.6))

(B (name kb03)
   (=> (meal-nn e1 x)
       (dinner-nn e2 x) :0.6))

(B (name kb04)
   (=> (financial-institution e1 x)
       (bank-nn e2 x) :0.2))

(B (name kb05)
   (=> (river-bank e1 x)
       (bank-nn e2 x) :0.8))
