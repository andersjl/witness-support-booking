module ValidateWithinOneCourt
  def within_one_court
    return unless user && court_session  # handled by other validations
    if user.court != court_session.court
      errors.add(
        :base, I18n.t(
          "booking.error.court_mismatch",
          user: user.inspect,
          court_session: court_session.inspect,
        ),
      )
    end
  end
end

