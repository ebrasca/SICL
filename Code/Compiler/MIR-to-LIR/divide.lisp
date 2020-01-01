(cl:in-package #:sicl-mir-to-lir)

(defmethod process-instruction
    ((instruction cleavir-ir:fixnum-divide-instruction) lexical-locations)
  (let ((inputs (cleavir-ir:inputs instruction))
        (outputs (cleavir-ir:outputs instruction)))
    (cleavir-ir:insert-instruction-before
     (make-instance 'cleavir-ir:assignment-instruction
       :input (make-instance 'cleavir-ir:immediate-input :value 0)
       :output *rdx*)
     instruction)
    (cond ((typep (first inputs) 'cleavir-ir:lexical-location)
           (insert-memref-before
            instruction
            (first inputs)
            *rax*
            *r11*
            lexical-locations))
          ((eq (first inputs) *rax*)
           nil)
          (t
           (cleavir-ir:insert-instruction-before
            (make-instance 'cleavir-ir:assignment-instruction
              :input (first inputs)
              :output *rax*)
            instruction)))
    (when (typep (second inputs) 'cleavir-ir:lexical-location)
      (insert-memref-before
       instruction
       (second inputs)
       *rcx*
       *r11*
       lexical-locations)
      (setf (second inputs) *rcx*))
    (cond ((typep (first outputs) 'cleavir-ir:lexical-location)
           (insert-memset-after
            instruction
            *rax*
            (first outputs)
            *r11*
            lexical-locations))
          ((eq (first inputs) *rax*)
           nil)
          (t
           (cleavir-ir:insert-instruction-after
            (make-instance 'cleavir-ir:assignment-instruction
              :input *rax*
              :output (first outputs))
            instruction)))
    (cond ((typep (second outputs) 'cleavir-ir:lexical-location)
           (insert-memset-after
            instruction
            *rdx*
            (second outputs)
            *r11*
            lexical-locations))
          ((eq (second outputs) *rdx*)
           nil)
          (t
           (cleavir-ir:insert-instruction-after
            (make-instance 'cleavir-ir:assignment-instruction
              :input *rdx*
              :output (second outputs))
            instruction)))
    (setf (first inputs) *rax*)
    (setf (first outputs) *rax*)
    (setf (second outputs) *rdx*)))
        
  
