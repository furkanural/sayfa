/* 1. Reading progress bar */
(function () {
  const article = document.querySelector("article");
  if (!article) return;

  const bar = document.createElement("div");
  bar.id = "reading-progress";
  bar.style.width = "0%";
  bar.setAttribute("aria-hidden", "true");
  document.body.appendChild(bar);

  window.addEventListener(
    "scroll",
    () => {
      const rect = article.getBoundingClientRect();
      const total = article.offsetHeight - window.innerHeight;
      if (total > 0) {
        bar.style.width =
          Math.min(Math.max(-rect.top / total, 0), 1) * 100 + "%";
      }
    },
    { passive: true }
  );
})();

/* 2. ToC scroll-spy */
(function () {
  const tocLinks = document.querySelectorAll('.toc-list a[href^="#"]');
  if (!tocLinks.length) return;

  const ids = [];
  tocLinks.forEach((a) => {
    ids.push(a.getAttribute("href").slice(1));
  });

  const headings = ids
    .map((id) => document.getElementById(id))
    .filter(Boolean);

  if (!headings.length) return;

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const link = document.querySelector(
          '.toc-list a[href="#' + entry.target.id + '"]'
        );
        if (link && entry.isIntersecting) {
          tocLinks.forEach((a) => a.classList.remove("toc-active"));
          link.classList.add("toc-active");
        }
      });
    },
    { rootMargin: "-80px 0px -70% 0px", threshold: 0 }
  );

  headings.forEach((el) => observer.observe(el));
})();

/* 3. Mobile menu toggle + Escape key */
(function () {
  const toggle = document.getElementById("menu-toggle");
  if (!toggle) return;

  const menu = document.getElementById("mobile-menu");
  const openIcon = document.querySelector(".menu-open");
  const closeIcon = document.querySelector(".menu-close");

  toggle.addEventListener("click", () => {
    const isHidden = menu.classList.contains("hidden");
    menu.classList.toggle("hidden");
    openIcon.classList.toggle("hidden", isHidden);
    closeIcon.classList.toggle("hidden", !isHidden);
    toggle.setAttribute("aria-expanded", String(isHidden));
  });

  document.addEventListener("keydown", (e) => {
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
  function initLanguageSwitcher(variant) {
    const suffix = variant ? "-" + variant : "";
    const switcher = document.getElementById("lang-switcher" + suffix);
    if (!switcher) return;

    const btn = document.getElementById("lang-toggle" + suffix);
    const menu = document.getElementById("lang-menu" + suffix);

    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      const isHidden = menu.classList.contains("hidden");
      menu.classList.toggle("hidden");
      btn.setAttribute("aria-expanded", String(isHidden));
    });

    document.addEventListener("click", (e) => {
      if (!switcher.contains(e.target)) {
        menu.classList.add("hidden");
        btn.setAttribute("aria-expanded", "false");
      }
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && !menu.classList.contains("hidden")) {
        menu.classList.add("hidden");
        btn.setAttribute("aria-expanded", "false");
        btn.focus();
      }
    });
  }

  initLanguageSwitcher("desktop");
  initLanguageSwitcher("mobile");
})();

/* 5. Code copy buttons */
(function () {
  const config = document.getElementById("sayfa-code-copy");
  if (!config) return;

  const selector = config.dataset.selector || "pre code";
  const copyText = config.dataset.copyText || "Copy";
  const copiedText = config.dataset.copiedText || "Copied!";

  document.querySelectorAll(selector).forEach((block) => {
    const pre = block.parentNode;
    if (pre.parentNode.classList.contains("code-block-wrap")) return;

    const lang = block.className.replace(/^language-/, "") || "";

    const wrapper = document.createElement("div");
    wrapper.className = "code-block-wrap not-prose";

    const header = document.createElement("div");
    header.className = "code-block-header";

    header.innerHTML =
      '<span class="code-block-lang">' +
      lang +
      "</span>" +
      '<button class="copy-btn code-copy-btn">' +
      '<svg class="code-copy-icon icon-copy" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>' +
      '<svg class="code-copy-icon icon-check" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>' +
      '<span class="copy-label">' +
      copyText +
      "</span></button>";

    const btn = header.querySelector(".copy-btn");
    btn.addEventListener("click", () => {
      const code = btn.closest(".code-block-wrap").querySelector("code").textContent;
      navigator.clipboard
        .writeText(code)
        .then(() => {
          btn.classList.add("copied");
          btn.querySelector(".copy-label").textContent = copiedText;
          setTimeout(() => {
            btn.classList.remove("copied");
            btn.querySelector(".copy-label").textContent = copyText;
          }, 2000);
        })
        .catch(() => {});
    });

    pre.style.margin = "0";
    pre.className = "code-block-pre";

    const parent = pre.parentNode;
    parent.insertBefore(wrapper, pre);
    wrapper.appendChild(header);
    wrapper.appendChild(pre);
  });
})();

/* 6. Copy link buttons */
(function () {
  document.addEventListener("click", (e) => {
    const btn = e.target.closest('[data-action="copy-link"]');
    if (!btn) return;

    const span = btn.querySelector("span");
    if (!span) return;

    const copyText = btn.dataset.copyText;
    const copiedText = btn.dataset.copiedText;

    navigator.clipboard
      .writeText(window.location.href)
      .then(() => {
        span.textContent = copiedText;
        setTimeout(() => {
          span.textContent = copyText;
        }, 2000);
      })
      .catch(() => {});
  });
})();
