function set-dependencies {
  # Generating Zookeeper quorum
  QUORUM=$ZK_QUORUM
  if [[ -n $CHROOT ]]; then
    QUORUM="${QUORUM}${CHROOT}"
  fi

  echo "Setting ZK Quorum to ${QUORUM}..."
  perl -pi -e "s#\#high-availability.zookeeper.quorum: \{\{QUORUM}}#high-availability.zookeeper.quorum: ${QUORUM}#" $FLINK_CONF_DIR/flink-conf.yaml
}
