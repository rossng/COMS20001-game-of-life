#include <stdio.h>
#include <print.h>
#include <xs1.h>
#include <platform.h>
#include <timer.h>
#include "accelerometer_defs.h"
#include "i2c.h"
#include "io_interfaces.h"
#include "accelerometer.h"

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

void pauser(
        server interface i_pauser_worker workers[n], unsigned n,
        server interface i_pauser_control control
        ) {

    int paused = 0;

    while(1) {
        select {
            case control.pause():
                paused = 1;
                for(int worker_number = 0; worker_number < n; worker_number++) {
                    workers[worker_number].pause_work();
                }
                break;
            case control.unpause():
                paused = 0;
                break;
            case workers[int i].still_paused() -> int still_paused:
                still_paused = paused;
                break;
        }
    }
}

void accelerometer(client interface i2c_master_if i2c, client interface i_pauser_control pause) {
  i2c_regop_res_t result;
  char status_data = 0;
  int tilted = 0, tiltedDelta = 0;

  // Configure FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  // Enable FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  pause.unpause();

  //Probe the accelerometer x-axis forever
  while (1) {

    //check until new accelerometer data is available
    do {
        status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);

    } while (!status_data & 0x08);

    //get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);
    printf("Read acceleration: %d\n", x);

    //send signal to distributor after first tilt
    if (x > 30) {
        tiltedDelta = 1;
    }else{
        tiltedDelta = 0;
    }

    if (tilted != tiltedDelta) { //Only notify when tilt has changed
        tilted = tiltedDelta;
        printf("New tilt %d\n",x);
        printf("Tilt change! now %d\n", tilted);
        if (tilted) {
            pause.pause();
        } else {
            pause.unpause();
        }
    }
  }
}
