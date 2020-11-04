require 'spec_helper'
require 'byebug'

class FindByMethodClass
  include ::ActiveRemote::Cached

  def self.find(**args)
    byebug
  end

  def self.search; nil; end;

  cached_finders_for :foo, :expires_in => 500
  cached_finders_for :guid
  cached_finders_for :guid, :user_guid
  cached_finders_for [:user_guid, :client_guid]
  cached_finders_for [:derp, :user_guid, :client_guid]
end

describe FindByMethodClass do
  describe "API" do
    it "creates 'cached_find_by'" do
      expect(FindByMethodClass).to respond_to(:cached_find_by)
    end

    it "creates 'cached_find_by!'" do
      expect(FindByMethodClass).to respond_to(:cached_find_by!)
    end

    it "creates 'cached_exist_find_by?'" do
      expect(FindByMethodClass).to respond_to(:cached_exist_find_by?)
    end
  end

  describe "#cached_find_by(:attribute => value)" do
    context "guid" do
      it "calls cached_find_by_guid and returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:guid => "foobar")).to eq(1)
      end

      it "calls cached_find_by_guid and nothing found" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([])
        expect(FindByMethodClass.cached_find_by(:guid => "foobar")).to be nil
      end

      it "calls cached_find_by_guid and nothing found does not raise an error" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([])
        expect do
          FindByMethodClass.cached_find_by(:guid => "foobar")
        end.not_to raise_error(::ActiveRemote::RemoteRecordNotFound)
      end
    end

    context "foo" do

    end

    context "user_guid, client_guid" do
      it "calls cached_find_by_guid and returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_user_guid_and_client_guid).with(["foo", "bar"], {}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:user_guid => "foo", :client_guid => "bar")).to eq(1)
      end

      it "calls cached_search_by_user_guid_and_client_guid with options returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_user_guid_and_client_guid).with(["foo", "bar"], {:expires_in => 1}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:user_guid => "foo", :client_guid => "bar", :options => { :expires_in => 1 })).to eq(1)
      end

      it "calls cached_find_by_guid and nothing found" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([])
        expect(FindByMethodClass.cached_find_by(:guid => "foobar")).to be nil
      end

      it "calls cached_find_by_guid and nothing found does not raise an error" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([])
        expect do
          FindByMethodClass.cached_find_by(:guid => "foobar")
        end.not_to raise_error(::ActiveRemote::RemoteRecordNotFound)
      end
    end
  end

  describe "#cached_find_by!(:attribute => value)" do
    context "guid" do
      it "calls cached_find_by_guid! and returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([1])
        expect(FindByMethodClass.cached_find_by!(:guid => "foobar")).to eq(1)
      end

      it "calls cached_find_by_guid! and nothing found to raise an error" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with("foobar", {}).and_return([])
        expect do
          FindByMethodClass.cached_find_by!(:guid => "foobar")
        end.to raise_error(::ActiveRemote::RemoteRecordNotFound)
      end
    end
  end

  # describe "#cached_find_by_guid" do
  #   before do
  #     ::ActiveRemote::Cached.cache(HashCache.new)
  #     ::ActiveRemote::Cached.default_options(:expires_in => 100)
  #   end

  #   after do
  #     ::ActiveRemote::Cached.default_options({})
  #   end

  #   it "executes find_by_guid when cached_find with guid called" do
  #     FindMethodClass.stub(:find, :hello) do
  #       FindMethodClass.cached_find(:guid => :guid).must_equal(:hello)
  #     end
  #   end

  #   it "executes the fetch block if not present in cache" do
  #     FindMethodClass.stub(:find, :hello) do
  #       FindMethodClass.cached_find_by_guid(:guid).must_equal(:hello)
  #     end
  #   end

  #   it "merges the default options in for the fetch call" do
  #     ::ActiveRemote::Cached.cache.expects(:fetch).with([FindMethodClass.name, "#find", "guid"], :expires_in => 100).returns(:hello)

  #     FindMethodClass.stub(:find, :hello) do
  #       FindMethodClass.cached_find_by_guid(:guid).must_equal(:hello)
  #     end
  #   end

  #   it "overrides the default options with local options for the fetch call" do
  #     ::ActiveRemote::Cached.cache.expects(:fetch).with([FindMethodClass.name, "#find", "guid"], :expires_in => 200).returns(:hello)

  #     FindMethodClass.stub(:find, :hello) do
  #       FindMethodClass.cached_find_by_guid(:guid, :expires_in => 200).must_equal(:hello)
  #     end
  #   end

  #   describe "namespaced cache" do
  #     before do
  #       ::ActiveRemote::Cached.default_options(:expires_in => 100, :namespace => "MyApp")
  #     end

  #     it "uses the namespace as a prefix to the cache key" do
  #       ::ActiveRemote::Cached.cache.expects(:fetch).with(["MyApp", FindMethodClass.name, "#find", "guid"], :expires_in => 100).returns(:hello)

  #       FindMethodClass.stub(:find, :hello) do
  #         FindMethodClass.cached_find_by_guid(:guid)
  #       end
  #     end
  #   end
  # end

  # describe "#cached_find_by_foo" do
  #   before do
  #     ::ActiveRemote::Cached.cache(HashCache.new)
  #     ::ActiveRemote::Cached.default_options(:expires_in => 100)
  #   end

  #   after do
  #     ::ActiveRemote::Cached.default_options({})
  #   end

  #   it "overrides the default options with cached_finder options for the fetch call" do
  #     ::ActiveRemote::Cached.cache.expects(:fetch).with([FindMethodClass.name, "#find", "foo"], :expires_in => 500).returns(:hello)

  #     FindMethodClass.stub(:find, :hello) do
  #       FindMethodClass.cached_find_by_foo(:foo).must_equal(:hello)
  #     end
  #   end

  #   it "overrides the cached_finder options with local options for the fetch call" do
  #     ::ActiveRemote::Cached.cache.expects(:fetch).with([FindMethodClass.name, "#find", "foo"], :expires_in => 200).returns(:hello)

  #     FindMethodClass.stub(:find, :hello) do
  #       FindMethodClass.cached_find_by_foo(:foo, :expires_in => 200).must_equal(:hello)
  #     end
  #   end
  # end
end
