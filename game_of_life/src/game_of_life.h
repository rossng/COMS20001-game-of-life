#include "io_interfaces.h"
#include "game_of_life_interfaces.h"

#ifndef GAME_OF_LIFE_H_
#define GAME_OF_LIFE_H_

void printer(server interface i_printer_worker workers[n], unsigned n);

void worker(
        int id,
        streaming chanend ?lin, streaming chanend ?lout,
        streaming chanend ?rin, streaming chanend ?rout,
        client interface i_printer_worker printer,
        client interface i_io_worker io,
        client interface i_pauser_worker pauser
);

#endif /* GAME_OF_LIFE_H_ */
