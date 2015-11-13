#include <stdio.h>
#include <print.h>
#include <xs1.h>
#include <platform.h>
#include <timer.h>
#include "io_interfaces.h"


void io(server interface i_io_worker workers[n], unsigned n,
        server interface i_io_control control) {

    int highest_reported_round = 0;
    int stopped_on_round = -1;

    while(1) {
        select {
            case control.start_export():
                printf("Exporting...\n");
                stopped_on_round = highest_reported_round + 1;
                for(int worker_number = 0; worker_number < n; worker_number++) {
                    workers[worker_number].trigger_export();
                }
                break;
            case control.start_import():
                printf("Import not yet implemented.\n");
                break;
            case workers[int i].report_round(int round):
                    if (round > highest_reported_round) {
                        highest_reported_round = round;
                        printf("Cell %d reported round: %d\n", i, round);
                    }
                    break;
            case workers[int i].get_round_to_export_at() -> int round:
                    round = stopped_on_round;
                    break;
        }
    }
}

void pauser(server interface i_pauser_worker workers[n], unsigned n) {
    while(1){}
    delay_milliseconds(200);

    for(int worker_number = 0; worker_number < n; worker_number++) {
        workers[worker_number].pause_work();
    }

    while(1) {
        select {
            case workers[int i].still_paused() -> int still_paused:
                    still_paused = 1;
                    break;
        }
    }

}
