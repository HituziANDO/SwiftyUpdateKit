#!/bin/bash

UNCRUSTIFY_VER=0.76.0
SWIFTFORMAT_VER=0.53.7

CF_DIR=.codeformat
TMP_DIR=tmp

echo_info() {
	ESC=$(printf '\033')
	echo -e "${ESC}[36m$1${ESC}[m"
}

echo_err() {
	ESC=$(printf '\033')
	echo -e "${ESC}[31m$1${ESC}[m"
}

download_uncrustify() {
	local arch="$1"
	echo_info "arch=$arch"
	echo_info "$(cmake --version)"

	git clone https://github.com/uncrustify/uncrustify.git
	cd uncrustify
	git checkout uncrustify-$UNCRUSTIFY_VER
	mkdir build
	cd build
	cmake -DCMAKE_OSX_ARCHITECTURES="$arch" -DCMAKE_BUILD_TYPE=Release ..
	make

	cd ../../

	return 0
}

download_swiftformat() {
	echo_info "$(swift -version)"

	git clone https://github.com/nicklockwood/SwiftFormat
	cd SwiftFormat
	git checkout $SWIFTFORMAT_VER
	swift build -c release

	cd ../

	return 0
}

install_tools() {
	if [ -e $CF_DIR ]; then
		rm -rf $CF_DIR
	fi
	mkdir $CF_DIR
	cd $CF_DIR

	mkdir $TMP_DIR
	cd $TMP_DIR

	download_uncrustify "$(uname -m)" || exit 1
	download_swiftformat "$(uname -m)" || exit 1

	# to $CF_DIR/
	cd ../

	# Move uncrustify command
	mv ./$TMP_DIR/uncrustify/build/uncrustify .
	# Move swiftformat command
	mv ./$TMP_DIR/SwiftFormat/.build/release/swiftformat .

	# Check version
	echo_info "Uncrustify=$(./uncrustify --version)"
	echo_info "SwiftFormat=$(./swiftformat -version)"

	# Clean up
	rm -rf $TMP_DIR
}

code_format() {
	echo_info "ObjC code formatting..."
	find . \
	-type d -name "*.framework" -prune \
	-a -type d -not -name "*.framework" \
	-o -type d -name "*.xcframework" -prune \
	-a -type d -not -name "*.xcframework" \
	-o -type d -name "Frameworks" -prune \
	-a -type d -not -name "Frameworks" \
	-o -type d -name "Resources" -prune \
	-a -type d -not -name "Resources" \
	-o -type d -name "Pods" -prune \
	-a -type d -not -name "Pods" \
	-o -type d -name "build" -prune \
	-a -type d -not -name "build" \
	-o -type d -name "vendor" -prune \
	-a -type d -not -name "vendor" \
	-o -type d -name "node_modules" -prune \
	-a -type d -not -name "node_modules" \
	-o -type d -name ".build" -prune \
	-a -type d -not -name ".build" \
	-o -type d -name "Output" -prune \
	-a -type d -not -name "Output" \
	-o -name "*.m" \
	-o -name "*.h" \
	| xargs $(pwd)/.codeformat/uncrustify -c uncrustify-objc.cfg -l OC --no-backup

	echo_info "Swift code formatting..."
	find . \
	-type d -name "*.framework" -prune \
	-a -type d -not -name "*.framework" \
	-o -type d -name "*.xcframework" -prune \
	-a -type d -not -name "*.xcframework" \
	-o -type d -name "Frameworks" -prune \
	-a -type d -not -name "Frameworks" \
	-o -type d -name "Resources" -prune \
	-a -type d -not -name "Resources" \
	-o -type d -name "Pods" -prune \
	-a -type d -not -name "Pods" \
	-o -type d -name "Carthage" -prune \
	-a -type d -not -name "Carthage" \
	-o -type d -name "build" -prune \
	-a -type d -not -name "build" \
	-o -type d -name "vendor" -prune \
	-a -type d -not -name "vendor" \
	-o -type d -name "node_modules" -prune \
	-a -type d -not -name "node_modules" \
	-o -type d -name ".build" -prune \
	-a -type d -not -name ".build" \
	-o -type d -name "Output" -prune \
	-a -type d -not -name "Output" \
	-o -name "*.swift" \
	| xargs $(pwd)/.codeformat/swiftformat
}

OPT1=$1

if [ $OPT1 = "--install" ]; then
	install_tools
elif [ $OPT1 = "--fix" ]; then
	code_format
else
	echo_err "Please add --install or --fix options."
fi
