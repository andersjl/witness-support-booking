
module CourtDaysHelper

  def td_rowspan( rows, content = nil)
    html = "<td"
    html += " rowspan=\"#{ rows}\"" if rows > 1
    html + ">#{ content}</td>"
  end

=begin
  def court_day_rows( court_day)
    [ 1, court_day.morning, court_day.afternoon].max
  end

  def morning_taken( court_day)
    rand( court_day.morning + 1)  # stub
  end

  def afternoon_taken( court_day)
    rand( court_day.afternoon + 1)  # stub
  end

# usage <%= court_days_table( @court_days).html_safe %>
  def court_days_table( court_days)
    html = ""
    html += %Q$
          <table class="table table-bordered table-condensed">$
    html += %Q$
            <thead><tr>
              <th></th>
              <th>Datum</th>
              <th>Förmiddag</th>
              <th>Eftermiddag</th>
              <th>Noteringar</th>
            </tr><thead>$
  # html += "<p>#{ court_days.count}</p>"
  # html += %Q$
  #       <ul>$
    court_days.each do |court_day|
      morning_taken = rand( court_day.morning + 1)  # stub
      afternoon_taken = rand( court_day.afternoon + 1)  # stub
      court_day_rows = [ 1, court_day.morning, court_day.afternoon].max
      1.upto( court_day_rows) do |row|
        html += %Q$
            <tr>$
        if row == 1
          html += %Q$
              #{ td_rowspan( court_day_rows, weekday( court_day.date))}
              #{ td_rowspan( court_day_rows, court_day.date)}$
        end
        if row <= morning_taken
          html += %Q$
              <td>NN</td>$  # stub
        else
          html += %Q$
              #{ unbooked_row( row, morning_taken, court_day.morning,
                               court_day_rows)}$
        end
        if row <= afternoon_taken
          html += %Q$
              <td>NN</td>$  # stub
        else
          html += %Q$
              #{ unbooked_row( row, afternoon_taken, court_day.afternoon,
                               court_day_rows)}$
        end
        if row == 1
          html += %Q$
              #{ td_rowspan( court_day_rows, court_day.notes)}$
        end
        html += %Q$
            </tr>$
      end
    #   html += %Q$
    #       <li>#{ court_day.date}, #{ court_day.morning}, #{ court_day.afternoon}, #{ court_day.notes}</li>$
    end
    html += %Q$
          </table>$
  # html += %Q$
  #       </ul>$
    html
  end

  def unbooked_row( row, taken, sessions, max)
    if row <= sessions
      if row == taken + 1
        "<td>#{ sessions - taken} kvar att boka</td>"
      else
        "<td></td>"
      end
    elsif row == sessions + 1
      td_rowspan( max - row + 1, "")
    else
      ""
    end
  end
=end
end

