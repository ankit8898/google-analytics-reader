require 'google/api_client'
require 'date'

module GoogleAnalytics
	class Reader

		def self.perform
						# Inspired by https://gist.github.com/3166610

			api_version = 'v3'
			cached_api_file = "analytics-#{api_version}.cache"

			# Update these to match your own apps credentials
			service_account_email = '723314723214@developer.gserviceaccount.com' # Email of service account
			key_file = File.join("#{Rails.root}/config/key","a509343c20a8486ae39593772f6631a4ca12da0a-privatekey.p12") # File containing your private key
			key_secret = 'notasecret' # Password to unlock private key
			profileID = '51025693' # Analytics profile ID.


			client = Google::APIClient.new(
			  :application_name => 'Ruby Service Accounts sample',
			  :application_version => '1.0.0')

			# Load our credentials for the service account
			key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
			client.authorization = Signet::OAuth2::Client.new(
			  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
			  :audience => 'https://accounts.google.com/o/oauth2/token',
			  :scope => 'https://www.googleapis.com/auth/analytics.readonly',
			  :issuer => service_account_email,
			  :signing_key => key)

			# Request a token for our service account
			client.authorization.fetch_access_token!

			analytics = nil
			# Load cached discovered API, if it exists. This prevents retrieving the
			# discovery document on every run, saving a round-trip to the discovery service.
			if File.exists? cached_api_file
			  File.open(cached_api_file) do |file|
			    analytics = Marshal.load(file)
			  end
			else
			  analytics = client.discovered_api('analytics', api_version)
			  File.open(cached_api_file, 'w') do |file|
			    Marshal.dump(analytics, file)
			  end
			end

			startDate = DateTime.now.prev_month.strftime("%Y-%m-%d")
			endDate = DateTime.now.strftime("%Y-%m-%d")

			visitCount = client.execute(:api_method => analytics.data.ga.get, :parameters => { 
			  'ids' => "ga:" + profileID, 
			  'start-date' => startDate,
			  'end-date' => endDate,
			  'dimensions' => "ga:day,ga:month",
			  'metrics' => "ga:visits",
			  'sort' => "ga:month,ga:day" 
			})

			# puts "--------#{visitCount.inspect}"
			# print visitCount.data.column_headers.map { |c|
			#   c.name  
			# }.join("\t")

			# visitCount.data.rows.each do |r|
			#   print r.join("\t"), "\n"
			# end

			{visit_count: visitCount}
		end
	end
end