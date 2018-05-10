(B (name criminals-steal)
    (=> (steal-vb e1 x y u)
        (criminal-nn e2 x) :0.6))

(B (name criminals-kill)
   (=> (kill e1 x y u)
       (criminal-nn e2 x) :0.6))

(B (name kill-vb)
   (=> (kill e1 x y u)
       (kill-vb e1 x y u)))

(B (name dinner-is-a-meal)
   (=> (meal e1 x)
       (dinner-nn e2 x) :0.6))

(B (name financial-bank)
   (=> (financial-institution e1 x)
       (bank-nn e2 x) :0.2))

(B (name river-bank)
   (=> (river-bank e1 x)
       (bank-nn e2 x) :0.8))

(B (name friendly-jj)
   (=> (friendly e2 x1)
       (friendly-jj e1 x1) :0.9))

(B (name friendly-people-wave)
   (=> (friendly e2 x1)
       (wave-vb e1 x1) :0.9))

(B (name nice-people-are-friendly)
   (=> (nice e2 x1)
       (friendly e1 x1) :0.9))
