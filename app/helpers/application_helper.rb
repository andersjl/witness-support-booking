module ApplicationHelper

  def full_title( page_title)
    page_title.empty? ? t( "general.application") :
                        "#{ t( 'general.application')} | #{ page_title}"
  end

  def day_of_week( date)
    t( "date.abbr_day_names")[ date.cwday - 1]
  end
end
