require 'spec_helper'

describe Guard::JRubyRSpec do
  # let(:default_options) do
  #   {
  #     :all_after_pass => true, :all_on_start => true, :keep_failed => true,
  #     :spec_paths => ['spec'], :run_all => {}
  #   }
  # end
  subject { described_class.new }

  let(:runner)    { mock(described_class::Runner, :set_rspec_version => nil, :rspec_version => nil) }

  before do
    described_class::Runner.stub(:new => runner)
  end

  describe '.initialize' do
    it 'creates a runner' do
      described_class::Runner.should_receive(:new).with(anything)

      described_class.new
    end
  end

  describe '#start' do
    it 'calls #run_all' do
      subject.should_receive(:run_all)
      subject.start
    end
  end

  describe '#run_all' do
    it "runs all specs specified by the default 'spec_paths' option" do
      runner.should_receive(:run).with(['spec']) { true }

      subject.run_all
    end

  end

  describe '#run_on_change' do

    it 'runs rspec with paths' do
      # TODO it should not reload because the file doesn't exist

      subject.run_on_change(['spec/foo'])
    end

  end

end

