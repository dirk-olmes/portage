# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/sysdig/sysdig-0.1.92.ebuild,v 1.2 2014/11/22 10:36:18 mgorny Exp $

EAPI=5

inherit linux-mod bash-completion-r1 cmake-utils

DESCRIPTION="A system exploration and troubleshooting tool"
HOMEPAGE="http://www.sysdig.org/"
SRC_URI="https://github.com/draios/sysdig/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+modules"

RDEPEND="net-misc/curl
	dev-libs/jsoncpp:0=
	dev-lang/luajit:2=
	sys-libs/ncurses
	dev-libs/openssl
	sys-libs/zlib:0="
DEPEND="${RDEPEND}
	app-arch/xz-utils
	virtual/os-headers"

# needed for the kernel module
CONFIG_CHECK="HAVE_SYSCALL_TRACEPOINTS TRACEPOINTS"

pkg_pretend() {
	use modules && linux-mod_pkg_setup
}

pkg_setup() {
	use modules && linux-mod_pkg_setup
}

src_prepare() {
	sed -i -e 's:-ggdb::' CMakeLists.txt || die
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		# we will use linux-mod for that
		-DBUILD_DRIVER=OFF
		# libscap examples are not installed or really useful
		-DBUILD_LIBSCAP_EXAMPLES=OFF

		# unbundle the deps
		-DUSE_BUNDLED_CURL=OFF
		-DUSE_BUNDLED_JSONCPP=OFF
		-DJSONCPP_PREFIX="${EPREFIX}"/usr
		-DJSONCPP_INCLUDE="${EPREFIX}"/usr/include/jsoncpp
		-DUSE_BUNDLED_LUAJIT=OFF
		-DLUAJIT_PREFIX="${EPREFIX}"/usr
		-DLUAJIT_INCLUDE="${EPREFIX}"/usr/include/luajit-2.0
		-DUSE_BUNDLED_NCURSES=OFF
		-DUSE_BUNDLED_OPENSSL=OFF
		-DUSE_BUNDLED_ZLIB=OFF
		-DZLIB_PREFIX="${EPREFIX}"/usr
	)

	cmake-utils_src_configure

	# setup linux-mod ugliness
	MODULE_NAMES="sysdig-probe(extra:${BUILD_DIR}/driver:)"
	BUILD_PARAMS='KERNELDIR="${KERNEL_DIR}"'
	BUILD_TARGETS="driver"
}

src_compile() {
	cmake-utils_src_compile

	use modules && linux-mod_src_compile
}

src_install() {
	cmake-utils_src_install

	use modules && linux-mod_src_install

	# remove sources
	rm -r "${ED%/}"/usr/src || die

	# move bashcomp to the proper location
	dobashcomp "${ED%/}"/usr/etc/bash_completion.d/sysdig || die
	rm -r "${ED%/}"/usr/etc || die
}