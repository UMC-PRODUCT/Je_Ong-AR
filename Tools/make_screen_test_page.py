#!/usr/bin/env python3
"""
카드 9장을 화면에 실제 물리 크기(90x127mm)로 띄우는 테스트 페이지를 만든다.

화면 표시로 인식을 1차 확인할 때, 표시 크기가 레퍼런스 이미지에 등록된 물리 크기와
어긋나면 ARKit이 앵커를 엉뚱한 거리에 놓는다. CSS의 mm 단위는 실제 화면 크기를 모르므로
(96 CSS px/inch 가정), 실물 카드로 px/mm를 직접 맞추는 캘리브레이션이 필요하다.

출력: 이미지를 data URI로 인라인한 단일 HTML.
"""

import base64
import io
import json
import os

from PIL import Image

SRC = os.environ.get("SRC_DIR", "../Docs/Assets/ReferenceCards/cards")
OUT = os.environ.get("OUT_HTML", "./techcards-screen-test.html")

# 화면 표시용 해상도. 90mm 폭을 220ppi 상당으로 — 레티나에서도 충분하다.
SCREEN_PX = (780, 1101)

# 패턴 계열은 README 표와 같다. 어느 카드가 왜 그렇게 생겼는지 대조할 때 쓴다.
PATTERNS = {
    "corelocation": "편심 방사선",
    "apple-intelligence": "노드-엣지 그래프",
    "cloudkit": "편심 동심호",
    "coreml": "회전 사각형 격자",
    "foundation-models": "어긋난 벽돌",
    "liquid-glass": "사선 밴드",
    "sirikit": "셰브론 파편",
    "nearby-interaction": "산개 삼각형",
    "widgetkit": "L자 코너 조각",
}

