#!/bin/sh
set -e
export WORLDPATH=${HOME}/.minetest/worlds/world

# create directory skeleton
mkdir -p ${WORLDPATH}/worldmods/

# clone dependencies
cd ${WORLDPATH}/worldmods/
for dep in ${INPUT_GIT_DEPENDENCIES}
do
    git clone --depth=1 $dep
done

# add the mtt mod if it does not exist
test -d ${WORLDPATH}/worldmods/mtt ||{
    git clone --depth=1 https://github.com/BuckarooBanzay/mtt
}

# install game
cd ${WORLDPATH}/
git clone --depth=1 ${INPUT_GIT_GAME_REPO} game

# create link to current mod
ln -s /github/workspace ${WORLDPATH}/worldmods/${INPUT_MODNAME}

# assemble minetest.conf
cat <<EOF > /minetest.conf
mg_name = ${INPUT_MAPGEN}
mtt_filter = ${INPUT_MODNAME}
mtt_enable = true
secure.trusted_mods = mtt
EOF
echo "${INPUT_ADDITIONAL_CONFIG}" >> /minetest.conf

test "${INPUT_ENABLE_COVERAGE}" == "true" && echo "mtt_enable_coverage = true" >> /minetest.conf
test "${INPUT_ENABLE_BENCHMARKS}" == "true" && echo "mtt_enable_benchmarks = true" >> /minetest.conf

# simple world.mt
cat <<EOF > ${WORLDPATH}/world.mt
enable_damage = false
creative_mode = true
mod_storage_backend = sqlite3
auth_backend = sqlite3
player_backend = dummy
backend = dummy
gameid = game
world_name = mtt
EOF

# start the engine
minetestserver --config /minetest.conf --world ${WORLDPATH}

# coverage filename replace
test "${INPUT_ENABLE_COVERAGE}" == "true" &&{
    sed -i "s#${WORLDPATH}/worldmods/${INPUT_MODNAME}/##g" ${WORLDPATH}/lcov.info
    mkdir /github/workspace/coverage
    cp ${WORLDPATH}/lcov.info /github/workspace/coverage/
}