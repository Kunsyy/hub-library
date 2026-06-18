import re
import os

path = r"C:\Project\hub-library\site\index.html"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Extract style
style_match = re.search(r'<style>(.*?)</style>', content, re.DOTALL)
style_content = style_match.group(1).strip() if style_match else ""

with open(r"C:\Project\hub-library\site\style.css", "w", encoding="utf-8") as f:
    f.write(style_content)

# Define head template
head = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Kunsy Hub — Premium Roblox Scripts</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="style.css">
</head>
<body>

<nav><div class="wrap">
  <a href="index.html" class="brand"><span class="logo">K</span> Kunsy Hub</a>
  <div class="navlinks">
    <a href="features.html">Features</a>
    <a href="games.html">Games</a>
    <a href="pricing.html">Pricing</a>
    <a href="#" id="discordTop">Discord</a>
  </div>
  <a class="btn btn-primary" href="pricing.html">Get Key</a>
</div></nav>
"""

footer = """
<footer><div class="wrap">
  <a href="index.html" class="brand"><span class="logo">K</span> Kunsy Hub</a>
  <div class="sub">© 2026 Kunsy Hub. Not affiliated with Roblox Corporation.</div>
</div></footer>

<script src="main.js"></script>
</body>
</html>
"""

# Extract sections
hero_match = re.search(r'(<section class="hero">.*?</section>)', content, re.DOTALL)
features_match = re.search(r'(<section class="block" id="features">.*?</section>)', content, re.DOTALL)
games_match = re.search(r'(<section class="block" id="games">.*?</section>)', content, re.DOTALL)
pricing_match = re.search(r'(<section class="block" id="pricing">.*?</section>)', content, re.DOTALL)
cta_match = re.search(r'(<section class="block"><div class="wrap"><div class="bigcta">.*?</section>)', content, re.DOTALL)
modal_match = re.search(r'(<div class="gmodal" id="gmodal">.*?</div>)', content, re.DOTALL)

hero = hero_match.group(1) if hero_match else ""
features = features_match.group(1) if features_match else ""
games = games_match.group(1) if games_match else ""
pricing = pricing_match.group(1) if pricing_match else ""
cta = cta_match.group(1) if cta_match else ""
modal = modal_match.group(1) if modal_match else ""

# Write main.js
js_content = """
const DISCORD = "https://discord.gg/pxWVmpjV";
document.querySelectorAll('#discordTop,#discordHero,#discordBottom,[data-discord]').forEach(function(a){
  if(a) a.addEventListener('click',function(e){e.preventDefault();window.open(DISCORD,'_blank');});
});

const copyBtn=document.getElementById('copyBtn'),loadstr=document.getElementById('loadstr');
if (copyBtn && loadstr) {
  copyBtn.addEventListener('click',function(){
    navigator.clipboard.writeText(loadstr.textContent).then(function(){
      copyBtn.textContent='Copied!';copyBtn.classList.add('copied');
      setTimeout(function(){copyBtn.textContent='Copy';copyBtn.classList.remove('copied');},1600);
    });
  });
}

function prettyName(s){return s.replace(/([a-z0-9])([A-Z])/g,'$1 $2').replace(/([A-Za-z])([0-9])/g,'$1 $2').replace(/([A-Z]+)([A-Z][a-z])/g,'$1 $2').trim();}
function initials(s){return s.split(/\\s+/).filter(Boolean).slice(0,3).map(function(w){return w[0];}).join('').toUpperCase();}

