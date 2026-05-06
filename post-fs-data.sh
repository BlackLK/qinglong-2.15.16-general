if [ -d "/data/local/debian" ];then
rm -rf /data/debian
mv /data/local/debian /data
fi
${0%/*}/init /data/debian
