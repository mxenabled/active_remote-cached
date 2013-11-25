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
    it "creates 'cached_exist_by_guid'" do
      ExistMethodClass.must_respond_to("cached_exist_by_guid")
    end

    it "creates 'cached_exist_by_user_guid'" do
      ExistMethodClass.must_respond_to("cached_exist_by_user_guid")
    end

    it "creates 'cached_exist_by_user_guid_and_client_guid'" do
      ExistMethodClass.must_respond_to("cached_exist_by_user_guid_and_client_guid")
    end

    it "creates 'cached_exist_by_client_guid_and_user_guid'" do
      ExistMethodClass.must_respond_to("cached_exist_by_client_guid_and_user_guid")
    end

    it "creates 'cached_exist_by_derp_and_user_guid_and_client_guid'" do
      ExistMethodClass.must_respond_to("cached_exist_by_derp_and_user_guid_and_client_guid")
    end

    it "creates 'cached_exist_by_client_guid_and_derp_and_user_guid'" do
      ExistMethodClass.must_respond_to("cached_exist_by_client_guid_and_derp_and_user_guid")
    end

    it "creates 'cached_exist_by_client_guid_and_user_guid_and_derp'" do
      ExistMethodClass.must_respond_to("cached_exist_by_client_guid_and_user_guid_and_derp")
    end

    it "creates 'cached_exist_by_guid?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_guid?")
    end

    it "creates 'cached_exist_by_user_guid?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_user_guid?")
    end

    it "creates 'cached_exist_by_user_guid_and_client_guid?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_user_guid_and_client_guid?")
    end

    it "creates 'cached_exist_by_client_guid_and_user_guid?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_client_guid_and_user_guid?")
    end

    it "creates 'cached_exist_by_derp_and_user_guid_and_client_guid?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_derp_and_user_guid_and_client_guid?")
    end

    it "creates 'cached_exist_by_client_guid_and_derp_and_user_guid?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_client_guid_and_derp_and_user_guid?")
    end

    it "creates 'cached_exist_by_client_guid_and_user_guid_and_derp?'" do
      ExistMethodClass.must_respond_to("cached_exist_by_client_guid_and_user_guid_and_derp?")
    end
  end
end
