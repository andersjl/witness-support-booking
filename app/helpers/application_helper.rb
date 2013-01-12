module ApplicationHelper

  def full_title( page_title)
    base_title = "Bokning av vittnesstöd"
    page_title.empty? ? base_title : "#{ base_title} | #{ page_title}"
  end

end
