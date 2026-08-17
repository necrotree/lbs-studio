option(ENABLE_LBS "Enable LBS (requires GTK4)" OFF)

add_executable(lbs)

# Linux desktop/application icon used by the resource bundle, install rules,
# and local runtime layout.
set(ICON_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/512x512/apps/com.necrotree.LBS.png")

    
find_package(Epoxy REQUIRED)
find_package(Gtk4 REQUIRED)
find_package(Libadwaita REQUIRED)
find_package(Libpanel REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Widgets)

# Debug
option(ENABLE_TRACING "Enable trace messages" OFF)
configure_file(obs-debug.h.in obs-debug.h @ONLY)

# GResources
find_program(GLIB_COMPILE_RESOURCES NAMES glib-compile-resources REQUIRED)
set(OBS_RESOURCES_C obs.gresources.c)
set(OBS_RESOURCES_XML obs.gresources.xml)
add_custom_command(
  OUTPUT ${OBS_RESOURCES_C}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND
    ${GLIB_COMPILE_RESOURCES} ARGS
    --target=${CMAKE_CURRENT_BINARY_DIR}/${OBS_RESOURCES_C} --generate-source
    ${OBS_RESOURCES_XML}
  VERBATIM
  MAIN_DEPENDENCY ${OBS_RESOURCES_XML}
  DEPENDS assets/projects.svg
          assets/collection-templates/empty.svg
          ${ICON_PATH}
          ${CMAKE_CURRENT_SOURCE_DIR}/audio/obs-audio-device-controls.ui
          icons/align-tool-symbolic.svg
          icons/axes-one-quadrant-symbolic.svg
          icons/blend-tool-symbolic.svg
          icons/bottom-symbolic.svg
          icons/chat-symbolic.svg
          icons/down-symbolic.svg
          icons/explore2-large-symbolic.svg
          icons/flap-symbolic.svg
          icons/general-properties-symbolic.svg
          icons/group-symbolic.svg
          icons/music-queue-symbolic.svg
          icons/sound-wave-symbolic.svg
          icons/system-monitor-symbolic.svg
          icons/top-symbolic.svg
          icons/ungroup-symbolic.svg
          icons/up-symbolic.svg
          obs-mixer-page.ui
          obs-scene-editor.ui
          obs-collections-page.ui
          obs-window.ui
          profiles/obs-profiles-dialog.ui
          preferences/obs-preferences-dialog.ui
          collections/obs-collection-template-icon.ui
          collections/obs-new-collection-dialog.ui
          style.css
          style-dark.css
          styles/default/style.css
          styles/default/style-dark.css
          styles/sakura/style.css
          styles/sakura/style-dark.css)
add_custom_target(obs-resources
                  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${OBS_RESOURCES_C})
add_dependencies(lbs image-source obs-resources
                 linux-pipewire linux-pulseaudio obs-ffmpeg obs-ffmpeg-mux obs-x264
                 obs-outputs obs-transitions obs-filters rtmp-services)

target_include_directories(lbs PRIVATE ${CMAKE_CURRENT_BINARY_DIR}
                                            ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(
  lbs
  PRIVATE audio/obs-audio-device-controls.c
          audio/obs-audio-peak-tracker.c
          audio/obs-volume-bar.c
          collections/obs-collection-template-icon.c
          collections/obs-new-collection-dialog.c
          main.c
          lbs-qt-bridge.cpp
          lbs-qt-bridge.h
          obs-application.c
          obs-audio-controller.c
          obs-audio-device.c
          obs-collection.c
          obs-collection-template.c
          obs-collections-page.c
          obs-config-manager.c
          obs-debug.h
          obs-display-renderer.c
          obs-display-widget.c
          obs-log.c
          obs-mixer-page.c
          obs-scene-editor.c
          obs-style-manager.c
          obs-templates-manager.c
          obs-utils.c
          obs-window.c
          profiles/obs-profiles-dialog.c
          preferences/obs-preferences-dialog.c
          ${CMAKE_CURRENT_BINARY_DIR}/${OBS_RESOURCES_C})

target_link_libraries(lbs PRIVATE OBS::libobs Epoxy::Epoxy GTK4::GTK4
                                       Libadwaita::Adwaita Libpanel::Panel
                                       Qt6::Widgets jansson::jansson)

target_compile_definitions(
  lbs
  PRIVATE HAVE_OBSCONFIG_H
          DL_OPENGL="$<TARGET_SONAME_FILE_NAME:OBS::libobs-opengl>")

# GTK signal callbacks commonly have parameters required by their ABI but not
# by the implementation.
target_compile_options(
  lbs PRIVATE -Wno-error=deprecated-declarations
                   -Wno-error=unused-parameter)

# Install the desktop identity alongside the icon. Flatpak and desktop shells
# require both filenames and the Icon key to match the application ID.
set(LBS_APP_ID com.necrotree.LBS)
set(LBS_ICON_NAME com.necrotree.LBS-v3)
if(DEFINED ENV{XDG_DATA_HOME} AND NOT "$ENV{XDG_DATA_HOME}" STREQUAL "")
  set(LBS_USER_DATA_DIR "$ENV{XDG_DATA_HOME}")
else()
  set(LBS_USER_DATA_DIR "$ENV{HOME}/.local/share")
endif()
configure_file(data/LBS.desktop.in ${LBS_APP_ID}.desktop COPYONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LBS_APP_ID}.desktop
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications
        COMPONENT LBSDesktop)

# Reuse OBS Studio's locale catalog for the LBS frontend.
set(OBS_FRONTEND_DATA_DIR "${CMAKE_SOURCE_DIR}/frontend/data")

install(
  DIRECTORY "${OBS_FRONTEND_DATA_DIR}/locale"
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/obs/lbs"
  COMPONENT LBS
)

install(
  FILES "${OBS_FRONTEND_DATA_DIR}/locale.ini"
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/obs/lbs"
  COMPONENT LBS
)

install(
  FILES "${OBS_FRONTEND_DATA_DIR}/locale/en-US.ini"
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/obs/lbs/locale"
  RENAME en_US.ini
  COMPONENT LBS
)

install(
  DIRECTORY "${OBS_FRONTEND_DATA_DIR}/themes"
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/obs/lbs"
  COMPONENT LBS
)

# Raw build-tree paths used by:
#
#   build_ubuntu/src/lbs
#
set(LBS_BUILD_DATA_DIR
    "${CMAKE_BINARY_DIR}/share/obs/lbs")

set(LIBOBS_BUILD_DATA_DIR
    "${CMAKE_BINARY_DIR}/share/obs/libobs")

# OBS runtime paths used by:
#
#   build_ubuntu/rundir/<CONFIG>/bin/lbs
#
set(LBS_RUNTIME_DATA_DIR
    "${OBS_OUTPUT_DIR}/$<CONFIG>/share/obs/lbs")

set(LIBOBS_RUNTIME_DATA_DIR
    "${OBS_OUTPUT_DIR}/$<CONFIG>/share/obs/libobs")

add_custom_command(
  TARGET lbs
  POST_BUILD

  # ------------------------------------------------------------
  # Raw build-tree LBS data
  # ------------------------------------------------------------

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${LBS_BUILD_DATA_DIR}/locale"

  COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    "${OBS_FRONTEND_DATA_DIR}/locale"
    "${LBS_BUILD_DATA_DIR}/locale"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${OBS_FRONTEND_DATA_DIR}/locale.ini"
    "${LBS_BUILD_DATA_DIR}/locale.ini"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${OBS_FRONTEND_DATA_DIR}/locale/en-US.ini"
    "${LBS_BUILD_DATA_DIR}/locale/en_US.ini"

  # ------------------------------------------------------------
  # Raw build-tree libobs data
  # ------------------------------------------------------------

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${LIBOBS_BUILD_DATA_DIR}"

  COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/libobs/data"
    "${LIBOBS_BUILD_DATA_DIR}"

  # ------------------------------------------------------------
  # OBS rundir LBS data
  # ------------------------------------------------------------

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${LBS_RUNTIME_DATA_DIR}/locale"

  COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    "${OBS_FRONTEND_DATA_DIR}/locale"
    "${LBS_RUNTIME_DATA_DIR}/locale"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${OBS_FRONTEND_DATA_DIR}/locale.ini"
    "${LBS_RUNTIME_DATA_DIR}/locale.ini"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${OBS_FRONTEND_DATA_DIR}/locale/en-US.ini"
    "${LBS_RUNTIME_DATA_DIR}/locale/en_US.ini"

  # ------------------------------------------------------------
  # OBS rundir libobs data
  # ------------------------------------------------------------

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${LIBOBS_RUNTIME_DATA_DIR}"

  COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/libobs/data"
    "${LIBOBS_RUNTIME_DATA_DIR}"

  # ------------------------------------------------------------
  # Desktop file and icon
  # ------------------------------------------------------------

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${CMAKE_BINARY_DIR}/share/applications"

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${CMAKE_BINARY_DIR}/share/icons/hicolor/512x512/apps"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_BINARY_DIR}/${LBS_APP_ID}.desktop"
    "${CMAKE_BINARY_DIR}/share/applications/${LBS_APP_ID}.desktop"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${ICON_PATH}"
    "${CMAKE_BINARY_DIR}/share/icons/hicolor/512x512/apps/${LBS_ICON_NAME}.png"

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${OBS_OUTPUT_DIR}/$<CONFIG>/share/applications"

  COMMAND
    ${CMAKE_COMMAND} -E make_directory
    "${OBS_OUTPUT_DIR}/$<CONFIG>/share/icons/hicolor/512x512/apps"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_BINARY_DIR}/${LBS_APP_ID}.desktop"
    "${OBS_OUTPUT_DIR}/$<CONFIG>/share/applications/${LBS_APP_ID}.desktop"

  COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
    "${ICON_PATH}"
    "${OBS_OUTPUT_DIR}/$<CONFIG>/share/icons/hicolor/512x512/apps/${LBS_ICON_NAME}.png"

  COMMENT "Copy LBS and libobs runtime data"
  VERBATIM
)

set_target_properties_obs(lbs PROPERTIES FOLDER frontend)
