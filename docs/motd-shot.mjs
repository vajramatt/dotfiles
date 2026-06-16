#!/usr/bin/env node
// Render docs/motd.ansi (the staged capture from motd-shot.zsh) to docs/motd.png
// via headless Chrome, so the README screenshot is reproducible and contains
// zero real machine data. Needs JetBrainsMono Nerd Font installed locally.
//
//   zsh docs/motd-shot.zsh && node docs/motd-shot.mjs
import { readFileSync, writeFileSync, rmSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';

const docs = dirname(fileURLToPath(import.meta.url));
const ansi = readFileSync(join(docs, 'motd.ansi'), 'utf8');

const BG = '#101012'; // terminal matte; the emblem rides on it with no box
const FG = '#c0caf5';
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// Minimal SGR parser: reset, bold, italic, 38;2 fg, 48;2 bg — all motd.sh emits.
function ansiToHtml(text) {
  let fg = null, bg = null, bold = false, italic = false;
  const span = (s) => {
    if (!s) return '';
    const css = [
      fg && `color:${fg}`, bg && `background:${bg}`,
      bold && 'font-weight:700', italic && 'font-style:italic',
    ].filter(Boolean).join(';');
    return css ? `<span style="${css}">${esc(s)}</span>` : esc(s);
  };
  let out = '', buf = '';
  const re = /\x1b\[([0-9;]*)m/g;
  let last = 0, m;
  while ((m = re.exec(text))) {
    buf = text.slice(last, m.index);
    out += span(buf);
    last = re.lastIndex;
    const p = m[1].split(';').map(Number);
    for (let i = 0; i < p.length; i++) {
      if (p[i] === 0) { fg = bg = null; bold = italic = false; }
      else if (p[i] === 1) bold = true;
      else if (p[i] === 3) italic = true;
      else if (p[i] === 38 && p[i + 1] === 2) { fg = `rgb(${p[i+2]},${p[i+3]},${p[i+4]})`; i += 4; }
      else if (p[i] === 48 && p[i + 1] === 2) { bg = `rgb(${p[i+2]},${p[i+3]},${p[i+4]})`; i += 4; }
    }
  }
  out += span(text.slice(last));
  return out;
}

// lineH 1.2 makes cells exactly 2:1 (16.8 x 8.4 px) like a real terminal grid,
// so the half-block HAL eye keeps its round proportions.
const fontPx = 14, lineH = 1.2, padPx = 24;
const lines = ansi.replace(/\n$/, '').split('\n');
const stripped = lines.map((l) => l.replace(/\x1b\[[0-9;]*m/g, ''));
const maxCols = Math.max(...stripped.map((l) => [...l].length));
const w = Math.ceil(maxCols * fontPx * 0.6 + padPx * 2);
const h = Math.ceil(lines.length * fontPx * lineH + padPx * 2);

const html = `<!doctype html><meta charset="utf-8">
<style>
  html, body { margin: 0; background: ${BG}; }
  pre {
    margin: 0; padding: ${padPx}px;
    font: ${fontPx}px/${lineH} "JetBrainsMono Nerd Font", "JetBrains Mono", monospace;
    color: ${FG};
  }
</style>
<pre>${lines.map(ansiToHtml).join('\n')}</pre>`;

const tmp = join(tmpdir(), 'motd-shot.html');
writeFileSync(tmp, html);
const out = join(docs, 'motd.png');
execFileSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
  '--headless', `--screenshot=${out}`, `--window-size=${w},${h}`,
  '--force-device-scale-factor=2', '--hide-scrollbars', tmp,
], { stdio: 'ignore' });
rmSync(tmp);
console.log(`wrote ${out} (${w * 2}x${h * 2})`);
