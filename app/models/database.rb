require "nokogiri"

module AllDataDefs

  COURT_DEF =
    [ "court", lambda{ |model_obj| model_obj.court.name},
      lambda{ |model_obj, name| model_obj.court = Court.find_by_name( name)}]
  BOOKING_COURT_DEF =
    [ "court", lambda{ |booking| booking.user.court.name},
      lambda{ |booking, court_name|
              @booking_court = Court.find_by_name( court_name)}]
  BOOKING_USER_DEF =
    [ "user", lambda{ |booking| booking.user.email},
      lambda{ |booking, email| booking.user =
                User.find_by_court_id_and_email( @booking_court, email)}]
  BOOKING_DATE_DEF =
    [ "date", lambda{ |booking| booking.court_day.date},
      lambda{ |booking, date| booking.court_day =
                CourtDay.find_by_court_id_and_date( @booking_court, date)}]
  SESSION_DEF = [ "session", nil, lambda{ |booking, session|
                                          booking.session = session.intern}]
  MODEL_DEFS =  # order matters, hence no Hash
    [ [ "court",     "name", "link"],
      [ "user",      COURT_DEF, "name", "email", "password_digest"],
      [ "court_day", COURT_DEF, "date", "morning", "afternoon", "notes"],
      [ "booking",   BOOKING_COURT_DEF, BOOKING_USER_DEF, BOOKING_DATE_DEF,
                     SESSION_DEF]]

  def self.define_standard_get( model_tag, attr_tag)
    define_method "get_#{ model_tag}_#{ attr_tag}".intern do |model_obj|
      model_obj.send( attr_tag)
    end
  end

  def self.define_standard_set( model_tag, attr_tag)
    define_method "set_#{ model_tag}_#{ attr_tag}".intern do
      |model_obj, value| model_obj.send( "#{ attr_tag}=", value)
    end
  end

  MODEL_DEFS.each do |model_def|
    model_tag = model_def.first
    model_def[ 1 .. -1].each do |attr_def|
      if attr_def.is_a?( Array)
        attr_tag = attr_def.first
        if attr_def[ 1]
          define_method "get_#{ model_tag}_#{ attr_tag}".intern do |model_obj|
            attr_def[ 1].call( model_obj)
          end
        else
          define_standard_get( model_tag, attr_tag)
        end
        if attr_def[ 2]
          define_method "set_#{ model_tag}_#{ attr_tag}".intern do
            |model_obj, value| attr_def[ 2].call( model_obj, value)
          end
        else
          define_standard_set( model_tag, attr_tag)
        end
      else
        define_standard_get( model_tag, attr_def)
        define_standard_set( model_tag, attr_def)
      end
    end
  end

  def model_tags
    @model_tags ||= MODEL_DEFS.collect{ |md| md.first}
  end

  def model_class( model_tag)
    (@model_classes ||= { })[ model_tag] ||= model_tag.camelize.constantize
  end

  def attr_tags( model_tag)
    (@attr_tags ||= { })[ model_tag] ||=
      MODEL_DEFS.assoc( model_tag)[ 1 .. -1].
        collect{ |a| a.is_a?( Array) ? a.first : a}
  end

  def attr_get( model_tag, attr_tag, model_obj)
    send( "get_#{ model_tag}_#{ attr_tag}", model_obj)
  end

  def attr_set( model_tag, attr_tag, model_obj, value)
  # puts [ "attr_set", model_tag, attr_tag, model_obj, value].inspect
    send( "set_#{ model_tag}_#{ attr_tag}", model_obj, value)
  end
end

class AllDataDoc < Nokogiri::XML::SAX::Document

