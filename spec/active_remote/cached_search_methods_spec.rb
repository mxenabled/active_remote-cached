require 'spec_helper'

class SearchMethodClass
  include ::ActiveRemote::Cached

  def self.derp; nil; end
  def self.find; nil; end
  def self.search; nil; end

  cached_finders_for :foo, :expires_in => 500
  cached_finders_for :guid
  cached_finders_for :guid, :user_guid
  cached_finders_for [:user_guid, :client_guid]
  cached_finders_for [:derp, :user_guid, :client_guid]
end

describe SearchMethodClass do
  describe "API" do
    it "creates 'cached_search_by_foo'" do
      SearchMethodClass.must_respond_to("cached_search_by_foo")
    end

    it "creates 'cached_search_by_foo!'" do
      SearchMethodClass.must_respond_to("cached_search_by_foo!")
    end

    it "creates 'cached_search_by_guid'" do
      SearchMethodClass.must_respond_to("cached_search_by_guid")
    end

    it "creates 'cached_search_by_user_guid'" do
      SearchMethodClass.must_respond_to("cached_search_by_user_guid")
    end

    it "creates 'cached_search_by_client_guid_and_user_guid'" do
      SearchMethodClass.must_respond_to("cached_search_by_client_guid_and_user_guid")
    end

    it "creates 'cached_search_by_client_guid_and_derp_and_user_guid'" do
      SearchMethodClass.must_respond_to("cached_search_by_client_guid_and_derp_and_user_guid")
    end

    it "creates 'cached_search_by_client_guid_and_derp_and_user_guid!'" do
      SearchMethodClass.must_respond_to("cached_search_by_client_guid_and_derp_and_user_guid!")
    end
  end

  describe "#cached_search_by_guid" do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it "executes the search block when a block is passed" do
      SearchMethodClass.stub(:derp, :derp) do
        SearchMethodClass.cached_search(:guid => :guid) do
          SearchMethodClass.derp
        end.must_equal(:derp)
      end
    end

    it "does not persist empty values by default" do
      SearchMethodClass.stub(:derp, []) do
        SearchMethodClass.cached_search(:guid => :guid) do
          SearchMethodClass.derp
        end

        SearchMethodClass.cached_exist_search_by_guid?(:guid).must_equal(false)
      end
    end

    it "persists empty values when allow_empty sent" do
      SearchMethodClass.stub(:derp, []) do
        SearchMethodClass.cached_search({:guid => :guid}, :allow_empty => true) do
          SearchMethodClass.derp
        end

        SearchMethodClass.cached_exist_search_by_guid?(:guid).must_equal(true)
      end
    end

    it "does not persist nil values by default" do
      SearchMethodClass.stub(:derp, nil) do
        SearchMethodClass.cached_search(:guid => :guid) do
          SearchMethodClass.derp
        end

        SearchMethodClass.cached_exist_search_by_guid?(:guid).must_equal(false)
      end
    end

    it "persists nil values when allow_nil sent" do
      SearchMethodClass.stub(:derp, nil) do
        SearchMethodClass.cached_search({:guid => :guid}, :allow_nil => true) do
          SearchMethodClass.derp
        end

        SearchMethodClass.cached_exist_search_by_guid?(:guid).must_equal(true)
      end
    end

    it "does persist non nil values" do
      SearchMethodClass.stub(:derp, :derp) do
        SearchMethodClass.cached_search(:guid => :guid) do
          SearchMethodClass.derp
        end

        SearchMethodClass.cached_exist_search_by_guid?(:guid).must_equal(true)
      end
    end

    it "executes search_by_guid when cached_search with guid called" do
      FindMethodClass.stub(:search, :hello) do
        FindMethodClass.cached_search(:guid => :guid).must_equal(:hello)
      end
    end

    it "executes the fetch block if not present in cache" do
      SearchMethodClass.stub(:search, :hello) do
        SearchMethodClass.cached_search_by_guid(:guid).must_equal(:hello)
      end
    end

    it "merges the default options in for the fetch call" do
      ::ActiveRemote::Cached.cache.expects(:fetch).with([SearchMethodClass.name, "#search", "guid"], :expires_in => 100).returns(:hello)

      SearchMethodClass.stub(:search, :hello) do
        SearchMethodClass.cached_search_by_guid(:guid).must_equal(:hello)
      end
    end

    it "overrides the default options with local options for the fetch call" do
      ::ActiveRemote::Cached.cache.expects(:fetch).with([SearchMethodClass.name, "#search", "guid"], :expires_in => 200).returns(:hello)

      SearchMethodClass.stub(:search, :hello) do
        SearchMethodClass.cached_search_by_guid(:guid, :expires_in => 200).must_equal(:hello)
      end
    end

    describe "namespaced cache" do
      before do
        ::ActiveRemote::Cached.default_options(:expires_in => 100, :namespace => "MyApp")
      end

      it "uses the namespace as a prefix to the cache key" do
        ::ActiveRemote::Cached.cache.expects(:fetch).with(["MyApp", SearchMethodClass.name, "#search", "guid"], :expires_in => 100).returns(:hello)

        SearchMethodClass.stub(:search, :hello) do
          SearchMethodClass.cached_search_by_guid(:guid)
        end
      end
    end
  end

  describe "#cached_search_by_foo" do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it "overrides the default options with cached_finder options for the fetch call" do
      ::ActiveRemote::Cached.cache.expects(:fetch).with([SearchMethodClass.name, "#search", "foo"], :expires_in => 500).returns(:hello)

      SearchMethodClass.stub(:find, :hello) do
        SearchMethodClass.cached_search_by_foo(:foo).must_equal(:hello)
      end
    end

    it "overrides the cached_finder options with local options for the fetch call" do
      ::ActiveRemote::Cached.cache.expects(:fetch).with([SearchMethodClass.name, "#search", "foo"], :expires_in => 200).returns(:hello)

      SearchMethodClass.stub(:find, :hello) do
        SearchMethodClass.cached_search_by_foo(:foo, :expires_in => 200).must_equal(:hello)
      end
    end
  end

  describe "#cached_search_by_foo!" do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it "returns results when present" do
      SearchMethodClass.stub(:search, [:hello]) do
        SearchMethodClass.cached_search_by_foo!(:foo, :expires_in => 200).must_equal([:hello])
      end
    end

    it "raises ActiveRemote::RemoteRecordNotFound when not found" do
      SearchMethodClass.stub(:search, []) do
        -> { SearchMethodClass.cached_search_by_foo!(:foo, :expires_in => 200) }.must_raise ::ActiveRemote::RemoteRecordNotFound
      end
    end
  end
end
