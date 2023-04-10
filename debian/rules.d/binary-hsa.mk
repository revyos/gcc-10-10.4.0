ifeq ($(with_offload_hsa),yes)
  #arch_binaries := $(arch_binaries) hsa
  arch_binaries := $(arch_binaries) hsa-plugin
endif

p_hsa	= gcc$(pkg_ver)-offload-hsa
d_hsa	= debian/$(p_hsa)

p_pl_hsa = libgomp-plugin-hsa1
d_pl_hsa = debian/$(p_pl_hsa)

dirs_hsa = \
	$(docdir)/$(p_xbase)/ \
	$(PF)/bin \
	$(gcc_lexec_dir)/accel

files_hsa = \
	$(PF)/bin/$(DEB_TARGET_GNU_TYPE)-accel-hsa-none-gcc$(pkg_ver) \
	$(gcc_lexec_dir)/accel/hsa-none

# not needed: libs moved, headers not needed for lto1
#	$(PF)/hsa-none

# are these needed?
#	$(PF)/lib/gcc/hsa-none/$(versiondir)/{include,finclude,mgomp}

ifneq ($(GFDL_INVARIANT_FREE),yes)
  files_hsa += \
	$(PF)/share/man/man1/$(DEB_HOST_GNU_TYPE)-accel-hsa-none-gcc$(pkg_ver).1
endif

$(binary_stamp)-hsa: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_hsa)
	dh_installdirs -p$(p_hsa) $(dirs_hsa)
	$(dh_compat2) dh_movefiles --sourcedir=$(d)-hsa -p$(p_hsa) \
		$(files_hsa)

	mkdir -p $(d_hsa)/usr/share/lintian/overrides
	echo '$(p_hsa) binary: hardening-no-pie' \
	  > $(d_hsa)/usr/share/lintian/overrides/$(p_hsa)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_hsa) binary: binary-without-manpage' \
	  >> $(d_hsa)/usr/share/lintian/overrides/$(p_hsa)
endif

	debian/dh_doclink -p$(p_hsa) $(p_xbase)

	debian/dh_rmemptydirs -p$(p_hsa)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_hsa)/$(gcc_lexec_dir)/accel/hsa-none/{collect2,lto1,lto-wrapper,mkoffload}
endif
	dh_strip -p$(p_hsa) \
	  $(if $(unstripped_exe),-X/lto1)
	dh_shlibdeps -p$(p_hsa)
	echo $(p_hsa) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-hsa-plugin: $(install_dependencies)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_pl_hsa)
	dh_installdirs -p$(p_pl_hsa) \
		$(docdir) \
		$(usr_lib)
	$(dh_compat2) dh_movefiles -p$(p_pl_hsa) \
		$(usr_lib)/libgomp-plugin-hsa.so.*

	debian/dh_doclink -p$(p_pl_hsa) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_pl_hsa)

	dh_strip -p$(p_pl_hsa)
	dh_makeshlibs -p$(p_pl_hsa)
	dh_shlibdeps -p$(p_pl_hsa)
	echo $(p_pl_hsa) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
