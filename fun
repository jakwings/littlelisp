;;; Conditionals

;; truth values
(define T (lambda (x y) x))
(define F (lambda (x y) y))
;; logical operators
(define and (lambda (x y) (x y F)))
(define or (lambda (x y) (x T y)))
(define not (lambda (x) (x F T)))
(define xor (lambda (x y) (or (and (not x) y) (and x (not y)))))

;;; Church encoding

(define zero (lambda (s z) z))
;(define suc (lambda (w y x) (y (w y x))))
(define suc (lambda (n) (lambda (y x) (y (n y x)))))
(define add (lambda (x y) (x suc y)))
;(define mul (lambda (w y x) (w (y x))))
(define mul (lambda (w y) (lambda (x) (w (y x)))))
(define pre (lambda (n)
  (n (lambda (p z) (z (suc (p T)) (p T))) (lambda (s) (s zero zero)) F)))
(define sub (lambda (x y) (x pre y)))
(define zerop (lambda (x) (x F not F)))
(define ge (lambda (x y) (zerop (sub x y))))
(define gt (lambda (x y) (not (ge y x))))
(define le (lambda (x y) (zerop (sub y x))))
(define lt (lambda (x y) (not (le y x))))
(define eq (lambda (x y) (and (ge x y) (ge y x))))
(define ne (lambda (x y) (not (eq x y))))

;;; Recursion

;; Y combinator, use it to get fixed point of a function
(define (Y f) ((lambda (x) (x x)) (lambda (x) (f (lambda (y) ((x x) y))))))
;; Use it to test Y combinator
(define (f_gen f) (lambda (n) (if (< n 1) 1 (* n (f (- n 1))))))
;; Use it to test Y combinator with currying support
(define (g_gen f) (lambda (n m) (if (< n 1) m (f (- n 1) (* m n)))))

(print "Load Completed. Have fun!")