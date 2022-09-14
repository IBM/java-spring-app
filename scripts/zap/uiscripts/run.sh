#export environment variables
bash ./export.sh

#==========
# Selenium
#==========
echo "Installing Selenium!"
mkdir -p /opt/selenium 
wget --no-verbose http://selenium-release.storage.googleapis.com/3.14/selenium-server-standalone-3.14.0.jar  -O /opt/selenium/selenium-server-standalone.jar && echo 'Selenium Installed successfully' || echo "Selenium installation failed"

	

#============================================
# Google Chrome - not able to find cleaner way yet
#============================================
echo $'[google-chrome] \n
name=google-chrome \n
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64 \n
enabled=1 \n
gpgcheck=1 \n
gpgkey=https://dl.google.com/linux/linux_signing_key.pub \n' > /etc/yum.repos.d/google-chrome.repo


yum install -y https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/desktop-file-utils-0.23-8.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/xdg-utils-1.1.2-5.el8.noarch.rpm \
http://mirror.centos.org/altarch/7/os/aarch64/Packages/liberation-fonts-common-1.07.2-16.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/liberation-mono-fonts-1.07.2-16.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/liberation-narrow-fonts-1.07.2-16.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/liberation-sans-fonts-1.07.2-16.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/liberation-serif-fonts-1.07.2-16.el7.noarch.rpm \
http://mirror.centos.org/altarch/7/os/aarch64/Packages/liberation-fonts-1.07.2-16.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/vulkan-filesystem-1.1.97.0-1.el7.noarch.rpm \
http://mirror.centos.org/centos/7/os/x86_64/Packages/vulkan-1.1.97.0-1.el7.x86_64.rpm

yum install -y google-chrome-stable && echo 'Chrome installed successfully' || echo "Chrome installation failed"

# #============================================
# # Chrome webdriver
# #============================================
# # can specify versions by CHROME_DRIVER_VERSION
# # Latest released version will be used by default
# #============================================
CHROME_DRIVER_VERSION="latest"
CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
  && echo "Using chromedriver version: "$CD_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver


#install xvfb    
yum install -y libXScrnSaver \
mesa-libgbm nss at-spi2-atk libX11-xcb \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/libxkbfile-1.1.0-1.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/xorg-x11-xkb-utils-7.7-28.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/xorg-x11-server-common-1.20.11-1.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/xorg-x11-xauth-1.0.9-12.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/libXdmcp-1.1.3-1.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/libXfont2-2.0.3-2.el8.x86_64.rpm \
https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/xorg-x11-server-Xvfb-1.20.10-1.el8.x86_64.rpm && echo 'XVFB installed successfully\n' || echo "XVFB installation failed\n"


yum install -y https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/libraw1394-2.1.2-5.el8.x86_64.rpm \
http://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/libavc1394-0.5.4-7.el8.x86_64.rpm


nohup sh -c 'xvfb-run --server-args="$DISPLAY -screen 0 $GEOMETRY -ac +extension RANDR"' >/dev/null 2>&1 & 
nohup sh -c 'java -jar /opt/selenium/selenium-server-standalone.jar -port 4444' >/dev/null 2>&1 &


npmExists='npm -v'
if ! $npmExists
then
    echo "npm could not be found"
    exit
fi

#install protractor command
npm install -g protractor && echo 'Protractor Installed successfully' || echo "Protractor installation failed"

#run protractor to browse page via zap proxy
protractorConfigFile='../uiscripts/conf/protractorConfig.js'
protractor $protractorConfigFile && echo 'Pages browsed successfully' && exit 0 || echo "Page browsing failed"

