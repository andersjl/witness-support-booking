require "nokogiri"

# Defines how to store and read the models' data in XML.
module AllDataDefs

  COURT_DEF =  # :nodoc:
    [ "court", lambda{ |model_obj| model_obj.court.name},
      lambda{ |model_obj, name| model_obj.court = Court.find_by_name( name)}]
  BOOKING_COURT_DEF =  # :nodoc:
    [ "court", lambda{ |booking| booking.user.court.name},
      lambda{ |booking, court_name|
              @booking_court = Court.find_by_name( court_name)}]
  BOOKING_USER_DEF =  # :nodoc:
    [ "user", lambda{ |booking| booking.user.email},
      lambda{ |booking, email| booking.user =
                User.find_by_court_id_and_email( @booking_court, email)}]
  BOOKING_SESSION_DEF =  # :nodoc:
    [ "session", lambda{ |booking| booking.court_session.start_time.iso8601},
      lambda{ |booking, time| booking.court_session =
                CourtSession.find_by_date_and_court_id_and_start(
                  time.to_date, @booking_court,
                  time.to_time - time.to_date.in_time_zone)}]

  # The root element in the XML file.
  ROOT_TAG = "db_dump"

  # An array of arrays.
  #
  # The first element in each subarray is the underscore variant of the model
  # name, and will also be the XML tag for that model's data.
  #
  # If this is the only element in the subarray, this model is NOT written to
  # the XML file, but any existing objects are deleted when reading XML.  If
  # the tag is present when reading an XML file, the read fails.
  #
  # Each remaining element describes an attribute.  It is either simply the
  # attribute name, or an array where the first element is the attribute name.
  # The attribute name will be the XML tag for the data.
  #
  # If the attribute is not described by an array, it is simply stored and
  # read using default data conversions - WHICH MAY BE LOCALIZATION DEPENDENT!
  # (e.g. date formats).
  #
  # If the attribute <em>is</em> described by an array, the second and third
  # elements are either <tt>nil</tt> or data conversion <tt>lambda</tt>s of
  # the form
  # 
  #   lambda{ |model_obj| getter( model_obj)}
  #   lambda{ |model_obj, value| setter( model_obj, value)}
  #
  MODEL_DEFS =  # order matters, hence no Hash (no longer true ...)
    [ [ "court",          "name", "link"],
      [ "user",           COURT_DEF, "name", "email", "password_digest"],
      [ "court_session",  COURT_DEF, "date", "start", "need"],
      [ "court_day_note", COURT_DEF, "date", "text"],
      [ "booking",        BOOKING_COURT_DEF, BOOKING_USER_DEF,
                          BOOKING_SESSION_DEF, "booked_at"
      ], [ "cancelled_booking"], [ "snapshot"],
    ]

  def self.define_standard_get( model_tag, attr_tag)  # :nodoc:
    define_method "get_#{ model_tag}_#{ attr_tag}".intern do |model_obj|
      model_obj.send( attr_tag)
    end
  end

  def self.define_standard_set( model_tag, attr_tag)  # :nodoc:
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

  def self.model_tags
    @@model_tags ||= MODEL_DEFS.collect{ |md| md.first}
  end

  def self.model_class( model_tag)
    (@@model_classes ||= { })[ model_tag] ||= model_tag.camelize.constantize
  end

  def self.attr_tags( model_tag)
    (@@attr_tags ||= { })[ model_tag] ||=
      MODEL_DEFS.assoc( model_tag)[ 1 .. -1].
        collect{ |a| a.is_a?( Array) ? a.first : a}
  end

  # Call the getter that has been defined based on <tt>MODEL_DEFS</tt>.
  def attr_get( model_tag, attr_tag, model_obj)
    send( "get_#{ model_tag}_#{ attr_tag}", model_obj)
  end

  # Call the setter that has been defined based on <tt>MODEL_DEFS</tt>.
  def attr_set( model_tag, attr_tag, model_obj, value)
    send( "set_#{ model_tag}_#{ attr_tag}", model_obj, value)
  end

  def self.version; ActiveRecord::Migrator.current_version.to_s end
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
    send @state, tag_name, attrs
  end

  def start_file( tag_name, attrs)
    expect( tag_name, ROOT_TAG)
    @state = :start_model
    expected_version = AllDataDefs.version
    read_version = lambda{ |v| v.is_a?( Array) ? v[ 1] : "none"
                         }.call( attrs.assoc( "version"))
    unless read_version == expected_version
      raise XmlParseError.new(
            "expected DB version #{ expected_version}, got #{ read_version}")
    end
  end

  def start_model( tag_name, attrs)
    expect( tag_name, AllDataDefs.model_tags)
    @state = :start_attr
    @new_db.push( { model: tag_name})
  end

  def start_attr( tag_name, attrs)
    expect( tag_name, AllDataDefs.attr_tags( @new_db.last[ :model]))
    @state = :read_attr
    @value = ""
  end

  def read_attr( tag_name, attrs)
    expect( tag_name, "no start tag while reading attribute value")
  end

  # does not seem to happen, actually
  def end_file( tag_name, attrs)
    expect( tag_name, "no start tag after #{ ROOT_TAG} end tag")
  end

  def characters( str)
    @value += str if @state == :read_attr
  end

  def end_element( tag_name)
    expect( tag_name, @current.pop)
    case @state
    when :start_model
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

