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
        notify_observers(:set, key, xlated)
      end
    end

    def <<(value)
      @collection <<  @wrapfunc_in.call(value).tap do |xlated|
        changed
        notify_observers(:push, xlated)
      end
    end

    alias :push :<<

    def delete(elt)
      @collection.delete(@wrapfunc_in.call(elt)).tap do |removed|
        if removed
          changed
          notify_observers(:delete, removed)
        end
      end
    end

    def delete_at(pos)
      @collection.delete_at(pos).tap do |removed|
        if removed
          changed
          notify_observers(:delete, removed) if removed
        end
      end
    end

    def clear
      @collection.clear.tap do
        changed
        notify_observers(:clear)
      end
    end

    def clone
      self.clone.tap do |newobj|
        newobj.instance_variable_set("@collection", @collection.clone)
      end
    end

    def dup
      self.dup.tap do |newobj|
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
    end
  end
end
