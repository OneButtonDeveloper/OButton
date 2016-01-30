import re
import os
import shutil
import collections
from os import path
from subprocess import call


class Directories:
    def __init__(self):
        pass

    BUILD = "build"
    CONTENT = "content"
    BUILD_CONTENT = path.join(BUILD, CONTENT)
    BACKGROUND = "background"
    BUILD_BACKGROUND = path.join(BUILD, BACKGROUND)
    HTML = ["html", "handlebars", "hb"]
    LIBS = ["libs"]
    CODE = ["src"]
    COFFEE = ["coffeeScript", "coffee"]
    TYPE_SCRIPT = ["typeScript", "ts"]
    STYLES = ["css", "less"]
    RESOURCES = ["res", "asserts", "raw"]
    PROJECT_FOLDERS = HTML + CODE + COFFEE + TYPE_SCRIPT + STYLES + RESOURCES + LIBS


class FileExtensions:
    def __init__(self):
        pass

    TEMPLATES = ["html", "handlebars", "hb"]


class FileName:
    def __init__(self):
        pass

    TEMPLATE = "__handlebars"
    TEMPLATE_EXT = ".js"
    TEMPLATE_NAME = TEMPLATE + TEMPLATE_EXT


def remove_build_path(my_path):
    return re.sub('^' + Directories.BUILD, '', my_path)


def get_files_in_folder(my_path, pattern):
    p = re.compile(pattern)
    return [(my_path + '/' + f) for f in os.listdir(my_path) if path.isfile(path.join(my_path, f)) and p.match(f)]


def get_files_recursive(my_path, pattern):
    p = re.compile(pattern)
    files = []
    for (dir_path, dir_names, file_names) in os.walk(my_path):
        for file_name in file_names:
            if p.match(file_name):
                files.append(file_name)
    return files


def delete_files(files):
    for file_name in files:
        if path.exists(file_name):
            os.remove(file_name)


def delete_files_recursive(my_path, pattern):
    p = re.compile(pattern)
    files = []
    for (dir_path, dir_names, file_names) in os.walk(my_path):
        for file_name in file_names:
            if p.match(file_name):
                files.append(path.join(dir_path, file_name))
    delete_files(files)


def find_files_recursive(my_path, pattern):
    p = re.compile(pattern)
    files = []
    for (dir_path, dir_names, file_names) in os.walk(my_path):
        for file_name in file_names:
            if p.match(file_name):
                files.append(path.join(dir_path, file_name))
    return files


def files_by_name_without_ext(my_path, name):
    files = []
    for (dir_path, dir_names, file_names) in os.walk(my_path):
        for file_name in file_names:
            if path.splitext(file_name)[0] == name:
                files.append(path.join(dir_path, file_name))
    return files


def file_ext(file_name):
    file_name, file_extension = os.path.splitext(file_name)
    if file_extension:
        file_extension = re.sub('^\.', '', file_extension)
    return file_extension


def file_ext_in(file_name, extensions):
    return file_ext(file_name) in extensions


def concat_files(output_path, file_names, remove=True):
    if not file_names:
        return

    with open(output_path, 'w') as outfile:
        for file_name in file_names:
            if path.exists(file_name):
                with open(file_name) as infile:
                    for line in infile:
                        outfile.write(line)
                outfile.write("\n")

    if remove:
        delete_files(file_names)


def concat_files_in_directory(output_path, directory, file_names, remove=True):
    full_file_names = [path.join(directory, file_name) for file_name in file_names]
    concat_files(output_path, full_file_names, remove)


def create_directory(path_to_directory):
    if not path.exists(path_to_directory):
        os.makedirs(path_to_directory)


def delete_directory(path_to_directory):
    if path.exists(path_to_directory):
        shutil.rmtree(path_to_directory)


def delete_directories(path_to_directory, directories):
    for d in directories:
        delete_directory(path.join(path_to_directory, d))


def create_build_directory():
    delete_directory(Directories.BUILD)
    create_directory(Directories.BUILD)
    shutil.copytree(Directories.BACKGROUND, Directories.BUILD_BACKGROUND)
    shutil.copytree(Directories.CONTENT, Directories.BUILD_CONTENT)


def get_directories_from(directory):
    return [f for f in os.listdir(directory) if path.isdir(path.join(directory, f))]


def get_module_directories():
    dirs = set(get_directories_from(Directories.BUILD_CONTENT)) - set(Directories.PROJECT_FOLDERS)
    return [path.join(Directories.BUILD_CONTENT, d) for d in dirs]


def compile_html(module_directory):
    try:

        templates_re = ".*\.(" + ('|'.join(map(str, FileExtensions.TEMPLATES))) + ")$"
        html_files = get_files_recursive(module_directory, templates_re)
        html_file_names = [path.splitext(f)[0] for f in html_files]

        duplicates = [item for item, count in collections.Counter(html_file_names).items() if count > 1]
        if duplicates:
            msg = "All html-files must have unique names to make possible to use them like templates"
            for file_name in duplicates:
                duplicates_path = [remove_build_path(f) for f in files_by_name_without_ext(module_directory, file_name)]
                msg += "\n\tConflict in '" + file_name + "'"
                msg += "\tFiles: " + duplicates_path.__str__()
            raise NameError(msg)

        if not html_file_names:
            return True

        new_file_names = []
        html_file_extensions = set([path.splitext(f)[1] for f in html_files])
        for ext in FileExtensions.TEMPLATES:
            if "." + ext in html_file_extensions:
                new_file_name = FileName.TEMPLATE + "." + ext + FileName.TEMPLATE_EXT
                path_to = path.join(module_directory, new_file_name)
                if path.exists(path_to):
                    raise NameError("Don't use " + new_file_name + " in file names. Name is reserved.")
                call("handlebars " + module_directory + " -f " + path_to + " -e " + ext, shell=True)
                new_file_names.append(new_file_name)

        delete_directories(module_directory, Directories.HTML)
        delete_files_recursive(module_directory, templates_re)

        new_path = path.join(module_directory, FileName.TEMPLATE_NAME)
        if path.exists(new_path):
            raise NameError("Don't use " + FileName.TEMPLATE_NAME + " in file names. Name is reserved.")
        concat_files_in_directory(new_path, module_directory, new_file_names)

    except NameError as e:
        print("ERROR: " + e.message)
        return False

    return True


def run():
    print "\n\n"
    create_build_directory()

    module_directories = get_module_directories()
    for module_directory in module_directories:
        if not compile_html(module_directory):
            return False

    if not compile_html(Directories.BUILD_CONTENT):
        return False

    print module_directories

    return 0


run()
