module ApplicationHelper

  def full_title( page_title)
    page_title.empty? ? APPLICATION_NAME :
                        "#{ APPLICATION_NAME} | #{ page_title}"
  end

  def day_of_week( date)
    [ "må", "ti", "on", "to", "fr", "lö", "sö"][ date.cwday - 1]
  end
end
