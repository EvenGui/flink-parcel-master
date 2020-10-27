function configbuilder {
   CONFIG_JSON=$1
   echo "Running configbuilder..."
   ${JAVA_HOME}/bin/java -Dorg.slf4j.simpleLogger.logFile=System.out -Dconfiguration=${CONFIG_JSON} -jar ${FLINK_BIN}/configbuilder.jar
}