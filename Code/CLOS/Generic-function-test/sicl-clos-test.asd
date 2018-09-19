(cl:in-package #:asdf-user)

(defsystem :sicl-clos-test
  :depends-on (#:closer-mop
               #:cleavir-code-utilities
               #:cleavir-environment
               #:concrete-syntax-tree)
  :serial t
  :components
  ((:file "package")
   (:file "import-from-host")
   (:file "../generic-function-defclass")
   (:file "../standard-generic-function-defclass")
   (:file "../variant-signature-defgeneric")

   (:file "../../Environment/packages")
   (:file "../../Environment/conditions")
   (:file "../../Environment/condition-reporters-english")
   (:file "../../Environment/generic-functions")
   (:file "../../Environment/info-methods")
   ;; (:file "../../Environment/typep-methods")
   (:file "../../Environment/other-methods")
   (:file "../../Environment/other-functions")

   (:file "../../Method-combination/packages")
   (:file "../../Method-combination/method-combination-template-defclass")
   (:file "../../Method-combination/lambda-list-variables")
   (:file "../../Method-combination/method-group-specifier")
   (:file "../../Method-combination/method-discriminator")
   (:file "../../Method-combination/long-form-expansion")
   (:file "../../Method-combination/short-form-expansion")
   (:file "../../Method-combination/define-method-combination-support")
   (:file "../../Method-combination/find-method-combination")
   (:file "../compute-effective-method-support-c")
   (:file "../compute-effective-method-defgenerics")
   (:file "../compute-effective-method-defmethods-b")
   (:file "../discriminating-automaton")
   (:file "../discriminating-tagbody")
   (:file "../list-utilities")
   (:file "../compute-applicable-methods-support")
   (:file "../compute-applicable-methods-defgenerics")
   (:file "../compute-applicable-methods-defmethods")
   (:file "../compute-discriminating-function-defgenerics")
   (:file "compute-discriminating-function-support")
   (:file "../compute-discriminating-function-defmethods")
   (:file "../compute-discriminating-function-support-c")
   (:file "../generic-function-initialization-support")
   (:file "../generic-function-initialization-defmethods")
   (:file "../method-combination-defclass")))

