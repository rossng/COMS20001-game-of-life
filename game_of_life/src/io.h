#include "io_interfaces.h"
#include "i2c.h"

#ifndef EXPORT_H_
#define EXPORT_H_

void io(
        server interface i_io_worker workers[n], unsigned n,
        server interface i_io_control control
        );

void pauser(
        server interface i_pauser_worker workers[n], unsigned n,
        server interface i_pauser_control control
        );

void accelerometer(
        client interface i2c_master_if i2c,
        client interface i_pauser_control pause
        );

#endif /* EXPORT_H_ */
