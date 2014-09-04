rm -rf build

#~/Bin/dart/dart-sdk/bin/pub build --mode debug
~/Bin/dart/dart-sdk/bin/pub build

rm build/web/*.dart.js

rm -rf dist
mkdir dist

cp -R web/images dist/
cp build/web/*.html dist/
cp build/web/*.precompiled.js dist/
cp build/web/*.js dist/
cp build/web/manifest.json dist/
mkdir -p dist/packages/chrome/
install packages/chrome/bootstrap.js dist/packages/chrome/