class Database
include AllDataDefs
include ActiveModel::Validations
include ActiveModel::Conversion
extend ActiveModel::Naming

  def self.attributes
    [ :all_data, :oldest_date]
  end

  def initialize( attributes = { })
    attributes && attributes.each do |name, value|
      send( "#{name}=", value) if respond_to? "#{name}=".intern
    end
  end

  def persisted?
    false
  end

  def self.inspect
    "#<#{ self.to_s} #{ self.attributes.collect{ |e| ":#{ e }"}.join(', ')}>"
  end

  def all_data=( uploaded)
    return unless uploaded
    all_data_doc = AllDataDoc.new
    Nokogiri::XML::SAX::Parser.new( all_data_doc).parse( uploaded.read)
    @replace_descr = all_data_doc.new_db
  end

  def all_data
    # The original and obvious code was simply
    #
    #   Nokogiri::XML::Builder.new( encoding: "UTF-8") do |xml|
    #     ...
    #   end.to_xml
    #
    # This sometimes takes more than 30 seconds to complete.  No problem,
    # since this requires master and should be called once a week or so.  But
    # if you deploy on Heroku the platform will return an error to the browser
    # if there is no response within 30 seconds.  (While sending and error to
    # the browser, Heroku does not interrupt the process, it runs to the end.)
    #
    # Hence this code using a helper model Snapshot to store the result for
    # ten minutes to return to the browser the next time around in case there
    # was no return the first time.
    #
    # This is not very convenient when testing, since the test code would have
    # to wait ten minutes after a change in the database before it can be
    # downloaded.  So we disable the snapshot-in-database mechanism in the
    # test environment.
    #
    snapshot = Snapshot.first
    if snapshot && Time.now - snapshot.created_at < 600
      result = snapshot.all_data
      Snapshot.delete_all
    else
      # Force the error in the Heroku stage environment
      sleep( 35) if ENV[ "RAILS_MODE"] == "DEBUG"
      snapshot = Snapshot.new
      snapshot.all_data =
        Nokogiri::XML::Builder.new( encoding: "UTF-8") do |xml|
          xml.send( ROOT_TAG, time: timestamp, version: version) do
            AllDataDefs.model_tags.each do |model_tag|
              AllDataDefs.model_class( model_tag).all.each do |model_obj|
                attr_tags = AllDataDefs.attr_tags( model_tag)
                next if attr_tags.count == 0
                xml.send( model_tag) do
                  attr_tags.each do |attr_tag|
                    fixed = attr_tag == "text" ? "text_" : attr_tag
                    xml.send( fixed, attr_get( model_tag, attr_tag, model_obj)
                            )
                  end
                end
              end
            end
          end
        end.to_xml
      Snapshot.delete_all
      snapshot.save unless Rails.env.test?
      result = snapshot.all_data
    end
    result
  end

  def oldest_date=( date)
    return unless date
    date = date.to_date
    @too_old = [ Booking, CancelledBooking].collect do |model|
                 model.all.inject( [ model]) do |list, obj|
                   list << obj.id if obj.court_session.date < date
                   list
                 end
               end + [ CourtDayNote, CourtSession].collect do |model|
                       model.where( "date < ?", date
                                  ).inject( [ model]){ |l, o| l << o.id}
                     end
  end

  def oldest_date; self.class.oldest_date end
  def self.oldest_date
    [ CourtDayNote, CourtSession
    ].collect{ |model| model.all.collect{ |obj| obj.date}}.flatten.min
  end

  def row_count( count_date)
    [ CourtDayNote, CourtSession].inject( 0) do |total, model|
      total + model.where( "date >= ?", count_date).count
    end + [ Booking, CancelledBooking].inject( 0) do |total, model|
            total + model.joins( :court_session).
                      where( "court_sessions.date >= ?", count_date).count
          end + Court.count + User.count
  end

  def save!
    replace! if @replace_descr
    destroy_old! if @too_old
  end

  def timestamp; @timestamp ||= Time.current.strftime( "%Y%m%dT%H%M%S%z") end
  def version; AllDataDefs.version end

  def replace!
    digests = User.all.inject( [ ]) do |acc, user|
      acc << [ user.court.name, user.name, user.email, user.role,
               user.read_attribute( :password_digest)]
    end
    AllDataDefs.model_tags.each{ |t| AllDataDefs.model_class( t).delete_all}
    @replace_descr.each do |obj_descr|
      model_tag = obj_descr[ :model]
      model_obj = AllDataDefs.model_class( model_tag).new
      AllDataDefs.attr_tags( model_tag).each do |attr_tag|
        attr_set( model_tag, attr_tag, model_obj, obj_descr[ attr_tag])
      end
      if model_tag == "user"
       model_obj.password = model_obj.password_confirmation = "dummy_password"
      end
      next unless model_obj.save
      if model_tag == "user"
        model_obj.update_attribute :password_digest,
                                   obj_descr[ "password_digest"]
      end
    end
    digests.each do |cnam_unam_email_role_digest|
      cnam, unam, email, role, digest = cnam_unam_email_role_digest
      court = Court.find_by_name( cnam) || Court.create!( name: cnam)
      user = User.find_by_court_id_and_email court.id, email
      if user
        user.update_attribute :name, unam
        user.update_attribute :role, role
      else
        user = User.new email: email, name: unam,
                        password: "dummy_password",
                        password_confirmation: "dummy_password"
        user.court = court
        user.role = role
        user.save!
      end
      user.update_attribute :password_digest, digest
    end
  end
  private :replace!

  def destroy_old!
    @too_old && @too_old.each{ |list| list.shift.delete list}
    @too_old = nil
  end
  private :destroy_old!
end

