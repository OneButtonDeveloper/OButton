import re
import os
import shutil
import collections
from distutils.dir_util import copy_tree
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
    JS = ["js"]
    COFFEE = ["coffee"]
    TYPE_SCRIPT = ["typeScript", "ts"]
    CODE = ["src"] + JS + COFFEE + TYPE_SCRIPT
    STYLES = ["css", "less"]
    RESOURCES = ["res", "asserts", "raw", "values", "strings"]
    PROJECT_FOLDERS = HTML + CODE + COFFEE + TYPE_SCRIPT + STYLES + RESOURCES + LIBS


class FileExtensions:
    def __init__(self):
        pass

    TEMPLATES = ["html", "handlebars", "hb"]
    CSS = "css"
    CSS_STYLES = [CSS]
    LESS = "less"
    LESS_STYLES = [LESS]
    COFFEE = ["coffee"]
    TYPE_SCRIPT = ["typeScript", "ts"]
    JS = ["js"]
    CODE = COFFEE + TYPE_SCRIPT + JS

    @staticmethod
    def find_re(extensions):
        return ".*\.(" + ('|'.join(map(str, extensions))) + ")$"

    META_PATTERN_RE = re.compile(".*\.meta\.js$")


class FileName:
    def __init__(self):
        pass

    TEMPLATE = "__handlebars"
    TEMPLATE_EXT = ".js"
    TEMPLATE_NAME = TEMPLATE + TEMPLATE_EXT

    STYLES_NAME = "__styles.css"


class ModuleSetting:
    def __init__(self):
        pass

    COMMENT = re.compile("^(//+|#+).*")
    SETTING = re.compile("^(//+|#+)(include|require)\s.+")
    SETTING_ERROR = re.compile("^(//+|#+)(includes|required)\s.+")
    INCLUDE_SETTING = re.compile("^(//+|#+)include\s")
    REQUIRE_SETTING = re.compile("^(//+|#+)require\s")


def remove_build_path(my_path):
    return re.sub('^' + Directories.BUILD, '', my_path)


def find_files_in_folder(my_path):
    return [path.join(my_path, f) for f in os.listdir(my_path) if path.isfile(path.join(my_path, f))]


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


def get_file_name(file_name):
    file_name, file_extension = os.path.splitext(file_name)
    return file_name


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
    copy_tree(Directories.BACKGROUND, Directories.BUILD_BACKGROUND)
    copy_tree(Directories.CONTENT, Directories.BUILD_CONTENT)


def get_directories_from(directory):
    return [f for f in os.listdir(directory) if path.isdir(path.join(directory, f))]


def get_module_directories():
    dirs = set(get_directories_from(Directories.BUILD_CONTENT)) - set(Directories.PROJECT_FOLDERS)
    return [path.join(Directories.BUILD_CONTENT, d) for d in dirs]


def compile_html(module_directory):
    html_files = get_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.TEMPLATES))
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

    # move all templates to upper level to skip "folder names in template names"
    template_files = find_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.TEMPLATES))
    for template_file in template_files:
        new_template_file_name = path.join(module_directory, path.basename(template_file))
        shutil.move(template_file, new_template_file_name)

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
    delete_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.TEMPLATES))

    new_path = path.join(module_directory, FileName.TEMPLATE_NAME)
    if path.exists(new_path):
        raise NameError("Don't use " + FileName.TEMPLATE_NAME + " in file names. Name is reserved.")
    concat_files_in_directory(new_path, module_directory, new_file_names)
    return True


def convert_css_to_js(path_to_file):
    if path.exists(path_to_file):
        output_path = path_to_file + ".js"
        delete_files([output_path])
        with open(output_path, 'w') as outfile:
            with open(path_to_file) as infile:
                outfile.write("$(\"head\").prepend(\"<style>\"\n")
                file_str = infile.read()
                outfile.write("+ \"" + file_str.replace("\"", "\\\"").replace("\n", "\"\n+ \"") + "\"\n")
                outfile.write("+ \"</style>\");")

        delete_files([path_to_file])
    else:
        raise IndentationError("Can't find created " + FileName.STYLES_NAME + " file")


def compile_styles(module_directory):
    less_files = find_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.LESS_STYLES))
    if less_files:
        for less_file in less_files:
            path_to = less_file + "." + FileExtensions.CSS
            if path.exists(path_to):
                raise NameError("Don't use " + get_file_name(less_file) + " in css-file names")
            call("lessc " + less_file + " " + path_to, shell=True)
        delete_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.LESS_STYLES))
    style_files = find_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.CSS_STYLES))
    if style_files:
        style_file = path.join(module_directory, FileName.STYLES_NAME)
        if path.exists(style_file):
            raise NameError("Don't use " + FileName.STYLES_NAME + " in css-file names")
        concat_files(style_file, style_files)
        convert_css_to_js(style_file)
    delete_directories(module_directory, Directories.STYLES)
    return True


