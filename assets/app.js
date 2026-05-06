// Shared chrome — nav + tweaks
(function() {
  // Mark active nav link
  const path = (location.pathname.split('/').pop() || 'index.html').toLowerCase();
  document.querySelectorAll('.nav a').forEach(a => {
    const href = (a.getAttribute('href') || '').toLowerCase();
    if (href === path || (path === '' && href === 'index.html')) a.classList.add('is-active');
  });

  // Liquid-glass nav thumb — slides between active / hovered link
  document.querySelectorAll('.nav').forEach(nav => {
    // Only animate over internal links (skip target=_blank like 知识库)
    const items = [...nav.querySelectorAll('a')].filter(a => !a.target || a.target === '_self');
    if (!items.length) return;
    const thumb = document.createElement('span');
    thumb.className = 'thumb';
    nav.prepend(thumb);

    let resting = nav.querySelector('a.is-active') || items[0];
    function moveTo(el) {
      const navRect = nav.getBoundingClientRect();
      const r = el.getBoundingClientRect();
      const x = r.left - navRect.left;
      const w = r.width;
      thumb.style.transform = `translateX(${x}px)`;
      thumb.style.width = `${w}px`;
      thumb.style.opacity = '1';
    }
    requestAnimationFrame(() => moveTo(resting));
    window.addEventListener('resize', () => moveTo(resting));
    // Refresh after fonts/i18n swap text width
    window.addEventListener('langchange', () => requestAnimationFrame(() => moveTo(resting)));

    items.forEach(a => {
      a.addEventListener('mouseenter', () => { nav.classList.add('is-hovering'); moveTo(a); });
    });
    // External (target=_blank) links — flick thumb to them too on hover
    nav.querySelectorAll('a[target="_blank"]').forEach(a => {
      a.addEventListener('mouseenter', () => { nav.classList.add('is-hovering'); moveTo(a); });
    });
    nav.addEventListener('mouseleave', () => {
      nav.classList.remove('is-hovering');
      moveTo(resting);
    });
  });

  // Liquid-glass thumb for the language switcher
  function setupLangThumb() {
    document.querySelectorAll('[data-langswitch]').forEach(host => {
      if (host.querySelector('.thumb')) return; // already done
      const btns = [...host.querySelectorAll('.lang-btn')];
      if (!btns.length) return;
      const thumb = document.createElement('span');
      thumb.className = 'thumb';
      host.prepend(thumb);

      function getActive() { return host.querySelector('.lang-btn.on') || btns[0]; }
      function moveTo(el) {
        const hr = host.getBoundingClientRect();
        const r = el.getBoundingClientRect();
        thumb.style.transform = `translateX(${r.left - hr.left}px)`;
        thumb.style.width = `${r.width}px`;
        thumb.style.opacity = '1';
      }
      requestAnimationFrame(() => moveTo(getActive()));
      window.addEventListener('resize', () => moveTo(getActive()));

      btns.forEach(b => {
        b.addEventListener('mouseenter', () => moveTo(b));
        b.addEventListener('click', () => {
          // Allow i18n to update .on class first, then settle.
          requestAnimationFrame(() => requestAnimationFrame(() => moveTo(getActive())));
        });
      });
      host.addEventListener('mouseleave', () => moveTo(getActive()));
    });
  }
  // i18n script builds the buttons on DOMContentLoaded — run after that.
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => requestAnimationFrame(setupLangThumb));
  } else {
    requestAnimationFrame(setupLangThumb);
  }
  window.addEventListener('langchange', () => requestAnimationFrame(setupLangThumb));

  // Live clock / locale in chrome
  const clock = document.querySelector('[data-clock]');
  if (clock) {
    const tick = () => {
      const d = new Date();
      const hh = String(d.getHours()).padStart(2, '0');
      const mm = String(d.getMinutes()).padStart(2, '0');
      clock.textContent = `JST ${hh}:${mm}`;
    };
    tick();
    setInterval(tick, 30000);
  }

  // Tweaks state
  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "accent": "vermilion",
    "theme": "light",
    "density": "default"
  }/*EDITMODE-END*/;

  const stored = (() => {
    try { return JSON.parse(localStorage.getItem('kong-tweaks')) || {}; }
    catch { return {}; }
  })();
  const state = Object.assign({}, TWEAK_DEFAULTS, stored);

  const ACCENTS = {
    vermilion: { '--accent': 'oklch(0.55 0.15 35)',  '--accent-ink': 'oklch(0.35 0.12 35)',  '--accent-soft': 'oklch(0.92 0.04 35)'  },
    indigo:    { '--accent': 'oklch(0.48 0.15 260)', '--accent-ink': 'oklch(0.35 0.12 260)', '--accent-soft': 'oklch(0.92 0.04 260)' },
    forest:    { '--accent': 'oklch(0.48 0.12 155)', '--accent-ink': 'oklch(0.32 0.10 155)', '--accent-soft': 'oklch(0.92 0.03 155)' },
    ochre:     { '--accent': 'oklch(0.62 0.14 75)',  '--accent-ink': 'oklch(0.40 0.10 75)',  '--accent-soft': 'oklch(0.93 0.04 75)'  },
    ink:       { '--accent': 'oklch(0.25 0.01 80)',  '--accent-ink': 'oklch(0.18 0.01 80)',  '--accent-soft': 'oklch(0.90 0.005 80)' }
  };

  function apply() {
    const vars = ACCENTS[state.accent] || ACCENTS.vermilion;
    Object.entries(vars).forEach(([k, v]) => document.documentElement.style.setProperty(k, v));
    document.body.classList.toggle('theme-dark', state.theme === 'dark');
    document.body.classList.toggle('density-compact', state.density === 'compact');
  }
  apply();

  // Register with host
  window.addEventListener('message', (e) => {
    if (!e.data || typeof e.data !== 'object') return;
    if (e.data.type === '__activate_edit_mode') openPanel();
    if (e.data.type === '__deactivate_edit_mode') closePanel();
  });
  window.parent && window.parent.postMessage({ type: '__edit_mode_available' }, '*');

  // Build tweak panel (lazy)
  let panel;
  function ensurePanel() {
    if (panel) return panel;
    panel = document.createElement('div');
    panel.id = 'tweaks';
    panel.innerHTML = `
      <h3>Tweaks 调整</h3>
      <label>
        Accent color
        <div class="swatches" data-accent-swatches>
          <span class="sw" data-accent="vermilion" style="background:oklch(0.55 0.15 35)"></span>
          <span class="sw" data-accent="indigo"    style="background:oklch(0.48 0.15 260)"></span>
          <span class="sw" data-accent="forest"    style="background:oklch(0.48 0.12 155)"></span>
          <span class="sw" data-accent="ochre"     style="background:oklch(0.62 0.14 75)"></span>
          <span class="sw" data-accent="ink"       style="background:oklch(0.25 0.01 80)"></span>
        </div>
      </label>
      <label>
        Theme
        <select data-theme>
          <option value="light">Light paper</option>
          <option value="dark">Dark ink</option>
        </select>
      </label>
    `;
    document.body.appendChild(panel);

    panel.querySelectorAll('[data-accent]').forEach(sw => {
      sw.addEventListener('click', () => {
        state.accent = sw.dataset.accent;
        persist(); apply(); syncUI();
      });
    });
    panel.querySelector('[data-theme]').addEventListener('change', (e) => {
      state.theme = e.target.value;
      persist(); apply();
    });
    syncUI();
    return panel;
  }

  function syncUI() {
    if (!panel) return;
    panel.querySelectorAll('[data-accent]').forEach(sw => {
      sw.classList.toggle('active', sw.dataset.accent === state.accent);
    });
    const sel = panel.querySelector('[data-theme]');
    if (sel) sel.value = state.theme;
  }

  function persist() {
    localStorage.setItem('kong-tweaks', JSON.stringify(state));
    window.parent && window.parent.postMessage({ type: '__edit_mode_set_keys', edits: state }, '*');
  }

  function openPanel() { ensurePanel().classList.add('open'); }
  function closePanel() { panel && panel.classList.remove('open'); }
})();
