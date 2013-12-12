module ApplicationHelper

  def full_title( page_title)
    page_title.empty? ? t( "general.application") :
                        "#{ t( 'general.application')} | #{ page_title}"
  end

  def debugging
    @debugging = ENV[ "RAILS_MODE"] == "DEBUG" if @debugging == nil
    @debugging
  end

  def media_query_available
    if @media_query_available == nil
      @media_query_available =
        !(ENV[ "RESPONSIVE"] == "FALSE") &&
        begin
          ie = /IE\s+(\d+)/ =~ request.user_agent
          !(ie && ie[ 1].to_i < 9)
        end
    end
    @media_query_available
  end

  # Makes a Bootstrap grid tag
  # more is a hash or a fixnum offset
  # hash keys:
  #   offset:  Bootstrap offset
  #   class:  concat with the Bootstrap class, e.g. 'my-class' (no quotes)
  #   html: other html string, e.g. 'id="whatever"' (with quotes)
  def bootstrap_tag( tag, span, more = nil)
    offstet = nil
    html_class = nil
    html_other = nil
    case more
    when Fixnum
      offset = more
    when Hash
      offset = more[ :offset]
      html_class = more[ :class]
      html_other = more[ :html]
    end
    result = "<#{ tag} class=\"col-#{ media_query_available ? 'md' : 'xs' 
                                    }-#{ span}"
    result += " col-#{ media_query_available ? 'md' : 'xs'
                     }-offset-#{ offset}" if offset && offset > 0
    result += " " + html_class if html_class
    result += "\""
    result += " " + html_other if html_other
    result += ">"
    result.html_safe
  end
end
