#! /bin/sh
## Copyright (C) 2017 Jeremiah Orians
## This file is part of M2-Planet.
##
## M2-Planet is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## M2-Planet is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with M2-Planet.  If not, see <http://www.gnu.org/licenses/>.

set -ex
# Build the test
./bin/M2-Planet --architecture armv7l \
	-f test/common_armv7l/functions/file.c \
	-f test/common_armv7l/functions/malloc.c \
	-f functions/calloc.c \
	-f test/common_armv7l/functions/exit.c \
	-f functions/match.c \
	-f functions/in_set.c \
	-f functions/numerate_number.c \
	-f functions/file_print.c \
	-f functions/number_pack.c \
	-f functions/string.c \
	-f functions/require.c \
	-f cc.h \
	-f cc_reader.c \
	-f cc_strings.c \
	-f cc_types.c \
	-f cc_core.c \
	-f cc.c \
	--debug \
	-o test/test100/cc.M1 || exit 1

# Build debug footer
blood-elf -f test/test100/cc.M1 \
	-o test/test100/cc-footer.M1 || exit 2

# Macro assemble with libc written in M1-Macro
M1 -f test/common_armv7l/armv7l_defs.M1 \
	-f test/common_armv7l/libc-core.M1 \
	-f test/test100/cc.M1 \
	-f test/test100/cc-footer.M1 \
	--LittleEndian \
	--architecture armv7l \
	-o test/test100/cc.hex2 || exit 3

# Resolve all linkages
hex2 -f test/common_armv7l/ELF-armv7l-debug.hex2 \
	-f test/test100/cc.hex2 \
	--LittleEndian \
	--architecture armv7l \
	--BaseAddress 0x10000 \
	-o test/results/test100-armv7l-binary --exec_enable || exit 4

# Ensure binary works if host machine supports test
if [ "$(get_machine ${GET_MACHINE_FLAGS})" = "armv7l" ]
then
	# Verify that the resulting file works
	./test/results/test100-armv7l-binary --architecture x86 \
		-f test/common_x86/functions/file.c \
		-f test/common_x86/functions/malloc.c \
		-f functions/calloc.c \
		-f test/common_x86/functions/exit.c \
		-f functions/match.c \
		-f functions/in_set.c \
		-f functions/numerate_number.c \
		-f functions/file_print.c \
		-f functions/number_pack.c \
		-f functions/string.c \
		-f functions/require.c \
		-f cc.h \
		-f cc_reader.c \
		-f cc_strings.c \
		-f cc_types.c \
		-f cc_core.c \
		-f cc.c \
		-o test/test100/proof || exit 5

	. ./sha256.sh
	out=$(sha256_check test/test100/proof.answer)
	[ "$out" = "test/test100/proof: OK" ] || exit 6
	[ ! -e bin/M2-Planet ] && mv test/results/test100-x86-binary bin/M2-Planet
fi
exit 0
