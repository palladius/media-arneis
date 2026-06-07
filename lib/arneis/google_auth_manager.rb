require "googleauth"
require "google/apis/slides_v1"
require "google/apis/drive_v3"
require "stringio"

module Arneis
  module GoogleAuthManager
    SCOPES = [
      "https://www.googleapis.com/auth/presentations",
      "https://www.googleapis.com/auth/drive"
    ].freeze

    def self.get_credentials
      if ENV["GOOGLE_APPLICATION_CREDENTIALS_JSON"]
        json_key_io = StringIO.new(ENV["GOOGLE_APPLICATION_CREDENTIALS_JSON"])
        Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: json_key_io,
          scope: SCOPES
        )
      elsif ENV["GOOGLE_APPLICATION_CREDENTIALS"] && File.exist?(ENV["GOOGLE_APPLICATION_CREDENTIALS"])
        json_key_io = StringIO.new(File.read(ENV["GOOGLE_APPLICATION_CREDENTIALS"]))
        Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: json_key_io,
          scope: SCOPES
        )
      else
        Google::Auth.get_application_default(SCOPES)
      end
    end

    def self.slides_service
      service = Google::Apis::SlidesV1::SlidesService.new
      service.authorization = get_credentials
      service
    end

    def self.drive_service
      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = get_credentials
      service
    end
  end
end
