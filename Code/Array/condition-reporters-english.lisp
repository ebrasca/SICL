(cl:in-package #:sicl-array)

(defmethod acclimation:report-condition
    ((condition object-must-be-an-array)
     stream
     (language acclimation:english))
  (format stream
          "An object of type ~s was expected,~@
           but the following object was found instead~@
           ~s"
          (type-error-expected-type condition)
          (type-error-datum condition)))

(defmethod acclimation:report-condition
  ((condition number-of-indices-must-equal-array-rank)
   stream
     (language acclimation:english))
  (format stream
          "The following indices:~@
           ~s~@
           were given in order to access the array:~@
           ~s~.@
           However, the number of indices given is ~d~@
           whereas the randk of the array is ~d."
          (indices condition)
          (given-array condition)
          (length (indices condition))
          (array-rank (given-array condition))))

(defmethod acclimation:report-condition
    ((condition index-must-be-non-negative-and-less-than-dimension)
     stream
     (language acclimation:english))
  (format stream
          "The ~:R index given in order to access the array:~@
           ~s~@
           has a value of ~s~@
           but the ~:R dimension of the array is ~d,~@
           so the index must be a non-negative integer~@
           that is strictly less than that dimension."
          (1+ (index-number condition))
          (given-array condition)
          (1+ (index-number condition))
          (array-dimension (given-array condition) (index-number condition))))
