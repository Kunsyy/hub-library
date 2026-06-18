import os

html = """<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charSet="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Kunsy Hub</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Outfit:wght@600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a class="nav-brand group" href="index.html">
                <span class="logo-icon">K</span>
            </a>
            <div class="nav-links">
                <a href="index.html" class="active">home</a>
                <a href="pricing.html">get key</a>
                <a href="games.html">games</a>
                <a href="pricing.html" class="premium-glow">premium</a>
                <a href="#" class="discord-link">discord</a>
            </div>
            <button class="menu-btn">☰</button>
        </div>
    </nav>

    <section class="hero-section">
        <div class="hero-content">
            <h1 class="hero-title"><span class="text-accent">kunsy</span></h1>
            
            <div class="code-box-wrapper">
                <img src="https://aged-haze-1b3d.marvnesterking.workers.dev/cat_jump.gif" alt="cat" class="cat-gif">
                <div class="code-box">
                    <div class="code-header">
                        <div class="dots"><i></i><i></i><i></i></div>
                        <span class="lang">lua</span>
                    </div>
                    <div class="code-body">
                        <code><span class="c-func">loadstring</span><span class="c-punc">(</span><span class="c-obj">game</span><span class="c-punc">:</span><span class="c-func">HttpGet</span><span class="c-punc">(</span><span class="c-str">"https://kunsydev.xyz/raw/loader.lua"</span><span class="c-punc">))()</span></code>
                        <button class="copy-btn" id="copyBtn">copy</button>
                    </div>
                </div>
            </div>
            
            <p class="hero-typing"><span class="text-accent font-semibold">premium scripts.</span><span class="cursor">|</span></p>
            
            <div class="hero-buttons">
                <a class="btn-primary" href="pricing.html">get your key</a>
                <a class="btn-outline" href="games.html">view games</a>
            </div>
        </div>
    </section>

    <section class="features-section">
        <div class="container">
            <div class="section-header">
                <h2>why choose <span class="text-accent">kunsy</span>?</h2>
                <p>built for performance and safety</p>
            </div>
            <div class="features-grid">
                <div class="feature-card">
                    <h3>undetected</h3>
                    <p>scripts are frequently updated to stay undetected and safe to use.</p>
                </div>
                <div class="feature-card">
                    <h3>best features</h3>
                    <p>packed with powerful features like auto farming every aspect of the game and more.</p>
                </div>
                <div class="feature-card">
                    <h3>optimized code</h3>
                    <p>clean, lightweight scripts that run smoothly without slowing down your game.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="faq-section">
        <div class="container-small">
            <div class="section-header">
                <h2>faq</h2>
            </div>
            <div class="faq-list">
                <div class="faq-item">
                    <button class="faq-btn">
                        <h3>do the scripts work on mobile?</h3>
                        <svg class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"></path></svg>
                    </button>
                    <div class="faq-content">
                        <p>yes! most of our scripts are compatible with popular Android executors.</p>
                    </div>
                </div>
                <div class="faq-item">
                    <button class="faq-btn">
                        <h3>will I get banned for using these scripts?</h3>
                        <svg class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"></path></svg>
                    </button>
                    <div class="faq-content">
                        <p>we build every script with safety in mind to minimize detection. while no script is 100% risk-free, we do our best to keep things safe.</p>
                    </div>
                </div>
                <div class="faq-item">
                    <button class="faq-btn">
                        <h3>what payment methods are accepted?</h3>
                        <svg class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"></path></svg>
                    </button>
                    <div class="faq-content">
                        <p>we accept most major payment methods for premium plan.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="cta-section">
        <div class="cta-bg"></div>
        <div class="container-small text-center relative z-10">
            <h2>ready to use <span class="text-accent">kunsy</span>?</h2>
            <div class="hero-buttons justify-center mt-8">
                <a class="btn-primary" href="pricing.html">get free key</a>
                <a class="btn-outline discord-link" href="#">join discord</a>
            </div>
        </div>
    </section>

    <footer>
        <div class="container footer-flex">
            <a class="footer-brand" href="/">
                <span class="logo-icon-small">K</span>
                <span class="text-accent">kunsy</span>
            </a>
            <div class="footer-sub">we luv kunsy!</div>
            <div class="footer-links">
                <a href="#" class="discord-link">discord</a>
                <a href="pricing.html" class="premium-glow">premium</a>
            </div>
        </div>
    </footer>

    <script src="main.js"></script>
</body>
</html>
"""

