require "nokogiri"

module AllDataDefs

  DOC_DEF =  # order matters, hence no Hash
    [ [ "user",      "name", "email"],
      [ "court_day", "date", "morning", "afternoon", "notes"],
      [ "booking",   [ "user", "email"], [ "court_day", "date"], "session"]]
  TYPECASTS = { "session" => lambda{ |v| v.to_sym}}

  MODELS = DOC_DEF.collect{ |model_def| model_def.first}  # order matters
  ATTR_DEFS = DOC_DEF.inject( { }) do |acc, m_def|
    acc[ m_def.first] = m_def[ 1 .. -1]
    acc
  end
  ATTRIBS = ATTR_DEFS.inject( { }) do |acc, model_adef|
    model, a_def = model_adef
    acc[ model] = a_def.collect{ |a| [ a].flatten.first}
    acc
  end
  CLASSES = MODELS.inject( { }){ |acc, m| acc[ m] = eval( m.camelize); acc}
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
    expect( tag_name, MODELS)
    @state = :start_attr
    @new_db.push( { :model => tag_name})
  end

  def start_attr( tag_name)
    expect( tag_name, ATTRIBS[ @new_db.last[ :model]])
    @state = :read_attr
    @value = ""
  end

  def read_attr( tag_name)
    expect( tag_name, "no start tag while reading attribute value")
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
      end
    when :start_attr
      @state = :start_model
    when :read_attr
      @state = :start_attr
      @new_db.last[ tag_name] = @value
    end
  end

  def error( message)
    raise XmlParseError.new( message)
  end

  def expect( got, expected)
    unless [ expected].flatten.include?( got)
      raise XmlParseError.new(
              "got #{ got.inspect}, expected #{ expected.inspect}")
    end
  end
end

class Database < ActiveRecord::Base

include AllDataDefs

  def self.columns
    @columns ||= [ :all_data, :new_pw].collect do |col|
      ActiveRecord::ConnectionAdapters::Column.new( col, :string, nil, false)
    end
  end

  attr_accessible :all_data, :new_pw

  attr_accessor :new_pw
  validates :new_pw, :presence => true, :length => { :minimum => 6}

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
        MODELS.each do |model|
          CLASSES[ model].find( :all).each do |model_obj|
            xml.send( model) do
              ATTR_DEFS[ model].each do |a_def|
                if a_def.is_a? Array
                  xml.send( a_def.first,
                            model_obj.send( a_def.first).send( a_def[ 1]))
                else
                  xml.send( a_def, model_obj.send( a_def))
                end
              end
            end
          end
        end
      end
    end.to_xml
  end

  def replace!
    return unless @replace_descr
    user_secrets = User.find( :all).inject( { }) do |acc, user|
      acc[ user.email] = [ user.read_attribute( :password_digest), user.role]
      acc
    end
    Booking.delete_all
    CourtDay.delete_all
    User.delete_all
    @replace_descr.each do |obj_descr|
      model = obj_descr[ :model]
      obj = CLASSES[ model].new
      ATTR_DEFS[ model].each do |a_def|
        obj_attr = a_def.is_a?( Array) ? a_def.first : a_def
        value = obj_descr[ obj_attr]
        if a_def.is_a? Array
          foreign_attr = a_def[ 1]
          value = CLASSES[ obj_attr].send( "find_by_#{ foreign_attr}", value)
        end
        typecast = TYPECASTS[ obj_attr]
        typecast && value = typecast.call( value)
        obj.send( "#{ obj_attr}=", value)
      end
      if model == "user"
        obj.password = obj.password_confirmation = new_pw
      end
      obj.save!
      if model == "user"
        secret = user_secrets[ obj.email]
        if secret
          password_digest, role = secret
          obj.update_attribute :password_digest, password_digest
          obj.update_attribute :role, role
        end
      end
    end
  end
end

