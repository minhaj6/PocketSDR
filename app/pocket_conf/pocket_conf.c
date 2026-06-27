// 
//  Pocket SDR C AP - Pocket SDR FE Device Configurator.
//
//  Author:
//  T.TAKASU
//
//  History:
//  2021-10-20  0.1  new
//  2022-01-04  1.0  support C++.
//  2024-06-29  1.1  support API changes of sdr_conf.c
//
#include "pocket_sdr.h"
#include "sdr_conf_path.h"

// constants and macro ---------------------------------------------------------
#define PROG_NAME       "pocket_conf" // program name

// print version ---------------------------------------------------------------
static void print_ver(void)
{
     printf("%s ver.%s\n", PROG_NAME, sdr_get_ver());
     exit(0);
}

// show usage ------------------------------------------------------------------
static void show_usage(void)
{
    printf("Usage: %s [-s] [-a] [-h] [--list] [--show name] [conf_file]\n", PROG_NAME);
    exit(0);
}

// main (see doc/command_ref.md) -----------------------------------------------
int main(int argc, char **argv)
{
    sdr_dev_t *dev;
    const char *file = "";
    int i, bus = -1, port = -1, opt1 = 0, opt2 = 0;
    
    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-s")) {
            opt1 |= 1;
        } else if (!strcmp(argv[i], "-a")) {
            opt2 |= 1;
        } else if (!strcmp(argv[i], "-h")) {
            opt1 |= 4;
            opt2 |= 4;
        } else if (!strcmp(argv[i], "-p") && i + 1 < argc) {
            sscanf(argv[++i], "%d,%d", &bus, &port);
        } else if (!strcmp(argv[i], "-v")) {
            print_ver();
        } else if (!strcmp(argv[i], "--list")) {
            sdr_conf_list();
            return 0;
        } else if (!strcmp(argv[i], "--show") && i + 1 < argc) {
            sdr_conf_show(argv[++i]);
            return 0;
        } else if (!strncmp(argv[i], "-", 1)) {
            show_usage();
        } else {
            file = sdr_conf_resolve(argv[i]);
        }
    }
    if (!(dev = sdr_dev_open(bus, port))) {
        return -1;
    }
    if (*file) {
        if (!sdr_conf_write(dev, file, opt1)) {
            sdr_dev_close(dev);
            return -1;
        }
        printf("%s device settings are changed%s.\n", SDR_DEV_NAME,
            (opt1 & 1) ? " and saved to EEPROM" : "");
    } else {
        if (!sdr_conf_read(dev, "", opt2)) {
            sdr_dev_close(dev);
            return -1;
        }
    }
    sdr_dev_close(dev);
    return 0;
}