def read_module_settings(module_directory):
    files_with_code = find_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.CODE))
    settings = []
    for file_with_code in files_with_code:
        settings.extend(read_module_settings_from_file(file_with_code))
    return settings


def read_module_settings_from_file(file_with_code):
    settings = []
    with open(file_with_code) as infile:
        for line in infile:
            s_line = line.replace("\n", "").replace("\r", "").replace("\t", "")
            if ModuleSetting.SETTING.match(s_line):
                settings.append(s_line)
            if ModuleSetting.SETTING_ERROR.match(s_line):
                raise NameError("Check file: {0}. \n Use only 'require' and 'include' keywords".format(file_with_code))
            if s_line and not ModuleSetting.COMMENT.match(s_line):
                break
    return settings


def compile_code(module_directory):
    coffee_files = find_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.COFFEE))
    if coffee_files:
        call("coffee --compile " + module_directory, shell=True)
        delete_files(coffee_files)

    type_script_files = find_files_recursive(module_directory, FileExtensions.find_re(FileExtensions.TYPE_SCRIPT))
    if type_script_files:
        call("tsc " + " ".join(type_script_files), shell=True)
        delete_files(type_script_files)

    # TODO: add sorting that depends on path and file name
    js_files = []
    js_files.extend(get_files_in_folder(module_directory, FileExtensions.find_re(FileExtensions.JS)))
    for code_dir in Directories.CODE:
        code_path = path.join(module_directory, code_dir)
        js_files.extend(find_files_recursive(code_path, FileExtensions.find_re(FileExtensions.JS)))
    if js_files:
        file_name = path.basename(module_directory) + ".gen." + FileExtensions.JS[0]
        module_script = path.join(module_directory, file_name)
        if path.exists(module_script):
            raise NameError("Don't use name " + file_name + " in module")
        concat_files(module_script, js_files)
        delete_directories(module_directory, Directories.CODE)
        return module_script
    return ""


def get_includes_from_settings(settings):
    includes = []
    for setting in settings:
        if ModuleSetting.INCLUDE_SETTING.match(setting):
            includes.append(re.sub(ModuleSetting.INCLUDE_SETTING, "// @include ", setting))
    if not includes:
        includes.append("// @include http://*")
        includes.append("// @include https://*")
        includes.append("// @include about:blank")
    return includes


def get_libs_for_module(module_directory):
    libs = []
    libs.extend(get_libs_for_directory(module_directory))
    libs.extend(get_libs_for_directory(Directories.BUILD_CONTENT))
    return libs


def get_libs_for_directory(module_directory):
    libs = []
    for libs_dir_name in Directories.LIBS:
        libs_dir = path.join(module_directory, libs_dir_name)
        if path.exists(libs_dir):
            libs.append(libs_dir)
    return libs


def remove_content_path(my_path):
    return my_path.replace(path.join(Directories.BUILD_CONTENT, ""), "")


def get_requires_from_settings(libs_dirs, js_file_module, settings):
    requires = []
    for setting in settings:
        if ModuleSetting.REQUIRE_SETTING.match(setting):
            lib_name = re.sub(ModuleSetting.REQUIRE_SETTING, "", setting)
            lib_path = ""
            for lib_dir in libs_dirs:
                lib_files = files_by_name_without_ext(lib_dir, lib_name)
                if lib_files:
                    if len(lib_files) > 1:
                        raise NameError("Duplicate libs with name: " + lib_name)
                    lib_path = lib_files[0]
                    break
            if not lib_path:
                raise NameError("Can't find lib with name: " + lib_name)

            requires.append("// @require " + remove_content_path(lib_path))
    requires.append("// @require " + remove_content_path(js_file_module))
    return requires


def create_user_script_file(libs_dirs, js_file_module, settings=None):
    includes = get_includes_from_settings(settings)
    requires = get_requires_from_settings(libs_dirs, js_file_module, settings)

    metadata_file = path.basename(js_file_module).replace(".js", ".meta.js")
    output_path = path.join(Directories.BUILD_CONTENT, metadata_file)
    if path.exists(output_path):
        raise NameError("Don't use " + metadata_file + " file name in the content folder")
    with open(output_path, 'w') as outfile:
        outfile.write("// ==UserScript==\n")
        for include in includes:
            outfile.write(include + "\n")
        for require in requires:
            outfile.write(require + "\n")
        outfile.write("// ==/UserScript==\n")
    return output_path


