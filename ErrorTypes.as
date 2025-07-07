/*
* Possible exceptions that may happen when using APIs from LeaderboardServices namespace.
*/
enum ErrorTypes {
    OK                          = -1,
    NO_RECORDS                  = -2,
    PLAYER_COUNT_IS_NULL        = -3,
    BAD_RESPONSE                = -4,
    FAILED_LEADERBOARDS         = -5,
    RANKTARGET_LIMIT_EXCEEDED   = -6,
    NONEXISTENT_MAP             = -7,
}