#!/bin/bash
# AR Resource Group이 제대로 컴파일되는지 actool로 검증한다.
#
# 빌드 통과만으로는 부족하다. unit을 잘못 쓰면 actool이 에러 없이 Physical Size를
# 0.01,0.01로 떨어뜨리기 때문에, 컴파일된 .car를 열어 실제 값을 확인해야 한다.
#
# 사용법: Tools/verify_ar_resource_group.sh [xcassets 경로] [기대 카드 수]

set -euo pipefail

export XCASSETS="${1:-$(dirname "$0")/../ARCoreDemoApp/ARCoreDemoApp/Resources/Assets.xcassets}"
export EXPECTED="${2:-9}"
export EXPECT_SIZE="0.09,0.13"        # 90 x 127 mm

ACTOOL=/Applications/Xcode.app/Contents/Developer/usr/bin/actool
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

echo "검증 대상: $XCASSETS"
echo

"$ACTOOL" "$XCASSETS" --compile "$OUT" --platform iphoneos \
  --minimum-deployment-target 17.0 --output-format human-readable-text >/dev/null

xcrun assetutil --info "$OUT/Assets.car" > "$OUT/info.json"

INFO_JSON="$OUT/info.json" python3 - <<'PY'
import json, os, sys

d = json.load(open(os.environ["INFO_JSON"]))
expected = int(os.environ["EXPECTED"])
expect_size = os.environ["EXPECT_SIZE"]

groups = [e for e in d if e.get("AssetType") == "Recognition Group"]
imgs = [e for e in d if e.get("AssetType") == "Recognition Image"]

print("Recognition Group:")
for g in groups:
    print(f"  {g.get('Name')}  —  {len(g.get('Contents', []))}장")
print()

print("Recognition Image:")
bad = 0
for e in sorted(imgs, key=lambda x: x.get("Name", "")):
    size = e.get("Physical Size", "?")
    ok = size == expect_size
    if not ok:
        bad += 1
    print(f"  {'OK ' if ok else 'BAD'} {e.get('Name','?'):<22} {size:<12} "
          f"{e.get('PixelWidth')}x{e.get('PixelHeight'):<6} {e.get('ColorModel','?')}")
print()

if not groups:
    sys.exit("FAIL: Recognition Group이 없다")
if len(imgs) != expected:
    sys.exit(f"FAIL: 레퍼런스 이미지가 {len(imgs)}장이다 (기대 {expected}장)")
if bad:
    sys.exit(f"FAIL: 물리 크기가 틀린 이미지 {bad}장 (기대 {expect_size} m)")
print(f"PASS: {len(imgs)}장 모두 물리 크기 {expect_size} m 로 컴파일됨")
PY
