require 'spec_helper'

class DeleteMethodClass
  include ::ActiveRemote::Cached

  def self.find; nil; end
  def self.search; nil; end

  cached_finders_for :guid
  cached_finders_for :guid, :user_guid
  cached_finders_for [:user_guid, :client_guid]
  cached_finders_for [:derp, :user_guid, :client_guid]
end

describe DeleteMethodClass do
  describe "API" do
    it "creates 'cached_delete_by_guid'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_guid")
    end

    it "creates 'cached_delete_by_user_guid'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_user_guid")
    end

    it "creates 'cached_delete_by_user_guid_and_client_guid'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_user_guid_and_client_guid")
    end

    it "creates 'cached_delete_by_client_guid_and_user_guid'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_client_guid_and_user_guid")
    end

    it "creates 'cached_delete_by_derp_and_user_guid_and_client_guid'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_derp_and_user_guid_and_client_guid")
    end

    it "creates 'cached_delete_by_client_guid_and_derp_and_user_guid'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_client_guid_and_derp_and_user_guid")
    end

    it "creates 'cached_delete_by_client_guid_and_user_guid_and_derp'" do
      DeleteMethodClass.must_respond_to("cached_delete_by_client_guid_and_user_guid_and_derp")
    end
  end
end
