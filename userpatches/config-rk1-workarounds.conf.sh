#!/usr/bin/env bash

# Turing RK1 on Turing Pi 2 is usually deployed as a general-purpose compute
# node rather than a full desktop or generic distro target. Keep the Armbian
# rockchip64 current baseline, preserve onboard Wi-Fi/Bluetooth/audio support,
# and trim the large external-device module families that do not fit this
# carrier/module pairing.
function custom_kernel_config__rk1_general_profile() {
	if [[ "${BOARD}" != "turing-rk1" || "${BRANCH}" != "current" ]]; then
		return 0
	fi

	# Keep the full upstream module coverage by default. Set
	# RK1_ENABLE_MODULE_TRIM=yes if you want the old aggressive trim profile.
	if [[ "${RK1_ENABLE_MODULE_TRIM:-no}" != "yes" ]]; then
		display_alert "RK1 module trim" "disabled (set RK1_ENABLE_MODULE_TRIM=yes to enable)" "info"
	else

	# These feed both the config hash calculation and the actual .config edits.
	opts_n+=(
		"ATM"
		"CAN"
		"FB_TFT"
		"HAMRADIO"
		"I2C_HID"
		"I2C_HID_ACPI"
		"IEEE802154"
		"INPUT_JOYDEV"
		"INPUT_JOYSTICK"
		"INPUT_TOUCHSCREEN"
		"IIO"
		"MEDIA_SUPPORT"
		"NET_DSA"
		"NFC"
		"PMBUS"
		"RC_CORE"
		"RC_DECODERS"
		"RC_DEVICES"
		"UHID"
		"USB_HIDDEV"
		"USBIP_CORE"
		"USBIP_HOST"
		"USBIP_VHCI_HCD"
		"USB_SERIAL"
		"USB_USBNET"
		"WWAN"
	)

	# Keep the USB host/controller and storage stack, but skip the long tail of
	# optional USB adapter drivers that add a lot of module churn for little
	# value on a Turing Pi 2 + RK1 general-purpose compute node.
	declare -a rk1_optional_usb_adapter_drivers=(
		"USB_ALI_M5632"
		"USB_AN2720"
		"USB_CATC"
		"USB_CDC_PHONET"
		"USB_EPSON2888"
		"USB_HSO"
		"USB_IPHETH"
		"USB_KAWETH"
		"USB_KC2190"
		"USB_LAN78XX"
		"USB_PEGASUS"
		"USB_RTL8150"
		"USB_RTL8152"
		"USB_SIERRA_NET"
		"USB_VL600"
	)

	# Preserve the generic HID path for plain keyboards and mice, but drop the
	# large vendor- and touch-oriented HID module set that is mostly noise for
	# the default RK1 general-purpose build in this repository.
	declare -a rk1_optional_hid_drivers=(
		"HID_A4TECH"
		"HID_ACCUTOUCH"
		"HID_ACRUX"
		"HID_ACRUX_FF"
		"HID_ALPS"
		"HID_APPLE"
		"HID_APPLEIR"
		"HID_AUREAL"
		"HID_BELKIN"
		"HID_BETOP_FF"
		"HID_BIGBEN_FF"
		"HID_BPF"
		"HID_CHERRY"
		"HID_CHICONY"
		"HID_CMEDIA"
		"HID_COUGAR"
		"HID_CORSAIR"
		"HID_CP2112"
		"HID_CREATIVE_SB0540"
		"HID_CYPRESS"
		"HID_DRAGONRISE"
		"HID_ELECOM"
		"HID_ELAN"
		"HID_ELO"
		"HID_EMS_FF"
		"HID_EZKEY"
		"HID_FT260"
		"HID_GEMBIRD"
		"HID_GFRM"
		"HID_GLORIOUS"
		"HID_GREENASIA"
		"HID_GT683R"
		"HID_GYRATION"
		"HID_HOLTEK"
		"HID_ICADE"
		"HID_ITE"
		"HID_JABRA"
		"HID_KENSINGTON"
		"HID_KEYTOUCH"
		"HID_KYE"
		"HID_LCPOWER"
		"HID_LENOVO"
		"HID_LETSKETCH"
		"HID_MACALLY"
		"HID_MAGICMOUSE"
		"HID_MALTRON"
		"HID_MCP2221"
		"HID_MEGAWORLD_FF"
		"HID_MICROSOFT"
		"HID_MONTEREY"
		"HID_MULTITOUCH"
		"HID_NINTENDO"
		"HID_NTI"
		"HID_NTRIG"
		"HID_ORTEK"
		"HID_PANTHERLORD"
		"HID_PENMOUNT"
		"HID_PETALYNX"
		"HID_PICOLCD"
		"HID_PICOLCD_BACKLIGHT"
		"HID_PICOLCD_CIR"
		"HID_PICOLCD_FB"
		"HID_PICOLCD_LCD"
		"HID_PICOLCD_LEDS"
		"HID_PID"
		"HID_PLANTRONICS"
		"HID_PRIMAX"
		"HID_PRODIKEYS"
		"HID_REDRAGON"
		"HID_RETRODE"
		"HID_RMI"
		"HID_ROCCAT"
		"HID_SAITEK"
		"HID_SAMSUNG"
		"HID_SEMITEK"
		"HID_SENSOR_ACCEL_3D"
		"HID_SENSOR_ALS"
		"HID_SENSOR_CUSTOM_INTEL_HINGE"
		"HID_SENSOR_CUSTOM_SENSOR"
		"HID_SENSOR_DEVICE_ROTATION"
		"HID_SENSOR_GYRO_3D"
		"HID_SENSOR_HUB"
		"HID_SENSOR_HUMIDITY"
		"HID_SENSOR_INCLINOMETER_3D"
		"HID_SENSOR_MAGNETOMETER_3D"
		"HID_SENSOR_PRESS"
		"HID_SENSOR_PROX"
		"HID_SENSOR_TEMP"
		"HID_SMARTJOYPLUS"
		"HID_SONY"
		"HID_SPEEDLINK"
		"HID_STEAM"
		"HID_STEELSERIES"
		"HID_SUNPLUS"
		"HID_THRUSTMASTER"
		"HID_THINGM"
		"HID_TIVO"
		"HID_TOPSEED"
		"HID_TWINHAN"
		"HID_U2FZERO"
		"HID_UCLOGIC"
		"HID_UDRAW_PS3"
		"HID_VIEWSONIC"
		"HID_WACOM"
		"HID_WALTOP"
		"HID_WIIMOTE"
		"HID_XIAOMI"
		"HID_XINMO"
		"HID_ZEROPLUS"
		"HID_ZYDACRON"
	)

	opts_n+=("${rk1_optional_usb_adapter_drivers[@]}")
	opts_n+=("${rk1_optional_hid_drivers[@]}")

	# Turing Pi 2 + RK1 still does not need a wide MIPI/LVDS panel matrix by
	# default. Disabling the discrete panel drivers removes a large chunk of
	# module churn while preserving the main DRM/KMS stack for normal output.
	declare -a rk1_panel_drivers=(
		"DRM_PANEL_ABT_Y030XX067A"
		"DRM_PANEL_ARM_VERSATILE"
		"DRM_PANEL_BOE_BF060Y8M_AJ0"
		"DRM_PANEL_BOE_HIMAX8279D"
		"DRM_PANEL_BOE_TV101WUM_NL6"
		"DRM_PANEL_DSI_CM"
		"DRM_PANEL_EDP"
		"DRM_PANEL_ELIDA_KD35T133"
		"DRM_PANEL_FEIXIN_K101_IM2BA02"
		"DRM_PANEL_FEIYANG_FY07024DI26A30D"
		"DRM_PANEL_ILITEK_IL9322"
		"DRM_PANEL_ILITEK_ILI9341"
		"DRM_PANEL_ILITEK_ILI9881C"
		"DRM_PANEL_INNOLUX_EJ030NA"
		"DRM_PANEL_INNOLUX_P079ZCA"
		"DRM_PANEL_JDI_LT070ME05000"
		"DRM_PANEL_JDI_R63452"
		"DRM_PANEL_KHADAS_TS050"
		"DRM_PANEL_KINGDISPLAY_KD097D04"
		"DRM_PANEL_LEADTEK_LTK500HD1829"
		"DRM_PANEL_LG_LB035Q02"
		"DRM_PANEL_LVDS"
		"DRM_PANEL_MIPI_DBI"
		"DRM_PANEL_NEC_NL8048HL11"
		"DRM_PANEL_NEWVISION_NV3052C"
		"DRM_PANEL_NOVATEK_NT35510"
		"DRM_PANEL_NOVATEK_NT35950"
		"DRM_PANEL_NOVATEK_NT36672A"
		"DRM_PANEL_NOVATEK_NT39016"
		"DRM_PANEL_OLIMEX_LCD_OLINUXINO"
		"DRM_PANEL_ORISETECH_OTM8009A"
		"DRM_PANEL_PANASONIC_VVX10F034N00"
		"DRM_PANEL_RASPBERRYPI_TOUCHSCREEN"
		"DRM_PANEL_RAYDIUM_RM67191"
		"DRM_PANEL_RAYDIUM_RM68200"
		"DRM_PANEL_RONBO_RB070D30"
		"DRM_PANEL_SAMSUNG_ATNA33XC20"
		"DRM_PANEL_SAMSUNG_DB7430"
		"DRM_PANEL_SAMSUNG_S6D16D0"
		"DRM_PANEL_SAMSUNG_S6D27A1"
		"DRM_PANEL_SAMSUNG_S6E3HA2"
		"DRM_PANEL_SAMSUNG_S6E63J0X03"
		"DRM_PANEL_SAMSUNG_S6E88A0_AMS452EF01"
		"DRM_PANEL_SAMSUNG_SOFEF00"
		"DRM_PANEL_SEIKO_43WVF1G"
		"DRM_PANEL_SHARP_LQ101R1SX01"
		"DRM_PANEL_SHARP_LS037V7DW01"
		"DRM_PANEL_SHARP_LS043T1LE01"
		"DRM_PANEL_SHARP_LS060T1SX01"
		"DRM_PANEL_SIMPLE"
		"DRM_PANEL_SITRONIX_ST7701"
		"DRM_PANEL_SONY_ACX565AKM"
		"DRM_PANEL_SONY_TULIP_TRULY_NT35521"
		"DRM_PANEL_TDO_TL070WSH30"
		"DRM_PANEL_TPO_TD028TTEC1"
		"DRM_PANEL_TPO_TD043MTEA1"
		"DRM_PANEL_TPO_TPG110"
		"DRM_PANEL_TRULY_NT35597_WQXGA"
		"DRM_PANEL_WIDECHIPS_WS2401"
		"DRM_PANEL_XINPENG_XPP055C272"
		"DRM_PANEL_YIXIAN_YX0345"
	)

	opts_n+=("${rk1_panel_drivers[@]}")
	fi

	# Optionally force specific symbols to modules using a flat list file.
	# Accepted line formats:
	#   CONFIG_SYMBOL=m
	#   SYMBOL
	declare force_modules_file="${USERPATCHES_PATH}/rk1-current-force-modules.txt"
	if [[ -r "${force_modules_file}" ]]; then
		declare -a rk1_force_modules=()
		while IFS= read -r line || [[ -n "${line}" ]]; do
			line="${line%%#*}"
			line="${line//[[:space:]]/}"
			[[ -z "${line}" ]] && continue
			if [[ "${line}" == CONFIG_*=m ]]; then
				line="${line#CONFIG_}"
				line="${line%=m}"
				line="${line%=}"
			elif [[ "${line}" == CONFIG_* ]]; then
				line="${line#CONFIG_}"
			fi
			[[ -z "${line}" ]] && continue
			rk1_force_modules+=("${line}")
		done < "${force_modules_file}"

		if [[ "${#rk1_force_modules[@]}" -gt 0 ]]; then
			opts_m+=("${rk1_force_modules[@]}")
			display_alert "RK1 force modules" "enabled ${#rk1_force_modules[@]} symbols from $(basename "${force_modules_file}")" "info"
		fi
	fi
}

