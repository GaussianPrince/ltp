#!/bin/sh
# Copyright (c) 2014 Oracle and/or its affiliates. All Rights Reserved.
# Copyright (c) International Business Machines  Corp., 2000
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it would be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc.,  51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#  PURPOSE: Copy files from server to client using the sendfile()
#           function.
#
#
#  SETUP: The home directory of root on the machine exported as "RHOST"
#         MUST have a ".rhosts" file with the hostname of the client
#         machine, where the test is executed.
#
#  HISTORY:
#    06/09/2003 Manoj Iyer manjo@mail.utexas.edu
#    - Modified to use LTP APIs, and added check to if commands used in test
#    exists.
#    03/01 Robbie Williamson (robbiew@us.ibm.com)
#      -Ported
#
#
#***********************************************************************

TST_TOTAL=1
TCID="sendfile01"
TST_CLEANUP=do_cleanup

do_setup()
{
	TCdat=${TCdat:-$LTPROOT/testcases/bin/datafiles}

	CLIENT="testsf_c${TST_IPV6}"
	SERVER="testsf_s${TST_IPV6}"

	FILES=${FILES:-"ascii.sm ascii.med ascii.lg ascii.jmb"}

	tst_require_cmds diff stat

	tst_tmpdir
}

do_test()
{
	tst_resm TINFO "Doing $0."

	local ipv="ipv${TST_IPV6:-"4"}"
	local ipaddr=$(tst_ipaddr rhost)
	local port=$(tst_rhost_run -s -c "tst_get_unused_port $ipv stream")
	[ -z "$port" ] && tst_brkm TBROK "failed to get unused port"

	tst_rhost_run -s -b -c "$SERVER $ipaddr $port"
	server_started=1
	sleep 10

	for clnt_fname in $FILES; do
		serv_fname=${TCdat}/$clnt_fname
		local size=$(stat -c '%s' $serv_fname)

		tst_resm TINFO \
			"$CLIENT ip '$ipaddr' port '$port' file '$clnt_fname'"

		$CLIENT $ipaddr $port $clnt_fname $serv_fname $size >\
			/dev/null 2>&1

		local ret=$?
		if [ $ret -ne 0 ]; then
			tst_resm TFAIL "$CLIENT returned error '$ret'"
			return;
		fi

		diff $serv_fname $clnt_fname > /dev/null 2>&1
		local diff_res=$?
		if [ $diff_res -gt 1 ]; then
			tst_resm TFAIL "ERROR: Cannot compare files"
			return
		fi

		if [ $diff_res -eq 1 ]; then
			tst_resm TFAIL "The file copied differs from the original"
			return
		fi
	done
	tst_resm TPASS "test finished successfully"
}

do_cleanup()
{
	[ -n "$server_started" ] && tst_rhost_run -s -c "pkill $SERVER"
	tst_rmdir
}

TST_USE_LEGACY_API=1
. tst_net.sh

do_setup
do_test

tst_exit
