
module CourtDaysHelper

  def offset_n_span_to_class( offset, span)
    result = ""
    result += "offset#{ offset} " if offset.is_a?( Numeric) && offset > 0
    result += "span#{ span}"
  end

=begin
  def render_day( court_day, session_span, notes_span, at_bottom)
    court_day_class = [ "court-day"]
    court_day_class << "last" if at_bottom
    court_day_id = "court-day-#{ court_day.date}"
    bs_day = bootstrap_row( court_day_class, court_day_id)
    bs_day << bootstrap_col( 1, "weekday", nil, weekday( court_day.date))
    bs_day << bootstrap_col( 1, nil, nil, court_day.date)
    edit_col = bootstrap_col( 2 * session_span + notes_span, nil, nil)
    if current_user.admin?
      edit_col << bs_admin_row( court_day, session_span, notes_span)
    end
    edit_col << bs_user_row( court_day, session_span, notes_span)
    bs_day << edit_col
    bs_day.to_s
  end

  def bs_admin_row( court_day, session_span, notes_span)
    row = bootstrap_row( nil, nil)
    [ "morning", "afternoon"].each do |session|
      offered = court_day.send( session)
      row << bootstrap_col( session_span, nil, nil, "#{ offered} totalt")
    end
    row << bootstrap_col( notes_span, nil, nil, h( court_day.notes
                                                 ).gsub( "\n", "<br/>"))
    row
  end

  def bs_user_row( court_day, session_span, notes_span)
    offset = 0
    row = bootstrap_row( nil, nil)
    [ "morning", "afternoon"].each do |session|
      col = bs_session( court_day, session, offset, session_span)
      if col
        row << col
        offset = 0
      else
        offset += session_span
      end
    end
    unless current_user.admin?
      row << bootstrap_col( notes_span, offset_to_class( offset), nil,
               h( court_day.notes).gsub( "\n", "<br/>"))
    end
    row
  end

  def bs_session( court_day, session, offset, session_span)
    offered = court_day.send( session)
    if offered > 0
      col = bootstrap_col( session_span, offset_to_class( offset), nil)
      taken = court_day.send( session + "_taken")
      if offered - taken > 0
        col << bootstrap_row( nil, nil, 
                 bootstrap_col( session_span, nil, nil,
                   "#{ offered - taken} kvar att boka"))
      end
      taken.times do
        col << bootstrap_row( nil, nil,
                 bootstrap_col( session_span, nil, nil,
                   "NN"))
      end
      col
    end
  end

  def offset_to_class( offset)
    "offset#{ offset}" if offset > 0
  end

  class ::String
    def indent
      gsub( "\n", "\n  ")
    end
  end

  class BootstrapScaffold < Array

    def to_s
      result = @preamble
      each{ |component| result += component.to_s.indent}
      result + "\n</div>"
    end

    def initialize( content, given_class, html_class, html_id)
      @preamble =  %Q$\n<div class="#{ given_class}$
      if html_class
        html_class = html_class.flatten.join( " ") if html_class.is_a?( Array)
        @preamble += %Q$ #{ html_class}$
      end
      @preamble += %Q$"$
      if html_id
        @preamble += %Q$ id="#{ html_id}"$
      end
      @preamble += %Q$>$
      content.each{ |part| append part}
    end
  end

  class BootstrapRow < BootstrapScaffold
    def initialize( columns, html_class, html_id)
      super columns, "row", html_class, html_id
    end
  end
  def bootstrap_row( html_class, html_id, *cols)
    BootstrapRow.new( cols, html_class, html_id)
  end

  class BootstrapCol < BootstrapScaffold
    def initialize( content, span, html_class, html_id)
      span = "span#{ span}" unless span.to_s[ 0, 4] == "span"
      super span, html_class, html_id, content
    end
  end
  def bootstrap_col( span, html_class, html_id, *content)
    BootstrapCol.new( content, span, html_class, html_id)
  end

  class BootstrapCol < BootstrapScaffold
    def initialize( span, html_class, html_id, *rows)
      span = "span#{ span}" unless span.to_s[ 0, 4] == "span"
      super rows, span, html_class, html_id
    end
  end
  def bootstrap_col( *args)
    BootstrapCol.new( *args)
  end
=end
end