css = """
:root {
  --background: #050505;
  --surface: #0a0a0a;
  --surface-hover: #111111;
  --border: #1f1f22;
  --border-hover: rgba(147, 85, 247, 0.4);
  --accent: #a855f7;
  --accent-dark: #9333ea;
  --accent-light: #c084fc;
  --text-main: #f4f4f5;
  --text-muted: #a1a1aa;
  
  --font-heading: 'Outfit', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; background: var(--background); }
body { font-family: 'Inter', sans-serif; color: var(--text-main); background: var(--background); overflow-x: hidden; }
a { text-decoration: none; color: inherit; }

/* Navbar */
.navbar { position: fixed; top: 0; left: 0; right: 0; z-index: 50; border-bottom: 1px solid var(--border); background: rgba(5,5,5,0.8); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }
.nav-container { max-width: 1200px; margin: 0 auto; padding: 12px 24px; display: flex; align-items: center; justify-content: space-between; }
.logo-icon { width: 28px; height: 28px; border-radius: 6px; background: linear-gradient(135deg, var(--accent-light), var(--accent-dark)); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 800; font-family: var(--font-heading); font-size: 16px; transition: transform 0.3s; }
.nav-brand:hover .logo-icon { transform: rotate(12deg); }
.nav-links { display: flex; gap: 8px; align-items: center; }
.nav-links a { padding: 6px 16px; font-size: 14px; font-weight: 500; color: var(--text-muted); transition: color 0.2s; text-transform: lowercase; }
.nav-links a:hover { color: var(--accent); }
.nav-links a.active { color: var(--accent); }
.premium-glow { text-shadow: 0 0 10px rgba(168, 85, 247, 0.5); color: var(--accent-light) !important; }
.menu-btn { display: none; background: none; border: none; color: var(--text-muted); font-size: 24px; cursor: pointer; }

/* Typography & Utils */
.text-accent { color: var(--accent); }
h1, h2, h3 { font-family: var(--font-heading); font-weight: 700; letter-spacing: 0.02em; }
.container { max-width: 1152px; margin: 0 auto; padding: 0 24px; }
.container-small { max-width: 768px; margin: 0 auto; padding: 0 24px; }
.text-center { text-align: center; }

/* Hero */
.hero-section { min-height: 100vh; display: flex; align-items: center; justify-content: center; position: relative; }
.hero-content { text-align: center; width: 100%; max-width: 768px; padding: 0 24px; z-index: 10; }
.hero-title { font-size: clamp(3rem, 8vw, 5rem); line-height: 1.1; margin-bottom: 16px; letter-spacing: 0.05em; text-transform: lowercase; }
.code-box-wrapper { position: relative; max-width: 620px; margin: 16px auto; }
.cat-gif { position: absolute; top: -75px; left: -8px; height: 75px; width: auto; z-index: 10; image-rendering: pixelated; pointer-events: none; }
.code-box { background: rgba(24, 24, 27, 0.8); border: 1px solid rgba(168, 85, 247, 0.2); border-radius: 12px; backdrop-filter: blur(4px); overflow: hidden; text-align: left; }
.code-header { display: flex; justify-content: space-between; align-items: center; padding: 8px 16px; border-bottom: 1px solid rgba(168, 85, 247, 0.1); }
.code-header .dots { display: flex; gap: 6px; }
.code-header .dots i { width: 10px; height: 10px; border-radius: 50%; background: rgba(168, 85, 247, 0.2); }
.code-header .dots i:nth-child(1) { background: rgba(168, 85, 247, 0.4); }
.code-header .lang { font-size: 10px; letter-spacing: 1px; color: rgba(255,255,255,0.25); text-transform: lowercase; }
.code-body { padding: 12px 16px; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.code-body code { font-family: var(--font-mono); font-size: 13px; color: var(--text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.c-func { color: var(--accent); }
.c-punc { color: rgba(255,255,255,0.4); }
.c-obj { color: rgba(168, 85, 247, 0.7); }
.c-str { color: rgba(255,255,255,0.6); }
.copy-btn { background: rgba(168, 85, 247, 0.1); color: var(--accent); border: none; padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 500; cursor: pointer; transition: 0.3s; }
.copy-btn:hover { background: rgba(168, 85, 247, 0.2); }

.hero-typing { margin-top: 20px; font-size: 1.125rem; color: var(--text-muted); }
.cursor { animation: blink 1s infinite; color: var(--accent); }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }

.hero-buttons { display: flex; gap: 16px; justify-content: center; margin-top: 40px; flex-wrap: wrap; }
.btn-primary { background: var(--accent); color: #fff; padding: 12px 32px; border-radius: 12px; font-weight: 600; text-transform: lowercase; transition: background 0.3s; }
.btn-primary:hover { background: var(--accent-dark); }
.btn-outline { background: rgba(24, 24, 27, 0.6); border: 1px solid var(--border); color: rgba(255,255,255,0.7); padding: 12px 32px; border-radius: 12px; font-weight: 600; text-transform: lowercase; backdrop-filter: blur(4px); transition: 0.3s; }
.btn-outline:hover { border-color: rgba(168, 85, 247, 0.5); color: var(--accent); }

/* Features */
.features-section { padding: 96px 0; background: rgba(10, 10, 10, 0.3); border-top: 1px solid var(--border); }
.section-header { text-align: center; margin-bottom: 48px; }
.section-header h2 { font-size: 2.25rem; text-transform: lowercase; }
.section-header p { color: rgba(255,255,255,0.4); margin-top: 8px; text-transform: lowercase; }

.features-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; max-width: 900px; margin: 0 auto; }
.feature-card { background: rgba(24, 24, 27, 0.5); border: 1px solid var(--border); border-radius: 16px; padding: 24px; backdrop-filter: blur(4px); transition: 0.3s; cursor: pointer; }
.feature-card:hover { border-color: rgba(168, 85, 247, 0.4); }
.feature-card h3 { font-size: 1.125rem; margin-bottom: 8px; text-transform: lowercase; }
.feature-card p { font-size: 0.875rem; color: rgba(255,255,255,0.45); line-height: 1.6; text-transform: lowercase; }

/* FAQ */
.faq-section { padding: 96px 0; background: rgba(10, 10, 10, 0.3); border-top: 1px solid var(--border); }
.faq-list { display: flex; flex-direction: column; gap: 16px; margin-top: 48px; }
.faq-item { background: rgba(24, 24, 27, 0.5); border: 1px solid var(--border); border-radius: 12px; backdrop-filter: blur(4px); transition: 0.3s; overflow: hidden; }
.faq-item:hover { border-color: rgba(168, 85, 247, 0.4); }
.faq-btn { width: 100%; background: none; border: none; padding: 20px 24px; display: flex; justify-content: space-between; align-items: center; color: var(--text-main); cursor: pointer; text-align: left; }
.faq-btn h3 { font-size: 1rem; text-transform: lowercase; }
.faq-btn .icon { width: 16px; height: 16px; color: var(--accent); transition: transform 0.3s; }
.faq-item.active .icon { transform: rotate(180deg); }
.faq-content { max-height: 0; overflow: hidden; transition: max-height 0.3s ease; }
.faq-item.active .faq-content { max-height: 200px; }
.faq-content p { padding: 0 24px 20px; font-size: 0.875rem; color: rgba(255,255,255,0.45); line-height: 1.6; text-transform: lowercase; }

/* CTA */
.cta-section { padding: 80px 0; border-top: 1px solid var(--border); position: relative; overflow: hidden; }
.cta-bg { position: absolute; inset: 0; background: linear-gradient(to bottom, rgba(168, 85, 247, 0.05), transparent); pointer-events: none; }
.cta-section h2 { font-size: 2.25rem; text-transform: lowercase; }

/* Footer */
footer { padding: 32px 0; border-top: 1px solid var(--border); background: rgba(10, 10, 10, 0.5); backdrop-filter: blur(4px); }
.footer-flex { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; }
.footer-brand { display: flex; align-items: center; gap: 8px; font-family: var(--font-heading); font-size: 1.125rem; }
.logo-icon-small { width: 20px; height: 20px; background: linear-gradient(135deg, var(--accent-light), var(--accent-dark)); color: #fff; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-size: 12px; font-weight: 800; }
.footer-sub { font-size: 0.875rem; color: rgba(255,255,255,0.4); text-transform: lowercase; }
.footer-links { display: flex; gap: 16px; font-size: 0.875rem; color: rgba(255,255,255,0.4); text-transform: lowercase; }
.footer-links a:hover { color: var(--accent); }

@media (max-width: 768px) {
    .nav-links { display: none; }
    .menu-btn { display: block; }
    .hero-title { font-size: 3rem; }
    .cat-gif { display: none; }
}
"""

js = """
// Discord Links
const DISCORD = "https://discord.gg/pxWVmpjV";
document.querySelectorAll('.discord-link').forEach(a => {
    a.addEventListener('click', e => { e.preventDefault(); window.open(DISCORD, '_blank'); });
});

// Copy button
const copyBtn = document.getElementById('copyBtn');
if (copyBtn) {
    copyBtn.addEventListener('click', () => {
        const text = 'loadstring(game:HttpGet("https://kunsydev.xyz/raw/loader.lua"))()';
        navigator.clipboard.writeText(text).then(() => {
            copyBtn.textContent = 'copied';
            setTimeout(() => { copyBtn.textContent = 'copy'; }, 1500);
        });
    });
}

// FAQ Accordion
document.querySelectorAll('.faq-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const item = btn.parentElement;
        const isActive = item.classList.contains('active');
        document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('active'));
        if (!isActive) item.classList.add('active');
    });
});
"""

with open(r"C:\Project\hub-library\site\index.html", "w", encoding="utf-8") as f:
    f.write(html)
with open(r"C:\Project\hub-library\site\style.css", "w", encoding="utf-8") as f:
    f.write(css)
with open(r"C:\Project\hub-library\site\main.js", "w", encoding="utf-8") as f:
    f.write(js)
