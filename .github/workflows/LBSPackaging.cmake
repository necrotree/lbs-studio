# LBS Linux package metadata for CPack.
#
# Include this near the end of the top-level CMakeLists.txt, after the project's
# install() rules have been declared:
#
#   include(cmake/LBSPackaging.cmake)

set(CPACK_PACKAGE_NAME "lbs-studio")
set(CPACK_PACKAGE_VENDOR "NecroTree")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Libre Broadcasting Software")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/Helladen/lbs-studio")

# Prefer the project's own version if it already defines one.
if(PROJECT_VERSION)
  set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
else()
  set(CPACK_PACKAGE_VERSION "0.1.0")
endif()

# Packages install beneath /usr when CI configures with
# -DCMAKE_INSTALL_PREFIX=/usr.
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")

# Debian
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "LBS Studio")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

# RPM
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)
set(CPACK_RPM_PACKAGE_LICENSE "GPL-2.0-or-later")
set(CPACK_RPM_PACKAGE_AUTOREQ ON)

include(CPack)
