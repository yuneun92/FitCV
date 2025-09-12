import os
import sys
from pathlib import Path

# 프로젝트 루트(/Users/yuneun/Desktop/Projects/fitcv)를 sys.path에 추가
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

# 패키지 루트(FitCV)도 보조적으로 추가
FITCV_ROOT = PROJECT_ROOT / "FitCV"
if str(FITCV_ROOT) not in sys.path:
    sys.path.insert(0, str(FITCV_ROOT)) 