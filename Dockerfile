FROM jenkins/jenkins:alpine

ARG ANDROID_COMMAND_LINE_TOOLS_SHA1SUM=9172381ff070ee2a416723c1989770cf4b0d1076
ARG ANDROID_COMMAND_LINE_TOOLS_VERSION=6609375_latest


#----- configuration as code
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/casc.yaml
COPY casc.yaml /usr/share/jenkins/casc.yaml

#------ add the jenkins plugins
COPY jenkins-plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

#------ setup android SDK tools
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_PLATFORM_TOOLS=${ANDROID_SDK_ROOT}/platform-tools \
    ANDROID_CMDLINE_TOOLS=${ANDROID_SDK_ROOT}/cmdline-tools
USER root
RUN apk update \
    && mkdir -p ${ANDROID_SDK_ROOT} \
    && mkdir -p ${ANDROID_PLATFORM_TOOLS} \
    && mkdir -p ${ANDROID_CMDLINE_TOOLS}
ENV PATH ${PATH}:${ANDROID_CMDLINE_TOOLS}/tools:${ANDROID_CMDLINE_TOOLS}/tools/bin:${ANDROID_PLATFORM_TOOLS}
RUN cd /opt \
  && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_COMMAND_LINE_TOOLS_VERSION}.zip -O commandlinetools-linux.zip \
  && echo "${ANDROID_COMMAND_LINE_TOOLS_SHA1SUM}  commandlinetools-linux.zip" | sha1sum -c \
  && unzip -qq commandlinetools-linux \
  && mv -f tools/ ${ANDROID_CMDLINE_TOOLS}/ \
  && rm -f commandlinetools-linux.zip
RUN yes | sdkmanager "tools" \
#  && yes | sdkmanager "cmdline-tools;latest" \
#  && yes | sdkmanager "emulator" \
#  && yes | sdkmanager "platform-tools" \
#  && yes | sdkmanager "patcher;v4" \
#  && yes | sdkmanager "ndk-bundle" \
#  && yes | sdkmanager "system-images;android-21;default;x86" \
#  && yes | sdkmanager "platforms;android-30" \
#  && yes | sdkmanager "platforms;android-29" \
#  && yes | sdkmanager "build-tools;30.0.2" \
#  && yes | sdkmanager "build-tools;28.0.3" \
  && yes | sdkmanager "build-tools;29.0.3"