include AllDataDefs

  attr_reader :new_db

  class XmlParseError < StandardError; end

  def initialize
    @current = [ ]
    @new_db = [ ]
    @state = :start_file
    @value = ""
  end

  def start_element( tag_name, attrs = [ ]) 
    @current.push tag_name
    send @state, tag_name
  end

  def start_file( tag_name)
    expect( tag_name, "db_dump")
    @state = :start_model
  end

  def start_model( tag_name)
    expect( tag_name, model_tags)
    @state = :start_attr
    @new_db.push( { :model => tag_name})
  end

  def start_attr( tag_name)
    expect( tag_name, attr_tags( @new_db.last[ :model]))
    @state = :read_attr
    @value = ""
  end

  def read_attr( tag_name)
    expect( tag_name, "no start tag while reading attribute value")
  end

  # does not seem to happen, actually
  def end_file( tag_name)
    expect( tag_name, "no start tag after db_dump end tag")
  end

  def characters( str)
    @value += str if @state == :read_attr
  end

  def end_element( tag_name)
    expect( tag_name, @current.pop)
    case @state
    when :start_model
      File.open( "/home/anders/tmp/debug_xml.txt", "w") do |f|
        @new_db.each{ |m| f.puts m.inspect}
      end unless Rails.env.production?
      @state = :end_file
    when :start_attr
      @state = :start_model
    when :read_attr
      @state = :start_attr
      @new_db.last[ tag_name] = @value
    end
  end

  def expect( got, expected)
    unless [ expected].flatten.include?( got)
      raise XmlParseError.new(
              "got #{ got.inspect}, expected #{ expected.inspect}")
    end
  end

  def error( message)
    raise XmlParseError.new( message)
  end
end

class Database < ActiveRecord::Base
include AllDataDefs

  def self.columns
    @columns ||= [ ActiveRecord::ConnectionAdapters::Column.new(
                     :all_data, :string, nil, false)]
  end

  def all_data=( uploaded)
    return unless uploaded
    all_data_doc = AllDataDoc.new
    Nokogiri::XML::SAX::Parser.new( all_data_doc).parse( uploaded.read)
    @replace_descr = all_data_doc.new_db
  end

  def all_data
    Nokogiri::XML::Builder.new( :encoding => "UTF-8") do |xml|
      xml.db_dump( :time => Time.now.strftime( "%Y-%m-%dT%H:%M:%S")
                 ) do
        model_tags.each do |model_tag|
          model_class( model_tag).all.each do |model_obj|
            xml.send( model_tag) do
              attr_tags( model_tag).each do |attr_tag|
                xml.send( attr_tag, attr_get( model_tag, attr_tag, model_obj))
              end
            end
          end
        end
      end
    end.to_xml
  end

  def replace!
    return unless @replace_descr
  # @replace_descr.each{ |object| puts object.inspect}
    digests = User.all.inject( [ ]) do |acc, user|
      acc << [ user.court.name, user.name, user.email, user.role,
               user.read_attribute( :password_digest)]
    end
    Booking.destroy_all
    CourtDay.destroy_all
    User.destroy_all
    Court.destroy_all
    @replace_descr.each do |obj_descr|
      model_tag = obj_descr[ :model]
      model_obj = model_class( model_tag).new
      attr_tags( model_tag).each do |attr_tag|
        attr_set( model_tag, attr_tag, model_obj, obj_descr[ attr_tag])
      end
      if model_tag == "user"
       model_obj.password = model_obj.password_confirmation = "dummy_password"
      end
      model_obj.save!
      if model_tag == "user"
        model_obj.update_attribute :password_digest,
                                   obj_descr[ "password_digest"]
      end
    end
    digests.each do |cnam_unam_email_role_digest|
      cnam, unam, email, role, digest = cnam_unam_email_role_digest
      court = Court.find_by_name( cnam) || Court.create!( :name => cnam)
      user = User.find_by_court_id_and_email court.id, email
      if user
        user.update_attribute :name, unam
        user.update_attribute :role, role
      else
        user = User.new :email => email, :name => unam,
                        :password => "dummy_password",
                        :password_confirmation => "dummy_password"
        user.court = court
        user.role = role
        user.save!
      end
      user.update_attribute :password_digest, digest
    end
  end
end

