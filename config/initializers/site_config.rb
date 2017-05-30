
USER_ROLES = [ "disabled", "normal", "admin", "master"]

# court_days index submit values
VALUE_LAST_WEEK            = "<<"
VALUE_NEXT_WEEK            = ">>"

WEEKS_P_PAGE               = 1
PARALLEL_SESSIONS_MAX      = 5
MORNING_TIME_OF_DAY        = ( 8 * 60 + 15) * 60
AFTERNOON_TIME_OF_DAY      = (12 * 60 + 15) * 60
ALLOW_LATE_BOOKING         = (          45) * 60
START_TIMES_OF_DAY_DEFAULT = [ MORNING_TIME_OF_DAY, AFTERNOON_TIME_OF_DAY]

BOOKING_DAYS_AHEAD_MIN     = 3
BOOKING_DAYS_AHEAD_MAX     = 10
BOOKING_DAYS_REMOVABLE     = 5

WS_DEFINITION_URL = "http://www.brottsoffermyndigheten.se/om-oss/vittnesstod"
OWNER_NAME                 = "Brottsofferjouren Sydost"
OWNER_URL                  = "http://www.farsta.boj.se"
COOKIES_INFO_PTS = "http://www.pts.se/sv/Privat/Internet/Skydd-av-uppgifter" +
                   "/Fragor-och-svar-om-kakor-for-anvandare1/"
