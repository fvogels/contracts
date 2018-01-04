require "spec_helper"

RSpec.describe Contracts do
  it "has a version number" do
    expect(Contracts::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
