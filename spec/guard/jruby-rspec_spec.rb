require 'spec_helper'

describe Guard::JRubyRSpec do
  let(:default_options) do
    {
      :all_after_pass => true, :all_on_start => true, :keep_failed => true,
      :spec_paths => ['spec'], :run_all => {}, :monitor_file=>".guard-jruby-rspec"
    }
  end

  let(:custom_watchers) do 
    [Guard::Watcher.new(%r{^spec/(.+)$}) { |m| "spec/#{m[1]}_match"}]
  end

  subject { described_class.new custom_watchers, default_options}

  let(:inspector) { mock(described_class::Inspector, :excluded= => nil, :spec_paths= => nil, :clean => []) }
  let(:runner)    { mock(described_class::Runner, :set_rspec_version => nil, :rspec_version => nil) }

  before do
    described_class::Runner.stub(:new => runner)
    described_class::Inspector.stub(:new => inspector)
  end

  shared_examples_for 'clear failed paths' do
    it 'should clear the previously failed paths' do
      inspector.stub(:clean).and_return(['spec/foo_match'], ['spec/bar_match'])

      runner.should_receive(:run).with(['spec/foo_match']) { false }
      expect { subject.run_on_change(['spec/foo']) }.to throw_symbol :task_has_failed

      runner.should_receive(:run) { true }
      expect { subject.run_all }.to_not throw_symbol # this actually clears the failed paths

      runner.should_receive(:run).with(['spec/bar_match']) { true }
      subject.run_on_change(['spec/bar'])
    end
  end

  describe '.initialize' do
    it 'creates an inspector' do
      described_class::Inspector.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end

    it 'creates a runner' do
      described_class::Runner.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end
  end

  describe '#start' do
    it 'calls #run_all' do
      subject.should_receive(:run_all)
      subject.start
    end

    context ':all_on_start option is false' do
      let(:subject) { subject = described_class.new([], :all_on_start => false) }

      it "doesn't call #run_all" do
        subject.should_not_receive(:run_all)
        subject.start
      end
    end
  end

  describe '#run_all' do
    it "runs all specs specified by the default 'spec_paths' option" do
      runner.should_receive(:run).with(['spec'], anything) { true }

      subject.run_all
    end

    it "should run all specs specified by the 'spec_paths' option" do
      subject = described_class.new([], :spec_paths => ['spec', 'spec/fixtures/other_spec_path'])
      runner.should_receive(:run).with(['spec', 'spec/fixtures/other_spec_path'], anything) { true }

      subject.run_all
    end

    it 'passes the :run_all options' do
      subject = described_class.new([], {
        :rvm => ['1.8.7', '1.9.2'], :cli => '--color', :run_all => { :cli => '--format progress' }
      })
      runner.should_receive(:run).with(['spec'], hash_including(:cli => '--format progress')) { true }

      subject.run_all
    end

    it 'passes the message to the runner' do
      runner.should_receive(:run).with(['spec'], hash_including(:message => 'Running all specs')) { true }

      subject.run_all
    end

    it "throws task_has_failed if specs don't passed" do
      runner.should_receive(:run) { false }

      expect { subject.run_all }.to throw_symbol :task_has_failed
    end

    it_should_behave_like 'clear failed paths'
  end

  describe '#run_on_change' do
    before { inspector.stub(:clean => ['spec/foo_match']) }

    it 'runs rspec with paths' do
      runner.should_receive(:run).with(['spec/foo_match']) { true }

      subject.run_on_change(['spec/foo'])
    end

    context 'the changed specs pass after failing' do
      it 'calls #run_all' do
        runner.should_receive(:run).with(['spec/foo_match']) { false }

        expect { subject.run_on_change(['spec/foo']) }.to throw_symbol :task_has_failed

        runner.should_receive(:run).with(['spec/foo_match']) { true }
        subject.should_receive(:run_all)

        expect { subject.run_on_change(['spec/foo']) }.to_not throw_symbol
      end

      context ':all_after_pass option is false' do
        subject { described_class.new(custom_watchers, :all_after_pass => false) }

        it "doesn't call #run_all" do
          runner.should_receive(:run).with(['spec/foo_match']) { false }

          expect { subject.run_on_change(['spec/foo']) }.to throw_symbol :task_has_failed

          runner.should_receive(:run).with(['spec/foo_match']) { true }
          subject.should_not_receive(:run_all)

          expect { subject.run_on_change(['spec/foo']) }.to_not throw_symbol
        end
      end
    end

    context 'the changed specs pass without failing' do
      it "doesn't call #run_all" do
        runner.should_receive(:run).with(['spec/foo_match']) { true }

        subject.should_not_receive(:run_all)

        subject.run_on_change(['spec/foo'])
      end
    end

    it 'keeps failed spec and rerun them later' do
      subject = described_class.new(custom_watchers, :all_after_pass => false)

      # TODO passing 'anything' to inspector means we aren't really testing the
      # customer watcher logic

      inspector.should_receive(:clean).with(anything).and_return(['spec/bar_match'])
      runner.should_receive(:run).with(['spec/bar_match']) { false }

      expect { subject.run_on_change(['spec/bar']) }.to throw_symbol :task_has_failed

      inspector.should_receive(:clean).with(anything).and_return(['spec/foo_match', 'spec/bar_match'])
      runner.should_receive(:run).with(['spec/foo_match', 'spec/bar_match']) { true }

      subject.run_on_change(['spec/foo'])

      inspector.should_receive(:clean).with(anything).and_return(['spec/foo_match'])
      runner.should_receive(:run).with(['spec/foo_match']) { true }

      subject.run_on_change(['spec/foo'])
    end

    it "throws task_has_failed if specs doesn't pass" do
      runner.should_receive(:run).with(['spec/foo_match']) { false }

      expect { subject.run_on_change(['spec/foo']) }.to throw_symbol :task_has_failed
    end
  end
end

