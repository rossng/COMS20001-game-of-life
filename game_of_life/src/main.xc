#include <stdio.h>
#include <print.h>
#include <xs1.h>
#include <platform.h>
#include <timer.h>
#include "i2c.h"
#include "io.h"
#include "game_of_life.h"
#include "accelerometer_defs.h"

// buttons port
on tile[0] : in port buttons_port = XS1_PORT_4E;

// accelerometer ports
on tile[1]: port p_scl = XS1_PORT_1E;
on tile[1]: port p_sda = XS1_PORT_1F;

void button_listener(in port buttons, client interface i_io_control io) {

    int buttons_value;

    while(1) {
        buttons when pinseq(15) :> buttons_value;
        buttons when pinsneq(15) :> buttons_value;

        if (buttons_value == 14) {
            io.start_export();
        } else if (buttons_value == 13) {
            io.start_import();
        }
    }
}

int main(void) {
    i2c_master_if i2c[1];

    streaming chan c[8];
    interface i_printer_worker r[5];
    interface i_io_worker io_w[5];
    interface i_io_control io_c;
    interface i_pauser_worker p[5];
    interface i_pauser_control p_c;

     /*
      *           <-0- <-2- <-4- <-6-
      * workers: 0    1    2    3    4
      *           -1-> -3-> -5-> -7->
      */

    par {
        on tile[0]:     printer(r, 5);
        on tile[0]:     io(io_w, 5, io_c);
        on tile[1] :    i2c_master(i2c, 1, p_scl, p_sda, 10);
        on tile[1]:     accelerometer(i2c[0], p_c);
        on tile[1]:     pauser(p, 5, p_c);
        on tile[0]:     button_listener(buttons_port, io_c);

        on tile[0]:     worker(0, null, null, c[0], c[1], r[0], io_w[0], p[0]); // worker 0
        on tile[0]:     worker(1, c[1], c[0], c[2], c[3], r[1], io_w[1], p[1]); // worker 1
        on tile[0]:     worker(2, c[3], c[2], c[4], c[5], r[2], io_w[2], p[2]); // worker 2
        on tile[1]:     worker(3, c[5], c[4], c[6], c[7], r[3], io_w[3], p[3]); // worker 3
        on tile[1]:     worker(4, c[7], c[6], null, null, r[4], io_w[4], p[4]); // worker 4
    }
    return 0;
}
