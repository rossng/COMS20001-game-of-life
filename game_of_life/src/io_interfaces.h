#ifndef IO_INTERFACES_H_
#define IO_INTERFACES_H_

interface i_io_worker {
    [[notification]] slave void trigger_export();
    [[clears_notification]] int get_round_to_export_at();

    void report_round(int round);
};

interface i_io_control {
    void start_export();
    void start_import();
};

interface i_pauser_worker {
    [[notification]] slave void pause_work();
    [[clears_notification]] int still_paused();
};

#endif /* IO_INTERFACES_H_ */
