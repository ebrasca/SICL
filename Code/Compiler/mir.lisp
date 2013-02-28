(in-package #:sicl-mir)

;;;; MIR stands for Medium-level Intermediate Representation.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Locations are used as inputs to and outputs from instructions. 
;;;
;;; The possible types of locations that can be found in a MIR program
;;; depends on the stage of translation.  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Drawing a location on a stream.

(defgeneric draw-location (location stream))

;;; During the drawing process, the value of this variable is a hash
;;; table that contains locations that have already been drawn. 
(defparameter *location-table* nil)

(defmethod draw-location :around (location stream)
  (when (null (gethash location *location-table*))
    (setf (gethash location *location-table*) (gensym))
    (format stream "  ~a [shape = ellipse, style = filled];~%"
	    (gethash location *location-table*))
    (call-next-method)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; When a MIR program is generated by the AST compiler, it contains
;;; three kinds of locations.  
;;;
;;; The IMMEDIATE-INPUT location corresponds to a raw machine interger
;;; that is considered sufficiently small that it can occur directly
;;; in the instruction stream.  The machine integer is represented in
;;; the instance as a Lisp integer.  The machine integer can represent
;;; some raw numeric information, or it can represent a tagged
;;; immediate Lisp datum such as a fixnum or a character. 
;;;
;;; Lexical locations including explicit local variables and generated
;;; temporaries are represented by instances of
;;; SICL-ENV:LEXICAL-LOCATION.  These locations have a name that can
;;; be used for debugging purposes.  Temporaries have GENSYMed names.
;;;
;;; The EXTERNAL-INPUT location corresponds to all external
;;; references, including constants that can not be handled by
;;; IMMEDIATE-INPUT either because they are numerically too large, or
;;; because they are not numeric.  This type of input also represents
;;; occurrences in the source of LOAD-TIME-VALUE.  Finally, we use
;;; this kind of input to stand for the global value cell of a
;;; function.  At load time, the value cell of the function is taken
;;; from the global environment. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Location class IMMEDIATE-INPUT.

(defclass immediate-input ()
  ((%value :initarg :value :reader value)))

(defun make-immediate-input (value)
  (make-instance 'immediate-input
    :value value))

(defmethod draw-location ((location immediate-input) stream)
  (format stream "   ~a [fillcolor = green, label = \"~a\"]~%"
	  (gethash location *location-table*)
	  (value location)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Location class EXTERNAL-INPUT.

(defclass external-input ()
  ((%value :initarg :value :reader value)))

(defun make-external-input (value)
  (make-instance 'external-input
    :value value))

(defmethod draw-location ((location external-input) stream)
  (format stream "   ~a [fillcolor = pink, label = \"~a\"]~%"
	  (gethash location *location-table*)
	  (value location)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Draw method for the SICL-ENV:LOCATION location class.

(defmethod draw-location ((location sicl-env:location) stream)
  (format stream "  ~a [fillcolor = yellow, label = \"~a\"]~%" 
	  (gethash location *location-table*)
	  (sicl-env:name location)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Later in the translation process, the lexical an external
;;; locations above are replaced by lower-level locations.  
;;;
;;; The SICL-ENV:LEXICAL-LOCATION is replaced by a LEXICAL-POSITION.
;;; This location contains two small non-negative integers.  The first
;;; such integer corresponds to the difference between the lexical
;;; depth of the instruction that accesses the location, and the
;;; lexical depth of the location itself.  This value is used to
;;; determine a LEVEL in the lexical runtime environment.  The second
;;; integer corresponds to the INDEX of that location in the lexical
;;; level determined by the first integer.  These indices are assigned
;;; sequentially to locations at the same lexical depth.
;;;
;;; The EXTERNAL-LOCATION is replaced by an EXTERNAL-POSITION.  This
;;; location contains a single small non-negative integer.  It
;;; corresponds to the INDEX of the vector of the externals allocated
;;; for a code object or for a set of related code objects (such as
;;; all the code objects in a file).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Location class LEXICAL-POSITION.

(defclass lexical-position ()
  ((%level :initarg :level :reader level)
   (%index :initarg :index :reader index)))

(defun make-lexical-position (level index)
  (make-instance 'lexical-position
    :level level
    :index index))

(defmethod draw-location ((location lexical-position) stream)
  (format stream "   ~a [fillcolor = yellow, label = \"[~a, ~a]\"]~%"
	  (gethash location *location-table*)
	  (level location)
	  (index location)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Location class EXTERNAL-POSITION.

(defclass external-position ()
  ((%index :initarg :index :reader index)))

(defun make-external-position (index)
  (make-instance 'external-position
    :index index))

(defmethod draw-location ((location external-position) stream)
  (format stream "   ~a [fillcolor = pink, label = \"[~a]\"]~%"
	  (gethash location *location-table*)
	  (index location)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instructions. 

(defclass instruction ()
  ((%successors :initform '() :initarg :successors :accessor successors)
   (%inputs :initform '() :initarg :inputs :reader inputs)
   (%outputs :initform '() :initarg :outputs :reader outputs)))

(defmethod initialize-instance :after ((obj instruction) &key &allow-other-keys)
  (unless (and (listp (successors obj))
	       (every (lambda (successor)
			(typep successor 'instruction))
		      (successors obj)))
    (error "successors must be a list of instructions")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Drawing instructions.

(defparameter *instruction-table* nil)

(defgeneric draw-instruction (instruction stream))
  
(defmethod draw-instruction :around (instruction stream)
  (when (null (gethash instruction *instruction-table*))
    (setf (gethash instruction *instruction-table*) (gensym))
    (format stream "  ~a [shape = box];~%"
	    (gethash instruction *instruction-table*))
    (call-next-method)))

(defmethod draw-instruction :before ((instruction instruction) stream)
  (loop for next in (successors instruction)
	do (draw-instruction next stream))
  (loop for next in (successors instruction)
	do (format stream
		   "  ~a -> ~a [style = bold];~%"
		   (gethash instruction *instruction-table*)
		   (gethash next *instruction-table*))))
  
(defmethod draw-instruction (instruction stream)
  (format stream "   ~a [label = \"~a\"];~%"
	  (gethash instruction *instruction-table*)
	  (class-name (class-of instruction))))

(defmethod draw-instruction :after (instruction stream)
  (loop for location in (inputs instruction)
	do (draw-location location stream)
	   (format stream "  ~a -> ~a [color = red, style = dashed];~%"
		   (gethash location *location-table*)
		   (gethash instruction *instruction-table*)))
  (loop for location in (outputs instruction)
	do (draw-location location stream)
	   (format stream "  ~a -> ~a [color = blue, style = dashed];~%"
		   (gethash instruction *instruction-table*)
		   (gethash location *location-table*))))

(defun draw-flowchart (start filename)
  (with-open-file (stream filename
			  :direction :output
			  :if-exists :supersede)
    (let ((*instruction-table* (make-hash-table :test #'eq))
	  (*location-table* (make-hash-table :test #'eq)))
	(format stream "digraph G {~%")
	(draw-instruction start stream)
	(format stream "}~%"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instructions for Common Lisp operators.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction NOP-INSTRUCTION.

(defclass nop-instruction (instruction)
  ())

(defun make-nop-instruction (successors)
  (make-instance 'nop-instruction
    :successors successors))

(defmethod draw-instruction ((instruction nop-instruction) stream)
  (format stream "   ~a [label = \"nop\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ASSIGNMENT-INSTRUCTION.

(defclass assignment-instruction (instruction)
  ())

(defun make-assignment-instruction (input output successor)
  (make-instance 'assignment-instruction
    :inputs (list input)
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction
    ((instruction assignment-instruction) stream)
  (format stream "   ~a [label = \"<-\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction TEST-INSTRUCTION.

(defclass test-instruction (instruction)
  ())

(defun make-test-instruction (input successors)
  (make-instance 'test-instruction
    :inputs (list input)
    :successors successors))

(defmethod draw-instruction ((instruction test-instruction) stream)
  (format stream "   ~a [label = \"test\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FUNCALL-INSTRUCTION.

(defclass funcall-instruction (instruction)
  ())

(defun make-funcall-instruction (input successor)
  (make-instance 'funcall-instruction
    :inputs (list input)
    :successors (list successor)))

(defmethod draw-instruction ((instruction funcall-instruction) stream)
  (format stream "   ~a [label = \"funcall\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction GET-ARGUMENTS-INSTRUCTION.

(defclass get-arguments-instruction (instruction)
  ((%lambda-list :initarg :lambda-list :accessor lambda-list)))

(defun make-get-arguments-instruction (successor lambda-list)
  (make-instance 'get-arguments-instruction
    :successors (list successor)
    :lambda-list lambda-list))

(defmethod outputs ((instruction get-arguments-instruction))
  (sicl-ast:required (lambda-list instruction)))

(defmethod draw-instruction ((instruction get-arguments-instruction) stream)
  (format stream "   ~a [label = \"get-args\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction GET-VALUES-INSTRUCTION.

(defclass get-values-instruction (instruction)
  ())

(defun make-get-values-instruction (outputs successor)
  (make-instance 'get-values-instruction
    :outputs outputs
    :successors (list successor)))

(defmethod draw-instruction ((instruction get-values-instruction) stream)
  (format stream "   ~a [label = \"get-values\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction PUT-ARGUMENTS-INSTRUCTION.

(defclass put-arguments-instruction (instruction)
  ())

(defun make-put-arguments-instruction (inputs successor)
  (make-instance 'put-arguments-instruction
    :inputs inputs
    :successors (list successor)))

(defmethod draw-instruction ((instruction put-arguments-instruction) stream)
  (format stream "   ~a [label = \"put-args\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction PUT-VALUES-INSTRUCTION.

(defclass put-values-instruction (instruction)
  ())

(defun make-put-values-instruction (inputs successor)
  (make-instance 'put-values-instruction
    :inputs inputs
    :successors (list successor)))

(defmethod draw-instruction ((instruction put-values-instruction) stream)
  (format stream "   ~a [label = \"put-values\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ENTER-INSTRUCTION.
;;;
;;; FIXME: maybe remove.

(defclass enter-instruction (instruction)
  ())

(defmethod draw-instruction ((instruction enter-instruction) stream)
  (format stream "   ~a [label = \"enter\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction LEAVE-INSTRUCTION.
;;;
;;; FIXME: maybe remove.

(defclass leave-instruction (instruction)
  ())

(defmethod draw-instruction ((instruction leave-instruction) stream)
  (format stream "   ~a [label = \"leave\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction RETURN-INSTRUCTION.

(defclass return-instruction (instruction)
  ())

(defun make-return-instruction ()
  (make-instance 'return-instruction))

(defmethod draw-instruction ((instruction return-instruction) stream)
  (format stream "   ~a [label = \"ret\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ENCLOSE-INSTRUCTION.

(defclass enclose-instruction (instruction)
  ((%code :initarg :code :accessor code)))  

(defun make-enclose-instruction (output successor code)
  (make-instance 'enclose-instruction
    :outputs (list output)
    :successors (list successor)
    :code code))

(defmethod draw-instruction ((instruction enclose-instruction) stream)
  (format stream "   ~a [label = \"enclose\"];~%"
	  (gethash instruction *instruction-table*))
  (draw-instruction (code instruction) stream)
  (format stream "  ~a -> ~a [color = pink, style = dashed];~%"
	  (gethash (code instruction) *instruction-table*)
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instructions for low-level operators.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction MEMALLOC-INSTRUCTION.
;;;
;;; FIXME: maybe remove this one, and replace it with a function call
;;; (which could be inlined).  The corresponding function would return
;;; a fixnum which has a magnitude that is 1/4 or 1/8 of the raw
;;; address, which would make it contain exactly the same bits as the
;;; raw address itself, provided the tag for fixnums is 0.

(defclass memalloc-instruction (instruction)
  ())

(defun make-memalloc-instruction (input output successor)
  (make-instance 'memalloc-instruction
    :inputs (list input)
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction ((instruction memalloc-instruction) stream)
  (format stream "   ~a [label = \"memalloc\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction MEMREF-INSTRUCTION.

(defclass memref-instruction (instruction)
  ())

(defun make-memref-instruction (input output successor)
  (make-instance 'memref-instruction
    :inputs (list input)
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction ((instruction memref-instruction) stream)
  (format stream "   ~a [label = \"memref\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction MEMSET-INSTRUCTION.

(defclass memset-instruction (instruction)
  ())

(defun make-memset-instruction (inputs successor)
  (make-instance 'memset-instruction
    :inputs inputs
    :successors (list successor)))

(defmethod draw-instruction ((instruction memset-instruction) stream)
  (format stream "   ~a [label = \"memset\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction U+-INSTRUCTION.

(defclass u+-instruction (instruction)
  ())

(defun make-u+-instruction (inputs output successors)
  (make-instance 'u+-instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

(defmethod draw-instruction ((instruction u+-instruction) stream)
  (format stream "   ~a [label = \"u+\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction U--INSTRUCTION.

(defclass u--instruction (instruction)
  ())

(defun make-u--instruction (inputs output successors)
  (make-instance 'u--instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

(defmethod draw-instruction ((instruction u--instruction) stream)
  (format stream "   ~a [label = \"u-\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction S+-INSTRUCTION.

(defclass s+-instruction (instruction)
  ())

(defun make-s+-instruction (inputs output successors)
  (make-instance 's+-instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

(defmethod draw-instruction ((instruction s+-instruction) stream)
  (format stream "   ~a [label = \"s+\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction S--INSTRUCTION.

(defclass s--instruction (instruction)
  ())

(defun make-s--instruction (inputs output successors)
  (make-instance 's--instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

(defmethod draw-instruction ((instruction s--instruction) stream)
  (format stream "   ~a [label = \"s-\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction NEG-INSTRUCTION.

(defclass neg-instruction (instruction)
  ())

(defun make-neg-instruction (inputs output successors)
  (make-instance 'neg-instruction
    :inputs inputs
    :outputs (list output)
    :successors successors))

(defmethod draw-instruction ((instruction neg-instruction) stream)
  (format stream "   ~a [label = \"neg\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction &-INSTRUCTION.

(defclass &-instruction (instruction)
  ())

(defun make-&-instruction (inputs output successor)
  (make-instance '&-instruction
    :inputs inputs
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction ((instruction &-instruction) stream)
  (format stream "   ~a [label = \"&\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction IOR-INSTRUCTION.

(defclass ior-instruction (instruction)
  ())

(defun make-ior-instruction (inputs output successor)
  (make-instance 'ior-instruction
    :inputs inputs
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction ((instruction ior-instruction) stream)
  (format stream "   ~a [label = \"ior\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction XOR-INSTRUCTION.

(defclass xor-instruction (instruction)
  ())

(defun make-xor-instruction (inputs output successor)
  (make-instance 'xor-instruction
    :inputs inputs
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction ((instruction xor-instruction) stream)
  (format stream "   ~a [label = \"xor\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ~-INSTRUCTION.

(defclass ~-instruction (instruction)
  ())

(defun make-~-instruction (inputs output successor)
  (make-instance '~-instruction
    :inputs inputs
    :outputs (list output)
    :successors (list successor)))

(defmethod draw-instruction ((instruction ~-instruction) stream)
  (format stream "   ~a [label = \"~\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ==-INSTRUCTION.

(defclass ==-instruction (instruction)
  ())

(defun make-==-instruction (inputs successors)
  (make-instance '==-instruction
    :inputs inputs
    :successors successors))

(defmethod draw-instruction ((instruction ==-instruction) stream)
  (format stream "   ~a [label = \"==\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction S<-INSTRUCTION.

(defclass s<-instruction (instruction)
  ())

(defun make-s<-instruction (inputs successors)
  (make-instance 's<-instruction
    :inputs inputs
    :successors successors))

(defmethod draw-instruction ((instruction s<-instruction) stream)
  (format stream "   ~a [label = \"s<\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction S<=-INSTRUCTION.

(defclass s<=-instruction (instruction)
  ())

(defun make-s<=-instruction (inputs successors)
  (make-instance 's<=-instruction
    :inputs inputs
    :successors successors))

(defmethod draw-instruction ((instruction s<=-instruction) stream)
  (format stream "   ~a [label = \"s<=\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction U<-INSTRUCTION.

(defclass u<-instruction (instruction)
  ())

(defun make-u<-instruction (inputs successors)
  (make-instance 'u<-instruction
    :inputs inputs
    :successors successors))

(defmethod draw-instruction ((instruction u<-instruction) stream)
  (format stream "   ~a [label = \"u<\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction U<=-INSTRUCTION.

(defclass u<=-instruction (instruction)
  ())

(defun make-u<=-instruction (inputs successors)
  (make-instance 'u<=-instruction
    :inputs inputs
    :successors successors))

(defmethod draw-instruction ((instruction u<=-instruction) stream)
  (format stream "   ~a [label = \"u<=\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction CATCH-INSTRUCTION.
;;;
;;; This instruction is used to mark the stack to be an exit point.
;;; It takes a single input and it has a single successor.  It has no
;;; outputs.  The effect of the instruction is to push an entry onto
;;; the dynamic environment that contains the value of the input to
;;; the instruction and the current stack.
;;;
;;; To implement the Common Lisp CATCH special operator, the entire
;;; CATCH form would be placed in a thunk that can not be inlined
;;; (because the return address must be explicit).  Inside that thunk,
;;; the CATCH-INSTRUCTION would be used to mark capture the stack at
;;; that point.  The THROW special operator would search the dynamic
;;; environment for the frame, and use the return address stored in it. 
;;;
;;; The CATCH-INSTRUCTION can also be used to implement lexical
;;; non-local control transfers such as RETURN-FROM and GO.  It would
;;; be used when the successor of an instruction I at some lexical
;;; depth is an instruction J at a lesser lexical depth.  The
;;; procedure at the lesser lexical depth would contain a lexical
;;; location L into which some unique object (say the result of (LIST
;;; NIL)) is placed.  This instruction would then be used with L as an
;;; input.  An UNIWIND-INSTRUCTION would be inserted into the arc from
;;; I to J.  That instruction would use L as an input.  The effect
;;; would be that before J is reached, the stack would be unwound to
;;; the state it had when the CATCH-INSTRUCTION was executed. 

(defclass catch-instruction (instruction)
  ())

(defun make-catch-instruction (input successor)
  (make-instance 'catch-instruction
    :inputs (list input)
    :successors (list successor)))

(defmethod draw-instruction ((instruction catch-instruction) stream)
  (format stream "   ~a [label = \"catch\"];~%"
	  (gethash instruction *instruction-table*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction UNWIND-INSTRUCTION.
;;;
;;; This instruction is used to unwind the stack.  It takes a single
;;; input and it has a single successor.  It has no outputs.
;;;
;;; To implement the Common Lisp THROW special operator, it suffices
;;; have this instruction with the value of the tag as an input and a
;;; RETURN-INSTRUCTION as its single successor. 
;;;
;;; This instruction can also be used together with the
;;; CATCH-INSTRUCTION to implement lexical non-local control transfers
;;; such as RETURN-FROM and GO.  See comment for CATCH-INSTRUCTION for
;;; details.

(defclass unwind-instruction (instruction)
  ())

(defun make-unwind-instruction (input successor)
  (make-instance 'unwind-instruction
    :inputs (list input)
    :successors (list successor)))

(defmethod draw-instruction ((instruction unwind-instruction) stream)
  (format stream "   ~a [label = \"unwind\"];~%"
	  (gethash instruction *instruction-table*)))

