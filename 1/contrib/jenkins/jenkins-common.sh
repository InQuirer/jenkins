#!/bin/sh

export JENKINS_HOME=/var/lib/jenkins
export CONFIG_PATH=${JENKINS_HOME}/config.xml
export OPENSHIFT_API_URL=https://openshift.default.svc.cluster.local
export KUBE_SA_DIR=/run/secrets/kubernetes.io/serviceaccount
export KUBE_CA=${KUBE_SA_DIR}/ca.crt
export AUTH_TOKEN=${KUBE_SA_DIR}/token
export JENKINS_PASSWORD KUBERNETES_SERVICE_HOST KUBERNETES_SERVICE_PORT
export ITEM_ROOTDIR="\${ITEM_ROOTDIR}" # Preserve this variable Jenkins has in config.xml

# Generate passwd file based on current uid
function generate_passwd_file() {
  export USER_ID=$1
  export GROUP_ID=$2
  envsubst < /opt/openshift/passwd.template > /opt/openshift/passwd
  export LD_PRELOAD=libnss_wrapper.so
  export NSS_WRAPPER_PASSWD=/opt/openshift/passwd
  export NSS_WRAPPER_GROUP=/etc/group

  USER_ID=$(id -u)
  GROUP_ID=$(id -g)

  if [ x"$USER_ID" != x"0" -a x"$USER_ID" != x"1001" ]; then

    NSS_WRAPPER_PASSWD=/opt/openshift/passwd
    NSS_WRAPPER_GROUP=/etc/group

    echo "jenkins:x:${USER_ID}:${GROUP_ID}:Jenkins Continuous Integration Server:${JENKINS_HOME}:/bin/false" >> $NSS_WRAPPER_PASSWD

    export NSS_WRAPPER_PASSWD
    export NSS_WRAPPER_GROUP
    export LD_PRELOAD=libnss_wrapper.so
  fi
}

function obfuscate_password {
    local password="$1"
    local acegi_security_path=`find /tmp/war/WEB-INF/lib/ -name acegi-security-*.jar`
    local commons_codec_path=`find /tmp/war/WEB-INF/lib/ -name commons-codec-*.jar`

    java -classpath "${acegi_security_path}:${commons_codec_path}:/opt/openshift/password-encoder.jar" com.redhat.openshift.PasswordEncoder $password
}