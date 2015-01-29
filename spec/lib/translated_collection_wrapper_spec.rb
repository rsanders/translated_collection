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
    context '.[]' do
      it 'should return xlated element at index' do
        subject[0].should == 'A'
      end
    end

    context '.fetch' do
      it 'should return xlated element on hit' do
        subject.fetch(1).should == 'B'
      end

      it 'should return xlated default element on miss' do
        subject.fetch(99, 'x').should == 'X'
      end
    end

    context '.each' do
      it 'should yield each element in order' do
        res = []
        subject.each {|elt| res << elt}
        res.should == xlated_collection
      end

    end

    context '.map' do
      it 'should yield each element in order, and return all' do
        subject.map {|elt| elt+elt}.should == %w[AA BB CC]
      end
    end

    context '.include?' do

    end


  end

  context 'destructive updates' do

  end

  context 'updating and returning a new collection' do

  end

  context 'copying' do
    it 'should return a new instance of itself on clone'
    it 'should wrap a copy of the collection on clone'
  end

  context 'introspection' do
    it 'should claim to be an instance of proxied collection'
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
