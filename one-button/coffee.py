import re
from os import listdir
from os.path import isfile, join


def get_files(my_path, pattern):
    p = re.compile(pattern)
    return [(my_path + '/' + f) for f in listdir(my_path) if isfile(join(my_path, f)) and p.match(f)]


def run():
    system_files = [file_name for file_name in get_files("main/coffee/content", "^_.*coffee$")]
    files = [file_name for file_name in get_files("main/coffee/content", "^[^_].*coffee$")]
    files.sort()
    files = system_files + files

    for file_name in files:
        lines_to_analyze = []
        f = open(file_name, 'r')
        line = f.readline()
        print("first line: " + line)
        while line is not None and line.startswith("#"):
            lines_to_analyze.append(line)
            line = f.readline()
        f.close()

        print file_name
        for line in lines_to_analyze:
            print line

    print "This line will be printed."


run()
