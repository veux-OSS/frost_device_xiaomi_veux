#=============================================================================
# Copyright (c) 2020-2021 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2020, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

# Disable read-ahead swap
echo 0 > /proc/sys/vm/page-cluster

# configure input boost settings
chown system:system /sys/devices/system/cpu/cpu_boost/input_boost_freq
echo "0:1401600" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
echo 200 > /sys/devices/system/cpu/cpu_boost/input_boost_ms

#liochen@SYSTEM, 2020/11/02, Add for enable ufs performance
echo 0 > /sys/class/scsi_host/host0/../../../clkscale_enable

# Setting b.L scheduler parameters
echo 95 95 > /proc/sys/kernel/sched_upmigrate
echo 85 85 > /proc/sys/kernel/sched_downmigrate
echo 100 > /proc/sys/kernel/sched_group_upmigrate
echo 85 > /proc/sys/kernel/sched_group_downmigrate
echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks
echo 400000000 > /proc/sys/kernel/sched_coloc_downmigrate_ns
echo 39000000 39000000 39000000 39000000 39000000 39000000 39000000 5000000 > /proc/sys/kernel/sched_coloc_busy_hyst_cpu_ns
echo 240 > /proc/sys/kernel/sched_coloc_busy_hysteresis_enable_cpus
echo 10 10 10 10 10 10 10 95 > /proc/sys/kernel/sched_coloc_busy_hyst_cpu_busy_pct

# set the threshold for low latency task boost feature which prioritize
# binder activity tasks
echo 325 > /proc/sys/kernel/walt_low_latency_task_threshold
# change colocation threshold
echo 162 > /proc/sys/kernel/sched_min_task_util_for_colocation

# configure governor settings for silver cluster
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/rate_limit_us
echo 806400 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

# configure governor settings for gold cluster
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
echo 0 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/rate_limit_us

# configure governor settings for gold+ cluster
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
echo 0 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/rate_limit_us

