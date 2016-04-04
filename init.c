/**
  @brief
  @author Michael D. Lowis
  @license BSD 2-clause License
*/
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>

static sigset_t set;
static char* const rcinitcmd[]     = { "/etc/rc.init", 0 };
static char* const rcrebootcmd[]   = { "/etc/rc.shutdown", "reboot", 0 };
static char* const rcpoweroffcmd[] = { "/etc/rc.shutdown", "poweroff", 0 };

static void spawn(char *const argv[]) {
    if (0 == fork()) {
        sigprocmask(SIG_UNBLOCK, &set, NULL);
        setsid();
        execvp(argv[0], argv);
        _exit(1);
    }
}

int main(void) {
    if (getpid() != 1) return 1;
    chdir("/");
    sigfillset(&set);
    sigprocmask(SIG_BLOCK, &set, NULL);
    spawn(rcinitcmd);
    while (1) {
        int sig;
        sigwait(&set, &sig);
        switch (sig) {
            case SIGUSR1: spawn(rcpoweroffcmd); break;
            case SIGINT:  spawn(rcrebootcmd);   break;
            case SIGCHLD:
                while (waitpid(-1, NULL, WNOHANG) > 0);
                break;
        }
    }
    return 0;
}
