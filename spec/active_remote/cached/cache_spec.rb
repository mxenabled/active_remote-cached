require 'spec_helper'

describe ::ActiveRemote::Cached::Cache do
  describe "API" do
    it "validates #delete present" do
      cache = OpenStruct.new(:write => nil, :fetch => nil, :read => nil, :exist? => nil)
      error = _(lambda { ::ActiveRemote::Cached.cache(cache) }).must_raise(RuntimeError)
      _(error.message).must_match(/respond_to.*delete/i)
    end

    it "validates #exist? present" do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :fetch => nil)
      error = _(lambda { ::ActiveRemote::Cached.cache(cache) }).must_raise(RuntimeError)
      _(error.message).must_match(/respond_to.*exist/i)
    end

    it "validates #fetch present" do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :exist? => nil)
      error = _(lambda { ::ActiveRemote::Cached.cache(cache) }).must_raise(RuntimeError)
      _(error.message).must_match(/respond_to.*fetch/i)
    end

    it "validates #read present" do
      cache = OpenStruct.new(:write => nil, :delete => nil, :fetch => nil, :exist? => nil)
      error = _(lambda { ::ActiveRemote::Cached.cache(cache) }).must_raise(RuntimeError)
      _(error.message).must_match(/respond_to.*read/i)
    end

    it "validates #write present" do
      cache = OpenStruct.new(:read => nil, :delete => nil, :fetch => nil, :exist? => nil)
      error = _(lambda { ::ActiveRemote::Cached.cache(cache) }).must_raise(RuntimeError)
      _(error.message).must_match(/respond_to.*write/i)
    end
  end

  describe "#delete" do
    it "returns nil when cache delete attempt raises an error" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:delete).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(ar_cache.delete("some_key")).must_be_nil
    end

    it "calls error proc" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:delete).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:call)
      ar_cache.delete("some_key")
    end

    describe "when handle_cache_error is false" do
      it "raises error" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:delete).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        _ { ar_cache.delete("some_key") }.must_raise(::RuntimeError, "kaBOOM")
      end

      it "doesn't invoke error proc" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:delete).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:log).never
        _ { ar_cache.delete("some_key") }.must_raise(::RuntimeError, "kaBOOM")
      end
    end
  end

  describe "#exist?" do
    it "returns false when cache exist? attempt check raises an error" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:exist?).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(ar_cache.exist?("some_key")).must_equal(false)
    end

    it "calls error proc" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:exist?).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:call)
      ar_cache.exist?("some_key")
    end

    describe "when handle_cache_error is false" do
      it "raises error" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:exist?).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        _ { ar_cache.exist?("some_key") }.must_raise(::RuntimeError, "kaBOOM")
      end

      it "doesn't invoke error proc" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:exist?).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:log).never
        _ { ar_cache.exist?("some_key") }.must_raise(::RuntimeError, "kaBOOM")
      end
    end
  end

  describe "#fetch" do
    it "returns cached value when read finds something" do
      cache = HashCache.new
      cache.write("some_key", "tada!")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(ar_cache.fetch("some_key")).must_equal("tada!")
    end

    it "invokes block when read returns nothing" do
      cache = HashCache.new
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(ar_cache.fetch("some_key") { "tada!" }).must_equal("tada!")
    end

    it "removes cache key when returned value is invalid" do
      cache = HashCache.new
      cache.write("some_key", [])
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(cache.exist?("some_key")).must_equal(true)
      ar_cache.fetch("some_key")
      _(cache.exist?("some_key")).must_equal(false)
    end
  end

  describe "#read" do
    it "returns nil when cache read attempt raises an error" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:read).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(ar_cache.read("some_key")).must_be_nil
    end

    it "calls error proc" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:read).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:call)
      ar_cache.read("some_key")
    end

    describe "when handle_cache_error is false" do
      it "raises error" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:read).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        _ { ar_cache.read("some_key") }.must_raise(::RuntimeError, "kaBOOM")
      end

      it "doesn't invoke error proc" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:read).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:log).never
        _ { ar_cache.read("some_key") }.must_raise(::RuntimeError, "kaBOOM")
      end
    end
  end

  describe "#write" do
    it "returns nil when cache write attempt raises an error" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:write).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      _(ar_cache.write("some_key", "some_value")).must_be_nil
    end

    it "calls error proc" do
      ::ActiveRemote::Cached.default_options(:handle_cache_error => true, :cache_error_proc => lambda { |_| } )
      cache = HashCache.new
      cache.expects(:write).raises(::RuntimeError, "kaBOOM")
      ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
      ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:call)
      ar_cache.write("some_key", "some_value")
    end

    describe "when handle_cache_error is false" do
      it "raises error" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:write).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        _ { ar_cache.write("some_key", "some_value") }.must_raise(::RuntimeError, "kaBOOM")
      end

      it "doesn't invoke error proc" do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false, :cache_error_proc => lambda { |_| } )
        cache = HashCache.new
        cache.expects(:write).raises(::RuntimeError, "kaBOOM")
        ar_cache = ::ActiveRemote::Cached::Cache.new(cache)
        ::ActiveRemote::Cached.default_options[:cache_error_proc].expects(:log).never
        _ { ar_cache.write("some_key", "some_value") }.must_raise(::RuntimeError, "kaBOOM")
      end
    end
  end
end
