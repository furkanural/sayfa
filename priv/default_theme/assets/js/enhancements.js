/* 1. Reading progress bar */
(function () {
  var article = document.querySelector("article");
  var prose = article && article.querySelector(".prose");
  if (!article || !prose) return;

  var bar = document.createElement("div");
  bar.id = "reading-progress";
  document.body.appendChild(bar);

  window.addEventListener(
    "scroll",
    function () {
      var rect = article.getBoundingClientRect();
      var total = article.offsetHeight - window.innerHeight;
      if (total > 0)
        bar.style.width = Math.min(Math.max(-rect.top / total, 0), 1) * 100 + "%";
    },
    { passive: true }
  );
})();

/* 2. ToC scroll-spy */
(function () {
  var tocLinks = document.querySelectorAll('aside nav ul li a[href^="#"]');
  if (!tocLinks.length) return;

  var ids = [];
  tocLinks.forEach(function (a) {
    ids.push(a.getAttribute("href").slice(1));
  });

  var headings = ids
    .map(function (id) {
      return document.getElementById(id);
    })
    .filter(Boolean);

  if (!headings.length) return;

  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        var link = document.querySelector(
          'aside nav ul li a[href="#' + entry.target.id + '"]'
        );
        if (link && entry.isIntersecting) {
          tocLinks.forEach(function (a) {
            a.classList.remove("toc-active");
          });
          link.classList.add("toc-active");
        }
      });
    },
    { rootMargin: "-80px 0px -70% 0px", threshold: 0 }
  );

  headings.forEach(function (el) {
    observer.observe(el);
  });
})();

/* 3. Mobile menu toggle + Escape key */
(function () {
  var toggle = document.getElementById("menu-toggle");
  if (!toggle) return;

  var menu = document.getElementById("mobile-menu");
  var openIcon = document.querySelector(".menu-open");
  var closeIcon = document.querySelector(".menu-close");

  toggle.addEventListener("click", function () {
    var isHidden = menu.classList.contains("hidden");
    menu.classList.toggle("hidden");
    openIcon.classList.toggle("hidden", isHidden);
    closeIcon.classList.toggle("hidden", !isHidden);
    toggle.setAttribute("aria-expanded", String(isHidden));
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") {
      if (menu && !menu.classList.contains("hidden")) {
        menu.classList.add("hidden");
        openIcon.classList.remove("hidden");
        closeIcon.classList.add("hidden");
        toggle.setAttribute("aria-expanded", "false");
        toggle.focus();
      }
    }
  });
})();

/* 4. Language switcher dropdown */
(function () {
  var switcher = document.getElementById("lang-switcher");
  if (!switcher) return;

  var btn = document.getElementById("lang-toggle");
  var menu = document.getElementById("lang-menu");

  btn.addEventListener("click", function (e) {
    e.stopPropagation();
    var isHidden = menu.classList.contains("hidden");
    menu.classList.toggle("hidden");
    btn.setAttribute("aria-expanded", String(isHidden));
  });

  document.addEventListener("click", function (e) {
    if (!switcher.contains(e.target)) {
      menu.classList.add("hidden");
      btn.setAttribute("aria-expanded", "false");
    }
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && !menu.classList.contains("hidden")) {
      menu.classList.add("hidden");
      btn.setAttribute("aria-expanded", "false");
      btn.focus();
    }
  });
})();

/* 5. Code copy buttons */
(function () {
  var config = document.getElementById("sayfa-code-copy");
  if (!config) return;

  var selector = config.getAttribute("data-selector") || "pre code";
  var copyText = config.getAttribute("data-copy-text") || "Copy";
  var copiedText = config.getAttribute("data-copied-text") || "Copied!";

  document.querySelectorAll(selector).forEach(function (block) {
    var pre = block.parentNode;
    if (pre.parentNode.classList.contains("not-prose")) return;

    var lang = block.className.replace(/^language-/, "") || "";

    var wrapper = document.createElement("div");
    wrapper.className =
      "not-prose my-6 rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700";

    var header = document.createElement("div");
    header.className =
      "flex items-center justify-between px-4 py-2 bg-slate-800 text-slate-400";

    header.innerHTML =
      '<span class="text-xs font-mono">' +
      lang +
      "</span>" +
      '<button class="copy-btn inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-slate-200">' +
      '<svg class="w-3.5 h-3.5 icon-copy" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>' +
      '<svg class="w-3.5 h-3.5 icon-check text-green-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>' +
      '<span class="copy-label">' +
      copyText +
      "</span></button>";

    var btn = header.querySelector(".copy-btn");
    btn.addEventListener("click", function () {
      var code = btn.closest(".not-prose").querySelector("code").textContent;
      navigator.clipboard
        .writeText(code)
        .then(function () {
          btn.classList.add("copied");
          btn.querySelector(".copy-label").textContent = copiedText;
          setTimeout(function () {
            btn.classList.remove("copied");
            btn.querySelector(".copy-label").textContent = copyText;
          }, 2000);
        })
        .catch(function () {});
    });

    pre.style.margin = "0";
    pre.className = "p-4 bg-slate-900 text-slate-100 overflow-x-auto m-0";

    var parent = pre.parentNode;
    parent.insertBefore(wrapper, pre);
    wrapper.appendChild(header);
    wrapper.appendChild(pre);
  });
})();
