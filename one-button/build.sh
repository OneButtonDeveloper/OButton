echo ">>> Removing build directory"
rm -rf build

echo ">>> Creating build directory"
mkdir build

echo ">>> Merging background scripts into one file"
for f in src/coffee/background/*.coffee; do (cat "${f}"; echo) >> build/background.coffee; done

echo ">>> Merging content scripts into one file"
for f in src/coffee/content/*.coffee; do (cat "${f}"; echo) >> build/content.coffee; done

echo ">>> Compile scripts"
coffee -o src/common/ -c build/

echo ">>> Removing build directory"
rm -rf build

echo ">>> Building handlebars"
handlebars src/handlebars/*.html -f src/common/handlebars.js -e html

echo ">>> Removing output directory"
rm -rf output

echo ">>> Building extension"
python ../kango-framework-latest/kango.py build ./
