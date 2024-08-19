#include "dbat/dg_event.h"
#include "dbat/dg_scripts.h"

std::unordered_set<struct trig_data*> triggers_waiting;
std::deque<struct trig_data*> triggers_queued;

/* Process any events whose time has come. */
void event_process(uint64_t heart_pulse, double deltaTime) {
    // copy the queue to avoid any issues with the queue being modified while we're processing it
    auto queued = triggers_waiting;

    for (auto trig : queued) {
        trig->waiting = std::max<double>(0.0, trig->waiting - deltaTime);
        if(trig->waiting == 0.0) {
            triggers_waiting.erase(trig);
            triggers_queued.push_back(trig);
        }
    }

    int toProcess = 5;
    while(toProcess > 0 && !triggers_queued.empty()) {
        auto trig = triggers_queued.front();
        triggers_queued.pop_front();
        script_driver(trig->owner, trig, trig->attach_type, TRIG_RESTART);
        toProcess--;
    }
}
