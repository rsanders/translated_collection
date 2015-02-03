require 'spec_helper'
require 'translated_collection/wrapper'

describe TranslatedCollection::Wrapper do
  let :upperfn do
    lambda {|elt| elt.upcase }
  end

  let :lowerfn do
    lambda {|elt| elt.downcase }
  end

  subject { TranslatedCollection::Wrapper.new(collection, lowerfn, upperfn) }

  let :collection do
    %w[a b c]
  end

  let :xlated_collection do
    collection.map {|elt| upperfn.call(elt)}
  end

  context 'creation' do
    let :collection do
      %w[a b C]
    end

    context '#new' do
      it 'should assign the same collection internally' do
        subject.instance_variable_get("@collection").__id__.should == collection.__id__
      end

      it 'should not check conformity by default' do
        expect { subject }.not_to raise_error
      end

      it 'should raise on creation if conformity check requested and failed' do
        expect { TranslatedCollection::Wrapper.new(collection, lowerfn, upperfn, true) }.
            to raise_error(ArgumentError)
      end
    end

    it 'should make the same collection available via #collection' do
      subject.collection.__id__.should == collection.__id__
    end
  end

  context 'validation' do
    context '#_conforming?' do
      it 'should be true for conforming collection' do
        subject._conforming?.should be_true
      end

      it 'should be false for non-conforming collection' do
        TranslatedCollection::Wrapper.new(%w[a B C], lowerfn, upperfn)._conforming?.should be_false
      end
    end

    context '#_make_conforming!' do
      it 'should leave a conforming collection unaltered' do
        oldcoll = subject.collection.dup
        subject._make_conforming!
        subject.collection.should == oldcoll
      end

      it 'should make a non-conforming collection conform' do
        tcw = TranslatedCollection::Wrapper.new(%w[a B C], lowerfn, upperfn)
        tcw._make_conforming!
        tcw.collection.should == %w[a b c]
      end

      it 'should preserve collection type' do
        tcw = TranslatedCollection::Wrapper.new(Set.new(%w[a B C]), lowerfn, upperfn)
        tcw._make_conforming!
        tcw.collection.should == Set.new(%w[a b c])
      end
    end
  end

  context 'reading' do
    context '#[]' do
      it 'should return xlated element at index' do
        subject[0].should == 'A'
      end
    end

    context '#fetch' do
      it 'should return xlated element on hit' do
        subject.fetch(1).should == 'B'
      end

      it 'should return xlated default element on miss' do
        subject.fetch(99, 'x').should == 'X'
      end
    end

    context '#each' do
      it 'should yield each element in order' do
        res = []
        subject.each {|elt| res << elt}
        res.should == xlated_collection
      end

    end

    context '#map' do
      it 'should yield each element in order, and return all' do
        subject.map {|elt| elt+elt}.to_a.should == %w[AA BB CC]
      end
    end

    context '#include?' do
      it 'should indicate that the translated form is present' do
        subject.should include('A')
      end

      it 'should indicate that the un-translated form is NOT present' do
        subject.should_not include('a')
      end
    end


  end

  context 'updating and returning a new collection' do
    context '#reject' do
        let :postreject do
          subject.reject {|x| x.to_i % 2 == 0 }
        end

        it 'should remove elements from new collection' do
          postreject.to_a.should_not == subject.to_a
        end

        it 'should return a new collection' do
          postreject.__id__.should_not == subject.__id__
        end

        it 'should not alter old collection' do
          expect { postreject }.not_to change { subject.to_a }
        end
      end
  end

  context 'destructive updates' do
    context '#clear' do
      it 'should return same class on clear' do
        subject.clear.should be_a(described_class)
      end

      it 'should be empty after clear' do
        expect { subject.clear }.not_to change { subject.__id__ }
      end
    end

    context '#reject!' do
      let :postreject do
        subject.reject! {|x| x.to_i % 2 == 0 }
      end

      it 'should remove elements from original' do
        expect { postreject }.to change { subject.to_a }
      end

      it 'should not return a new collection' do
        postreject.__id__.should == subject.__id__
      end

      it 'should remove the correct elements' do
        postreject.to_a.should == []
      end

      it 'should return nil if no changes were made' do
        subject.reject! {|x| x == Object.new }.should be_nil
      end
    end
  end

  context 'Enumerable' do
    let :collection do
      %w[a b c d e f g h i j k l]
    end

    context 'methods with optional block' do
      context '#drop_while' do
        it 'should invoke condition block on translated-out values' do
          subject.drop_while {|x| x < 'C'}.to_a.should == %w[C D E F G H I J K L]
        end
      end

      context '#map' do
        it 'should invoke map block on translated-out values' do
          subject.map {|x| x * 3}.to_a.should == %w[AAA BBB CCC DDD EEE FFF GGG HHH III JJJ KKK LLL]
        end
      end

      context '#collect' do
        it 'should invoke collect block on translated-out values' do
          subject.collect {|x| x * 3}.to_a.should == %w[AAA BBB CCC DDD EEE FFF GGG HHH III JJJ KKK LLL]
        end
      end

      context '#find_all' do
        it 'should invoke condition block on translated-out values' do
          subject.find_all {|x| x.to_i % 2 == 0 }.to_a.should == %w[A B C D E F G H I J K L]
        end
      end

      context '#sort_by' do
        it 'should sort elements by comparison on translated-out elements'
      end

      context '#take_while' do
        it 'should evaluate condition on translated-out elements'
      end
    end
  end


  context 'copying' do
    context '#clone' do
      it 'should return a new instance of itself'do
        subject.clone.__id__.should_not == subject.__id__
      end

      it 'should wrap a copy of the collection' do
        coll_id = subject.collection.__id__
        subject.clone.collection.__id__.should_not == coll_id
      end

      it 'should keep the translated-in versions of elements in the copy' do
        subject.clone.collection.should == subject.collection
      end

      it 'should preserve frozen status' do
        subject.freeze
        copy = subject.clone

        copy.should be_frozen
        copy.collection.should be_frozen
      end
    end


    context '#dup' do
      it 'should return a new instance of itself'do
        subject.dup.__id__.should_not == subject.__id__
      end

      it 'should wrap a copy of the collection' do
        coll_id = subject.collection.__id__
        subject.dup.collection.__id__.should_not == coll_id
      end

      it 'should keep the translated-in versions of elements in the copy' do
        subject.dup.collection.should == subject.collection
      end

      it 'should not preserve frozen status' do
        subject.freeze
        copy = subject.dup

        copy.should_not be_frozen
        copy.collection.should_not be_frozen
      end
    end
  end

  context 'introspection' do
    it 'should claim to be an instance of proxied collection if Array' do
      subject.should be_a_kind_of(Array)
      subject.should_not be_a_kind_of(Set)
    end

    it 'should claim to be an instance of proxied collection if Set' do
      wrapped = TranslatedCollection::Wrapper.new(Set.new(%w[a b c]), lowerfn, upperfn)
      wrapped.should be_a_kind_of(Set)
      wrapped.should_not be_a_kind_of(Array)
    end
  end

  context 'observation' do
    context '#[]=' do

    end

    context '#clear' do

    end

    context '#delete' do

    end

    context '#delete_at' do

    end

    context '#<<' do

    end

    context '#push' do

    end

    context '#pop' do

    end


  end

end
