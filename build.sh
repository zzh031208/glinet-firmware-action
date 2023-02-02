#!/bin/bash


CRTDIR=$(pwd)

base=$1
profile=$2
ui=$3
echo $base
if [ ! -e "$base" ]; then
	echo "Please enter base folder"
	exit 1
else
	if [ ! -d $base ]; then 
		echo "Openwrt base folder not exist"
		exit 1
	fi
fi

if [ ! -n "$profile" ]; then
	profile=target_wlan_ap-gl-ax1800
fi

if [ ! -n "$ui" ]; then
        ui=true
fi


echo "Start..."

#clone source tree 
git clone https://github.com/gl-inet/gl-infra-builder.git $base/gl-infra-builder
cp -r custom/  $base/gl-infra-builder/feeds/custom/
cp -r *.yml $base/gl-infra-builder/profiles
cd $base/gl-infra-builder
#setup

if [[ $profile == *5-4* ]]; then
        python3 setup.py -c configs/config-wlan-ap-5.4.yml
elif [[ $profile == *a1300* ]]; then
		python3 setup.py -c configs/config-21.02.2.yml
elif [[ $profile == *mt7981* ]]; then
		python3 setup.py -c  configs/config-mt798x-7.6.6.1.yml
else
        python3 setup.py -c configs/config-wlan-ap.yml
fi

if [[ $profile == *wlan_ap*  ]]; then
	ln -s $base/gl-infra-builder/wlan-ap/openwrt ~/openwrt
elif [[ $profile == *mt7981* ]]; then
	ln -s $base/gl-infra-builder/mt7981 ~/openwrt
else
	ln -s $base/gl-infra-builder/openwrt-21.02/openwrt-21.02.2 ~/openwrt
fi
cd ~/openwrt


if [[ $ui == true  ]] && [[ $profile == *wlan_ap* ]]; then 
	./scripts/gen_config.py $profile glinet_depends glinet_nas custom
elif [[ $ui == true  ]] && [[ $profile == *mt7981* ]]; then
	./scripts/gen_config.py $profile glinet_depends glinet_nas custom
elif [[ $ui == true  ]] && [[ $profile == *ipq40xx* ]]; then
	./scripts/gen_config.py $profile glinet_depends glinet_nas custom
else
	./scripts/gen_config.py $profile openwrt_common luci custom
fi

# fix helloword build error
rm -rf feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/branches/openwrt-22.03/lang/golang feeds/packages/lang/golang

git clone https://github.com/gl-inet/glinet4.x.git $base/glinet
./scripts/feeds update -a 
./scripts/feeds install -a
make defconfig

if [[ $ui == true  ]] && [[ $profile == *wlan_ap* ]]; then 
	make -j$(expr $(nproc) + 1) GL_PKGDIR=$base/glinet/ipq60xx/ V=s
elif [[ $ui == true  ]] && [[ $profile == *mt7981* ]]; then
	if [[ $profile == *mt2500 ]]; then
		cp $base/glinet/pkg_config/gl_pkg_config_mt7981_mt2500.mk $base/glinet/mt7981/gl_pkg_config.mk
	else
		cp $base/glinet/pkg_config/gl_pkg_config_mt7981_mt3000.mk $base/glinet/mt7981/gl_pkg_config.mk
	fi
	make -j$(expr $(nproc) + 1) GL_PKGDIR=$base/glinet/mt7981/ V=s
else
	make -j$(expr $(nproc) + 1)  V=s
fi

