# team_project2

TurtleBot3 Raspberry Pi 카메라 영상을 ROS 2로 받아 YOLO로 부품·사람을 검출하는 프로젝트입니다. 이미지 수집, 디지털 줌, Colab 학습·추가 학습을 포함합니다.

- 환경: Ubuntu 22.04 / ROS 2 Humble / Python 3.10, 기본 도메인 `44`
- 부품: `DHT11`, `bluetooth`, `led_green`, `led_red`, `led_yellow`, `rgb`, `usb`
- 기본 모델: 저화질 증강으로 추가 학습한 YOLO11n
- 흐름: `/csi/image_raw` → YOLO → `/yolo/image_raw`

## 설치 (노트북)

ROS 2 Humble이 설치된 환경에서 저장소 루트에서 실행합니다.

```bash
sudo apt install python3-venv ros-humble-rqt-image-view
python3 -m venv --system-site-packages yolo_training/.venv
yolo_training/.venv/bin/python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
yolo_training/.venv/bin/python -m pip install -r requirements.txt
```

## 카메라 실행 (라즈베리파이)

```bash
sudo apt install v4l-utils ros-humble-v4l2-camera
v4l2-ctl --list-devices
bash camera.sh /dev/video2
```

`/dev/video2`는 마지막 확인한 CSI MMAL 장치입니다. 재부팅하면 번호가 바뀔 수 있으므로 **mmal service의 캡처 장치**를 선택하세요. USB 웹캠·메타데이터 장치와 구분해야 합니다. 노트북과 로봇은 같은 네트워크와 도메인 `44`를 사용합니다.

## 검출 실행 (노트북)

```bash
# 화면 없이 검출 영상을 /yolo/image_raw로 발행
python3 python_project/yolo_ros.py --ros-args -p imgsz:=640

# 또는 검출기와 영상 창을 함께 실행
python3 python_project/yolo_preview.py --ros-args -p imgsz:=640
```

둘 중 하나만 실행합니다. 미리보기 모드는 `/yolo_preview/image_raw`를 사용하며 창을 닫으면 검출기도 종료합니다. Ctrl+C로도 종료할 수 있습니다. VS Code에서 이 저장소 폴더를 열고 F5로 실행할 수도 있습니다.

`imgsz:=320`은 속도 우선, `640`은 작은 부품 검출 우선입니다. 입력 토픽과 신뢰도 기준은 `-p input_topic:=/csi/image_raw -p confidence:=0.35`로 변경할 수 있습니다. 이 기준은 결과 필터이며 신뢰도 자체를 높이지 않습니다.

사람만 검출하려면 사전 학습 모델을 선택합니다. 최초 실행에는 다운로드가 필요합니다.

```bash
python3 python_project/yolo_ros.py --ros-args \
  -p weights:=yolo26n.pt -p person_only:=true -p imgsz:=320
```

`person_only`는 COCO 사전 학습 모델의 사람(ID 0) 필터입니다. 부품 모델에는 사용하지 마세요. 클래스 필터만으로 모델 전체 추론 연산이 크게 줄어들지는 않습니다.

## 이미지 수집 / 줌

```bash
source /opt/ros/humble/setup.bash
export ROS_DOMAIN_ID=44
# 기본 1초 간격, ~/camera_dataset/images에 저장
/usr/bin/python3 python_project/test.py --count 100
# 디지털 줌 영상을 발행한 뒤 다른 터미널에서 캡처
/usr/bin/python3 yolo_training/zoom_camera.py --ros-args -p zoom:=1.5
/usr/bin/python3 python_project/zoom_test.py --count 100
```

줌 영상은 `/camera/zoom`, 줌 캡처는 `~/camera_dataset/zoom_images`에 저장합니다. 디지털 확대는 세부 정보를 복원하지 않습니다.

## Colab 학습

- 처음 학습: `colab/train_components7_yolo11.ipynb` → GPU 런타임 → 업로드 셀에서 `colab/components_dataset.zip` 선택
- 추가 학습: `colab/finetune_components7_lowres.ipynb` → 업로드 셀에서 `colab/components7_finetune_bundle.zip` 선택
- 학습 결과 `best.pt`를 `yolo_training/best_components7_finetuned.pt`로 교체해 적용

학습 243장 / 검증 63장. 추가 학습 모델의 검증 mAP@50은 99.5%, mAP@50–95는 74.3%입니다. 동일 촬영 환경의 소규모 검증이며 실시간 정확도를 보장하지 않습니다. LED 색상을 유지하면서 해상도 저하·흐림·압축·노이즈를 증강했습니다. `electric bulb`는 제외했고 단색 LED 박스는 금속 핀을 제외합니다.

## 실행 영상

[영상 1 · 09:48:57](videos/demo_01.webm) · [영상 2 · 09:49:22](videos/demo_02.webm) · [영상 3 · 09:54:15](videos/demo_03.webm)

원본 스크린캐스트 3개를 `videos/`에 포함했습니다. GitHub에서 미리보기가 제공되지 않으면 파일을 다운로드해 재생하세요.
