;; void value for CBV evaluaiton strategy to prevent non-termination
(define void (lambda (x) x))
(define (const x) (lambda (_) x))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Currying
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define curry (lambda (f) (lambda (x) (lambda (y) (f x y)))))
(define uncurry (lambda (f) (lambda (x y) ((f x) y))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Conditionals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; truth values

;(define T (lambda (t) (lambda (f) t)))
;(define T (lambda (t f) t))
;(define 'T (lambda (onTrue)
;             (lambda (onFalse)
;               (onTrue void))))
(define 'T (lambda (onTrue onFalse)
             (onTrue void)))

;(define F (lambda (t) (lambda (f) f)))
;(define F (lambda (t f) f))
;(define 'F (lambda (onTrue)
;             (lambda (onFalse)
;               (onFalse void))))
(define 'F (lambda (onTrue onFalse)
             (onFalse void)))

;; logical operators

;(define and (lambda (x) (lambda (y) ((x y) F))))
;(define and (lambda (x y) (x y F)))
;(define 'and (lambda (x)
;               (lambda (y)
;                 ((x (const y)) (const 'F)))))
(define ('and x y)
  (x (const y) (const 'F)))

;(define or (lambda (x) (lambda (y) ((x T) y))))
;(define or (lambda (x y) (x T y)))
;(define 'or (lambda (x)
;              (lambda (y)
;                ((x (const 'T)) (const y)))))
(define ('or x y)
  (x (const 'T) (const y)))

;(define not (lambda (x) ((x F) T)))
;(define not (lambda (x) (x F T)))
;(define 'not (lambda (x)
;               ((x (const 'F)) (const 'T))))
(define ('not x)
  (x (const 'F) (const 'T)))

;(define xor (lambda (x)
;              (lambda (y)
;                ((or ((and (not x)) y)) ((and x) (not y))))))
;(define xor (lambda (x y) (or (and (not x) y) (and x (not y)))))
;(define 'xor (lambda (x)
;               (lambda (y)
;                 ('or ('and ('not x) y) ('and x ('not y))))))
(define ('xor x y)
  ('or ('and ('not x) y) ('and x ('not y))))

;; controller

;(define if (lambda (e) (lambda (t) (lambda (f) ((e t) f)))))
;(define (if e t f) (e t f))
;(define 'if (lambda (test)
;              (lambda (onTrue)
;                (lambda (onFalse)
;                  ((test (const onTrue)) (const onFalse))))))
(define ('if test onTrue onFalse)
  (test (const onTrue) (const onFalse)))

;; Church encoding & decoding

(define (bool test)
  (if test 'T 'F))
(define (boolify test)
  ((test (const 1)) (const 0)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Numerical
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(define zero (lambda (f) (lambda (z) z)))
(define zero (lambda (f z) z))

;(define suc (lambda (w) (lambda (y) (lambda (x) (y ((w y) x))))))
(define (suc n)
  (lambda (y x) (y (n y x))))

;(define add (lambda (x) (lambda (y) ((x suc) y))))
(define (add x y)
  (x suc y))

;(define mul (lambda (w) (lambda (y) (lambda (x) (w (y x))))))
(define (mul w y)
  (lambda (x) (w (y x))))

;(define suc_pair (lambda (p)
;                   (lambda (z)
;                     ((z (suc (p (lambda (t f) t)))) (p (lambda (t f) t))))))
(define (suc_pair p)
  (lambda (z)
    (z (suc (p (lambda (t f) t))) (p (lambda (t f) t)))))

;(define pre (lambda (n)
;              (((n suc_pair) (lambda (z) ((z zero) zero))) (lambda (t f) f))))
(define (pre n)
  ((n suc_pair (lambda (z) (z zero zero))) (lambda (t f) f)))

;(define sub (lambda (x) (lambda (y) ((y pre) x))))
(define (sub x y) (y pre x))

;(define zerop (lambda (x) (((x F) not) F)))
;(define zerop (lambda (x) ((x F not) F)))
;(define zerop (lambda (x)
;                (((x (lambda (x) (('F (const x)) void))) 'not) 'F)))
(define zerop (lambda (x)
                ((x (lambda (x) ('F (const x) void)) 'not) 'F)))

;(define ge (lambda (x) (lambda (y) (zerop ((sub y) x)))))
(define (ge x y) (zerop (sub y x)))

;(define gt (lambda (x) (lambda (y) ('not ((ge y x))))))
(define (gt x y) ('not (ge y x)))

;(define le (lambda (x) (lambda (y) (zerop ((sub x) y)))))
(define (le x y) (zerop (sub x y)))

;(define lt (lambda (x) (lambda (y) ('not ((le y) x)))))
(define (lt x y) ('not (le y x)))

;(define eq (lambda (x) (lambda (y) (('and ((ge x) y)) ((ge y) x)))))
(define (eq x y) ('and (ge x y) (ge y x)))

;(define ne (lambda (x) (lambda (y) ('not ((eq x) y)))))
(define (ne x y) ('not (eq x y)))

;; Church encoding & decoding

(define (number n)
  ((Y (lambda (g k)
        (if (< k 1) zero (suc (g (- k 1)))))) n))

(define (numerify n)
  ((n (lambda (x) (+ 1 x))) 0))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Let-binding
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; No way to connect the inner scopes of two separating functions.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; List
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Recursion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Y combinator, use it to get fixed point of a function
;(define Y (lambda (g)
;            ((lambda (x) (x x)) (lambda (x) (g (lambda (y) ((x x) y)))))))
;(define Y (lambda (g)
;            ((lambda (x) (g (lambda (y) ((x x) y))))
;              (lambda (x) (g (lambda (y) ((x x) y)))))))
(define (Y g)
  ((lambda (x) (g (lambda (y) ((x x) y))))
    (lambda (x) (g (lambda (y) ((x x) y))))))

;; Use it to test Y combinator
(define (f_gen f) (lambda (n) (if (< n 1) 1 (* n (f (- n 1))))))

;; Use it to test Y combinator with currying support
(define (g_gen f) (lambda (n m) (if (< n 1) m (f (- n 1) (* m n)))))

(print "Church encoding library loaded. Have fun!")