def special_sort(my_list):
    p = re.compile("^_+.*")
    first = []
    second = []
    for item in my_list:
        if p.match(item):
            first.append(item)
        else:
            second.append(item)
    first.sort()
    second.sort()
    first.extend(second)
    return first


def run():
    print "\n\n"

    try:

        create_build_directory()

        content_scripts = []
        for module_directory in get_module_directories():
            compile_html(module_directory)
            compile_styles(module_directory)
            settings = read_module_settings(module_directory)
            js_file_module = compile_code(module_directory)
            if js_file_module:
                libs = get_libs_for_module(module_directory)
                content_scripts.append(remove_content_path(create_user_script_file(libs, js_file_module, settings)))

        compile_html(Directories.BUILD_CONTENT)
        compile_styles(Directories.BUILD_CONTENT)

        plain_module_scripts = []
        coffee_pattern_re = re.compile(FileExtensions.find_re(FileExtensions.COFFEE))
        type_script_pattern_re = re.compile(FileExtensions.find_re(FileExtensions.TYPE_SCRIPT))
        js_script_pattern_re = re.compile(FileExtensions.find_re(FileExtensions.JS))

        for module_file in get_files_in_folder(Directories.BUILD_CONTENT, FileExtensions.find_re(FileExtensions.CODE)):
            if FileExtensions.META_PATTERN_RE.match(module_file):
                continue
            settings = read_module_settings_from_file(module_file)
            js_file_module = ""

            if coffee_pattern_re.match(module_file):
                call("coffee --compile " + module_file, shell=True)
                delete_files([module_file])
                js_file_module = re.sub("\.[^.]+$", ".js", module_file)
                if not path.exists(js_file_module):
                    raise RuntimeError("Can't compile file: " + module_file)

            if type_script_pattern_re.match(module_file):
                call("tsc " + module_file, shell=True)
                delete_files([module_file])
                js_file_module = re.sub("\.[^.]+$", ".js", module_file)
                if not path.exists(js_file_module):
                    raise RuntimeError("Can't compile file: " + module_file)

            if js_script_pattern_re.match(module_file):
                js_file_module = module_file

            if js_file_module:
                libs = get_libs_for_directory(Directories.BUILD_CONTENT)
                plain_module_script = remove_content_path(create_user_script_file(libs, js_file_module, settings))
                plain_module_scripts.append(plain_module_script)

        at_the_begin = []
        after_begin = []
        at_the_end = []

        for plain_module in plain_module_scripts:
            if plain_module == "_AtTheBeginning.meta.js":
                at_the_begin.append(plain_module)
                continue
            if plain_module == "_AtTheEnd.meta.js":
                at_the_end.append(plain_module)
                continue
            after_begin.append(plain_module)

        after_begin = special_sort(after_begin)
        content_scripts = special_sort(content_scripts)

        at_the_begin.extend(after_begin)
        at_the_begin.extend(content_scripts)
        at_the_begin.extend(at_the_end)
        content_scripts = at_the_begin

        for content_script in content_scripts:
            if content_script == "background.meta.js":
                raise NameError("Don't use background.js file name for content scripts")

        background_module_js = compile_code(Directories.BUILD_BACKGROUND)
        if not background_module_js:
            raise NameError("Can't build background.js file. Check content of 'background' directory")
        background_js = background_module_js.replace("gen.js", "js")
        os.rename(background_module_js, background_js)

        config = path.join(Directories.BUILD_CONTENT, "config.json")
        shutil.copyfile("config.json", config)
        extension_info = path.join(Directories.BUILD_CONTENT, "extension_info.json")
        with open(extension_info, 'w') as outfile:
            with open(config) as infile:
                file_str = infile.read()
                outfile.write(file_str.replace("%content_scripts%", "\", \"".join(content_scripts)))
        delete_files([config])

        common_path = path.join("src", "common")
        for dir_to_remove in get_directories_from(common_path):
            if dir_to_remove != "icons":
                delete_directory(path.join(common_path, dir_to_remove))

        delete_files(find_files_in_folder(common_path))

        copy_tree(Directories.BUILD_BACKGROUND, common_path)
        copy_tree(Directories.BUILD_CONTENT, common_path)

        call("python ../kango-framework-latest/kango.py build ./", shell=True)

    except NameError as e:
        print("ERROR: " + e.message)
        return False

    return True


run()
