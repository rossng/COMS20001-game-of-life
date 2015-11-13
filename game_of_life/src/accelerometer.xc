#include <xs1.h>
#include <stdio.h>
#include "i2c.h"
#include <xscope.h>
#include "accelerometer_defs.h"

int read_acceleration(client interface i2c_master_if i2c, int reg) {
    i2c_regop_res_t result;
    int accel_val = 0;
    unsigned char data = 0;

    // Read MSB data
    data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, reg, result);
    if (result != I2C_REGOP_SUCCESS) {
        printf("I2C read reg failed\n");
        return 0;
    }

    accel_val = data << 2;
    // Read LSB data
    data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, reg+1, result);
    if (result != I2C_REGOP_SUCCESS) {
        printf("I2C read reg failed\n");
        return 0;
    }

    accel_val |= (data >> 6);

    if (accel_val & 0x200) {
        accel_val -= 1023;
    }
    return accel_val;
}
