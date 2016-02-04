import sys
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
    def webpack(params):
        bin_path = path.join("node_modules", "webpack", "bin", "webpack.js")
        if params:
            return "{} {}".format(params, bin_path)
        else:
            return bin_path


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
    if [arg for arg in WebPackParam.PRODUCTION if arg in args]:
        params.set_param(WebPackParam.BUILD_TYPE, 'production')

    args = [arg for arg in WebPackParam.BUILD_TYPE_VALUES if arg not in args]
    if len(args) == 1:
        params.set_param(WebPackParam.MODULE_NAME, args[0])

    call('clear', shell=True)
    call(CompileCommand.coffee("webpack.config.coffee"), shell=True)
    call(CompileCommand.webpack(params.join()), shell=True)

run()
