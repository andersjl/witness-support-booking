module CourtDaysHelper

  WEEKPICKER_WIDTH = 6

  def weekpicker_width
    admin? ? WEEKPICKER_WIDTH : 12
  end

  def datepicker_width
    ( 12 - weekpicker_width) / 2
  end
end