TEMPLATE = r"""<title>TechCards 캘리브레이션 시트</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans+KR:wght@400;500;600;700&display=swap">

<style>
  /* 라이트 팔레트 전체. 다크는 아래에서 토큰만 다시 정의한다. */
  :root {
    --ground:    #eef0f2;
    --surface:   #ffffff;
    --surface-2: #e3e6e9;
    --ink:       #14181b;
    --ink-2:     #5c646c;
    --ink-3:     #8b939b;
    --line:      #ccd2d8;
    --line-2:    #aab2ba;
    --accent:    #1d5fb0;
    --accent-in: #ffffff;
    --ok:        #2c7a4d;
    --warn:      #a75f1c;
    --stage:     #0b0d0e;

    --f-ui: "IBM Plex Sans KR", ui-sans-serif, system-ui, -apple-system, sans-serif;
    --f-mono: "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, monospace;

    --ppmm: 3.7795;           /* 캘리브레이션 전 기본값: 96 CSS px / inch */
  }

  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --ground:    #0f1214;
      --surface:   #171b1e;
      --surface-2: #212528;
      --ink:       #e7eaec;
      --ink-2:     #98a1a9;
      --ink-3:     #6c757d;
      --line:      #2c3236;
      --line-2:    #3d454a;
      --accent:    #6aa5ec;
      --accent-in: #0b0f14;
      --ok:        #57b981;
      --warn:      #d29a55;
      --stage:     #000000;
    }
  }

  :root[data-theme="dark"] {
    --ground:    #0f1214;
    --surface:   #171b1e;
    --surface-2: #212528;
    --ink:       #e7eaec;
    --ink-2:     #98a1a9;
    --ink-3:     #6c757d;
    --line:      #2c3236;
    --line-2:    #3d454a;
    --accent:    #6aa5ec;
    --accent-in: #0b0f14;
    --ok:        #57b981;
    --warn:      #d29a55;
    --stage:     #000000;
  }

  * { box-sizing: border-box; }

  body {
    margin: 0;
    background: var(--ground);
    color: var(--ink);
    font-family: var(--f-ui);
    font-size: 15px;
    line-height: 1.55;
    -webkit-font-smoothing: antialiased;
  }

  .wrap {
    max-width: 1180px;
    margin: 0 auto;
    padding: 32px 24px 72px;
    display: flex;
    flex-direction: column;
    gap: 28px;
  }

  /* ---------------------------------------------------------------- 헤더 */

  header { display: flex; flex-direction: column; gap: 10px; }

  .eyebrow {
    font-family: var(--f-mono);
    font-size: 11px;
    letter-spacing: .14em;
    text-transform: uppercase;
    color: var(--ink-3);
  }

  h1 {
    margin: 0;
    font-size: clamp(26px, 4vw, 38px);
    font-weight: 600;
    letter-spacing: -.015em;
    text-wrap: balance;
  }

  .lede { margin: 0; max-width: 62ch; color: var(--ink-2); }

  /* ---------------------------------------------------------------- 계기 */

  .panel {
    background: var(--surface);
    border: 1px solid var(--line);
    border-radius: 4px;
  }

  .panel-head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 16px;
    flex-wrap: wrap;
    padding: 14px 18px;
    border-bottom: 1px solid var(--line);
  }

  .panel-title {
    font-size: 13px;
    font-weight: 600;
    letter-spacing: .02em;
  }

  .panel-note { font-size: 12.5px; color: var(--ink-2); }

  .calib-body {
    padding: 18px;
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 24px;
    align-items: start;
  }

  @media (max-width: 720px) {
    .calib-body { grid-template-columns: minmax(0, 1fr); }
  }

  .calib-controls { display: flex; flex-direction: column; gap: 14px; min-width: 0; }

  .steps {
    margin: 0;
    padding-left: 1.15em;
    font-size: 13.5px;
    color: var(--ink-2);
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .steps li::marker { color: var(--ink-3); font-family: var(--f-mono); }

  input[type="range"] {
    width: 100%;
    accent-color: var(--accent);
  }

  .readout {
    display: flex;
    gap: 22px;
    flex-wrap: wrap;
    font-family: var(--f-mono);
    font-size: 12.5px;
    font-variant-numeric: tabular-nums;
  }
  .readout div { display: flex; flex-direction: column; gap: 2px; }
  .readout dt { color: var(--ink-3); font-size: 10.5px; letter-spacing: .1em; text-transform: uppercase; }
  .readout dd { margin: 0; font-size: 15px; font-weight: 500; }

  /* 실물 ID-1 카드(85.60 x 53.98 mm)를 맞대는 기준 사각형 */
  .id1 {
    border: 1.5px solid var(--accent);
    border-radius: 3.18px;             /* ID-1 규격 모서리 */
    background: repeating-linear-gradient(
      -45deg, transparent 0 7px, color-mix(in srgb, var(--accent) 12%, transparent) 7px 14px);
    display: grid;
    place-items: center;
    font-family: var(--f-mono);
    font-size: 11px;
    color: var(--accent);
    text-align: center;
    padding: 6px;
  }

  .ruler {
    position: relative;
    height: 34px;
    border-left: 1px solid var(--line-2);
    border-bottom: 1px solid var(--line-2);
    overflow: hidden;
  }
  .ruler i {
    position: absolute;
    bottom: 0;
    width: 1px;
    background: var(--line-2);
  }
  .ruler b {
    position: absolute;
    bottom: 14px;
    font-family: var(--f-mono);
    font-size: 9.5px;
    color: var(--ink-3);
    transform: translateX(2px);
    font-weight: 400;
  }

  /* ---------------------------------------------------------------- 버튼 */

  .row { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }

  button {
    font: inherit;
    font-size: 13px;
    font-weight: 500;
    padding: 7px 14px;
    border-radius: 3px;
    border: 1px solid var(--line-2);
    background: var(--surface);
    color: var(--ink);
    cursor: pointer;
    transition: background .12s ease, border-color .12s ease;
  }
  button:hover { background: var(--surface-2); }
  button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  button.primary { background: var(--accent); border-color: var(--accent); color: var(--accent-in); }
  button.primary:hover { filter: brightness(1.08); }

  /* ---------------------------------------------------------------- 격자 */

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 18px;
  }

  .card {
    display: flex;
    flex-direction: column;
    gap: 9px;
    padding: 0;
    border: 1px solid var(--line);
    background: var(--surface);
    border-radius: 4px;
    overflow: hidden;
    text-align: left;
    cursor: pointer;
  }
  .card:hover { border-color: var(--accent); background: var(--surface); }
  .card img { width: 100%; display: block; aspect-ratio: 90 / 127; object-fit: cover; }

  /* ---------------------------------------------------------------- 무대 */

  .stage {
    position: fixed;
    inset: 0;
    background: var(--stage);
    display: none;
    place-items: center;
    z-index: 50;
  }
  .stage[data-open="true"] { display: grid; }

  .stage-scroll {
    width: 100%;
    height: 100%;
    overflow: auto;
    display: grid;
    place-items: center;
    padding: 16px;
  }

  .sheet { display: grid; gap: 10px; }
  .sheet img {
    display: block;
    width: calc(var(--ppmm) * 90px);
    height: calc(var(--ppmm) * 127px);
  }
  .sheet[data-fit="true"] img {
    width: auto;
    height: min(92vh, calc(92vw * 127 / 90));
  }
  .sheet[data-mode="all"] { grid-template-columns: repeat(3, max-content); }

  .hud {
    position: fixed;
    top: 0; left: 0; right: 0;
    display: flex;
    gap: 14px;
    align-items: center;
    flex-wrap: wrap;
    padding: 10px 14px;
    background: color-mix(in srgb, var(--stage) 82%, transparent);
    color: #e9ecee;
    font-family: var(--f-mono);
    font-size: 12px;
    font-variant-numeric: tabular-nums;
    border-bottom: 1px solid #23282b;
  }
  .hud[hidden] { display: none; }
  .hud .sp { flex: 1; }
  .hud button {
    background: #1b1f22;
    border-color: #333a3e;
    color: #e9ecee;
    font-family: var(--f-ui);
  }
  .hud button:hover { background: #262b2f; }
  .hud .measure { color: #7fb2f0; }

  kbd {
    font-family: var(--f-mono);
    font-size: 11px;
    padding: 1px 5px;
    border: 1px solid var(--line-2);
    border-bottom-width: 2px;
    border-radius: 3px;
    color: var(--ink-2);
  }
  .hud kbd { border-color: #3a4247; color: #aeb6bc; }

  /* ---------------------------------------------------------------- 주의 */

  .notes { display: flex; flex-direction: column; gap: 12px; }
  .note {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    gap: 12px;
    align-items: start;
    padding: 13px 16px;
    border: 1px solid var(--line);
    border-left: 3px solid var(--warn);
    background: var(--surface);
    border-radius: 3px;
    font-size: 13.5px;
    color: var(--ink-2);
  }
  .note b { color: var(--ink); font-weight: 600; }
  .note .k {
    font-family: var(--f-mono);
    font-size: 10.5px;
    letter-spacing: .1em;
    text-transform: uppercase;
    color: var(--warn);
    padding-top: 2px;
  }

  footer {
    font-size: 12.5px;
    color: var(--ink-3);
    border-top: 1px solid var(--line);
    padding-top: 16px;
  }

  @media (prefers-reduced-motion: reduce) {
    * { transition: none !important; animation: none !important; }
  }
</style>

<div class="wrap">
  <header>
    <span class="eyebrow">ARKit Reference Images · TechCards</span>
    <h1>화면으로 먼저 확인하는 카드 인식</h1>
    <p class="lede">
      인쇄 전에 9장이 서로 구분되어 인식되는지 화면으로 1차 확인합니다.
      레퍼런스 이미지에는 <b>90 × 127 mm</b>가 등록되어 있으므로, 화면에도 같은 크기로
      띄워야 앵커가 맞는 거리에 붙습니다. 먼저 아래에서 화면을 맞추세요.
    </p>
  </header>

  <section class="panel">
    <div class="panel-head">
      <span class="panel-title">1 · 화면 캘리브레이션</span>
      <span class="panel-note">CSS는 실제 화면 크기를 모릅니다. 실물 카드로 직접 맞춥니다.</span>
    </div>
    <div class="calib-body">
      <div class="calib-controls">
        <ol class="steps">
          <li>신용카드·교통카드 등 <b>실물 카드</b>를 화면의 파란 사각형에 맞댑니다.</li>
          <li>사각형이 실물 카드와 정확히 같아질 때까지 슬라이더를 움직입니다.</li>
          <li>아래 눈금자를 실제 자로 재서 교차 확인하면 더 정확합니다.</li>
        </ol>

        <input id="cal" type="range" min="2" max="9" step="0.005" value="3.7795"
               aria-label="화면 배율 (밀리미터당 픽셀)">

        <dl class="readout">
          <div><dt>밀리미터당 픽셀</dt><dd id="r-ppmm">3.780</dd></div>
          <div><dt>화면 밀도</dt><dd id="r-dpi">96 dpi</dd></div>
          <div><dt>카드 표시 크기</dt><dd id="r-card">340 × 480 px</dd></div>
        </dl>

        <div class="ruler" id="ruler" aria-hidden="true"></div>

        <div class="row">
          <button type="button" id="reset">기본값으로</button>
          <span class="panel-note">설정은 이 브라우저에 기억됩니다.</span>
        </div>
      </div>

      <div class="id1" id="id1">
        ID-1<br>85.60 × 53.98 mm
      </div>
    </div>
  </section>

  <section class="panel">
    <div class="panel-head">
      <span class="panel-title">2 · 카드 9장</span>
      <span class="panel-note">
        카드를 누르면 실제 크기로 띄웁니다 · <kbd>←</kbd><kbd>→</kbd> 이동 ·
        <kbd>H</kbd> HUD 숨기기 · <kbd>Esc</kbd> 닫기
      </span>
    </div>
    <div style="padding:18px; display:flex; flex-direction:column; gap:16px;">
      <div class="row">
        <button type="button" class="primary" id="open-all">9장 한 번에 띄우기</button>
        <button type="button" id="open-first">1번부터 하나씩</button>
      </div>
      <div class="grid" id="grid"></div>
    </div>
  </section>

  <section class="notes">
    <div class="note">
      <span class="k">반사</span>
      <span><b>화면 표시는 스모크 테스트입니다.</b> Apple 문서도 유광 표면의 반사가 인식을
      방해한다고 명시합니다. 화면이 통과해도 인쇄물 검증을 건너뛰면 안 됩니다.
      화면 밝기를 낮추고 조명이 화면에 비치지 않는 각도에서 스캔하세요.</span>
    </div>
    <div class="note">
      <span class="k">크기</span>
      <span>캘리브레이션이 어긋나면 인식은 되어도 <b>마커가 카드와 안 맞습니다.</b>
      검증 앱에 뜨는 실측 크기가 <b>90×127mm</b>가 아니면 등록 문제, 마커만 어긋나면
      화면 배율 문제입니다.</span>
    </div>
    <div class="note">
      <span class="k">확인</span>
      <span>봐야 할 것 — 9장이 <b>각각</b> 인식되는가 · <b>오인식</b>되는 쌍이 있는가 ·
      초록 판이 카드에 겹치고 하늘색 판이 5cm 떠 있는가(설계 좌표계 검증).</span>
    </div>
  </section>

  <footer>
    카드 생성 <code>Tools/gen_reference_cards.py</code> · 리소스 그룹
    <code>Tools/make_ar_resource_group.py</code> · 검증 화면
    <code>ARCoreDemoApp → 이미지 인식 검증</code>
  </footer>
</div>

<div class="stage" id="stage" data-open="false">
  <div class="hud" id="hud">
    <span id="hud-pos">1 / 9</span>
    <span id="hud-name">CoreLocation</span>
    <span class="measure" id="hud-size">90 × 127 mm</span>
    <span class="sp"></span>
    <button type="button" id="btn-fit">화면에 맞추기</button>
    <button type="button" id="btn-hud">HUD 숨기기 <kbd>H</kbd></button>
    <button type="button" id="btn-close">닫기 <kbd>Esc</kbd></button>
  </div>
  <div class="stage-scroll">
    <div class="sheet" id="sheet" data-mode="one" data-fit="false"></div>
  </div>
</div>

<script>
  const CARDS = __CARDS__;

  const root = document.documentElement;
  const $ = (id) => document.getElementById(id);

  // ---------------------------------------------------------------- 캘리브레이션

  const DEFAULT_PPMM = 96 / 25.4;
  let ppmm = DEFAULT_PPMM;

  function load() {
    try {
      const v = parseFloat(localStorage.getItem("techcards.ppmm"));
      if (v > 0) return v;
    } catch (e) { /* 저장소가 막혀 있어도 동작해야 한다 */ }
    return DEFAULT_PPMM;
  }
  function save(v) {
    try { localStorage.setItem("techcards.ppmm", String(v)); } catch (e) {}
  }

  function applyPpmm(v) {
    ppmm = v;
    root.style.setProperty("--ppmm", String(v));
    $("id1").style.width = (85.60 * v) + "px";
    $("id1").style.height = (53.98 * v) + "px";
    $("r-ppmm").textContent = v.toFixed(3);
    $("r-dpi").textContent = Math.round(v * 25.4) + " dpi";
    $("r-card").textContent = Math.round(90 * v) + " × " + Math.round(127 * v) + " px";
    drawRuler();
    save(v);
  }

  function drawRuler() {
    const el = $("ruler");
    el.textContent = "";
    const maxMm = Math.min(120, Math.floor((el.clientWidth - 2) / ppmm));
    for (let mm = 0; mm <= maxMm; mm++) {
      const major = mm % 10 === 0;
      const mid = mm % 5 === 0;
      const t = document.createElement("i");
      t.style.left = (mm * ppmm) + "px";
      t.style.height = major ? "16px" : mid ? "10px" : "6px";
      el.appendChild(t);
      if (major && mm > 0) {
        const lab = document.createElement("b");
        lab.style.left = (mm * ppmm) + "px";
        lab.textContent = (mm / 10) + "cm";
        el.appendChild(lab);
      }
    }
  }

  $("cal").addEventListener("input", (e) => applyPpmm(parseFloat(e.target.value)));
  $("reset").addEventListener("click", () => {
    $("cal").value = DEFAULT_PPMM;
    applyPpmm(DEFAULT_PPMM);
  });
  window.addEventListener("resize", drawRuler);

  // ---------------------------------------------------------------- 격자

  const grid = $("grid");
  CARDS.forEach((c, i) => {
    const fig = document.createElement("figure");
    fig.className = "card";
    fig.tabIndex = 0;
    fig.setAttribute("role", "button");
    fig.setAttribute("aria-label", c.name + " 실제 크기로 띄우기");
    // 캡션 없이 카드만 보여준다. 카드에 글자가 없으므로 페이지에도 없어야
    // 실제로 인쇄될 모습과 같다.
    fig.innerHTML = '<img src="' + c.src + '" alt="' + c.name + '">';
    const open = () => openStage("one", i);
    fig.addEventListener("click", open);
    fig.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); open(); }
    });
    grid.appendChild(fig);
  });

  // ---------------------------------------------------------------- 무대

  const stage = $("stage"), sheet = $("sheet"), hud = $("hud");
  let index = 0, mode = "one";

  function render() {
    sheet.dataset.mode = mode;
    sheet.textContent = "";
    const list = mode === "all" ? CARDS : [CARDS[index]];
    list.forEach((c) => {
      const img = document.createElement("img");
      img.src = c.src;
      img.alt = c.name;
      sheet.appendChild(img);
    });
    const fit = sheet.dataset.fit === "true";
    $("hud-pos").textContent = mode === "all"
      ? "9장 전체"
      : (index + 1) + " / " + CARDS.length;
    $("hud-name").textContent = mode === "all" ? "격자" : CARDS[index].name;
    $("hud-size").textContent = fit ? "화면 맞춤 — 크기 부정확" : "90 × 127 mm";
    $("btn-fit").textContent = fit ? "실제 크기로" : "화면에 맞추기";
  }

  function openStage(m, i) {
    mode = m;
    index = i ?? 0;
    stage.dataset.open = "true";
    render();
    stage.focus();
  }
  function closeStage() { stage.dataset.open = "false"; }
  function step(d) {
    if (mode !== "one") return;
    index = (index + d + CARDS.length) % CARDS.length;
    render();
  }

  $("open-all").addEventListener("click", () => openStage("all"));
  $("open-first").addEventListener("click", () => openStage("one", 0));
  $("btn-close").addEventListener("click", closeStage);
  $("btn-hud").addEventListener("click", () => { hud.hidden = true; });
  $("btn-fit").addEventListener("click", () => {
    sheet.dataset.fit = sheet.dataset.fit === "true" ? "false" : "true";
    render();
  });

  document.addEventListener("keydown", (e) => {
    if (stage.dataset.open !== "true") return;
    if (e.key === "Escape") { hud.hidden ? (hud.hidden = false) : closeStage(); }
    else if (e.key === "ArrowRight" || e.key === " ") { e.preventDefault(); step(1); }
    else if (e.key === "ArrowLeft") { step(-1); }
    else if (e.key === "h" || e.key === "H") { hud.hidden = !hud.hidden; }
    else if (e.key === "f" || e.key === "F") { $("btn-fit").click(); }
  });

  // ---------------------------------------------------------------- 시작

  const initial = load();
  $("cal").value = initial;
  applyPpmm(initial);
</script>
"""


def main():
    cards = json.load(open(os.path.join(SRC, "cards.json"), encoding="utf-8"))
    payload = []
    for c in cards:
        im = Image.open(os.path.join(SRC, f"{c['id']}.png")).convert("RGB")
        im = im.resize(SCREEN_PX, Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=90, optimize=True)
        b64 = base64.b64encode(buf.getvalue()).decode("ascii")
        payload.append({
            "id": c["id"],
            "name": c["name"],
            "tag": c["tag"],
            "pattern": PATTERNS.get(c["id"], ""),
            "src": "data:image/jpeg;base64," + b64,
        })

    html = TEMPLATE.replace("__CARDS__", json.dumps(payload, ensure_ascii=False))
    with open(OUT, "w", encoding="utf-8") as fp:
        fp.write(html)

    size = os.path.getsize(OUT)
    print(f"  {len(payload)}장 인라인 → {OUT}")
    print(f"  {size / 1024 / 1024:.2f} MB")


if __name__ == "__main__":
    main()
