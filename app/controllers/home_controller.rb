 require 'google_analytics/reader'
class HomeController < ApplicationController
  def index
  	@data = GoogleAnalytics::Reader.perform
  end
end
