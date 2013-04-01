module ApplicationHelper

  def full_title( page_title)
    page_title.empty? ? t( "general.application") :
                        "#{ t( 'general.application')} | #{ page_title}"
  end
end
