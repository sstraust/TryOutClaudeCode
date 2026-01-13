(ns test-maps
  "Test file for cider-format-maps.el

  Use C-x C-e after each expression to see the formatted output.")

;; Simple map
{:a 1 :b 2 :c 3}

;; Map with namespace-qualified keywords
{:deft.deft-test/side1 1, :deft.deft-test/side2 3}

;; Nested map (from the original example)
{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}

;; Deeply nested maps
{:user {:name "Alice" :address {:street "123 Main St" :city "Springfield" :country "USA"}} :active true}

;; Map with vectors
{:coords [1 2 3], :labels ["x" "y" "z"], :metadata {:created "2026-01-04"}}

;; Map with mixed types
{:count 42, :ratio 3.14, :active? true, :name "test", :data nil}

;; Complex nested structure
{:config {:database {:host "localhost" :port 5432 :credentials {:user "admin" :pass "secret"}} :cache {:enabled true :ttl 3600}} :version "1.0.0"}
