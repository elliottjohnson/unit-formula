(in-package :unit-formulas)

;;; units are described by s-expressions, with operations: * / expt sqrt
;;; * is implied if car of a list is other symbol

(defun multiply-units (units)
  (if (cdr units)
      (make-instance 'unit
		     :factor (reduce #'* (mapcar #'factor-of units))
		     :units (apply #'map 'vector #'+ (mapcar #'units-of units)))
      (car units)))

(defun divide-units (units)
  (if (cdr units)
      (make-instance 'unit
		     :factor (reduce #'/ (mapcar #'factor-of units))
		     :units (apply #'map 'vector #'- (mapcar #'units-of units)))
      (car units)))

(defun expt-units (unit power)
  (check-type power (or integer ratio))
  (make-instance 'unit
		 :factor (expt (factor-of unit) power)
		 :units (map 'vector (curry #'* power) (units-of unit))))

(defun sqrt-units (unit)
  (make-instance 'unit
		 :factor (sqrt (factor-of unit))
		 :units (map 'vector (curry #'/ 2) (units-of unit))))

(defun same-unit-p (unit1 unit2 &key (factor nil))
  (and (every #'= (units-of unit1) (units-of unit2))
       (if factor
	   (= (factor-of unit1) (factor-of unit2))
	   t)))

(defun reduce-unit (unit-description)
  (etypecase unit-description
    (null (make-instance 'unit))
    (unit unit-description)
    (number
     (make-instance 'unit :factor unit-description))
    (symbol
     (let ((substitution
	    (gethash unit-description *units*)))
       (if substitution substitution (error "Unknown unit ~a" unit-description))))
    (list
     (case (car unit-description)
       (* (multiply-units (mapcar #'reduce-unit (cdr unit-description))))
       (/ (divide-units (mapcar #'reduce-unit (cdr unit-description))))
       (expt (expt-units (reduce-unit (cadr unit-description)) (caddr unit-description)))
       (sqrt (sqrt-units (reduce-unit (cadr unit-description))))
       (t (multiply-units (mapcar #'reduce-unit unit-description)))))))

