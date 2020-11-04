require 'spec_helper'
require 'byebug'

class FindByMethodClass
  include ::ActiveRemote::Cached

  def self.find(**args); nil; end;
  def self.search(**args); nil; end;

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
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:guid => "foobar")).to eq(1)
      end

      it "calls cached_find_by_guid and nothing found" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([])
        expect(FindByMethodClass.cached_find_by(:guid => "foobar")).to be nil
      end

      it "calls cached_find_by_guid and nothing found does not raise an error" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([])
        expect do
          FindByMethodClass.cached_find_by(:guid => "foobar")
        end.not_to raise_error(::ActiveRemote::RemoteRecordNotFound)
      end
    end

    context "user_guid, client_guid" do
      it "calls cached_find_by_guid and returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_user_guid_and_client_guid).with(["foo", "bar"], {}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:user_guid => "foo", :client_guid => "bar")).to eq(1)
      end

      it "calls cached_search_by_user_guid_and_client_guid with options returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_user_guid_and_client_guid).with(["foo", "bar"], {:expires_in => 1}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:user_guid => "foo", :client_guid => "bar", :cache_options => { :expires_in => 1 })).to eq(1)
      end

      it "calls cached_search_by_user_guid_and_client_guid with out of order attribute keys" do
        # cached_search_by_client_guid_and_user_guid is inverse of `cached_finders_for [:user_guid, :client_guid]` because it permutes
        # all possible combinations of the attributes
        expect(FindByMethodClass).to receive(:cached_search_by_client_guid_and_user_guid).with(["bar", "foo"], {}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:client_guid => "bar", :user_guid => "foo")).to eq(1)
      end

      it "calls cached_find_by_guid and nothing found" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([])
        expect(FindByMethodClass.cached_find_by(:guid => "foobar")).to be nil
      end

      it "calls cached_find_by_guid and nothing found does not raise an error" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([])
        expect do
          FindByMethodClass.cached_find_by(:guid => "foobar")
        end.not_to raise_error(::ActiveRemote::RemoteRecordNotFound)
      end
    end

    context "derp, user_guid, client_guid" do
      it "calls cached_search_by_user_guid_and_client_guid with out of order attribute keys" do
        expect(FindByMethodClass).to receive(:cached_search_by_derp_and_user_guid_and_client_guid).with(["foo", "bar", "baz"], {}).and_return([1])
        expect(FindByMethodClass.cached_find_by(:derp => "foo", :user_guid => "bar", :client_guid => "baz")).to eq(1)
      end
    end
  end

  describe "#cached_find_by!(:attribute => value)" do
    context "guid" do
      it "calls cached_find_by_guid! and returns 1" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([1])
        expect(FindByMethodClass.cached_find_by!(:guid => "foobar")).to eq(1)
      end

      it "calls cached_find_by_guid! and nothing found to raise an error" do
        expect(FindByMethodClass).to receive(:cached_search_by_guid).with(["foobar"], {}).and_return([])
        expect do
          FindByMethodClass.cached_find_by!(:guid => "foobar")
        end.to raise_error(::ActiveRemote::RemoteRecordNotFound)
      end
    end
  end

end
