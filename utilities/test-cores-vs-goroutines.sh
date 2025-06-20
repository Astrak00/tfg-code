#!/usr/bin/env bash
set -euo pipefail

echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 1 > "processes 0 -- gorotines 1".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 1 > "processes 0 -- gorotines 1".log 2>&1 &
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 2 > "processes 0 -- gorotines 2".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 2 > "processes 0 -- gorotines 2".log 2>&1 &
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 1-2 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 2 > "processes 1-2 -- gorotines 2".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 1-2 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 2 > "processes 1-2 -- gorotines 2".log 2>&1 &
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 3-4 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 4 > "processes 3-4 -- gorotines 4".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 3-4 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 4 > "processes 3-4 -- gorotines 4".log 2>&1 &
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 5-8 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 4 > "processes 5-8 -- gorotines 4".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 5-8 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 4 > "processes 5-8 -- gorotines 4".log 2>&1 &
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 9-12 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 8 > "processes 9-12 -- gorotines 8".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 9-12 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 8 > "processes 9-12 -- gorotines 8".log 2>&1 &
wait
# 8 cores
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-7 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 8 > "processes 0-7 -- gorotines 8".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-7 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 8 > "processes 0-7 -- gorotines 8".log 2>&1 &
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 8-15 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 16 > "processes 8-15 -- gorotines 16".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 8-15 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 16 > "processes 8-15 -- gorotines 16".log 2>&1 &
wait
# 14 cores
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-13 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 14 > "processes 0-13 -- gorotines 14".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-13 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 14 > "processes 0-13 -- gorotines 14".log 2>&1 &
wait
# wait
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-13 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 28 > "processes 0-13 -- gorotines 28".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-13 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 28 > "processes 0-13 -- gorotines 28".log 2>&1 &
wait
# 16 cores
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 16 > "processes 0-15 -- gorotines 16".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 16 > "processes 0-15 -- gorotines 16".log 2>&1 &
wait
# wait
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 32 > "processes 0-15 -- gorotines 32".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 32 > "processes 0-15 -- gorotines 32".log 2>&1 &
wait
# 28 cores Same CPU
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-27 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 28 > "processes 0-27 -- gorotines 28".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-27 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 28 > "processes 0-27 -- gorotines 28".log 2>&1 &
wait
# wait
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-27 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 56 > "processes 0-27 -- gorotines 56".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-27 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 56 > "processes 0-27 -- gorotines 56".log 2>&1 &
wait
# 28 cores real-cores CPU
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-43  ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 28 > "processes 0-15,32-43  -- gorotines 28".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-43  ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 28 > "processes 0-15,32-43  -- gorotines 28".log 2>&1 &
wait
# wait
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-43  ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 56 > "processes 0-15,32-43  -- gorotines 56".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-43  ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 56 > "processes 0-15,32-43  -- gorotines 56".log 2>&1 &
wait
# 32 cores

wait
# 32 cores
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 32 > "processes 0-15,32-47 -- gorotines 32".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 32 > "processes 0-15,32-47 -- gorotines 32".log 2>&1 &
wait
# 32 cores Same CPU (using first 32 logical cores)
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-31 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 32 > "processes 0-31 -- gorotines 32".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-31 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 32 > "processes 0-31 -- gorotines 32".log 2>&1 &
wait
# 32 cores 
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 64 > "processes 0-15,32-47 -- gorotines 64".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-15,32-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 64 > "processes 0-15,32-47 -- gorotines 64".log 2>&1 &
wait
# 32 cores Same CPU
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-31 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 64 > "processes 0-31 -- gorotines 64".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-31 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 64 > "processes 0-31 -- gorotines 64".log 2>&1 &


wait
# 48 cores 
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 48 > "processes 0-47 -- gorotines 48".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 48 > "processes 0-47 -- gorotines 48".log 2>&1 &
wait
# 48 cores 
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 96 > "processes 0-47 -- gorotines 96".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-47 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 96 > "processes 0-47 -- gorotines 96".log 2>&1 &
wait
# 60 cores 
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 60 > "processes 0-30,32-62 -- gorotines 60".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 60 > "processes 0-30,32-62 -- gorotines 60".log 2>&1 &
wait
# 60 cores 
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 120 > "processes 0-30,32-62 --cores-- gorotines 20".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 120 > "processes 0-30,32-62 --cores-- gorotines 20".log 2>&1 &
wait
# 60 cores with 200 threads
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 200 > "processes 0-30,32-62 --cores-- gorotines 200".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 200 > "processes 0-30,32-62 --cores-- gorotines 200".log 2>&1 &
wait
# 60 cores with 250 threads
echo "nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 250 > "processes 0-30,32-62 --cores-- gorotines 250".log 2>&1 &"
nohup perf stat -r 5 -e power/energy-pkg/,power/energy-ram/ taskset -c 0-30,32-62 ../ray-tracer --path ../../sphere_data.txt --output go.ppm --cores 250 > "processes 0-30,32-62 --cores-- gorotines 250".log 2>&1 &
