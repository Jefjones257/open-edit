import fs from 'node:fs';
import path from 'node:path';
const [media, transcriptPath, outDir, durationArg] = process.argv.slice(2);
const duration=Number(durationArg);
if(!media||!transcriptPath||!outDir||!Number.isFinite(duration)||duration<=0) throw Error('Usage: node build-page.mjs media transcript outDir durationSeconds');
const preset=JSON.parse(fs.readFileSync(new URL('./presets/clean.json',import.meta.url)));
const transcript=JSON.parse(fs.readFileSync(transcriptPath));
const words=transcript.chunks.flatMap(c=>c.words);
if(!words.length) throw Error('No word timings; review transcript before rendering');
for(const w of words) if(typeof w.text!=='string'||!w.timestamp?.every(Number.isFinite)||w.timestamp[1]<w.timestamp[0]) throw Error('Invalid word timestamp');
fs.mkdirSync(outDir,{recursive:true});
// Each piece carries its footage, transcript, preset and page in one directory.
for(const [src,name] of [[media,'footage.mp4'],[transcriptPath,'transcript.json']]) {
 if(path.resolve(src)!==path.resolve(outDir,name)) fs.copyFileSync(src,path.join(outDir,name));
}
fs.writeFileSync(path.join(outDir,'preset.json'),JSON.stringify(preset,null,2));
const safeJSON=x=>JSON.stringify(x).replaceAll('<','\\u003c');
fs.writeFileSync(path.join(outDir,'index.html'),`<!doctype html><html><meta charset="utf-8"><style>
*{box-sizing:border-box}body{margin:0;background:#101216}#stage{width:1080px;height:1920px;position:relative;overflow:hidden;background:#101216}
video{width:100%;height:100%;object-fit:cover;transform-origin:50% 45%}#shade{position:absolute;inset:0;background:linear-gradient(transparent 45%,rgba(0,0,0,.25));pointer-events:none}
#caption{position:absolute;left:${preset.captions.leftPx}px;right:${preset.captions.rightPx}px;bottom:${preset.captions.bottomPx}px;text-align:center;font:800 ${preset.captions.fontSize}px/1.18 Arial,sans-serif;color:white;text-shadow:0 3px 8px #000,0 0 3px #000;-webkit-text-stroke:1px #000;overflow-wrap:anywhere}
.word{display:inline-block;margin:0 8px;white-space:pre-wrap}#fade{position:absolute;inset:0;background:#101216;pointer-events:none}
</style><div id="stage"><video muted src="footage.mp4"></video><div id="shade"></div><div id="caption"></div><div id="fade"></div></div><script>
const words=${safeJSON(words)},cfg=${safeJSON(preset)},duration=${duration};
const phrases=[];let phrase=[];
for(const word of words){const last=phrase.at(-1);if(phrase.length&&(phrase.length>=cfg.captions.wordsPerPhrase||phrase.map(w=>w.text).join(' ').length+word.text.length+1>cfg.captions.maxPhraseChars||word.timestamp[0]-last.timestamp[1]>cfg.captions.gapSeconds)){phrases.push(phrase);phrase=[]}phrase.push(word)}if(phrase.length)phrases.push(phrase);
const video=document.querySelector('video'),caption=document.querySelector('#caption'),fade=document.querySelector('#fade');let current;
window.__seek=t=>{
 const phase=(1-Math.cos(2*Math.PI*t/cfg.motion.zoomPeriodSeconds))/2;
 video.style.transform='scale('+(1+(cfg.motion.zoomMax-1)*phase)+')';
 const p=phrases.find(p=>t>=p[0].timestamp[0]&&t<p.at(-1).timestamp[1]);
 if(current!==p){caption.replaceChildren();if(p)for(const w of p){const s=document.createElement('span');s.className='word';s.textContent=w.text;caption.append(s)}current=p}
 if(p)Array.from(caption.children).forEach((el,i)=>{const w=p[i],active=t>=w.timestamp[0]&&t<w.timestamp[1];el.style.color=active?cfg.captions.activeColor:cfg.captions.textColor;const pop=Math.min(1,Math.max(0,(t-w.timestamp[0])/cfg.captions.popSeconds));el.style.transform='scale('+(active?1.06-0.06*pop:1)+')'});
 fade.style.opacity=String(Math.max(0,1-t/cfg.motion.edgeFadeSeconds,1-(duration-t)/cfg.motion.edgeFadeSeconds));
};window.__seek(0);
</script></html>`);
console.log(path.resolve(outDir,'index.html'));
