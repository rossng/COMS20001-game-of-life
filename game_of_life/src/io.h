#include "io_interfaces.h"

#ifndef EXPORT_H_
#define EXPORT_H_

void io(
        server interface i_io_worker workers[n], unsigned n,
        server interface i_io_control control
        );

void pauser(server interface i_pauser_worker workers[n], unsigned n);

#endif /* EXPORT_H_ */
