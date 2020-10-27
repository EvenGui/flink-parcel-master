function set-dependencies {
  # Generating Zookeeper quorum
  QUORUM=$ZK_QUORUM
  if [[ -n $CHROOT ]]; then
    QUORUM="${QUORUM}${CHROOT}"
  fi

  echo "Setting ZK Quorum to ${QUORUM}..."
  perl -pi -e "s#\#high-availability.zookeeper.quorum: \{\{QUORUM}}#high-availability.zookeeper.quorum: ${QUORUM}#" $FLINK_CONF_DIR/flink-conf.yaml

  DEFAULT_DB="default_database"
  if [[ "${ENABLE_HIVE_CATALOG}" == "true" ]]; then
    echo "enabling hive catalog in sql-client-defaults.yaml"
    sed -i 's/^catalogs.*$/catalogs: \n  - name: hive\n    type: hive\n    hive-conf-dir: \/etc\/hive\/conf\n    hive-version: 2.1.1/g' $FLINK_CONF_DIR/sql-client-defaults.yaml

    if [[ "${SQL_CATALOG}" == "HIVE" ]]; then
      sed -i -E "s/(^\s*current\-catalog:)(.*)/\1 hive/g" $FLINK_CONF_DIR/sql-client-defaults.yaml
      DEFAULT_DB="default"
    fi
  else
    echo "hive catalog is not enabled"
  fi

  if [[ -n "${SQL_DEFAULT_DB}" ]]; then
    DEFAULT_DB="${SQL_DEFAULT_DB}"
  fi
  sed -i -E "s/(^\s*current\-database:)(.*)/\1 $DEFAULT_DB/g" $FLINK_CONF_DIR/sql-client-defaults.yaml
}
