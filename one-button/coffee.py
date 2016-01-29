import re
import os
import shutil
import collections
from os import path
from subprocess import call

BUILD_DIRECTORY_NAME = "build"


def remove_build_path(my_path):
    return re.sub('^' + BUILD_DIRECTORY_NAME, '', my_path)


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
                files.append(path.join(dir_path, file_name));
    return files


def find_files_by_name(my_path, name):
    files = []
    for (dir_path, dir_names, file_names) in os.walk(my_path):
        for file_name in file_names:
            if file_name == name:
                files.append(path.join(dir_path, file_name))
    return files


def create_folder(path_to_folder):
    if not path.exists(path_to_folder):
        os.makedirs(path_to_folder)


def delete_folder(path_to_folder):
    if path.exists(path_to_folder):
        shutil.rmtree(path_to_folder)


def create_build_folder():
    delete_folder(BUILD_DIRECTORY_NAME)
    create_folder(BUILD_DIRECTORY_NAME)


def file_ext(file_name):
    file_name, file_extension = os.path.splitext(file_name)
    if file_extension:
        file_extension = re.sub('^\.', '', file_extension)
    return file_extension


def file_ext_in(file_name, extensions):
    return file_ext(file_name) in extensions


def concat_files(output_path, file_names, remove = True):
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


def concat_files_in_directory(output_path, directory, file_names, remove = True):
    full_file_names = [path.join(directory, file_name) for file_name in file_names]
    concat_files(output_path, full_file_names, remove)


def run():
    print "\n\n"
    create_build_folder()
    shutil.copytree("background", path.join(BUILD_DIRECTORY_NAME, "background"))
    shutil.copytree("content", path.join(BUILD_DIRECTORY_NAME, "content"))

    try:

        template_extensions = ['html', 'handlebars']
        templates_re = ".*\.(" + ('|'.join(map(str, template_extensions))) + ")$"

        html_file_names = [path.splitext(f)[0] for f in get_files_recursive(BUILD_DIRECTORY_NAME, templates_re)]

        duplicates = [item for item, count in collections.Counter(html_file_names).items() if count > 1]

        if duplicates:
            print "ERROR! All html-files must have unique names to make possible to use them like Handlebars templates"
            for file_name in duplicates:
                print "Check conflict: ", file_name
                print "Files: ", [remove_build_path(f) for f in find_files_by_name(BUILD_DIRECTORY_NAME, file_name)]
            return False

        html_directories = []
        for (dir_path, dir_names, file_names) in os.walk(BUILD_DIRECTORY_NAME):
            if path.basename(path.normpath(dir_path)) in template_extensions and dir_path not in html_directories:
                html_directories.append(dir_path)

        for html_dir in html_directories:
            files = find_files_recursive(html_dir, templates_re)
            new_path = path.dirname(html_dir)
            for file_name in files:
                shutil.move(file_name, path.join(new_path, path.basename(file_name)))
            delete_folder(html_dir)

        directories_with_template_files = set()

        for ext in template_extensions:
            directories_with_html_files = []
            for (dir_path, dir_names, file_names) in os.walk(BUILD_DIRECTORY_NAME):
                if dir_path in directories_with_html_files:
                    continue
                for file_name in file_names:
                    if dir_path in directories_with_html_files:
                        break
                    if file_ext(file_name) == ext:
                        directories_with_html_files.append(dir_path)

            if directories_with_html_files:
                directories_with_template_files.update(directories_with_html_files)

                for directory in directories_with_html_files:
                    path_from = path.join(directory, "*." + ext)
                    new_file_name = "__handlebars." + ext + ".js"
                    path_to = path.join(directory, new_file_name)
                    if path.exists(path_to):
                        raise NameError("Don't use " + new_file_name + " in file names. Name is reserved.")
                    compile_templates_command = "handlebars " + path_from + " -f " + path_to + " -e " + ext
                    call(compile_templates_command, shell=True)

        delete_files_recursive(BUILD_DIRECTORY_NAME, templates_re)

        file_names_to_merge = ["__handlebars." + ext + ".js" for ext in template_extensions]

        for directory_with_templates in directories_with_template_files:
            new_path = path.join(directory_with_templates, "__handlebars.js")
            print new_path
            if path.exists(new_path):
                raise NameError("Don't use __handlebars.js in file names. Name is reserved.")
            concat_files_in_directory(new_path,  directory_with_templates, file_names_to_merge)

    except NameError as e:
        print("ERROR: " + e.message)
        return False

    return True


run()
