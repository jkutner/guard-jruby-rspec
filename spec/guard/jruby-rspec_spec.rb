require 'spec_helper'

describe Guard::JRubyRSpec do
  let(:default_options) do
    {
      :focus_on_failed=>false, :all_after_pass=>true, :all_on_start=>true, 
      :keep_failed=>true, :spec_paths=>["spec"], :run_all=>{}, :spec_file_suffix=>"_spec.rb", 
      :monitor_file=>".guard-jruby-rspec"
    }
  end

  let(:custom_watchers) do 
    [Guard::Watcher.new(%r{^spec/(.+)$}, lambda { |m| "spec/#{m[1]}_match"})]
  end

  subject { described_class.new custom_watchers, default_options}

  let(:inspector) { mock(described_class::Inspector, :excluded= => nil, :spec_paths= => ['spec'], :clean => []) }
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
      inspector.should_receive(:spec_paths).with(no_args)
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

  describe '#reload_paths' do

    it 'should reload files other than spec files' do
      lib_file = 'lib/myapp/greeter.rb'
      spec_file = 'specs/myapp/greeter_spec.rb'
      File.stub(:exists?).and_return(true)
      subject.stub(:load)
      subject.should_receive(:load).with(lib_file)
      subject.should_not_receive(:load).with(spec_file)

      subject.reload_paths([lib_file, spec_file])
    end

    it 'should use @options to alter spec file suffix' do
      subject = described_class.new([], :spec_file_suffix => '_test.rb')
      test_file = 'specs/myapp/greeter_test.rb'
      File.stub(:exists?).and_return(true)
      subject.stub(:load)
      subject.should_not_receive(:load).with(test_file)

      subject.reload_paths([test_file])
    end

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

      inspector.should_receive(:clean).with(['spec/bar_match']).and_return(['spec/bar_match'])
      runner.should_receive(:run).with(['spec/bar_match']) { false }

      expect { subject.run_on_change(['spec/bar']) }.to throw_symbol :task_has_failed

      inspector.should_receive(:clean).with(['spec/foo_match', 'spec/bar_match']).and_return(['spec/foo_match', 'spec/bar_match'])
      runner.should_receive(:run).with(['spec/foo_match', 'spec/bar_match']) { true }

      subject.run_on_change(['spec/foo'])

      inspector.should_receive(:clean).with(['spec/foo_match']).and_return(['spec/foo_match'])
      runner.should_receive(:run).with(['spec/foo_match']) { true }

      subject.run_on_change(['spec/foo'])
    end

    it "throws task_has_failed if specs doesn't pass" do
      runner.should_receive(:run).with(['spec/foo_match']) { false }

      expect { subject.run_on_change(['spec/foo']) }.to throw_symbol :task_has_failed
    end

    it "works with watchers that don't have an action" do
      subject = described_class.new([Guard::Watcher.new(%r{^spec/(.+)$})])

      inspector.should_receive(:clean).with(anything).and_return(['spec/quack_spec'])
      runner.should_receive(:run).with(['spec/quack_spec']) { true }

      subject.run_on_change(['spec/quack_spec']) 
    end

    it "works with watchers that do have an action" do
      watcher_with_action = mock(Guard::Watcher, :match => :matches, :action => true)
      watcher_with_action.should_receive(:call_action).with(:matches).and_return('spec/foo_match')

      subject = described_class.new([watcher_with_action])

      inspector.should_receive(:clean).with(['spec/foo_match']).and_return(['spec/foo_match'])
      runner.should_receive(:run).with(['spec/foo_match']) { true }

      subject.run_on_change(['spec/foo'])
    end
  end
end

