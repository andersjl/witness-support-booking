
class ApplicationController < ActionController::Base
  protect_from_forgery
  include UserSessionsHelper
  include CourtDaysHelper
end

