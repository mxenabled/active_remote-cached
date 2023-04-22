require 'spec_helper'

class ExistMethodClass
  include ::ActiveRemote::Cached

  def self.find; nil; end
  def self.search; nil; end

  cached_finders_for :guid
  cached_finders_for :guid, :user_guid
  cached_finders_for [:user_guid, :client_guid]
  cached_finders_for [:derp, :user_guid, :client_guid]
end

describe ExistMethodClass do
  describe "API" do
    it "creates 'cached_exist_find_by_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_guid")
    end

    it "creates 'cached_exist_search_by_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_guid")
    end

    it "creates 'cached_exist_find_by_user_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_user_guid")
    end

    it "creates 'cached_exist_search_by_user_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_user_guid")
    end

    it "creates 'cached_exist_find_by_user_guid_and_client_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_user_guid_and_client_guid")
    end

    it "creates 'cached_exist_search_by_user_guid_and_client_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_user_guid_and_client_guid")
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_client_guid_and_user_guid")
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_client_guid_and_user_guid")
    end

    it "creates 'cached_exist_find_by_derp_and_user_guid_and_client_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_derp_and_user_guid_and_client_guid")
    end

    it "creates 'cached_exist_search_by_derp_and_user_guid_and_client_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_derp_and_user_guid_and_client_guid")
    end

    it "creates 'cached_exist_find_by_client_guid_and_derp_and_user_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_client_guid_and_derp_and_user_guid")
    end

    it "creates 'cached_exist_search_by_client_guid_and_derp_and_user_guid'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_client_guid_and_derp_and_user_guid")
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid_and_derp'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_client_guid_and_user_guid_and_derp")
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid_and_derp'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_client_guid_and_user_guid_and_derp")
    end

    # ? based methods
    it "creates 'cached_exist_find_by_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_guid?")
    end

    it "creates 'cached_exist_search_by_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_guid?")
    end

    it "creates 'cached_exist_find_by_user_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_user_guid?")
    end

    it "creates 'cached_exist_search_by_user_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_user_guid?")
    end

    it "creates 'cached_exist_find_by_user_guid_and_client_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_user_guid_and_client_guid?")
    end

    it "creates 'cached_exist_search_by_user_guid_and_client_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_user_guid_and_client_guid?")
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_client_guid_and_user_guid?")
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_client_guid_and_user_guid?")
    end

    it "creates 'cached_exist_find_by_derp_and_user_guid_and_client_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_derp_and_user_guid_and_client_guid?")
    end

    it "creates 'cached_exist_search_by_derp_and_user_guid_and_client_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_derp_and_user_guid_and_client_guid?")
    end

    it "creates 'cached_exist_find_by_client_guid_and_derp_and_user_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_client_guid_and_derp_and_user_guid?")
    end

    it "creates 'cached_exist_search_by_client_guid_and_derp_and_user_guid?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_client_guid_and_derp_and_user_guid?")
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid_and_derp?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_find_by_client_guid_and_user_guid_and_derp?")
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid_and_derp?'" do
      _(ExistMethodClass).must_respond_to("cached_exist_search_by_client_guid_and_user_guid_and_derp?")
    end

    describe "when cache raises upstream failure redis error" do
      it "returns false" do
        ::ActiveRemote::Cached.cache.expects(:exist?).raises(::RuntimeError, "upstream failure")
        _(ExistMethodClass.cached_exist_search_by_guid?(:guid)).must_equal(false)
      end
    end

    describe "when cache raises any other kind of error" do
      it "allows error to pass through" do
        ::ActiveRemote::Cached.cache.expects(:exist?).raises(::RuntimeError, "kaBOOM")
        assert_raises(::RuntimeError, "kaBOOM") { ExistMethodClass.cached_exist_search_by_guid?(:guid) }
      end
    end
  end
end
