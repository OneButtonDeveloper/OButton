import sys
import re
from os import path
from subprocess import call


class CompileCommand:
    def __init__(self):
        pass

    @staticmethod
    def coffee(module_directory):
        bin_path = path.join("node_modules", "coffee-script", "bin", "coffee")
        return "%s -b -c %s" % (bin_path, module_directory)

    @staticmethod
    def webpack(params, args=[]):
        bin_path = path.join("node_modules", "webpack", "bin", "webpack.js")
        result = []
        if params:
            result.append(params)
        result.append(bin_path)
        if args:
            result.append(" ".join(args))
        return " ".join(result)


class WebPackParam:
    BUILD_TYPE = 'BUILD_TYPE'
    DEVELOPMENT = ['-d', '-dev', '--develop', '--development']
    PRODUCTION = ['-p', '-prod', '--product', '--production']
    BUILD_TYPE_VALUES = DEVELOPMENT + PRODUCTION

    MODULE_NAME = 'MODULE_NAME'

    def __init__(self):
        self.params = {}

    def set_param(self, key, value):
        self.params[key] = value

    def join(self):
        return " ".join([(key + "=" + self.params[key]) for key in self.params.keys()])


def run():
    sys.argv.pop(0)
    args = sys.argv
    params = WebPackParam()
    if [arg for arg in WebPackParam.DEVELOPMENT if arg in args]:
        params.set_param(WebPackParam.BUILD_TYPE, 'development')
        er = '--display-error-details'  # --display-modules --display-reasons
        if er not in args:
            args.append(er)
    if [arg for arg in WebPackParam.PRODUCTION if arg in args]:
        params.set_param(WebPackParam.BUILD_TYPE, 'production')

    args = [arg for arg in args if arg not in WebPackParam.BUILD_TYPE_VALUES]

    module_arg = ""
    for arg in args:
        if re.compile('^[^-].+$').match(arg):
            params.set_param(WebPackParam.MODULE_NAME, arg)
            module_arg = arg
            break
    if module_arg:
        args.remove(module_arg)

    call('clear', shell=True)
    call(CompileCommand.coffee("webpack.config.coffee"), shell=True)
    compileCommand = CompileCommand.webpack(params.join(), args)
    print compileCommand
    call(compileCommand, shell=True)


run()
