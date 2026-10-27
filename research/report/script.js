// Charts for the CareerBridge AI model report (plain SVG, no libraries, works offline).
(function () {
  var C = { navy: "#12355b", teal: "#1f8a8a", grey: "#b7c0cd", bad: "#c0392b", line: "#e3e8ef", muted: "#5d6b82", ink: "#0f1b2d" };
  var models = ["v2", "v5", "v6", "v7", "v8"];
  var names = { v2: "v2 · SVM (deployed)", v5: "v5 · Transformer", v6: "v6 · normalised text", v7: "v7 · + rough synthetic", v8: "v8 · + template synthetic" };
  var real = { v2: 92.9, v5: 60.7, v6: 91.1, v7: 91.1, v8: 94.6 };       // independent review, 56 real Malaysian CVs
  var publicAcc = { v2: 81.5, v5: 88.2, v6: 86.1, v7: 87.0, v8: 86.0 };  // public test set, 2,817 resumes
  var llm = { // blind LLM review of the first answer: exact, close, weak, wrong (% of 58 CVs)
    v2: [67.2, 17.3, 13.8, 1.7], v5: [44.8, 12.1, 13.8, 29.3], v6: [60.3, 19.0, 17.3, 3.4],
    v7: [60.3, 24.2, 8.6, 6.9], v8: [62.1, 24.1, 12.1, 1.7]
  };
  var epochs = { v5: [72.1, 86.3, 87.4, 88.1], v6: [67.7, 82.1, 84.7, 85.8], v7: [70.4, 83.9, 85.9, 87.5], v8: [67.7, 83.0, 84.5, 86.0] };
  var colour = function (m) { return m === "v5" ? C.bad : (m === "v2" ? C.navy : C.grey); };

  function svg(w, h, body, label) {
    return '<svg viewBox="0 0 ' + w + " " + h + '" role="img" aria-label="' + label + '">' + body + "</svg>";
  }
  function t(x, y, s, extra) { return '<text x="' + x + '" y="' + y + '" ' + (extra || "") + ">" + s + "</text>"; }

  // 1. Horizontal bars: real CVs, independent review.
  (function () {
    var W = 760, rowH = 34, L = 210, R = 60, H = models.length * rowH + 30;
    var X = function (v) { return L + v / 100 * (W - L - R); }, b = "";
    [0, 25, 50, 75, 100].forEach(function (v) {
      b += '<line class="gridline" x1="' + X(v) + '" x2="' + X(v) + '" y1="0" y2="' + (H - 22) + '"/>' + t(X(v), H - 6, v + "%", 'class="axis" text-anchor="middle"');
    });
    models.forEach(function (m, i) {
      var y = i * rowH + 6;
      b += t(L - 10, y + 17, names[m], 'text-anchor="end"' + (m === "v2" ? ' font-weight="700"' : ""));
      b += '<rect x="' + L + '" y="' + y + '" width="' + (X(real[m]) - L) + '" height="22" rx="2" fill="' + colour(m) + '"/>';
      b += t(X(real[m]) + 6, y + 16, real[m].toFixed(1) + "%", 'font-weight="700"');
    });
    document.getElementById("chart-real").innerHTML = svg(W, H, b, "Accuracy on real Malaysian CVs by model");
  })();

  // 2. Slope chart: public test vs real CVs.
  (function () {
    var W = 460, H = 300, x1 = 120, x2 = 340, top = 30, bot = 260, lo = 55, hi = 100;
    var Y = function (v) { return bot - (v - lo) / (hi - lo) * (bot - top); };
    var b = t(x1, 16, "Public test", 'class="axis" text-anchor="middle"') + t(x2, 16, "Real MY CVs", 'class="axis" text-anchor="middle"');
    b += '<line class="gridline" x1="' + x1 + '" x2="' + x1 + '" y1="' + top + '" y2="' + bot + '"/><line class="gridline" x1="' + x2 + '" x2="' + x2 + '" y1="' + top + '" y2="' + bot + '"/>';
    models.forEach(function (m) {
      var w = (m === "v2" || m === "v5") ? 3 : 1.5;
      b += '<line x1="' + x1 + '" y1="' + Y(publicAcc[m]) + '" x2="' + x2 + '" y2="' + Y(real[m]) + '" stroke="' + colour(m) + '" stroke-width="' + w + '"/>';
      b += '<circle cx="' + x1 + '" cy="' + Y(publicAcc[m]) + '" r="4" fill="' + colour(m) + '"/><circle cx="' + x2 + '" cy="' + Y(real[m]) + '" r="4" fill="' + colour(m) + '"/>';
      if (m === "v2" || m === "v5") {
        b += t(x2 + 10, Y(real[m]) + 4, m + " " + real[m].toFixed(1) + "%", 'fill="' + colour(m) + '" font-weight="700"');
        b += t(x1 - 10, Y(publicAcc[m]) + 4, publicAcc[m].toFixed(1) + "% " + m, 'text-anchor="end" fill="' + colour(m) + '" font-weight="700"');
      }
    });
    b += t(x2 + 10, Y(92) + 4, "v6–v8 91–95%", 'fill="' + C.muted + '"');
    document.getElementById("chart-slope").innerHTML = svg(W, H, b, "Public test accuracy compared with real CV accuracy per model");
  })();

  // 3. Stacked bars: blind LLM review.
  (function () {
    var W = 460, rowH = 34, L = 50, R = 10, H = models.length * rowH + 26;
    var X = function (v) { return L + v / 100 * (W - L - R); }, cols = [C.navy, C.teal, C.grey, C.bad], b = "";
    [0, 50, 100].forEach(function (v) { b += t(X(v), H - 6, v + "%", 'class="axis" text-anchor="middle"'); });
    models.forEach(function (m, i) {
      var y = i * rowH + 4, acc = 0;
      b += t(L - 8, y + 16, m, 'text-anchor="end"');
      llm[m].forEach(function (v, k) {
        b += '<rect x="' + X(acc) + '" y="' + y + '" width="' + (X(acc + v) - X(acc)) + '" height="22" fill="' + cols[k] + '"/>';
        if (v >= 9) b += t(X(acc) + 4, y + 15, Math.round(v), 'fill="' + (k === 2 ? C.ink : "#fff") + '" font-size="11"');
        acc += v;
      });
    });
    document.getElementById("chart-llm").innerHTML = svg(W, H, b, "LLM ratings of each model's first answer");
  })();

  // 5. Line chart: validation accuracy per epoch.
  (function () {
    var W = 460, H = 250, L = 44, R = 16, T = 12, B = 34, lo = 65, hi = 90;
    var X = function (e) { return L + (e - 1) / 3 * (W - L - R); }, Y = function (v) { return T + (1 - (v - lo) / (hi - lo)) * (H - T - B); };
    var cols = { v5: C.bad, v6: C.grey, v7: C.teal, v8: C.navy }, b = "", lg = "";
    [65, 70, 75, 80, 85, 90].forEach(function (v) {
      b += '<line class="gridline" x1="' + L + '" x2="' + (W - R) + '" y1="' + Y(v) + '" y2="' + Y(v) + '"/>' + t(L - 6, Y(v) + 4, v + "%", 'class="axis" text-anchor="end"');
    });
    [1, 2, 3, 4].forEach(function (e) { b += t(X(e), H - 12, "Epoch " + e, 'class="axis" text-anchor="middle"'); });
    Object.keys(epochs).forEach(function (m) {
      b += '<polyline points="' + epochs[m].map(function (v, i) { return X(i + 1) + "," + Y(v); }).join(" ") + '" fill="none" stroke="' + cols[m] + '" stroke-width="2"/>';
      epochs[m].forEach(function (v, i) { b += '<circle cx="' + X(i + 1) + '" cy="' + Y(v) + '" r="3" fill="' + cols[m] + '"/>'; });
      lg += '<span><i style="background:' + cols[m] + '"></i>' + m + "</span>";
    });
    document.getElementById("chart-epochs").innerHTML = svg(W, H, b, "Validation accuracy after each epoch");
    document.getElementById("legend-epochs").innerHTML = lg;
  })();
})();
