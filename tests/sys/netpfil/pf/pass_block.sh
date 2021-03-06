# $FreeBSD$

. $(atf_get_srcdir)/utils.subr

atf_test_case "v4" "cleanup"
v4_head()
{
	atf_set descr 'Basic pass/block test for IPv4'
	atf_set require.user root
}

v4_body()
{
	pft_init

	epair=$(pft_mkepair)
	ifconfig ${epair}a 192.0.2.1/24 up

	# Set up a simple jail with one interface
	pft_mkjail alcatraz ${epair}b
	jexec alcatraz ifconfig ${epair}b 192.0.2.2/24 up

	# Trivial ping to the jail, without pf
	atf_check -s exit:0 -o ignore ping -c 1 -t 1 192.0.2.2

	# pf without policy will let us ping
	jexec alcatraz pfctl -e
	atf_check -s exit:0 -o ignore ping -c 1 -t 1 192.0.2.2

	# Block everything
	pft_set_rules alcatraz "block in"
	atf_check -s exit:2 -o ignore ping -c 1 -t 1 192.0.2.2

	# Block everything but ICMP
	pft_set_rules alcatraz "block in" "pass in proto icmp"
	atf_check -s exit:0 -o ignore ping -c 1 -t 1 192.0.2.2
}

v4_cleanup()
{
	pft_cleanup
}

atf_test_case "v6" "cleanup"
v6_head()
{
	atf_set descr 'Basic pass/block test for IPv6'
	atf_set require.user root
}

v6_body()
{
	pft_init

	epair=$(pft_mkepair)
	ifconfig ${epair}a inet6 2001:db8:42::1/64 up no_dad

	# Set up a simple jail with one interface
	pft_mkjail alcatraz ${epair}b
	jexec alcatraz ifconfig ${epair}b inet6 2001:db8:42::2/64 up no_dad

	# Trivial ping to the jail, without pf
	atf_check -s exit:0 -o ignore ping6 -c 1 -x 1 2001:db8:42::2

	# pf without policy will let us ping
	jexec alcatraz pfctl -e
	atf_check -s exit:0 -o ignore ping6 -c 1 -x 1 2001:db8:42::2

	# Block everything
	pft_set_rules alcatraz "block in"
	atf_check -s exit:2 -o ignore ping6 -c 1 -x 1 2001:db8:42::2

	# Block everything but ICMP
	pft_set_rules alcatraz "block in" "pass in proto icmp6"
	atf_check -s exit:0 -o ignore ping6 -c 1 -x 1 2001:db8:42::2

	# Allowing ICMPv4 does not allow ICMPv6
	pft_set_rules alcatraz "block in" "pass in proto icmp"
	atf_check -s exit:2 -o ignore ping6 -c 1 -x 1 2001:db8:42::2
}

v6_cleanup()
{
	pft_cleanup
}

atf_init_test_cases()
{
	atf_add_test_case "v4"
	atf_add_test_case "v6"
}
