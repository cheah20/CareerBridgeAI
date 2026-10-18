(function () {
  // metric bars, scale 0.70 → 1.00
  var metrics = [
    ["Category top-1", 0.8154, 0.8821], ["Macro F1", 0.8092, 0.8677], ["Category top-3", 0.9379, 0.9379],
    ["Field top-1", 0.8548, 0.9191], ["Field top-3", 0.9638, 0.9617]
  ];
  var lo = 0.70, hi = 1.00, pct = function (v) { return ((v - lo) / (hi - lo) * 100) + "%"; };
  var bars = document.getElementById("bars");
  metrics.forEach(function (m) {
    var row = document.createElement("div"); row.className = "bar-row";
    row.innerHTML = '<div class="bar-label">' + m[0] + '</div><div class="track">' +
      '<div class="bar v2" style="width:' + pct(m[1]) + '"><span>' + m[1].toFixed(3) + '</span></div>' +
      '<div class="bar v5" style="width:' + pct(m[2]) + '"><span>' + m[2].toFixed(3) + '</span></div></div>';
    bars.appendChild(row);
  });
  var axis = document.createElement("div"); axis.className = "axis";
  var t = '<div></div><div class="ticks" style="margin-right:3.5rem">';
  [0.70, 0.80, 0.90, 1.00].forEach(function (v) { t += '<i style="left:' + pct(v) + '">' + v.toFixed(2) + '</i>'; });
  axis.innerHTML = t + "</div>"; bars.appendChild(axis);

  // per-category dumbbells, scale 0.30 → 1.00, sorted by change (largest gain first)
  var rows = [["BPO",0.742,0.545],["PMO",0.882,0.695],["React Developer",0.615,0.524],["ETL Developer",0.94,0.865],["Automobile",0.765,0.705],["DotNet Developer",0.916,0.867],["Python Developer",0.765,0.719],["Java Developer",0.935,0.909],["DevOps",0.977,0.978],["Arts",0.803,0.806],["Health and Fitness",0.885,0.887],["Mechanical Engineer",0.931,0.962],["Apparel",0.795,0.828],["Accountant",0.888,0.932],["Architecture",0.829,0.883],["SAP Developer",0.891,0.946],["Agriculture",0.792,0.85],["Public Relations",0.848,0.907],["Banking",0.841,0.901],["SQL Developer",0.733,0.8],["Finance",0.79,0.859],["Food and Beverages",0.891,0.96],["Operations Manager",0.866,0.935],["Building and Construction",0.872,0.943],["Electrical Engineering",0.889,0.964],["Blockchain",0.857,0.933],["Civil Engineer",0.901,0.983],["Consultant",0.807,0.89],["Network Security Engineer",0.884,0.968],["Aviation",0.848,0.933],["Human Resources",0.855,0.946],["Business Analyst",0.844,0.944],["Designing",0.75,0.867],["Advocate",0.789,0.908],["Database",0.731,0.851],["Information Technology",0.764,0.89],["Digital Media",0.781,0.912],["Data Science",0.788,0.933],["Education",0.79,0.939],["Healthcare",0.566,0.717],["Sales",0.711,0.865],["Web Designing",0.713,0.873],["Business Development",0.773,0.941],["Testing",0.803,0.984],["Management",0.38,0.597]];
  rows.reverse();
  var L = 0.30, H = 1.00, p2 = function (v) { return ((v - L) / (H - L) * 100); };
  var db = document.getElementById("db");
  rows.forEach(function (r) {
    var d = r[2] - r[1], a = Math.min(p2(r[1]), p2(r[2])), b = Math.max(p2(r[1]), p2(r[2]));
    var col = d >= 0 ? "var(--good)" : "var(--bad)";
    var el = document.createElement("div"); el.className = "db-row";
    el.title = r[0] + ": v2 " + r[1].toFixed(3) + " → v5 " + r[2].toFixed(3);
    el.innerHTML = '<span class="db-name">' + r[0] + '</span><div class="db-line">' +
      '<div class="db-seg" style="left:' + a + '%;width:' + (b - a) + '%;background:' + col + '"></div>' +
      '<div class="db-dot v2" style="left:' + p2(r[1]) + '%"></div><div class="db-dot v5" style="left:' + p2(r[2]) + '%"></div></div>' +
      '<span class="db-d" style="color:' + col + '">' + (d >= 0 ? "+" : "−") + Math.abs(d).toFixed(3) + '</span>';
    db.appendChild(el);
  });
  var tk = document.getElementById("dbticks"), s = "";
  [0.3, 0.5, 0.7, 0.9].forEach(function (v) { s += '<i style="left:' + p2(v) + '%">' + v.toFixed(1) + '</i>'; });
  tk.innerHTML = s;

  // loss curve, run B (logged loss / 2)
  var steps = [], loss = [];
  var raw = [7.659,7.590,7.401,7.016,6.605,5.936,5.226,4.812,4.333,3.966,3.532,2.980,2.806,2.342,2.306,2.210,1.927,1.986,1.721,1.540,1.686,1.659,1.608,1.398,1.428,1.272,1.242,1.177,1.136,1.035,1.059,1.109,1.125,1.053,0.966,1.016,1.017,0.981,0.752,0.870,0.901,0.773,0.699,0.802,0.829,0.930,0.822,0.729,0.832,0.718];
  raw.forEach(function (v, i) { steps.push(60 + i * 50); loss.push(v / 2); });
  var W = 720, Hh = 260, ml = 44, mr = 16, mt = 12, mb = 34, x1 = 2536, y1 = 4;
  var X = function (s) { return ml + s / x1 * (W - ml - mr); }, Y = function (v) { return mt + (1 - v / y1) * (Hh - mt - mb); };
  var g = '<svg viewBox="0 0 ' + W + ' ' + Hh + '" role="img" aria-label="Training loss falls from about 3.8 to about 0.36 over 2,536 steps">';
  [0, 1, 2, 3, 4].forEach(function (v) { g += '<line class="grid" x1="' + ml + '" x2="' + (W - mr) + '" y1="' + Y(v) + '" y2="' + Y(v) + '"/><text x="' + (ml - 8) + '" y="' + (Y(v) + 4) + '" text-anchor="end">' + v.toFixed(1) + '</text>'; });
  [634, 1268, 1902].forEach(function (s, i) { g += '<line class="epoch" x1="' + X(s) + '" x2="' + X(s) + '" y1="' + mt + '" y2="' + (Hh - mb) + '"/>'; });
  [0, 634, 1268, 1902, 2536].forEach(function (s) { g += '<text x="' + X(s) + '" y="' + (Hh - mb + 16) + '" text-anchor="middle">' + s + '</text>'; });
  g += '<text x="' + (W - mr) + '" y="' + (Hh - 4) + '" text-anchor="end">optimiser step</text>';
  var pts = steps.map(function (s, i) { return X(s).toFixed(1) + "," + Y(loss[i]).toFixed(1); });
  g += '<path class="area" d="M' + X(steps[0]) + ',' + Y(0) + ' L' + pts.join(" L") + ' L' + X(steps[steps.length - 1]) + ',' + Y(0) + ' Z"/>';
  g += '<polyline class="loss" points="' + pts.join(" ") + '"/>';
  var ex = X(steps[steps.length - 1]), ey = Y(loss[loss.length - 1]);
  g += '<circle class="end" cx="' + ex + '" cy="' + ey + '" r="4"/><text x="' + (ex - 8) + '" y="' + (ey - 10) + '" text-anchor="end">' + loss[loss.length - 1].toFixed(2) + '</text>';
  g += '<text x="' + (X(steps[0]) + 8) + '" y="' + (Y(loss[0]) + 4) + '">' + loss[0].toFixed(2) + '</text></svg>';
  document.getElementById("losschart").innerHTML = g;
})();
