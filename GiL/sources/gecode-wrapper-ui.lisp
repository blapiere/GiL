(cl:defpackage "gil"
  (:nicknames "GIL")
   (:use common-lisp :cl-user :cl :cffi))

(in-package :gil)
;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creating int variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass int-var ()
    ((id :initarg :id :accessor id))
)

(defmethod add-int-var (sp l h) 
    "Adds a integer variable with domain [l,h] to sp"
    (make-instance 'int-var :id (add-int-var-low sp l h)))

(defmethod add-int-var-dom (sp dom)
    "Adds a integer variable with domain dom to sp"
    (make-instance 'int-var :id (add-int-var-dom-low sp dom)))

(defmethod add-int-var-array (sp n l h)
    "Adds an array of n integer variables with domain [l,h] to sp"
    (loop for v in (add-int-var-array-low sp n l h) collect
        (make-instance 'int-var :id v)))

(defmethod add-int-var-array-dom (sp n dom)
    "Adds an array of n integer variables with domain dom to sp"
    (loop for v in (add-int-var-array-dom-low sp n dom) collect
        (make-instance 'int-var :id v)))

;id getter
(defmethod vid ((self int-var))
    "Gets the vid of the variable self"
    (id self))

(defmethod vid ((self list))
    "Gets the vids of the variables in self"
    (loop for v in self collect (vid v)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creating bool variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass bool-var ()
    ((id :initarg :id :accessor id))
)

(defmethod add-bool-var (sp l h)
    "Adds a boolean variable with domain [l,h] to sp"
    (make-instance 'bool-var :id (add-bool-var-range sp l h)))

(defmethod add-bool-var-expr (sp (v1 int-var) rel-type (v2 fixnum))
    "Adds a boolean variable representing the expression 
    v1 rel-type v2 to sp"
    (make-instance 'bool-var 
        :id (add-bool-var-expr-val sp (vid v1) rel-type v2)))

(defmethod add-bool-var-expr (sp (v1 int-var) rel-type (v2 int-var))
    (make-instance 'bool-var 
        :id (add-bool-var-expr-var sp (vid v1) rel-type (vid v2))))

;id getter
(defmethod vid ((self bool-var)) (id self))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Methods for int constraints ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;REL
(defmethod g-rel (sp (v1 int-var) rel-type (v2 fixnum))
    "Post the constraint that v1 rel-type v2."
    (val-rel sp (vid v1) rel-type v2))

(defmethod g-rel (sp (v1 int-var) rel-type (v2 int-var)) 
    (var-rel sp (vid v1) rel-type (vid v2)))

(defmethod g-rel (sp (v1 list) rel-type (v2 null)) 
    (arr-rel sp (vid v1) rel-type))

(defmethod g-rel (sp (v1 list) rel-type (v2 fixnum)) 
    (arr-val-rel sp (vid v1) rel-type v2))

(defmethod g-rel (sp (v1 list) rel-type (v2 int-var)) 
    (arr-var-rel sp (vid v1) rel-type (vid v2)))

(defmethod g-rel (sp (v1 list) rel-type (v2 list)) 
    (arr-arr-rel sp (vid v1) rel-type (vid v2)))

;DISTINCT
(defmethod g-distinct (sp vars) 
    "Post the constraint that the given vars are distinct."
    (distinct sp (vid vars)))

;LINEAR
(defmethod g-linear (sp coeffs vars rel-type (v fixnum))
    "Post the linear relation coeffs*vars rel-type v."
    (val-linear sp coeffs (vid vars) rel-type v))

(defmethod g-linear (sp coeffs vars rel-type (v int-var))
    (var-linear sp coeffs (vid vars) rel-type (vid v)))

;ARITHMETICS
(defmethod g-abs (sp (v1 int-var) (v2 int-var))
    "Post the constraints that v2 = |v1|."
    (ge-abs sp (vid v1) (vid v2)))

(defmethod g-div (sp (v1 int-var) (v2 int-var) (v3 int-var))
    "Post the constraints that v3 = v1/v2."
    (ge-div sp (vid v1) (vid v2) (vid v3)))

(defmethod g-mod (sp (v1 int-var) (v2 int-var) (v3 int-var))
    "Post the constraints that v3 = v1%v2."
    (var-mod sp (vid v1) (vid v2) (vid v3)))

(defmethod g-divmod (sp (v1 int-var) (v2 int-var) (v3 int-var) (v4 int-var))
    "Post the constraints that v3 = v1/v2 and v4 = v1%v2."
    (ge-divmod sp (vid v1) (vid v2) (vid v3) (vid v4)))

(defmethod g-min (sp (v1 int-var) (v2 int-var) (v3 int-var) &rest vars)
    "Post the constraints that v1 = min(v2, v3, ...)."
    (cond 
        ((null vars) 
            (ge-min sp (vid v2) (vid v3) (vid v1)))
        (t (ge-arr-min sp (vid v1) 
            (append (list (vid v2) (vid v3)) (vid vars))))))

(defmethod g-lmin (sp (v int-var) vars)
    "Post the constraints that v = min(vars)."
    (ge-arr-min sp  (vid v) (vid vars)))

(defmethod g-argmin (sp vars (v int-var))
    "Post the constraints that v = argmin(vars)."
    (ge-argmin sp (vid vars) (vid v2)))

(defmethod g-max (sp (v1 int-var) (v2 int-var) (v3 int-var) &rest vars)
    "Post the constraints that v1 = max(v2, v3, ...)."
    (cond ((null vars) (ge-max sp (vid v2) (vid v3) (vid v1)))
          (t (ge-arr-max sp (vid v1) (append (list (vid v2) (vid v3)) (vid vars))))))

(defmethod g-lmax (sp (v int-var) vars)
    "Post the constraints that v = max(vars)."
    (ge-arr-max sp (vid v) (vid vars)))

(defmethod g-argmax (sp vars (v int-var))
    "Post the constraints that v2 = argmax(vars)."
    (ge-argmax sp (vid vars) (vid v)))

(defmethod g-mult (sp (v1 int-var) (v2 int-var) (v3 int-var))
    "Post the constraints that v3 = v1*v2."
    (ge-mult sp (vid v1) (vid v2) (vid v3)))

(defmethod g-sqr (sp (v1 int-var) (v2 int-var))
    "Post the constraints that v2 is the square of v1."
    (ge-sqr sp (vid v1) (vid v2)))

(defmethod g-sqrt (sp (v1 int-var) (v2 int-var))
    "Post the constraints that v2 square root of v1."
    (ge-sqrt sp (vid v1) (vid v2)))

(defmethod g-pow (sp (v1 int-var) n (v2 int-var))
    "Post the constraints that v2 nth power of v1."
    (ge-pow sp (vid v1) n (vid v2)))

(defmethod g-nroot (sp (v1 int-var) n (v2 int-var))
    "Post the constraints that v2 is the nth root of v1."
    (ge-nroot sp (vid v1) n (vid v2)))

(defmethod g-sum (sp (v int-var) vars)
    "Post the constraints that v = sum(vars)."
    (rel-sum sp (vid v) (vid vars)))

;DOM
(defmethod g-dom (sp (v int-var) dom)
    "Post the constraints that dom(v) = dom."
    (set-dom sp (vid v) dom))

(defmethod g-member (sp vars (v int-var))
    "Post the constraints that v is in vars."
    (set-member sp (vid vars) (vid v)))


;COUNT
(defmethod g-count (sp vars (v1 fixnum) rel-type (v2 fixnum))
    "Post the constraints that v2 is the number of times v1 occurs in vars."
    (count-val-val sp (vid vars) v1 rel-type v2))

(defmethod g-count (sp vars (v1 fixnum) rel-type (v2 int-var))
    (count-val-var sp (vid vars) v1 rel-type (vid v2)))

(defmethod g-count (sp vars (v1 int-var) rel-type (v2 fixnum))
    (count-var-val sp (vid vars) (vid v1) rel-type v2))

(defmethod g-count (sp vars (v1 int-var) rel-type (v2 int-var)) 
    (count-var-var sp (vid vars) (vid v1) rel-type (vid v2)))

;NUMBER OF VALUES
(defmethod g-nvalues (sp vars rel-type (v int-var))
    "Post the constraints that v is the number of distinct values in vars."
    (nvalues sp (vid vars) rel-type (vid v)))

;HAMILTONIAN PATH/CIRCUIT
(defmethod g-circuit (sp costs vars1 vars2 v)
    "Post the constraint that values of vars1 are the edges of an hamiltonian circuit in 
    the graph formed by the n variables in vars1, vars2 are the costs of these edges described
    by costs, and v is the total cost of the circuit, i.e. sum(vars2)."
    (hcircuit sp costs (vid vars1) (vid vars2) (vid v)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Methods for bool constraints ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;OP
(defmethod g-op (sp (v1 bool-var) bool-op (v2 bool-var) (v3 fixnum))
    "Post the constraints that v1 bool-op v2 = v3."
    (val-bool-op sp (vid v1) bool-op (vid v2) v3))

(defmethod g-op (sp (v1 bool-var) bool-op (v2 bool-var) (v3 bool-var))
    (var-bool-op sp (vid v1) bool-op (vid v2) (vid v3)))

;REL
(defmethod g-rel (sp (v1 bool-var) rel-type (v2 fixnum))
    "Post the constraints that v1 rel-type v2."
    (val-bool-rel sp (vid v1) rel-type v2))

(defmethod g-rel (sp (v1 bool-var) rel-type (v2 bool-var))
    (var-bool-rel sp (vid v1) rel-type (vid v2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Methods for exploration ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmethod g-branch (sp (v int-var) var-strat val-strat)
    "Post a branching on v with strategies var-strat and val-strat."
    (branch sp (list (vid v)) var-strat val-strat))

(defmethod g-branch (sp (v bool-var) var-strat val-strat)
    (branch-b sp (list (vid v)) var-strat val-strat))

(defmethod g-branch (sp (v list) var-strat val-strat)
    (if (typep (car v) 'int-var)
        (branch sp (vid v) var-strat val-strat)
        (branch-b sp (vid v) var-strat val-strat)))

;cost
(defmethod g-cost (sp (v int-var))
    "Defines that v is the cost of sp."
    (set-cost sp (vid v)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Methods for search engines ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass BAB-engine ()
    ((bab :initform nil :initarg :bab :accessor bab))
)

(defclass DFS-engine ()
    ((dfs :initform nil :initarg :dfs :accessor dfs))
)

(defmethod search-engine (sp &optional (bab nil))
    "Creates a new search engine (dfs or bab)."
    (if bab
        (make-instance 'BAB-engine :bab (bab-engine-low sp))
        (make-instance 'DFS-engine :dfs (dfs-engine-low sp))))

;solution exist?
(defun sol? (sol)
    "Existence predicate for a solution"
    (and (not (cffi::null-pointer-p sol)) sol))

;next solution
(defmethod search-next ((se BAB-engine))
    "Search the next solution of se."
    (sol? (bab-next (bab se))))

(defmethod search-next ((se DFS-engine))
    (sol? (dfs-next (dfs se))))

(defmethod search-next ((se null))
    nil)

;;;;;;;;;;;;;;;;;;;;;;;;;
; Methods for solutions ;
;;;;;;;;;;;;;;;;;;;;;;;;;

;values
(defmethod g-values (sp (v int-var))
    "Get the values assigned to v."
    (get-value sp (vid v)))

(defmethod g-values (sp (v list))
    (get-values sp (vid v)))

(defmethod g-values ((sp null) v)
    nil)

;print
(defmethod g-print (sp (v int-var))
    "Print v."
    (print-vars sp (list (vid v))))

(defmethod g-print (sp (v list))
    (print-vars sp (vid v)))

(defmethod g-print ((sp null) v)
    nil)
