require 'spec_helper'

describe Reloaders do
  subject(:reloaders) { described_class.new }

  describe 'storing blocks to be executed at reload time' do
    it 'passes the paths to be reloaded to the reloaders' do
      reloaders.register do |paths|
        paths.should == ['/path/to/file']
      end
      reloaders.reload ['/path/to/file']
    end

    describe 'the order in which reloaders are executed' do
      before :each do
        @a = @b = @counter = 0
        reloaders.register do
          @counter += 1
          @a = @counter
        end
        reloaders.register(:prepend => prepend) do
          @counter += 1
          @b = @counter
        end
        reloaders.reload
      end

      context 'in normal order' do
        let(:prepend) { false }
        it 'reloads in the same order as reloaders registered' do
          @a.should == 1
          @b.should == 2
        end
      end

      context 'with the 2nd reloader prepended' do
        let(:prepend) { true }
        it 'reloads in the same order as reloaders registered' do
          @a.should == 2
          @b.should == 1
        end
      end
    end
  end
end
