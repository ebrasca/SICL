(cl:in-package #:sicl-sequence)

(declaim (inline map-for-effect-1))
(defun map-for-effect-1 (function sequence)
  (if (listp sequence)
      (mapc function sequence)
      (let ((function (function-designator-function function)))
        (multiple-value-bind (scanner state)
            (make-sequence-scanner sequence)
          (declare (sequence-scanner scanner))
          (with-scan-buffers (scan-buffer)
            (loop
              (multiple-value-bind (amount new-state)
                  (funcall scanner sequence state scan-buffer)
                (setf state new-state)
                (let ((n (min amount)))
                  (when (zerop n) (return))
                  (loop for index below n do
                    (funcall function (elt scan-buffer index)))))))))))

(declaim (inline map-for-effect-2))
(defun map-for-effect-2 (function sequence-1 sequence-2)
  (if (and (listp sequence-1)
           (listp sequence-2))
      (mapc function sequence-1 sequence-2)
      (let ((function (function-designator-function function)))
        (multiple-value-bind (scanner-1 state-1)
            (make-sequence-scanner sequence-1)
          (declare (sequence-scanner scanner-1))
          (multiple-value-bind (scanner-2 state-2)
              (make-sequence-scanner sequence-2)
            (declare (sequence-scanner scanner-2))
            (with-scan-buffers (scan-buffer-1 scan-buffer-2)
              (loop
                (multiple-value-bind (amount-1 new-state-1)
                    (funcall scanner-1 sequence-1 state-1 scan-buffer-1)
                  (setf state-1 new-state-1)
                  (multiple-value-bind (amount-2 new-state-2)
                      (funcall scanner-2 sequence-2 state-2 scan-buffer-2)
                    (setf state-2 new-state-2)
                    (let ((amount (min amount-1 amount-2)))
                      (when (zerop amount) (return))
                      (loop for index below amount do
                        (funcall function
                                 (elt scan-buffer-1 index)
                                 (elt scan-buffer-2 index)))))))))))))

(declaim (inline map-for-effect-3))
(defun map-for-effect-3 (function sequence-1 sequence-2 sequence-3)
  (if (and (listp sequence-1)
           (listp sequence-2)
           (listp sequence-3))
      (mapc function sequence-1 sequence-2 sequence-3)
      (let ((function (function-designator-function function)))
        (multiple-value-bind (scanner-1 state-1)
            (make-sequence-scanner sequence-1)
          (declare (sequence-scanner scanner-1))
          (multiple-value-bind (scanner-2 state-2)
              (make-sequence-scanner sequence-2)
            (declare (sequence-scanner scanner-2))
            (multiple-value-bind (scanner-3 state-3)
                (make-sequence-scanner sequence-3)
              (declare (sequence-scanner scanner-3))
              (with-scan-buffers (scan-buffer-1 scan-buffer-2 scan-buffer-3)
                (loop
                  (multiple-value-bind (amount-1 new-state-1)
                      (funcall scanner-1 sequence-1 state-1 scan-buffer-1)
                    (setf state-1 new-state-1)
                    (multiple-value-bind (amount-2 new-state-2)
                        (funcall scanner-2 sequence-2 state-2 scan-buffer-2)
                      (setf state-2 new-state-2)
                      (multiple-value-bind (amount-3 new-state-3)
                          (funcall scanner-3 sequence-3 state-3 scan-buffer-3)
                        (setf state-3 new-state-3)
                        (let ((amount (min amount-1 amount-2 amount-3)))
                          (when (zerop amount) (return))
                          (loop for index below amount do
                            (funcall function
                                     (elt scan-buffer-1 index)
                                     (elt scan-buffer-2 index)
                                     (elt scan-buffer-3 index)))))))))))))))

(defun map-for-effect-n (function sequence &rest more-sequences)
  (if (and (listp sequence) (every #'listp more-sequences))
      (apply #'mapc function sequence more-sequences)
      (let* ((function (function-designator-function function))
             (sequences (list* sequence more-sequences))
             (n-sequences (1+ (cl:length more-sequences)))
             (scanners (make-array n-sequences))
             (states (make-array n-sequences))
             (scan-buffers (make-array n-sequences)))
        (declare (optimize speed))
        (loop for sequence in sequences
              for index from 0 do
                (setf (values
                       (svref scanners index)
                       (svref states index))
                      (make-sequence-scanner sequence))
                (setf (svref scan-buffers index)
                      (make-scan-buffer)))
        (loop
          (let ((min-amount +scan-buffer-length+))
            (declare (scan-amount min-amount))
            ;; Fill all scan buffers.
            (loop for sequence in sequences
                  and index below n-sequences
                  do (symbol-macrolet
                         ((scanner (the sequence-scanner (svref scanners index)))
                          (state (svref states index))
                          (scan-buffer (the scan-buffer (svref scan-buffers index))))
                       (multiple-value-bind (amount new-state)
                           (funcall scanner sequence state scan-buffer)
                         (when (< amount min-amount)
                           (setf min-amount amount))
                         (setf state new-state))))
            (when (zerop min-amount)
              (return))
            (loop for index below min-amount do
              (let ((args '()))
                (loop for pos from (1- n-sequences) downto 0 do
                  (push (svref (svref scan-buffers pos) index) args))
                (apply function args))))))))

(defun map-for-effect (function sequence &rest more-sequences)
  (case (length more-sequences)
    (0 (map-for-effect-1 function sequence))
    (1 (map-for-effect-2 function sequence (first more-sequences)))
    (2 (map-for-effect-3 function sequence (first more-sequences) (second more-sequences)))
    (otherwise
     (apply #'map-for-effect-n function sequence more-sequences))))

(define-compiler-macro map-for-effect (&whole form function sequence &rest more-sequences)
  (case (length more-sequences)
    (0 `(map-for-effect-1 ,function ,sequence ,@more-sequences))
    (1 `(map-for-effect-2 ,function ,sequence ,@more-sequences))
    (2 `(map-for-effect-3 ,function ,sequence ,@more-sequences))
    (otherwise form)))