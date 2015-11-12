#include <stdio.h>
#include <print.h>
#include <xs1.h>
#include <platform.h>
#include <timer.h>

on tile[0] : in port buttons_port = XS1_PORT_4E;

interface cell_to_printer {
    void print_cell(int cell_number, int round);
};

interface cell_to_export_controller {
    [[notification]] slave void trigger_export();
    [[clears_notification]] int get_round_to_export_at();

    void report_round(int round);
};

interface cell_to_pause_controller {
    [[notification]] slave void pause_work();
    [[clears_notification]] int still_paused();
};

interface button_listener_to_export_controller {
    void button_pressed(int button);
};

void button_listener(in port buttons,
        client interface button_listener_to_export_controller export_controller
        ) {

    int buttons_value;

    while(1) {
        buttons when pinseq(15) :> buttons_value;
        buttons when pinsneq(15) :> buttons_value;

        if (buttons_value == 14) {
            export_controller.button_pressed(1);
        } else if (buttons_value == 13) {
            export_controller.button_pressed(2);
        }
    }
}

void pause_controller(server interface cell_to_pause_controller cells[n], unsigned n) {
    while(1){}
    delay_milliseconds(200);

    for(int cell_number = 0; cell_number < n; cell_number++) {
        cells[cell_number].pause_work();
    }

    while(1) {
        select {
            case cells[int i].still_paused() -> int still_paused:
                    still_paused = 1;
                    break;
        }
    }

}

void export_controller(server interface cell_to_export_controller cells[n], unsigned n,
        server interface button_listener_to_export_controller button_listener) {
    if (n > 50) {
        fprintf(stderr, "Cannot handle more than 50 cells.\n");
        return;
    }

    int highest_reported_round = 0;
    int stopped_on_round = -1;

    while(1) {
        select {
            case button_listener.button_pressed(int button):
                if (button == 1) {
                    stopped_on_round = highest_reported_round + 1;
                    for(int cell_number = 0; cell_number < n; cell_number++) {
                        cells[cell_number].trigger_export();
                    }
                }
                break;
            case cells[int i].report_round(int round):
                    if (round > highest_reported_round) {
                        highest_reported_round = round;
                        printf("Cell %d reported round: %d\n", i, round);
                    }
                    break;
            case cells[int i].get_round_to_export_at() -> int round:
                    round = stopped_on_round;
                    break;
        }
    }
}

void printer(server interface cell_to_printer cells[n], unsigned n) {
    if (n > 5) {
        fprintf(stderr, "Cannot handle more than 5 cells.\n");
        return;
    }

    int current_state[5] = {0};

    while(1) {
        select {
            case cells[int i].print_cell(int cell_number, int round):
                current_state[cell_number] = round;

                printf("|%d|%d|%d|%d|%d|\n", current_state[0], current_state[1], current_state[2], current_state[3], current_state[4]);
                break;
        }
    }
}

void cell(int cell_number,
          streaming chanend ?lin, streaming chanend ?lout,
          streaming chanend ?rin, streaming chanend ?rout,
          client interface cell_to_printer printer,
          client interface cell_to_export_controller export_controller,
          client interface cell_to_pause_controller pause_controller
) {
    int round = 0;
    int max_round = -1;
    int paused = 0;

        while (1) {
            export_controller.report_round(round);
            printer.print_cell(cell_number, round);

            select {
                case pause_controller.pause_work():
                    paused = 1;
                    printf("Cell %d paused\n", cell_number);
                    break;
                case export_controller.trigger_export():
                    max_round = export_controller.get_round_to_export_at();
                    break;
                default:
                    break;
            }

            while(paused) {
                delay_milliseconds(500);
                paused = pause_controller.still_paused();
            }

            if (round == max_round) {
                printf("Cell number %d reached max_round: %d\n", cell_number, max_round);
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

int main(void) {
    streaming chan c[8];
    interface cell_to_printer r[5];
    interface cell_to_export_controller s[5];
    interface cell_to_pause_controller p[5];
    interface button_listener_to_export_controller b;
    //input_gpio_if i_buttons[2];

     /*
      *        <-0- <-2- <-4- <-6-
     * cells: 0    1    2    3    4
     *         -1-> -3-> -5-> -7->
     */

    par {
        //on tile[0]:     input_gpio_with_events(i_buttons, 2, buttons_port, null);
        on tile[0]:     printer(r, 5);
        on tile[0]:     export_controller(s, 5, b);
        on tile[1]:     pause_controller(p, 5);
        on tile[0]:     button_listener(buttons_port, b);

        on tile[0]:     cell(0, null, null, c[0], c[1], r[0], s[0], p[0]); // cell 0
        on tile[0]:     cell(1, c[1], c[0], c[2], c[3], r[1], s[1], p[1]); // cell 1
        on tile[0]:     cell(2, c[3], c[2], c[4], c[5], r[2], s[2], p[2]); // cell 2
        on tile[1]:     cell(3, c[5], c[4], c[6], c[7], r[3], s[3], p[3]); // cell 3
        on tile[1]:     cell(4, c[7], c[6], null, null, r[4], s[4], p[4]); // cell 4
    }
    return 0;
}
