CancelledBooking.find{ |cb| ! CourtSession.find{ |cs| cs.id == cb.court_session_id}}
