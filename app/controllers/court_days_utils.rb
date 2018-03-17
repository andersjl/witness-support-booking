
module CourtDaysUtils

  def back_to_court_days( court = nil)
    collect_court_days( court || current_user.court, no_params: true)
    render "court_days/index"
  end

  # collects data for the <tt>court_days/index</tt> page
  def collect_court_days( court, options = {})
    options[ :session_prefix] = "court_days"
    @page_mode = persistent_param( :mode, options.merge( { default: :weeks})
      ) do |mode|
        mode = given = mode.intern
        unless :weeks == mode
          case params[ :commit]
          when t( "court_days.submit.cancelled")   then mode = :cancelled
          when t( "court_days.submit.underbooked") then mode = :underbooked
          end
        end
        given == mode ? mode : [ mode, mode.to_s]
      end
    @monday = persistent_param(
        :monday, options.merge( { default: Date.today.iso8601})
      ) do |date|
        date = given = Date.parse( date)
        unless options[ :no_params]
          case params[ :commit]
          when VALUE_LAST_WEEK then date -= 7
          when VALUE_NEXT_WEEK then date += 7
          end
        end
        converted = CourtDay.monday( date)
        given == converted ? given : [ converted, converted.iso8601]
      end
    @start_date = persistent_param(
        :start_date,
        options.merge( { default: Date.civil( Date.today.cwyear - 1).iso8601})
      ) do |date|
        date = Date.parse( date)
        today = Date.today
        if date >= today
          date = today - 1
          [ date, date.iso8601]
        else
          date
        end
      end
    @end_date = persistent_param(
        :end_date,
        options.merge( { default: ( ( @start_date >> 12) - 1).iso8601})
      ){ |date| Date.parse( date)}
    options = {}
    if :weeks == @page_mode
      start_date = @monday
    else
      start_date = @start_date
      options[ :end_date] = @end_date
    end
    @court_days = CourtDay.page( court, @page_mode, start_date, options
      ) do |mode, count, extra|
        case mode
        when :cancelled
          @cancelled    = count
          @late_cancels = extra
        when :underbooked
          @underbooked = count
          @unbooked    = extra
        end
      end
    @title = t( "court_days.index.title.#{ @page_mode}")
    @disabled_count = admin? ? User.disabled_count( !master? && court) : 0
  end
end

