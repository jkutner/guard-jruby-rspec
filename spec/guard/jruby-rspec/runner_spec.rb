require 'spec_helper'

describe Guard::JRubyRSpec::Runner do
  subject { described_class.new }

  describe '#run' do
    context 'when passed an empty paths list' do
      it 'returns false' do
        subject.run([]).should be_false
      end
    end
  end
end
