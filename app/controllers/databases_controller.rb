class DatabasesController < ApplicationController
extend Authorization

  authorize [ :new, :create, :show, :update], "master"

  def new
    @database = Database.new
  end

  def create
    Database.new( params[ :database]).save!
    flash[ :success] = t( "database.created")
    redirect_to log_in_path
  rescue AllDataDoc::XmlParseError => e
    flash[ :error] = "#{ t( 'database.error.parse') }: #{ e.message
                                       }. #{ t( 'database.error.untouched')}."
    redirect_to new_database_path
  rescue Exception => e
    flash[ :error] = "#{ t( 'database.error.exception',
                            exception: e.class.name)
                      }: #{ e.message}. #{ t( 'database.error.compromised')}."
    redirect_to new_database_path
  end

  def show
    count_date = params[ :count_date]
    if count_date
      session[ :count_date] = count_date
      redirect_to user_path( current_user)
    else
      db = Database.new
      send_data db.all_data, :type => "text/xml",
                filename: "#{ t( 'databases.show.file_name')
                            }-#{ db.version}-#{ db.timestamp}.xml"
    end
  end

  def update
    new_oldest_date = session[ :count_date] || Database.oldest_date
    Database.new( oldest_date: new_oldest_date).save!
    flash[ :success] =
      t( "database.dropped_older_than", date: new_oldest_date)
    redirect_to user_path( current_user)
  end
end