const modal=document.getElementById('gmodal');
if (modal) {
  function openGame(g){
    const head=modal.querySelector('.gmhead');
    head.style.backgroundImage=g.thumb?('url('+g.thumb+')'):'';
    head.querySelector('.gmini').textContent=g.thumb?'':initials(g.name);
    modal.querySelector('#gmName').textContent=g.name;
    const sub=modal.querySelector('#gmSub');
    sub.textContent=g.supported?'● Supported':'● Coming soon';
    sub.style.color=g.supported?'#4ade80':'#f0b429';
    const body=modal.querySelector('#gmBody');
    if(g.supported){
      var free=(g.features&&g.features.length?g.features:['Auto farm','Auto sell','Anti-AFK']);
      var prem=g.premium||[];
      var fl=function(items){return '<ul class="featlist">'+items.map(function(f){return '<li><span class="ck">✓</span>'+f+'</li>';}).join('')+'</ul>';};
      var html='<div class="gmsection"><div class="lbl">Free features</div>'+fl(free)+'</div>';
      if(prem.length){html+='<div class="gmprem"><div class="lbl"><span class="ptag">PREMIUM</span> Unlocked with a key</div>'+fl(prem)+'</div>';}
      body.innerHTML=html;
    }else{
      body.innerHTML='<p class="gmsoon" style="color:var(--sub); margin-bottom: 24px;">This game is on our roadmap. Want it prioritized? Vote & request it in our Discord.</p><a class="btn btn-primary" id="gmDiscord" href="#">Request in Discord</a>';
      body.querySelector('#gmDiscord').addEventListener('click',function(e){e.preventDefault();window.open(DISCORD,'_blank');});
    }
    modal.classList.add('open');
  }
  modal.addEventListener('click',function(e){if(e.target===modal||e.target.closest('.gmclose'))modal.classList.remove('open');});
  document.addEventListener('keydown',function(e){if(e.key==='Escape')modal.classList.remove('open');});
  
  function makeCard(g){
    const card=document.createElement('div');
    card.className='gamecard';
    card.innerHTML='<div class="gthumb"'+(g.thumb?(' style="background-image:url('+g.thumb+')"'):'')+'>'+(g.thumb?'':'<span class="gini">'+initials(g.name)+'</span>')+'<div class="seehint">See features</div></div><div class="gbody"><h3>'+g.name+'</h3><span class="sup'+(g.supported?'':' soon')+'">'+(g.supported?'Supported':'Soon')+'</span></div>';
    card.addEventListener('click',function(){openGame(g);});
    return card;
  }

  const grid=document.getElementById('gamesGrid');
  if(grid) {
    fetch('https://raw.githubusercontent.com/Kunsyy/hub-library/main/games.json?v='+Date.now())
      .then(function(r){return r.json();})
      .then(function(d){
        const games=d.games||{},keys=Object.keys(games);
        grid.innerHTML='';
        keys.forEach(function(name){
          const info=games[name];
          grid.appendChild(makeCard({
            name:info.display||prettyName(name),
            thumb:info.thumb||'',
            features:info.features||[],
            premium:info.premiumFeatures||[],
            supported:info.supported!==false
          }));
        });
        (d.comingSoon||[]).forEach(function(item){
          const obj=(typeof item==='string')?{name:item}:item;
          grid.appendChild(makeCard({name:obj.name,thumb:obj.thumb||'',features:[],supported:false}));
        });
        const stGames = document.getElementById('stGames');
        const gameCount = document.getElementById('gameCount');
        if (stGames) stGames.textContent=keys.length;
        if (gameCount) gameCount.textContent=keys.length;
      }).catch(function(){});
  }
}

document.querySelectorAll('[data-buy]').forEach(function(b){
  if(b) b.addEventListener('click',function(e){e.preventDefault();window.open(DISCORD,'_blank');});
});
const adsBtn = document.getElementById('adsBtn');
if (adsBtn) adsBtn.addEventListener('click',function(e){e.preventDefault();window.open(DISCORD,'_blank');});
"""
with open(r"C:\Project\hub-library\site\main.js", "w", encoding="utf-8") as f:
    f.write(js_content)

# Write index.html
with open(r"C:\Project\hub-library\site\index.html", "w", encoding="utf-8") as f:
    f.write(head + "\\n" + hero + "\\n" + cta + "\\n" + footer)

# Write features.html
with open(r"C:\Project\hub-library\site\features.html", "w", encoding="utf-8") as f:
    f.write(head + "\\n" + features + "\\n" + cta + "\\n" + footer)

# Write games.html
with open(r"C:\Project\hub-library\site\games.html", "w", encoding="utf-8") as f:
    f.write(head + "\\n" + games + "\\n" + modal + "\\n" + cta + "\\n" + footer)

# Write pricing.html
with open(r"C:\Project\hub-library\site\pricing.html", "w", encoding="utf-8") as f:
    f.write(head + "\\n" + pricing + "\\n" + footer)

print("Done generating multiple pages!")