# configure bus-dcvs
device=/sys/devices/platform/soc
	for cpubw in $device/*cpu-cpu-llcc-bw/devfreq/*cpu-cpu-llcc-bw
	do
		cat $cpubw/available_frequencies | cut -d " " -f 1 > $cpubw/min_freq
		echo "4577 7110 9155 12298 14236 15258" > $cpubw/bw_hwmon/mbps_zones
		echo 4 > $cpubw/bw_hwmon/sample_ms
		echo 80 > $cpubw/bw_hwmon/io_percent
		echo 20 > $cpubw/bw_hwmon/hist_memory
		echo 10 > $cpubw/bw_hwmon/hyst_length
		echo 30 > $cpubw/bw_hwmon/down_thres
		echo 0 > $cpubw/bw_hwmon/guard_band_mbps
		echo 250 > $cpubw/bw_hwmon/up_scale
		echo 1600 > $cpubw/bw_hwmon/idle_mbps
		echo 12298 > $cpubw/max_freq
		echo 40 > $cpubw/polling_interval
	done

	for llccbw in $device/*cpu-llcc-ddr-bw/devfreq/*cpu-llcc-ddr-bw
	do
		cat $llccbw/available_frequencies | cut -d " " -f 1 > $llccbw/min_freq
		if [ ${ddr_type:4:2} == $ddr_type4 ]; then
		echo "1720 2086 2929 3879 5931 6515 8136" > $llccbw/bw_hwmon/mbps_zones
		elif [ ${ddr_type:4:2} == $ddr_type5 ]; then
		echo "1720 2086 2929 3879 6515 7980 12191" > $llccbw/bw_hwmon/mbps_zones
		fi
		echo 4 > $llccbw/bw_hwmon/sample_ms
		echo 80 > $llccbw/bw_hwmon/io_percent
		echo 20 > $llccbw/bw_hwmon/hist_memory
		echo 10 > $llccbw/bw_hwmon/hyst_length
		echo 30 > $llccbw/bw_hwmon/down_thres
		echo 0 > $llccbw/bw_hwmon/guard_band_mbps
		echo 250 > $llccbw/bw_hwmon/up_scale
		echo 1600 > $llccbw/bw_hwmon/idle_mbps
		echo 6515 > $llccbw/max_freq
		echo 40 > $llccbw/polling_interval
	done

	for l3bw in $device/*snoop-l3-bw/devfreq/*snoop-l3-bw
	do
		cat $l3bw/available_frequencies | cut -d " " -f 1 > $l3bw/min_freq
		echo 4 > $l3bw/bw_hwmon/sample_ms
		echo 10 > $l3bw/bw_hwmon/io_percent
		echo 20 > $l3bw/bw_hwmon/hist_memory
		echo 10 > $l3bw/bw_hwmon/hyst_length
		echo 0 > $l3bw/bw_hwmon/down_thres
		echo 0 > $l3bw/bw_hwmon/guard_band_mbps
		echo 0 > $l3bw/bw_hwmon/up_scale
		echo 1600 > $l3bw/bw_hwmon/idle_mbps
		echo 9155 > $l3bw/max_freq
		echo 40 > $l3bw/polling_interval
	done

	# configure mem_latency settings for LLCC and DDR scaling and qoslat
	for memlat in $device/*lat/devfreq/*lat
	do
		cat $memlat/available_frequencies | cut -d " " -f 1 > $memlat/min_freq
		echo 8 > $memlat/polling_interval
		echo 400 > $memlat/mem_latency/ratio_ceil
	done

	# configure compute settings for gold latfloor
	for latfloor in $device/*cpu4-cpu*latfloor/devfreq/*cpu4-cpu*latfloor
	do
		cat $latfloor/available_frequencies | cut -d " " -f 1 > $latfloor/min_freq
		echo 8 > $latfloor/polling_interval
	done

	# configure mem_latency settings for prime latfloor
	for latfloor in $device/*cpu7-cpu*latfloor/devfreq/*cpu7-cpu*latfloor
	do
		cat $latfloor/available_frequencies | cut -d " " -f 1 > $latfloor/min_freq
		echo 8 > $latfloor/polling_interval
		echo 25000 > $latfloor/mem_latency/ratio_ceil
	done

	# CPU4 L3 ratio ceil
	for l3gold in $device/*cpu4-cpu-l3-lat/devfreq/*cpu4-cpu-l3-lat
	do
		echo 4000 > $l3gold/mem_latency/ratio_ceil
	done

	# CPU5 L3 ratio ceil
	for l3gold in $device/*cpu5-cpu-l3-lat/devfreq/*cpu5-cpu-l3-lat
	do
		echo 4000 > $l3gold/mem_latency/ratio_ceil
	done

	# CPU6 L3 ratio ceil
	for l3gold in $device/*cpu6-cpu-l3-lat/devfreq/*cpu6-cpu-l3-lat
	do
		echo 4000 > $l3gold/mem_latency/ratio_ceil
	done

	# prime L3 ratio ceil
	for l3prime in $device/*cpu7-cpu-l3-lat/devfreq/*cpu7-cpu-l3-lat
	do
		echo 20000 > $l3prime/mem_latency/ratio_ceil
	done

	# qoslat ratio ceil
	for qoslat in $device/*qoslat/devfreq/*qoslat
	do
		echo 50 > $qoslat/mem_latency/ratio_ceil
	done

echo N > /sys/module/lpm_levels/parameters/sleep_disabled

# Remove unused swapfile
rm -rf /data/vendor/swap
sync

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
	image_version="10:"
	image_version+=`getprop ro.build.id`
	image_version+=":"
	image_version+=`getprop ro.build.version.incremental`
	image_variant=`getprop ro.product.name`
	image_variant+="-"
	image_variant+=`getprop ro.build.type`
	oem_version=`getprop ro.build.version.codename`
	echo 10 > /sys/devices/soc0/select_image
	echo $image_version > /sys/devices/soc0/image_version
	echo $image_variant > /sys/devices/soc0/image_variant
	echo $oem_version > /sys/devices/soc0/image_crm_version
fi

setprop vendor.post_boot.parsed 1
