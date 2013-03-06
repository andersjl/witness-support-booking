
class DatabasesController < ApplicationController

  before_filter :logged_in_user
  before_filter :enabled_user
  before_filter :admin_user

  def new
    @database = Database.new
  end

  def create
    begin
      Database.new( params[ :database]).replace!
      flash[ :success] = "Ny databas inläst. Du måste logga in igen."
      redirect_to log_in_path
    rescue AllDataDoc::XmlParseError => e
      flash[ :error] =
        "Inläsningen misslyckades: #{ e.message}. Databasen är orörd."
      redirect_to new_database_path
    end
  end

  def show
    send_data Database.new.all_data, :type => "text/xml",
              :filename => "#{ ALL_DATA_FILE_NAME}.xml"
  end
end