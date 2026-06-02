#include "weather_db.h"


bool MOON_TIMECHECK() {
    switch(time_info.day) {
        case 20:
            return time_info.hours >= 21;
        case 21:
            return time_info.hours < 4 || time_info.hours >= 21;
        case 22:
            return time_info.hours < 4;
    }
    return false;
}
