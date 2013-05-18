class DatabasesController < ApplicationController
extend Authorization

  authorize [ :new, :create, :show], "master"

  def new
    @database = Database.new
  end

  def create
    begin
      Database.new( params[ :database]).replace!
      flash[ :success] = t( "database.created")
      redirect_to log_in_path
    rescue AllDataDoc::XmlParseError => e
      flash[ :error] = t( "database.error.message",
                          reason: t( "database.error.parse"),
                          message: e.message)
      redirect_to new_database_path
    rescue Exception => e
      flash[ :error] = t( "database.error.message",
                          reason: t( "database.error.exception",
                                     exception: e.class.name),
                          message: e.message)
      redirect_to new_database_path
    end
  end

  def show
    db = Database.new
    send_data db.all_data, :type => "text/xml",
              filename: "#{ t( 'databases.show.file_name')
                          }-#{ db.version}-#{ db.timestamp}.xml"
  end
end

