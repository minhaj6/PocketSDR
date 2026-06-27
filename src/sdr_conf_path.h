//
//  sdr_conf_path.h -- config file path discovery for PocketSDR tools
//
//  A config name that contains '/' is treated as an explicit path and used
//  as-is (preserves existing usage like "../conf/pocket_L1L5_24MHz.conf").
//  A bare name is searched, most specific first:
//
//      1. ~/.config/pocketsdr/                  (user configs)
//      2. /usr/local/share/pocketsdr/conf/      (system presets, see install.sh)
//
#ifndef SDR_CONF_PATH_H
#define SDR_CONF_PATH_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <limits.h>

#ifndef POCKETSDR_CONF_SYS
#define POCKETSDR_CONF_SYS "/usr/local/share/pocketsdr/conf"
#endif
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif
#ifndef NAME_MAX
#define NAME_MAX 255
#endif

// buffer big enough to hold "<dir>/<name>" without truncation
#define SDR_CONF_PATHBUF (PATH_MAX + NAME_MAX + 2)

// user config dir: $XDG_CONFIG_HOME/pocketsdr, else ~/.config/pocketsdr ----------
static void sdr_conf_userdir(char *buf, size_t size)
{
    const char *xdg = getenv("XDG_CONFIG_HOME");
    const char *home = getenv("HOME");
    if (xdg && *xdg) {
        snprintf(buf, size, "%s/pocketsdr", xdg);
    } else if (home && *home) {
        snprintf(buf, size, "%s/.config/pocketsdr", home);
    } else {
        buf[0] = '\0';
    }
}

// resolve a config name to a path ------------------------------------------------
//  returns a static buffer, or the original name if not found (so the caller's
//  own "file not found" error still fires).
static const char *sdr_conf_resolve(const char *name)
{
    static char path[SDR_CONF_PATHBUF];
    char dir[PATH_MAX];

    if (!name || !*name) return name;
    if (strchr(name, '/')) return name;            // explicit path: use as-is

    sdr_conf_userdir(dir, sizeof(dir));
    if (*dir) {
        snprintf(path, sizeof(path), "%s/%s", dir, name);
        if (access(path, R_OK) == 0) return path;
    }
    snprintf(path, sizeof(path), "%s/%s", POCKETSDR_CONF_SYS, name);
    if (access(path, R_OK) == 0) return path;

    return name;                                   // not found; let caller report
}

// list available configs (user dir then system, de-duplicated) -------------------
static void sdr_conf_list(void)
{
    static char seen[256][NAME_MAX + 1];
    int nseen = 0;
    char userdir[PATH_MAX];
    sdr_conf_userdir(userdir, sizeof(userdir));

    const char *dirs[2] = {userdir, POCKETSDR_CONF_SYS};
    const char *tags[2] = {"user", "system"};

    for (int d = 0; d < 2; d++) {
        if (!*dirs[d]) continue;
        DIR *dp = opendir(dirs[d]);
        if (!dp) continue;
        struct dirent *e;
        while ((e = readdir(dp))) {
            const char *n = e->d_name;
            size_t len = strlen(n);
            if (len < 6 || strcmp(n + len - 5, ".conf")) continue;  // *.conf only
            int dup = 0;
            for (int k = 0; k < nseen; k++)
                if (!strcmp(seen[k], n)) { dup = 1; break; }
            if (dup) continue;                                      // user shadows system
            if (nseen < 256) snprintf(seen[nseen++], NAME_MAX + 1, "%s", n);
            printf("  %-40s [%s]\n", n, tags[d]);
        }
        closedir(dp);
    }
    if (nseen == 0) printf("  (no configs found)\n");
}

// show where a config name resolves and which tier it came from ------------------
static void sdr_conf_show(const char *name)
{
    char dir[PATH_MAX], path[SDR_CONF_PATHBUF];

    if (!name || !*name) { printf("usage: --show <name>\n"); return; }
    if (strchr(name, '/')) {
        printf("%s  [explicit path]%s\n", name,
            (access(name, R_OK) == 0) ? "" : "  (NOT FOUND)");
        return;
    }
    sdr_conf_userdir(dir, sizeof(dir));
    if (*dir) {
        snprintf(path, sizeof(path), "%s/%s", dir, name);
        if (access(path, R_OK) == 0) { printf("%s  [user]\n", path); return; }
    }
    snprintf(path, sizeof(path), "%s/%s", POCKETSDR_CONF_SYS, name);
    if (access(path, R_OK) == 0) { printf("%s  [system]\n", path); return; }

    printf("%s: not found in ~/.config/pocketsdr or %s\n", name, POCKETSDR_CONF_SYS);
}

#endif // SDR_CONF_PATH_H