# Work around an upstream Armbian packaging regression where arm64 kernel
# installs may produce /boot/Image without the expected versioned vmlinuz path.
function kernel_package_callback_linux_image() {
	display_alert "linux-image deb packaging" "${package_directory}" "debug"

	declare kernel_pre_package_path="${tmp_kernel_install_dirs[INSTALL_PATH]}"
	declare image_name="Image"
	if [[ -n "${NAME_KERNEL}" ]]; then
		display_alert "NAME_KERNEL is set" "using '${NAME_KERNEL}' instead of '${image_name}'" "debug"
		image_name="${NAME_KERNEL}"
	fi

	declare kernel_image_installed_file_name=""
	declare kernel_image_pre_package_path=""
	declare installed_image_path=""

	if [[ -z "$(find "${kernel_pre_package_path}" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]]; then
		declare built_kernel_dir="${SRC}/cache/sources/${LINUXSOURCEDIR}"
		declare built_kernel_image="${built_kernel_dir}/arch/${KERNEL_SRC_ARCH}/boot/${image_name}"
		if [[ -f "${built_kernel_image}" ]]; then
			display_alert "Kernel install output is empty" "seeding ${kernel_pre_package_path} from ${built_kernel_image}" "warn"
			run_host_command_logged install -D -m 0644 "${built_kernel_image}" "${kernel_pre_package_path}/${image_name}"
			if [[ -f "${built_kernel_dir}/System.map" ]]; then
				run_host_command_logged install -D -m 0644 "${built_kernel_dir}/System.map" "${kernel_pre_package_path}/System.map-${kernel_version_family}"
			fi
			if [[ -f "${built_kernel_dir}/.config" ]]; then
				run_host_command_logged install -D -m 0644 "${built_kernel_dir}/.config" "${kernel_pre_package_path}/config-${kernel_version_family}"
			fi
		fi
	fi

	if compgen -G "${kernel_pre_package_path}/vmlinu*-${kernel_version_family}" > /dev/null; then
		kernel_image_installed_file_name="$(basename "$(compgen -G "${kernel_pre_package_path}/vmlinu*-${kernel_version_family}" | head -n1)")"
		kernel_image_pre_package_path="${kernel_pre_package_path}/${kernel_image_installed_file_name}"
		installed_image_path="boot/${kernel_image_installed_file_name}"
	elif [[ -f "${kernel_pre_package_path}/${image_name}-${kernel_version_family}" ]]; then
		kernel_image_installed_file_name="${image_name}-${kernel_version_family}"
		kernel_image_pre_package_path="${kernel_pre_package_path}/${kernel_image_installed_file_name}"
		installed_image_path="boot/${kernel_image_installed_file_name}"
	elif [[ -f "${kernel_pre_package_path}/${image_name}" ]]; then
		kernel_image_installed_file_name="${image_name}"
		kernel_image_pre_package_path="${kernel_pre_package_path}/${kernel_image_installed_file_name}"
		installed_image_path="boot/${image_name}-${kernel_version_family}"
		display_alert "Kernel install output is not versioned" "staging '${kernel_image_installed_file_name}' as '${installed_image_path}'" "warn"
	else
		display_alert "Showing contents of Kbuild produced /boot" "linux-image" "debug"
		run_host_command_logged ls -la "${kernel_pre_package_path}" "|| true"
		exit_with_error "Could not find a packaged kernel image in ${kernel_pre_package_path}"
	fi

	declare kernel_image_name
	kernel_image_name="$(basename "${installed_image_path}")"
	kernel_image_name="${kernel_image_name%%-*}"
	display_alert "linux-image deb packaging kernel_image_name" "${kernel_image_name}" "info"

	display_alert "Showing contents of Kbuild produced /boot" "linux-image" "debug"
	run_host_command_logged tree -C --du -h "${tmp_kernel_install_dirs[INSTALL_PATH]}"

	display_alert "Kernel-built image filetype" "${kernel_image_installed_file_name}: $(file --brief "${kernel_image_pre_package_path}")" "info"

	run_host_command_logged ls -la "${kernel_pre_package_path}" "${kernel_image_pre_package_path}"

	call_extension_method "pre_package_kernel_image" <<- 'PRE_PACKAGE_KERNEL_IMAGE'
		*fix Image/uImage/zImage before packaging kernel*
		Some (legacy/vendor) kernels need preprocessing of the produced Image/uImage/zImage before packaging.
		Use this hook to do that, by modifying the file in place, in `${kernel_pre_package_path}` directory.
		The final file that will be used is stored in `${kernel_image_pre_package_path}` -- which you shouldn't change.
	PRE_PACKAGE_KERNEL_IMAGE

	display_alert "Kernel image filetype after pre_package_kernel_image" "${kernel_image_installed_file_name}: $(file --brief "${kernel_image_pre_package_path}")" "info"

	unset kernel_pre_package_path
	unset kernel_image_pre_package_path

	run_host_command_logged cp -rp "${tmp_kernel_install_dirs[INSTALL_PATH]}" "${package_directory}/"
	run_host_command_logged cp -rp "${tmp_kernel_install_dirs[INSTALL_MOD_PATH]}/lib" "${package_directory}/"

	if [[ ! -f "${package_directory}/${installed_image_path}" && -f "${package_directory}/boot/${kernel_image_installed_file_name}" ]]; then
		run_host_command_logged mv -v "${package_directory}/boot/${kernel_image_installed_file_name}" "${package_directory}/${installed_image_path}"
	fi

	run_host_command_logged rm -v -f "${package_directory}/lib/modules/${kernel_version_family}/build" "${package_directory}/lib/modules/${kernel_version_family}/source"

	if [[ -d "${package_directory}/lib/modules/${kernel_version_family}/kernel" ]]; then
		display_alert "Showing contents of Kbuild produced modules" "linux-image" "debug"
		run_host_command_logged tree -C --du -h -d -L 1 "${package_directory}/lib/modules/${kernel_version_family}/kernel" "|| true"
	fi

	if [[ -d "${tmp_kernel_install_dirs[INSTALL_DTBS_PATH]}" ]]; then
		display_alert "DTBs present on kernel output" "DTBs ${package_name}: /usr/lib/linux-image-${kernel_version_family}" "debug"
		mkdir -p "${package_directory}/usr/lib"
		run_host_command_logged cp -rp "${tmp_kernel_install_dirs[INSTALL_DTBS_PATH]}" "${package_directory}/usr/lib/linux-image-${kernel_version_family}"
	fi

	cat <<- CONTROL_FILE > "${package_DEBIAN_dir}/control"
		Package: ${package_name}
		Version: ${artifact_version}
		Source: linux-${kernel_version}
		Armbian-Kernel-Version: ${kernel_version}
		Armbian-Kernel-Version-Family: ${kernel_version_family}
		Architecture: ${ARCH}
		Maintainer: ${MAINTAINER} <${MAINTAINERMAIL}>
		Section: kernel
		Priority: optional
		Provides: linux-image, linux-image-armbian, armbian-$BRANCH, wireguard-modules
		Description: Armbian Linux $BRANCH kernel image $kernel_version_family
		 This package contains the Linux kernel, modules and corresponding other files.
		 ${artifact_version_reason:-"${kernel_version_family}"}
	CONTROL_FILE

	declare debian_kernel_hook_dir="/etc/kernel"
	for script in "postinst" "postrm" "preinst" "prerm"; do
		mkdir -p "${package_directory}${debian_kernel_hook_dir}/${script}.d"

		kernel_package_hook_helper "${script}" <(
			cat <<- KERNEL_HOOK_DELEGATION
				export DEB_MAINT_PARAMS="\$*"
				export INITRD=$(if_enabled_echo CONFIG_BLK_DEV_INITRD Yes No)
				test -d ${debian_kernel_hook_dir}/${script}.d && run-parts --arg="${kernel_version_family}" --arg="/${installed_image_path}" ${debian_kernel_hook_dir}/${script}.d
			KERNEL_HOOK_DELEGATION

			if [[ "${script}" == "preinst" ]]; then
				cat <<- HOOK_FOR_REMOVE_VFAT_BOOT_FILES
					if is_boot_dev_vfat; then
						rm -f /boot/System.map* /boot/config* /boot/vmlinuz* /boot/$image_name /boot/uImage
					fi
				HOOK_FOR_REMOVE_VFAT_BOOT_FILES
			fi

			if [[ "${script}" == "postinst" ]]; then
				cat <<- HOOK_FOR_LINK_TO_LAST_INSTALLED_KERNEL
					touch /boot/.next
					if is_boot_dev_vfat; then
						echo "Armbian: FAT32 /boot: move last-installed kernel to '$image_name'..."
						mv -v /${installed_image_path} /boot/${image_name}
					else
						echo "Armbian: update last-installed kernel symlink to '$image_name'..."
						ln -sfv $(basename "${installed_image_path}") /boot/$image_name
					fi
				HOOK_FOR_LINK_TO_LAST_INSTALLED_KERNEL

				cat <<- HOOK_FOR_DEBIAN_COMPAT_SYMLINK
					if ! is_boot_dev_vfat; then
						echo "Armbian: Debian compat: linux-update-symlinks install ${kernel_version_family} ${installed_image_path}"
						linux-update-symlinks install "${kernel_version_family}" "${installed_image_path}" || true
					fi
				HOOK_FOR_DEBIAN_COMPAT_SYMLINK
			fi
		)
	done
}
