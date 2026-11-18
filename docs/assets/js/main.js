/* ============================================================
   GrowWithMe — Investor Brief
   Progressive enhancement: nav, scroll reveals, tabs, counters
   ============================================================ */
(function () {
  "use strict";

  /* ---------- Sticky nav shadow ---------- */
  var nav = document.getElementById("nav");
  function onScroll() {
    if (!nav) return;
    nav.classList.toggle("scrolled", window.scrollY > 12);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* ---------- Mobile menu ---------- */
  var toggle = document.getElementById("navToggle");
  var links = document.getElementById("navLinks");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    links.addEventListener("click", function (e) {
      if (e.target.tagName === "A") {
        links.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        links.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  /* ---------- Scroll reveal ---------- */
  var reveals = Array.prototype.slice.call(document.querySelectorAll(".reveal"));
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function countUp(el) {
    if (el.dataset.done === "1") return;
    el.dataset.done = "1";
    var target = parseInt(el.dataset.count, 10);
    if (isNaN(target) || reduceMotion) return;
    var suffix = el.dataset.suffix || "";
    var start = null;
    var dur = 1100;
    function step(ts) {
      if (!start) start = ts;
      var p = Math.min((ts - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(target * eased) + suffix;
      if (p < 1) requestAnimationFrame(step);
      else el.textContent = target + suffix;
    }
    requestAnimationFrame(step);
  }

  if ("IntersectionObserver" in window && !reduceMotion) {
    var revealObs = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          if (entry.target.classList.contains("stat-num")) countUp(entry.target);
          revealObs.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });

    reveals.forEach(function (el) { revealObs.observe(el); });

    /* counters live inside .stat cards — observe their own trigger */
    var counters = Array.prototype.slice.call(document.querySelectorAll(".stat-num"));
    counters.forEach(function (el) { countUpSoon(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add("in"); });
  }

  /* counters inside cards trigger when the card scrolls into view */
  function countUpSoon(el) {
    var parent = el.closest(".stat");
    if (!parent) return;
    var o = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) { countUp(el); o.disconnect(); }
      });
    }, { threshold: 0.4 });
    o.observe(parent);
  }

  /* ---------- Active nav link ---------- */
  var sections = ["problem", "product", "traction", "market", "model", "ask"]
    .map(function (id) { return document.getElementById(id); })
    .filter(Boolean);
  if ("IntersectionObserver" in window && sections.length) {
    var navObs = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var id = entry.target.id;
        Array.prototype.forEach.call(links ? links.querySelectorAll("a") : [], function (a) {
          a.classList.toggle("active", a.getAttribute("href") === "#" + id);
        });
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    sections.forEach(function (s) { navObs.observe(s); });
  }

  /* ---------- Product tour tabs ---------- */
  var tabs = Array.prototype.slice.call(document.querySelectorAll(".tab"));
  var tourImg = document.getElementById("tourImg");
  var tourCap = document.getElementById("tourCap");
  tabs.forEach(function (tab) {
    tab.addEventListener("click", function () {
      tabs.forEach(function (t) {
        t.classList.remove("active");
        t.setAttribute("aria-selected", "false");
      });
      tab.classList.add("active");
      tab.setAttribute("aria-selected", "true");
      if (tourImg && tab.dataset.img) {
        tourImg.style.opacity = "0.25";
        var next = new Image();
        next.onload = function () {
          tourImg.src = next.src;
          tourImg.style.opacity = "1";
        };
        next.onerror = function () { tourImg.style.opacity = "1"; };
        next.src = "assets/img/" + tab.dataset.img;
      }
      if (tourCap && tab.dataset.cap) tourCap.textContent = tab.dataset.cap;
    });
  });
})();
