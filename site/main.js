
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
