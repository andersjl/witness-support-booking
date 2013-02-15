module ApplicationHelper

  def full_title( page_title)
    base_title = "Bokning av vittnesstöd"
    page_title.empty? ? base_title : "#{ base_title} | #{ page_title}"
  end

  def day_of_week( date)
    [ "må", "ti", "on", "to", "fr", "lö", "sö"][ date.cwday - 1]
  end
end
