require 'spec_helper'

class Guard::JRubyRSpec::Runner::UI; end

describe Guard::JRubyRSpec::Runner do
  subject { described_class.new }

  describe '#run' do

    before(:each) do
      Guard::JRubyRSpec::Runner::UI.stub(:info)
    end

    it 'keeps the RSpec global configuration between runs' do
      RSpec::Core::Runner.stub(:run)
      orig_configuration = ::RSpec.configuration
      ::RSpec.should_receive(:instance_variable_set).with(:@configuration, orig_configuration)

      subject.run(['spec/foo'])
    end

    context 'when passed an empty paths list' do
      it 'returns false' do
        subject.run([]).should be_false
      end
    end

    context 'when one of the source files is bad' do
      it 'recovers from syntax errors in files by displaying the error' do
        RSpec::Core::Runner.stub(:run).and_raise(SyntaxError.new('Bad Karma'))
        Guard::JRubyRSpec::Runner::UI.should_receive(:error).with('Bad Karma')
        subject.run(['spec/foo'])
      end
    end
  end
end
