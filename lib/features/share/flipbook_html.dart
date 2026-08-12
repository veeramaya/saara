import 'dart:convert';
import 'dart:typed_data';

/// Build a single **self-contained** HTML flipbook from a set of card images
/// (§13). Every image is embedded as a base64 data URI — no server, no external
/// fonts, no internet. It opens in any browser and works fully offline, so a
/// committed listener outside Saara can flip through the book you send them.
///
/// [pages] are PNG bytes, one per card face, in order. [captions] (optional)
/// label each page. The result is a complete HTML document string.
String buildFlipbookHtml({
  required String title,
  required List<Uint8List> pages,
  List<String>? captions,
}) {
  final figures = StringBuffer();
  for (var i = 0; i < pages.length; i++) {
    final b64 = base64Encode(pages[i]);
    final cap = (captions != null && i < captions.length) ? captions[i] : '';
    figures.writeln(
      '<figure class="page${i == 0 ? ' on' : ''}">'
      '<img alt="${_esc(cap.isEmpty ? 'Card ${i + 1}' : cap)}" '
      'src="data:image/png;base64,$b64"/>'
      '${cap.isEmpty ? '' : '<figcaption>${_esc(cap)}</figcaption>'}'
      '</figure>',
    );
  }

  final safeTitle = _esc(title);
  // JS avoids template literals and the dollar sign so it survives Dart's
  // string interpolation untouched; only $safeTitle / $figures are injected.
  return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>$safeTitle</title>
<style>
  :root { color-scheme: dark light; }
  * { box-sizing: border-box; }
  html, body { margin: 0; height: 100%; }
  body {
    background: #0E0E12; color: #EDE8E2;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    display: flex; flex-direction: column; min-height: 100%;
  }
  header { text-align: center; padding: 16px 16px 4px; }
  header h1 { margin: 0; font-size: 17px; font-weight: 700; letter-spacing: .2px; }
  header p { margin: 4px 0 0; font-size: 12px; opacity: .55; }
  .stage {
    flex: 1; display: flex; align-items: center; justify-content: center;
    perspective: 1600px; padding: 12px; overflow: hidden;
  }
  .deck { position: relative; width: min(88vw, 380px); }
  .deck::before { content: ""; display: block; padding-top: 122.6%; } /* 466/380 */
  .page {
    position: absolute; inset: 0; margin: 0;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    opacity: 0; transform: rotateY(12deg) translateX(24px) scale(.98);
    transition: opacity .38s ease, transform .38s ease;
    pointer-events: none;
  }
  .page.on { opacity: 1; transform: none; pointer-events: auto; }
  .page.left { transform: rotateY(-12deg) translateX(-24px) scale(.98); }
  .page img {
    width: 100%; height: auto; border-radius: 18px;
    box-shadow: 0 18px 50px rgba(0,0,0,.55);
    display: block;
  }
  .page figcaption { margin-top: 10px; font-size: 12px; opacity: .6; }
  nav {
    display: flex; align-items: center; justify-content: center; gap: 18px;
    padding: 10px 16px calc(16px + env(safe-area-inset-bottom));
  }
  button.arrow {
    appearance: none; border: 0; cursor: pointer;
    width: 44px; height: 44px; border-radius: 50%;
    background: rgba(255,255,255,.10); color: inherit; font-size: 20px;
  }
  button.arrow:hover { background: rgba(255,255,255,.18); }
  button.arrow:disabled { opacity: .3; cursor: default; }
  .dots { display: flex; gap: 7px; align-items: center; flex-wrap: wrap; justify-content: center; max-width: 60vw; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: rgba(255,255,255,.28); }
  .dot.on { background: #E7C46B; width: 10px; height: 10px; }
  .count { font-size: 12px; opacity: .6; min-width: 46px; text-align: center; }
  @media (prefers-color-scheme: light) {
    body { background: #EDE9E5; color: #1B1613; }
    .dot { background: rgba(0,0,0,.25); }
    button.arrow { background: rgba(0,0,0,.08); }
  }
</style>
</head>
<body>
<header>
  <h1>$safeTitle</h1>
  <p>Tap the arrows, swipe, or use the arrow keys.</p>
</header>
<div class="stage">
  <div class="deck" id="deck">
$figures
  </div>
</div>
<nav>
  <button class="arrow" id="prev" aria-label="Previous">&#8249;</button>
  <div class="dots" id="dots"></div>
  <span class="count" id="count"></span>
  <button class="arrow" id="next" aria-label="Next">&#8250;</button>
</nav>
<script>
(function () {
  var pages = Array.prototype.slice.call(document.querySelectorAll(".page"));
  var deck = document.getElementById("deck");
  var prev = document.getElementById("prev");
  var next = document.getElementById("next");
  var dotsWrap = document.getElementById("dots");
  var count = document.getElementById("count");
  var i = 0;
  for (var d = 0; d < pages.length; d++) {
    var dot = document.createElement("span");
    dot.className = "dot";
    (function (n) { dot.addEventListener("click", function () { go(n); }); })(d);
    dotsWrap.appendChild(dot);
  }
  var dots = Array.prototype.slice.call(dotsWrap.children);
  function render() {
    for (var p = 0; p < pages.length; p++) {
      pages[p].classList.remove("on", "left");
      if (p === i) pages[p].classList.add("on");
      else if (p < i) pages[p].classList.add("left");
      dots[p].classList.toggle("on", p === i);
    }
    count.textContent = (i + 1) + " / " + pages.length;
    prev.disabled = i === 0;
    next.disabled = i === pages.length - 1;
  }
  function go(n) { i = Math.max(0, Math.min(pages.length - 1, n)); render(); }
  prev.addEventListener("click", function () { go(i - 1); });
  next.addEventListener("click", function () { go(i + 1); });
  document.addEventListener("keydown", function (e) {
    if (e.key === "ArrowLeft") go(i - 1);
    else if (e.key === "ArrowRight") go(i + 1);
  });
  var x0 = null;
  var stage = document.querySelector(".stage");
  stage.addEventListener("touchstart", function (e) { x0 = e.touches[0].clientX; }, { passive: true });
  stage.addEventListener("touchend", function (e) {
    if (x0 === null) return;
    var dx = e.changedTouches[0].clientX - x0;
    if (Math.abs(dx) > 40) go(dx < 0 ? i + 1 : i - 1);
    x0 = null;
  }, { passive: true });
  render();
})();
</script>
</body>
</html>''';
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
