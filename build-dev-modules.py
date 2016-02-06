import sys
from subprocess import call


def call_buid(args=[]):
    args.pop(0)
    args_def = ['--display-error-details', '--display-modules', '--display-reasons']
    for arg in args_def:
        if arg not in args:
            args.append(arg)
    call("python build.py -d " + " ".join(args), shell=True)


call_buid(sys.argv)
