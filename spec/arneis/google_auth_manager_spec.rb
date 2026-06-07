require "spec_helper"
require "arneis/google_auth_manager"
require "google/apis/slides_v1"
require "google/apis/drive_v3"

RSpec.describe Arneis::GoogleAuthManager do
  let(:mock_credentials) { double("GoogleAuthCredentials") }

  before do
    # Clear env vars before each test to prevent pollution
    ENV.delete("GOOGLE_APPLICATION_CREDENTIALS")
    ENV.delete("GOOGLE_APPLICATION_CREDENTIALS_JSON")
  end

  describe ".get_credentials" do
    context "when GOOGLE_APPLICATION_CREDENTIALS file path is provided" do
      it "loads credentials from the file" do
        ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "/path/to/credentials.json"
        expect(File).to receive(:exist?).with("/path/to/credentials.json").and_return(true)
        expect(Google::Auth::ServiceAccountCredentials).to receive(:make_creds)
          .with(json_key_io: anything, scope: anything)
          .and_return(mock_credentials)

        # We mock File.read to avoid reading a real file
        allow(File).to receive(:read).with("/path/to/credentials.json").and_return("{}")

        creds = described_class.get_credentials
        expect(creds).to eq(mock_credentials)
      end
    end

    context "when GOOGLE_APPLICATION_CREDENTIALS_JSON raw JSON is provided" do
      it "loads credentials from the JSON string" do
        json_str = '{"type": "service_account"}'
        ENV["GOOGLE_APPLICATION_CREDENTIALS_JSON"] = json_str
        expect(Google::Auth::ServiceAccountCredentials).to receive(:make_creds)
          .with(json_key_io: anything, scope: anything)
          .and_return(mock_credentials)

        creds = described_class.get_credentials
        expect(creds).to eq(mock_credentials)
      end
    end

    context "when no specific env var is provided" do
      it "falls back to application default credentials" do
        expect(Google::Auth).to receive(:get_application_default).and_return(mock_credentials)

        creds = described_class.get_credentials
        expect(creds).to eq(mock_credentials)
      end
    end
  end

  describe ".slides_service" do
    it "instantiates SlidesService and sets credentials" do
      allow(described_class).to receive(:get_credentials).and_return(mock_credentials)
      service = described_class.slides_service
      expect(service).to be_an_instance_of(Google::Apis::SlidesV1::SlidesService)
      expect(service.authorization).to eq(mock_credentials)
    end
  end

  describe ".drive_service" do
    it "instantiates DriveService and sets credentials" do
      allow(described_class).to receive(:get_credentials).and_return(mock_credentials)
      service = described_class.drive_service
      expect(service).to be_an_instance_of(Google::Apis::DriveV3::DriveService)
      expect(service.authorization).to eq(mock_credentials)
    end
  end
end
