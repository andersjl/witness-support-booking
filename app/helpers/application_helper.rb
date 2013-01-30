module ApplicationHelper

  def full_title( page_title)
    base_title = "Bokning av vittnesstöd"
    page_title.empty? ? base_title : "#{ base_title} | #{ page_title}"
  end

  def weekday( date)
    [ "Må", "Ti", "On", "To", "Fr", "Lö", "Sö"][ date.cwday - 1]
  end
end
