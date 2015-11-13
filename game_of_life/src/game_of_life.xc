#include <stdio.h>
#include <print.h>
#include <xs1.h>
#include <platform.h>
#include <timer.h>
#include "io_interfaces.h"
#include "game_of_life_interfaces.h"

void printer(server interface i_printer_worker workers[n], unsigned n) {
    if (n > 5) {
        fprintf(stderr, "Cannot handle more than 5 cells.\n");
        return;
    }

    int current_state[5] = {0};

    while(1) {
        select {
            case workers[int i].update(int worker_number, int round):
                current_state[worker_number] = round;

                printf("|%d|%d|%d|%d|%d|\n", current_state[0], current_state[1], current_state[2], current_state[3], current_state[4]);
                break;
        }
    }
}

void worker(int id,
          streaming chanend ?lin, streaming chanend ?lout,
          streaming chanend ?rin, streaming chanend ?rout,
          client interface i_printer_worker printer,
          client interface i_io_worker io,
          client interface i_pauser_worker pauser
) {
    int round = 0;
    int max_round = -1;
    int paused = 0;

        while (1) {
            io.report_round(round);
            printer.update(id, round);

            select {
                case pauser.pause_work():
                    paused = 1;
                    printf("Cell %d paused\n", id);
                    break;
                case io.trigger_export():
                    max_round = io.get_round_to_export_at();
                    break;
                default:
                    break;
            }

            while(paused) {
                delay_milliseconds(500);
                paused = pauser.still_paused();
            }

            if (round == max_round) {
                printf("Cell number %d reached max_round: %d\n", id, max_round);
            }

            if (!isnull(lout)) {
                lout <: 1;
            }
            if (!isnull(rout)) {
                rout <: 1;
            }
            if (!isnull(lin)) {
                lin :> int temp;
            }
            if (!isnull(rin)) {
                rin :> int temp;
            }

            // update self here

            round++;

        }
}
