require 'observer'

module TranslatedCollection
  class Wrapper
    include Enumerable
    include Observable

    attr_reader :collection

    def initialize(collection, wrapfunc_in, wrapfunc_out, check = false)
      @collection   = collection
      @wrapfunc_in  = wrapfunc_in
      @wrapfunc_out = wrapfunc_out

      raise ArgumentError, "Non-conforming array provided" if
          check && !collection.empty? && !_conforming?
    end

    def each
      @collection.each do |elt|
        yield @wrapfunc_out.call(elt)
      end
    end

    def [](key)
      @wrapfunc_out.call(@collection[key])
    end

    SENTINEL = Object.new

    def fetch(*args, &blk)
      @wrapfunc_out.call(@collection.__send__(:fetch, *args, &blk))
    end

    def []=(key, value)
      @collection[key] = @wrapfunc_in.call(value).tap do |xlated|
        changed
        notify_observers(self, :set, key, xlated)
      end
    end

    def <<(value)
      @collection <<  @wrapfunc_in.call(value).tap do |xlated|
        changed
        notify_observers(self, :push, xlated)
      end
    end

    alias :push :<<

    def pop(count=nil)
      if @collection.count > 0
        if count == nil
          value = @wrapfunc_out.call(@collection.pop)
        else
          value = @collection.pop(count).map(&@wrapfunc_out)
        end
        changed
        notify_observers(self, :pop)
      else
        value = nil
      end

      value
    end

    def delete(elt)
      @collection.delete(@wrapfunc_in.call(elt)).tap do |removed|
        if removed
          changed
          notify_observers(self, :delete, removed)
        end
      end
    end

    def delete_at(pos)
      @collection.delete_at(pos).tap do |removed|
        if removed
          changed
          notify_observers(self, :delete, removed) if removed
        end
      end
    end

    def clear
      @collection.clear.tap do
        changed
        notify_observers(self, :clear)
      end
      self
    end

    def self.copy_clone_states(from,to)
      to.taint  if from.tainted? && ! to.tainted?
      to.freeze if from.frozen?  && ! to.frozen?
      to
    end

    def clone
      dup.tap do |newobj|
        newobj.instance_variable_set("@collection", self.class.copy_clone_states(@collection, @collection.dup))
        self.class.copy_clone_states(self, newobj)
      end
    end

    def dup
      super.tap do |newobj|
        newobj.instance_variable_set("@collection", @collection.dup)
      end
    end

    def freeze
      @collection.freeze
      super
    end

    #
    # Are all the elements of this collection unchanged when the "in" wrapper is
    # applied to them?
    #
    def _conforming?
      @collection.each do |elt|
        return false if @wrapfunc_in.call(elt) != elt
      end
      true
    end

    def _make_conforming!
      return if _conforming?

      xlated = @collection.map {|elt| @wrapfunc_in.call(elt) }
      @collection.clear
      xlated.each {|elt| @collection << elt }
      changed
      notify_observers(self, :misc)
      self
    end

    def is_a?(clazz)
      super(clazz) || @collection.is_a?(clazz)
    end

    alias :kind_of? :is_a?

    #
    # Used to wrap results from various Enumerable methods that are defined
    # to return an array
    #
    def _rewrap_array(result)
      newcoll = @collection.class.new(result)
      self.class.new(newcoll, @wrapfunc_in, @wrapfunc_out)
    end

    def _wrap_enumerator(enumerator)
      Enumerator.new do |y|
        loop do
          changed
          notify_observers(self, :misc)
          y << @wrapfunc_out.call(enumerator.next)
        end
      end
    end

    # methods that take a block and return an array, or return an enumerator
    %w[collect collect_concat drop_while find_all
       flat_map map select sort_by take_while].each do |meth|
      define_method(meth) do |*args, &blk|
        if blk
          blk2 = Proc.new {|elt| blk.call(@wrapfunc_out.call(elt)) }
          _rewrap_array(@collection.__send__(meth, *args, &blk2))
        else
          _wrap_enumerator(@collection.__send__(meth, *args))
        end
      end
    end

    def reject!(&blk)
      if blk
        @collection.reject! {|x| blk.call(@wrapfunc_out.call(x)) } && self
      else
        _wrap_enumerator(@collection.reject!)
      end
    end
  end
end
