#!/usr/bin/env bash
# Run the LED fine-tuned candidate using this checkout's model and runtime.
set -e

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source /opt/ros/humble/setup.bash
export ROS_DOMAIN_ID=44
export TURTLEBOT3_MODEL=waffle_pi

YOLO_LED_WEIGHTS="$PROJECT_DIR/yolo_training/best_led_multiscene_20261026.pt"
if [ ! -f "$YOLO_LED_WEIGHTS" ]; then
  echo "모델 파일을 찾을 수 없습니다: $YOLO_LED_WEIGHTS" >&2
  exit 1
fi

printf 'ROS_DOMAIN_ID=%s | LED 추가 학습 모델 | imgsz=640\n' "$ROS_DOMAIN_ID"
exec /usr/bin/python3 "$PROJECT_DIR/python_project/yolo_switch.py" \
  --ros-args \
  -p weights:="$YOLO_LED_WEIGHTS" \
  -p imgsz:=640 \
  "$@"
