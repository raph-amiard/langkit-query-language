with Ada.Unchecked_Deallocation;
with Ada.Containers.Vectors;

generic

   type Element_Type is private;
   --  Type of the values yielded by the iterator

package Iters.Iterators is

   type Element_Array is array (Positive range <>) of Element_Type;
   --  Array type to use when consuming the iterator into an array of elements

   --------------
   -- Iterator --
   --------------

   type Iterator_Interface is interface;
   --  Abstraction for iterating over a sequence of values

   type Iterator_Access is access all Iterator_Interface'Class;

   function Next (Iter   : in out Iterator_Interface;
                  Result : out Element_Type) return Boolean is abstract;
   --  Get the next iteration element. If there was no element to yield
   --  anymore, return false. Otherwise, return true and set Result.

   function Clone
     (Iter : Iterator_Interface) return Iterator_Interface is abstract;
   --  Make a deep copy of the iterator

   procedure Release (Iter : in out Iterator_Interface) is null;
   --  Release ressources that belong to Iter

   function Consume (Iter : Iterator_Interface'Class) return Element_Array;
   --  Consume the iterator and return an array that contains the yielded
   --  elements.
   --  The ressources associated with the iterator will be released.

   procedure Free_Iterator is new Ada.Unchecked_Deallocation
     (Iterator_Interface'Class, Iterator_Access);

   -----------
   -- Funcs --
   -----------

   generic

      type Return_Type (<>) is private;
      --  Function's return type

   package Funcs is

      type Func is interface;
      --  Abstraction representing a function that takes Element_Type values
      --  and returns values of type Return_Type.

      type Func_Access is access all Func'Class;
      --  Pointer to a Func

      function Evaluate (Self    : in out Func;
                         Element : Element_Type)
                         return Return_Type is abstract;
      --  Apply the current Func to Element

      procedure Free_Func is new Ada.Unchecked_Deallocation
        (Func'Class, Func_Access);
      --  Free the memory accessed through a Func_Access pointer

   end Funcs;

   ---------------
   -- Consumers --
   ---------------

   generic

      type Return_Type (<>) is private;
      --  Type of values produced by the iterator's consumption

   package Consumers is

      type Consumer_Interface is interface;

      function Consume (Self : in out Consumer_Interface;
                        Iter : in out Iterator_Interface'Class)
                        return Return_Type is abstract;
      --  Consume and release the iterator

   end Consumers;

   ------------
   -- Filter --
   ------------

   package Predicates is new Funcs (Boolean);
   --  Function that takes an Element_Type argument an retrurns a Boolean

   subtype Predicate_Access is Predicates.Func_Access;
   --  Pointer to a predicate

   type Filter_Iter is new Iterator_Interface with private;
   --  Iterator that wraps an other iterator an filters it's elements using a
   --  Predicate.

   overriding function Next (Iter   : in out Filter_Iter;
                             Result : out Element_Type) return Boolean;

   overriding function Clone (Iter : Filter_Iter) return Filter_Iter;

   overriding procedure Release (Iter : in out Filter_Iter);

   function Filter
     (Iter : Iterator_Access; Pred : Predicate_Access) return Filter_Iter;

   function Filter (Iter : Iterator_Interface'Class;
                    Pred : Predicates.Func'Class)
                    return Filter_Iter;

   ------------
   -- Repeat --
   ------------

   type Resetable_Iter is new Iterator_Interface with private;
   --  Resetable iterator that caches the elements that it yields.

   type Resetable_Access is access all Resetable_Iter;

   overriding function Next (Iter   : in out Resetable_Iter;
                             Result : out Element_Type) return Boolean;

   overriding procedure Release (Iter : in out Resetable_Iter);

   overriding function Clone (Iter : Resetable_Iter) return Resetable_Iter;

   procedure Reset (Iter : in out Resetable_Iter);
   --  Reset the iterator. Further calls to 'Next' will yield the cached
   --  elements.

private

   procedure Free_Predicate_Access is new Ada.Unchecked_Deallocation
     (Predicates.Func'Class, Predicate_Access);

   type Filter_Iter is new Iterator_Interface with record
      Inner     : Iterator_Access;
      Predicate : Predicate_Access;
   end record;

   package Element_Vectors is new Ada.Containers.Vectors
     (Positive, Element_Type);

   type Element_Vector_Access is access all Element_Vectors.Vector;

   procedure Free_Element_Vector is new Ada.Unchecked_Deallocation
     (Element_Vectors.Vector, Element_Vector_Access);

   subtype Cache_Index is Integer range -1 .. Integer'Last;

   type Resetable_Iter is new Iterator_Interface with record
      Inner : Iterator_Access;
      --  Wrapped iterator
      Cache : Element_Vector_Access := new Element_Vectors.Vector;
      --  Cached values
      Cache_Pos : Cache_Index := -1;
      --  Index of the next cache value to read.
      --  -1 if the wrapped iterator hasn't been fully consumed yet
   end record;

end Iters.Iterators;
