require "spec_helper"


RSpec::Matchers.define :have_type do |type|
  match do |actual|
    type.check(actual).success?
  end
end


RSpec.describe Contracts do
  include Contracts::TypeMixin
  
  it "has a version number" do
    expect(Contracts::VERSION).not_to be nil
  end

  describe 5 do
    it { is_expected.to have_type integer }
    it { is_expected.to have_type integer(minimum: 0) }
    it { is_expected.to have_type integer(minimum: 5) }
    it { is_expected.to have_type integer(minimum: 0, maximum: 10) }
    it { is_expected.to have_type is(:odd?) }
    it { is_expected.to have_type one_of(1, 2, 3, 4, 5) }
    
    it { is_expected.not_to have_type one_of(1, 2, 3, 4) }
    it { is_expected.not_to have_type integer(minimum: 6) }
    it { is_expected.not_to have_type integer(maximum: 4) }
  end

  describe 1.2 do
    it { is_expected.not_to have_type integer }
    it { is_expected.to have_type numeric }
    it { is_expected.not_to have_type string }
  end

  describe "abc" do
    subject { 'abc' }

    it { is_expected.to have_type string }
    it { is_expected.to have_type any }
    it { is_expected.to have_type is_not(:empty?) }
    it { is_expected.to have_type has(:size) }
    it { is_expected.to have_type value('abc') }

    it { is_expected.not_to have_type void }
    it { is_expected.not_to have_type integer }
    it { is_expected.not_to have_type array(string) }
end

  describe [1, 2, 3] do
    it { is_expected.not_to have_type integer }
    it { is_expected.to have_type array(integer) }
    it { is_expected.to have_type array(one_of(1, 2, 3)) }
    
    it { is_expected.not_to have_type array(string) }
    it { is_expected.not_to have_type array(one_of('1', '2', '3')) }
  end
end
