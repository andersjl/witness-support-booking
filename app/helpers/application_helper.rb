module ApplicationHelper

  def full_title( page_title)
    base_title = "Bokning av vittnesstöd"
    page_title.empty? ? base_title : "#{ base_title} | #{ page_title}"
  end

  def weekday( date)
    [ "mån", "tis", "ons", "tor", "fre", "lör", "sön"][ date.cwday - 1]
  end
end
